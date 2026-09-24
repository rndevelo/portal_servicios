import 'package:flutter_test/flutter_test.dart';
import 'package:portal_servicios/app/router.dart';
import 'package:portal_servicios/features/requests/domain/request.dart';
import 'package:portal_servicios/features/requests/domain/draft.dart';
import 'package:portal_servicios/features/requests/data/memory_drafts.dart';
import 'package:portal_servicios/features/requests/data/memory_request_repository.dart';
import 'package:portal_servicios/features/requests/data/http_request_repository.dart';

void main() {
  test('idempotencia conserva recurso y detecta payload distinto', () async {
    final repo = MemoryRequestRepository();
    final first = await repo.create(
      userId: 'ana',
      title: 'Servicio nuevo',
      description: 'Motivo del servicio',
      idempotencyKey: 'intent-1',
    );
    final second = await repo.create(
      userId: 'ana',
      title: 'Servicio nuevo',
      description: 'Motivo del servicio',
      idempotencyKey: 'intent-1',
    );
    expect(first.id, second.id);
    await expectLater(
      repo.create(
        userId: 'ana',
        title: 'Otro servicio',
        description: 'Motivo del servicio',
        idempotencyKey: 'intent-1',
      ),
      throwsA(isA<AppFailure>()),
    );
    await expectLater(repo.get('bruno', first.id), throwsA(isA<AppFailure>()));
  });

  test('borradores aíslan cuentas y rechazan una revisión anterior', () async {
    final repo = MemoryDraftRepository();
    RequestDraft draft(int revision) => RequestDraft(
      userId: 'ana',
      requestId: 'new',
      title: 'Revisión $revision',
      description: 'Motivo válido',
      revision: revision,
      idempotencyKey: 'intent',
      resultUnknown: false,
    );
    await repo.save(draft(5));
    await repo.save(draft(4));
    expect((await repo.read('ana', 'new'))?.revision, 5);
    expect(await repo.read('bruno', 'new'), isNull);
    await repo.deleteIfRevision('ana', 'new', 4);
    expect(await repo.read('ana', 'new'), isNotNull);
  });

  test('contrato distingue enum nuevo de entidad incompleta', () {
    expect(parseStatus('future_state'), RequestStatus.unknown);
    expect(() => parseRequest({'id': 'x'}), throwsA(isA<AppFailure>()));
  });

  test('retorno de login rechaza ubicaciones externas', () {
    expect(safeReturnPath('/requests/req-1'), '/requests/req-1');
    expect(safeReturnPath('https://example.org'), '/requests');
    expect(safeReturnPath('//example.org/requests'), '/requests');
    expect(safeReturnPath('/login'), '/requests');
  });
}
