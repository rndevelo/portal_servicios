class RequestDraft {
  const RequestDraft({
    required this.userId,
    required this.requestId,
    required this.title,
    required this.description,
    required this.revision,
    required this.idempotencyKey,
    required this.resultUnknown,
  });
  final String userId;
  final String requestId;
  final String title;
  final String description;
  final int revision;
  final String idempotencyKey;
  final bool resultUnknown;
}

abstract interface class DraftRepository {
  Future<RequestDraft?> read(String userId, String requestId);
  Future<void> save(RequestDraft draft);
  Future<void> deleteIfRevision(String userId, String requestId, int revision);
}
