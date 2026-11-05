import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:portal_servicios/main.dart';
import 'package:portal_servicios/app/dependencies.dart';
import 'package:portal_servicios/features/requests/data/memory_request_repository.dart';
import 'package:portal_servicios/features/requests/domain/request.dart';

class PendingRepository extends MemoryRequestRepository {
  final pending = Completer<void>();
  int calls = 0;
  @override
  Future<ServiceRequest> create({
    required String userId,
    required String title,
    required String description,
    required String idempotencyKey,
  }) async {
    calls++;
    await pending.future;
    return super.create(
      userId: userId,
      title: title,
      description: description,
      idempotencyKey: idempotencyKey,
    );
  }
}

void main() {
  testWidgets('la creación pendiente deshabilita el segundo envío', (
    tester,
  ) async {
    final repository = PendingRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [repositoryProvider.overrideWithValue(repository)],
        child: const PortalApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('login-ana')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('new-request')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('request-title')),
      'Acceso remoto',
    );
    await tester.enterText(
      find.byKey(const Key('request-reason')),
      'Necesito acceso al portal',
    );
    await tester.tap(find.byKey(const Key('request-submit')));
    await tester.pump();
    expect(repository.calls, 1);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('request-submit')))
          .onPressed,
      isNull,
    );
    repository.pending.complete();
    await tester.pumpAndSettle();
    expect(find.text('Acceso remoto'), findsOneWidget);
    expect(repository.calls, 1);
  });

  testWidgets(
  'el listado no desborda a 360 ni a 800 píxeles',
  (tester) async {
    final repository = MemoryRequestRepository();

    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          repositoryProvider.overrideWithValue(repository),
        ],
        child: const PortalApp(),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('login-ana')));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    tester.view.physicalSize = const Size(800, 900);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  },
);
}
