from datetime import datetime, timedelta, timezone
import json
import threading
import unittest
from urllib.error import HTTPError
from urllib.request import Request, urlopen
from lab_server import LabServer


class ServerTests(unittest.TestCase):
    def setUp(self):
        self.server = LabServer(('127.0.0.1', 0))
        self.thread = threading.Thread(target=self.server.serve_forever, daemon=True)
        self.thread.start()
        self.base = f'http://127.0.0.1:{self.server.server_port}'

    def tearDown(self):
        self.server.shutdown()
        self.server.server_close()
        self.thread.join()

    def call(self, path, method='GET', body=None, user='ana', key=None, fault=None, token=None, timeout=6):
        headers = {'Authorization': 'Bearer ' + (token or f'lab-{user}')}
        if body is not None:
            headers['Content-Type'] = 'application/json'
        if key:
            headers['Idempotency-Key'] = key
        if fault:
            headers['X-Lab-Fault'] = fault
        req = Request(self.base + path, method=method, headers=headers,
                      data=None if body is None else json.dumps(body).encode())
        try:
            response = urlopen(req, timeout=timeout)
        except HTTPError as error:
            response = error
        with response:
            return response.status, json.loads(response.read())

    def test_isolation_and_pagination(self):
        status, page = self.call('/requests')
        self.assertEqual(status, 200)
        self.assertEqual(len(page['items']), 3)
        self.assertTrue(all(x['owner_id'] == 'ana' for x in page['items']))
        self.assertEqual(self.call('/requests/req-1', user='bruno')[0], 404)
        self.assertEqual(self.call('/requests?cursor=-1')[0], 400)

    def test_idempotency_and_validation(self):
        body = {'title': 'Acceso al portal', 'description': 'Necesito acceso remoto'}
        first = self.call('/requests', 'POST', body, key='intent-a')
        second = self.call('/requests', 'POST', body, key='intent-a')
        self.assertEqual(first[1]['id'], second[1]['id'])
        self.assertEqual(self.server.state.creates, 1)
        self.assertEqual(self.call('/requests', 'POST', {**body, 'title': 'Cambio'}, key='intent-a')[0], 409)
        self.assertEqual(self.call('/requests', 'POST', {'title': 'x'}, key='intent-b')[0], 422)

    def test_version_conflict_and_replay(self):
        body = {'version': 1, 'description': 'Nuevo motivo de la solicitud'}
        first = self.call('/requests/req-1', 'PATCH', body, key='edit-1')
        self.assertEqual(first[1]['version'], 2)
        self.assertEqual(self.call('/requests/req-1', 'PATCH', body, key='edit-1')[0], 200)
        self.assertEqual(self.call('/requests/req-1', 'PATCH', body, key='edit-2')[0], 409)

    def test_refresh_rotation(self):
        self.call('/lab/expire', 'POST', {'user_id': 'ana'})
        self.assertEqual(self.call('/requests')[0], 401)
        status, pair = self.call('/lab/refresh', 'POST', {'refresh_token': 'refresh-ana'})
        self.assertEqual(status, 200)
        self.assertEqual(self.call('/requests', token=pair['access_token'])[0], 200)
        self.assertEqual(self.call('/lab/refresh', 'POST', {'refresh_token': 'refresh-ana'})[0], 400)

    def test_legacy_and_recovery(self):
        status, body = self.call('/requests', fault='legacy_expired')
        self.assertEqual(status, 200)
        self.assertEqual(body['code'], 'EEM030')
        self.assertIn('items', self.call('/requests', fault='legacy_expired')[1])
        self.assertEqual(self.call('/requests', fault='503')[0], 503)
        self.assertEqual(self.call('/requests', fault='503')[0], 200)

    def test_confirmed_response_loss(self):
        body = {'title': 'Respuesta perdida', 'description': 'Motivo de laboratorio'}
        with self.assertRaises(TimeoutError):
            self.call('/requests', 'POST', body, key='lost-response',
                      fault='post_confirmed_timeout', timeout=0.1)
        status, recovered = self.call('/requests', 'POST', body, key='lost-response')
        self.assertEqual(status, 200)
        self.assertEqual(self.server.state.creates, 1)
        self.assertEqual(self.server.state.items[recovered['id']], recovered)

    def test_dates_and_strict_version(self):
        status, page = self.call('/requests?created_from=2026-09-01T10:02:00Z&created_to=2026-09-01T10:04:00Z')
        self.assertEqual(status, 200)
        self.assertEqual([x['id'] for x in page['items']], ['req-2', 'req-3'])
        future = (datetime.now(timezone.utc) + timedelta(days=7)).isoformat()
        body = {'version': True, 'scheduled_at': future}
        self.assertEqual(self.call('/requests/req-1', 'PATCH', body, key='bad-version')[0], 422)
        body['version'] = 1
        self.assertEqual(self.call('/requests/req-1', 'PATCH', body, key='schedule')[1]['version'], 2)
        self.assertEqual(self.call('/lab/refresh', 'POST', {'refresh_token': {}})[0], 400)


if __name__ == '__main__':
    unittest.main()
