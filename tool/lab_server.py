from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import json
import secrets
import threading
import time
from urllib.parse import urlparse, parse_qs


class LabState:
    def __init__(self):
        self.lock = threading.RLock()
        self.items = {}
        for i in range(1, 13):
            self.items[f'req-{i}'] = {
                'id': f'req-{i}', 'owner_id': 'ana' if i <= 6 else 'bruno',
                'title': f'Servicio {i}',
                'description': f'Descripción de laboratorio {i}',
                'status': ['open', 'in_progress', 'closed'][(i - 1) % 3],
                'version': 1, 'created_at': f'2026-09-01T10:{i:02}:00Z',
                'scheduled_at': None,
            }
        self.access = {'lab-ana': 'ana', 'lab-bruno': 'bruno'}
        self.refresh = {'refresh-ana': 'ana', 'refresh-bruno': 'bruno'}
        self.idempotency = {}
        self.faults = set()
        self.sequence = 100
        self.creates = 0
        self.renewals = 0


class LabServer(ThreadingHTTPServer):
    daemon_threads = True

    def __init__(self, address):
        self.state = LabState()
        super().__init__(address, Handler)


class Handler(BaseHTTPRequestHandler):
    server_version = 'PortalLab/1.0'

    def log_message(self, format, *args):
        # No registrar Authorization, cuerpos ni datos del formulario.
        pass

    def send_json(self, status, body, headers=None):
        payload = json.dumps(body, ensure_ascii=False).encode('utf-8')
        self.send_bytes(status, payload, headers)

    def send_bytes(self, status, payload, headers=None):
        try:
            self.send_response(status)
            self.send_header('Content-Type', 'application/json; charset=utf-8')
            self.send_header('Content-Length', str(len(payload)))
            for key, value in (headers or {}).items():
                self.send_header(key, value)
            self.end_headers()
            self.wfile.write(payload)
        except (BrokenPipeError, ConnectionResetError):
            pass

    def read_body(self):
        try:
            length = int(self.headers.get('Content-Length', '0'))
            if length < 0 or length > 65536:
                raise ValueError('size')
            body = json.loads(self.rfile.read(length))
            if not isinstance(body, dict):
                raise ValueError('object required')
            return body
        except (ValueError, UnicodeDecodeError):
            self.send_json(400, {'code': 'invalid_json'})
            return None

    def principal(self):
        value = self.headers.get('Authorization', '')
        token = value[7:] if value.startswith('Bearer ') else ''
        with self.server.state.lock:
            user = self.server.state.access.get(token)
        if user is None:
            self.send_json(401, {'code': 'session_expired'})
        return user

    def consume_fault(self, user, name):
        if self.headers.get('X-Lab-Fault') != name:
            return False
        state = self.server.state
        with state.lock:
            key = (user, name)
            if key in state.faults:
                return False
            state.faults.add(key)
            return True

    def fail_before(self, user):
        for name, status in [('503', 503), ('403', 403), ('404', 404),
                             ('429', 429), ('422', 422)]:
            if self.consume_fault(user, name):
                body = {'code': f'fixture_{name}'}
                if status == 422:
                    body['fields'] = {'description': 'rejected_by_fixture'}
                self.send_json(status, body, {'Retry-After': '1'} if status == 429 else None)
                return True
        if self.consume_fault(user, 'legacy_expired'):
            self.send_json(200, {'has_error': True, 'code': 'EEM030'})
            return True
        if self.consume_fault(user, 'legacy_business'):
            self.send_json(200, {'has_error': True, 'code': 'REQUEST_NOT_EDITABLE'})
            return True
        if self.consume_fault(user, 'malformed_json'):
            self.send_bytes(200, b'{broken')
            return True
        if self.consume_fault(user, 'timeout'):
            time.sleep(4)
        return False

    def do_GET(self):
        parsed = urlparse(self.path)
        state = self.server.state
        if parsed.path == '/lab/stats':
            with state.lock:
                self.send_json(200, {'creates': state.creates, 'renewals': state.renewals})
            return
        user = self.principal()
        if user is None or self.fail_before(user):
            return
        if parsed.path == '/me':
            self.send_json(200, {'id': user, 'display_name': user.capitalize()})
            return
        if parsed.path == '/services':
            self.send_json(200, {'items': [{'id': 'support', 'name': 'Soporte'}]})
            return
        if parsed.path == '/requests':
            args = parse_qs(parsed.query)
            query = args.get('query', [''])[0]
            status = args.get('status', [None])[0]
            try:
                bounds = []
                for name in ('created_from', 'created_to'):
                    value = args.get(name, [None])[0]
                    instant = None if value is None else datetime.fromisoformat(value.replace('Z', '+00:00'))
                    if instant is not None and instant.tzinfo is None:
                        raise ValueError()
                    bounds.append(instant)
                start, end = bounds
                if start is not None and end is not None and start >= end:
                    raise ValueError()
            except ValueError:
                self.send_json(422, {'code': 'invalid_date_range'})
                return
            try:
                offset = int(args.get('cursor', ['0'])[0])
                if offset < 0:
                    raise ValueError()
            except ValueError:
                self.send_json(400, {'code': 'invalid_cursor'})
                return
            if self.headers.get('X-Lab-Fault') == 'reverse':
                time.sleep(0.4 if len(query) < 9 else 0.02)
            with state.lock:
                rows = [dict(x) for x in state.items.values()
                        if x['owner_id'] == user and query.casefold() in x['title'].casefold()
                        and (status is None or x['status'] == status)
                        and (start is None or datetime.fromisoformat(x['created_at'].replace('Z', '+00:00')) >= start)
                        and (end is None or datetime.fromisoformat(x['created_at'].replace('Z', '+00:00')) < end)]
            page = rows[offset:offset + 3]
            next_cursor = str(offset + 3) if offset + 3 < len(rows) else None
            if page and self.consume_fault(user, 'unknown_enum'):
                page[0]['status'] = 'new_backend_state'
            if offset > 0 and self.headers.get('X-Lab-Fault') == 'duplicate_page':
                page = rows[offset - 1:offset] + page
            self.send_json(200, {'items': page, 'next_cursor': next_cursor})
            return
        if parsed.path.startswith('/requests/'):
            request_id = parsed.path.removeprefix('/requests/')
            with state.lock:
                item = state.items.get(request_id)
                result = dict(item) if item and item['owner_id'] == user else None
            self.send_json(200 if result else 404, result or {'code': 'not_found'})
            return
        self.send_json(404, {'code': 'route_not_found'})

    def do_POST(self):
        path = urlparse(self.path).path
        body = self.read_body()
        if body is None:
            return
        state = self.server.state
        if path == '/lab/expire':
            user = body.get('user_id')
            if user not in ('ana', 'bruno'):
                self.send_json(422, {'code': 'unknown_lab_user'})
                return
            with state.lock:
                state.access = {t: u for t, u in state.access.items() if u != user}
            self.send_json(200, {'expired': True})
            return
        if path == '/lab/refresh':
            refresh_token = body.get('refresh_token')
            if not isinstance(refresh_token, str):
                self.send_json(400, {'code': 'invalid_grant'})
                return
            with state.lock:
                user = state.refresh.pop(refresh_token, None)
                if user is None:
                    self.send_json(400, {'code': 'invalid_grant'})
                    return
                access = 'access-' + secrets.token_hex(12)
                refresh = 'refresh-' + secrets.token_hex(12)
                state.access[access] = user
                state.refresh[refresh] = user
                state.renewals += 1
            self.send_json(200, {'access_token': access, 'refresh_token': refresh})
            return
        user = self.principal()
        if user is None or self.fail_before(user):
            return
        if path != '/requests':
            self.send_json(404, {'code': 'route_not_found'})
            return
        self.mutate(user, path, body, creating=True)

    def do_PATCH(self):
        path = urlparse(self.path).path
        body = self.read_body()
        if body is None:
            return
        user = self.principal()
        if user is None or self.fail_before(user):
            return
        if not path.startswith('/requests/'):
            self.send_json(404, {'code': 'route_not_found'})
            return
        self.mutate(user, path, body, creating=False)

    def mutate(self, user, path, body, creating):
        key = self.headers.get('Idempotency-Key', '')
        if not key or len(key) > 128:
            self.send_json(400, {'code': 'idempotency_key_required'})
            return
        fingerprint = json.dumps(body, sort_keys=True, separators=(',', ':'))
        scope = (user, self.command, path, key)
        state = self.server.state
        with state.lock:
            previous = state.idempotency.get(scope)
            if previous:
                old_fingerprint, old_result = previous
                if old_fingerprint != fingerprint:
                    self.send_json(409, {'code': 'idempotency_conflict'})
                else:
                    self.send_json(200, old_result)
                return
            fields = {}
            title = body.get('title')
            description = body.get('description')
            if creating and (not isinstance(title, str) or not 3 <= len(title.strip()) <= 80):
                fields['title'] = 'length'
            if (creating or 'description' in body) and (
                    not isinstance(description, str) or not 5 <= len(description.strip()) <= 500):
                fields['description'] = 'length'
            scheduled = body.get('scheduled_at')
            if 'scheduled_at' in body:
                try:
                    instant = datetime.fromisoformat(scheduled.replace('Z', '+00:00'))
                    if instant.tzinfo is None or instant <= datetime.now(timezone.utc):
                        raise ValueError()
                except (AttributeError, ValueError, TypeError):
                    fields['scheduled_at'] = 'future_instant_required'
            if fields:
                self.send_json(422, {'code': 'validation', 'fields': fields})
                return
            if creating:
                request_id = f'req-{state.sequence}'
                state.sequence += 1
                result = {'id': request_id, 'owner_id': user, 'title': title.strip(),
                          'description': description.strip(), 'status': 'open',
                          'version': 1, 'created_at': datetime.now(timezone.utc).isoformat(),
                          'scheduled_at': None}
                state.creates += 1
            else:
                request_id = path.removeprefix('/requests/')
                current = state.items.get(request_id)
                if current is None or current['owner_id'] != user:
                    self.send_json(404, {'code': 'not_found'})
                    return
                if current['status'] != 'open':
                    self.send_json(422, {'code': 'not_editable'})
                    return
                if type(body.get('version')) is not int or body['version'] < 1:
                    self.send_json(422, {'code': 'invalid_version'})
                    return
                if body['version'] != current['version']:
                    self.send_json(409, {'code': 'version_conflict', 'current_version': current['version']})
                    return
                if 'description' not in body and 'scheduled_at' not in body:
                    self.send_json(422, {'code': 'empty_update'})
                    return
                result = dict(current)
                if 'description' in body:
                    result['description'] = description.strip()
                if 'scheduled_at' in body:
                    result['scheduled_at'] = scheduled
                result['version'] += 1
            state.items[request_id] = result
            state.idempotency[scope] = (fingerprint, dict(result))
        if self.consume_fault(user, 'post_confirmed_timeout'):
            time.sleep(4)
        self.send_json(201 if creating else 200, result)


if __name__ == '__main__':
    server = LabServer(('127.0.0.1', 8080))
    print('Portal Lab: http://127.0.0.1:8080; datos ficticios en memoria')
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()
