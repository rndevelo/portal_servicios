import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/dependencies.dart';
import '../../auth/presentation/session.dart';
import '../domain/request.dart';

typedef RequestFilter = ({String query, RequestStatus? status});
final filterProvider = NotifierProvider<Filter, RequestFilter>(Filter.new);

class Filter extends Notifier<RequestFilter> {
  @override
  RequestFilter build() {
    ref.watch(sessionProvider);
    return (query: '', status: null);
  }

  void search(String value) =>
      state = (query: value.trim(), status: state.status);
  void selectStatus(RequestStatus? value) =>
      state = (query: state.query, status: value);
}

final requestsProvider = AsyncNotifierProvider<Requests, RequestPage>(
  Requests.new,
  retry: (count, error) => null,
);

class Requests extends AsyncNotifier<RequestPage> {
  int _revision = 0;
  @override
  Future<RequestPage> build() async {
    _revision++;
    ref.onDispose(() {
      _revision++;
    });
    final session = ref.watch(sessionProvider);
    final filter = ref.watch(filterProvider);
    final repository = ref.watch(repositoryProvider);
    if (session == null) return RequestPage(const [], null);
    return repository.list(
      userId: session.userId,
      query: filter.query,
      status: filter.status,
    );
  }

  Future<void> reload() async {
    ref.invalidateSelf();
    await future;
  }

  Future<void> loadMore() async {
    final snapshot = state;
    if (snapshot is! AsyncData<RequestPage>) return;
    final page = snapshot.value;
    final session = ref.read(sessionProvider);
    if (session == null || page.nextCursor == null || page.isLoadingMore) {
      return;
    }
    final revision = _revision;
    final filter = ref.read(filterProvider);
    final repository = ref.read(repositoryProvider);
    state = AsyncData(
      RequestPage(page.items, page.nextCursor, isLoadingMore: true),
    );
    try {
      final next = await repository.list(
        userId: session.userId,
        query: filter.query,
        status: filter.status,
        cursor: page.nextCursor,
      );
      if (!ref.mounted ||
          revision != _revision ||
          ref.read(sessionProvider)?.epoch != session.epoch) {
        return;
      }
      final merged = {for (final item in page.items) item.id: item};
      for (final item in next.items) {
        final old = merged[item.id];
        if (old == null || item.version >= old.version) merged[item.id] = item;
      }
      state = AsyncData(RequestPage(merged.values.toList(), next.nextCursor));
    } on Object catch (error) {
      if (!ref.mounted ||
          revision != _revision ||
          ref.read(sessionProvider)?.epoch != session.epoch) {
        return;
      }
      state = AsyncData(
        RequestPage(
          page.items,
          page.nextCursor,
          moreFailure: error is AppFailure
              ? error
              : const AppFailure('unexpected'),
        ),
      );
    }
  }
}

final detailProvider = FutureProvider.autoDispose
    .family<ServiceRequest, String>((ref, id) {
      final session = ref.watch(sessionProvider);
      if (session == null) throw const AppFailure('session_expired');
      return ref.watch(repositoryProvider).get(session.userId, id);
    }, retry: (count, error) => null);
