import '../domain/request.dart';

class MemoryRequestRepository implements RequestRepository {
  MemoryRequestRepository() {
    for (var i = 1; i <= 12; i++) {
      _items.add(
        ServiceRequest(
          id: 'req-$i',
          ownerId: i <= 6 ? 'ana' : 'bruno',
          title: 'Servicio $i',
          description: 'Descripción de laboratorio $i',
          status: RequestStatus.values[(i - 1) % 3],
          version: 1,
          createdAt: DateTime.utc(2026, 9, 1, 10, i),
        ),
      );
    }
  }
  final _items = <ServiceRequest>[];
  final _created = <(String, String), ServiceRequest>{};
  int _sequence = 100;

  @override
  Future<RequestPage> list({
    required String userId,
    required String query,
    RequestStatus? status,
    String? cursor,
  }) async {
    final offset = cursor == null ? 0 : int.tryParse(cursor);
    if (offset == null || offset < 0) throw const AppFailure('invalid_cursor');
    final rows = _items
        .where(
          (r) =>
              r.ownerId == userId &&
              r.title.toLowerCase().contains(query.toLowerCase()) &&
              (status == null || r.status == status),
        )
        .toList();
    final page = rows.skip(offset).take(3).toList();
    return RequestPage(
      page,
      offset + page.length < rows.length ? '${offset + page.length}' : null,
    );
  }

  @override
  Future<ServiceRequest> get(String userId, String id) async {
    for (final item in _items) {
      if (item.id == id && item.ownerId == userId) return item;
    }
    throw const AppFailure('not_found');
  }

  @override
  Future<ServiceRequest> create({
    required String userId,
    required String title,
    required String description,
    required String idempotencyKey,
  }) async {
    final errors = validateRequest(title, description);
    if (errors.isNotEmpty) throw AppFailure('validation', fields: errors);
    final key = (userId, idempotencyKey);
    final previous = _created[key];
    if (previous != null) {
      if (previous.title != title || previous.description != description) {
        throw const AppFailure('idempotency_conflict');
      }
      return previous;
    }
    final item = ServiceRequest(
      id: 'req-${_sequence++}',
      ownerId: userId,
      title: title,
      description: description,
      status: RequestStatus.open,
      version: 1,
      createdAt: DateTime.now().toUtc(),
    );
    _items.add(item);
    _created[key] = item;
    return item;
  }
}
