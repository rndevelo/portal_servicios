import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:portal_servicios/app/dependencies.dart';
import 'package:portal_servicios/features/auth/presentation/session.dart';
import 'package:portal_servicios/features/requests/domain/request.dart';
import 'package:portal_servicios/features/requests/data/memory_request_repository.dart';
import 'package:portal_servicios/features/requests/presentation/providers.dart';

class ControlledRepository extends MemoryRequestRepository {
  final oldPage = Completer<RequestPage>();
  @override
  Future<RequestPage> list({
    required String userId,
    required String query,
    RequestStatus? status,
    String? cursor,
  }) {
    if (userId == 'ana' && cursor != null) return oldPage.future;
    return super.list(
      userId: userId,
      query: query,
      status: status,
      cursor: cursor,
    );
  }
}

void main() {
  test('página pendiente de Ana no se publica en sesión de Bruno', () async {
    final repo = ControlledRepository();
    final container = ProviderContainer(
      overrides: [repositoryProvider.overrideWithValue(repo)],
    );
    final subscription = container.listen(
      requestsProvider,
      (previous, next) {},
    );
    addTearDown(() {
      subscription.close();
      container.dispose();
    });
    container.read(sessionProvider.notifier).login('ana');
    final ana = await container.read(requestsProvider.future);
    final pending = container.read(requestsProvider.notifier).loadMore();
    container.read(sessionProvider.notifier).login('bruno');
    await container.read(requestsProvider.future);
    repo.oldPage.complete(RequestPage(ana.items, null));
    await pending;
    final visible = await container.read(requestsProvider.future);
    expect(visible.items, isNotEmpty);
    expect(visible.items.every((item) => item.ownerId == 'bruno'), isTrue);
  });
}
