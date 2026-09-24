import '../domain/draft.dart';

class MemoryDraftRepository implements DraftRepository {
  final _items = <(String, String), RequestDraft>{};
  @override
  Future<RequestDraft?> read(String userId, String requestId) async =>
      _items[(userId, requestId)];
  @override
  Future<void> save(RequestDraft draft) async {
    final key = (draft.userId, draft.requestId);
    final old = _items[key];
    if (old == null || draft.revision >= old.revision) _items[key] = draft;
  }

  @override
  Future<void> deleteIfRevision(
    String userId,
    String requestId,
    int revision,
  ) async {
    final key = (userId, requestId);
    if (_items[key]?.revision == revision) _items.remove(key);
  }
}
