enum RequestStatus { open, inProgress, closed, unknown }

class AppFailure implements Exception {
  const AppFailure(this.code, {this.fields = const {}});
  final String code;
  final Map<String, String> fields;
  @override
  String toString() => 'AppFailure($code)';
}

class ServiceRequest {
  const ServiceRequest({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.description,
    required this.status,
    required this.version,
    required this.createdAt,
    this.scheduledAt,
  });
  final String id;
  final String ownerId;
  final String title;
  final String description;
  final RequestStatus status;
  final int version;
  final DateTime createdAt;
  final DateTime? scheduledAt;
}

class RequestPage {
  RequestPage(
    List<ServiceRequest> items,
    this.nextCursor, {
    this.isLoadingMore = false,
    this.moreFailure,
  }) : items = List.unmodifiable(items);
  final List<ServiceRequest> items;
  final String? nextCursor;
  final bool isLoadingMore;
  final AppFailure? moreFailure;
}

abstract interface class RequestRepository {
  Future<RequestPage> list({
    required String userId,
    required String query,
    RequestStatus? status,
    String? cursor,
  });
  Future<ServiceRequest> get(String userId, String id);
  Future<ServiceRequest> create({
    required String userId,
    required String title,
    required String description,
    required String idempotencyKey,
  });
}

Map<String, String> validateRequest(String title, String description) => {
  if (title.trim().length < 3 || title.trim().length > 80) 'title': 'length',
  if (description.trim().length < 5 || description.trim().length > 500)
    'description': 'length',
};
