import 'package:dio/dio.dart';
import '../domain/request.dart';

RequestStatus parseStatus(Object? raw) => switch (raw) {
  'open' => RequestStatus.open,
  'in_progress' => RequestStatus.inProgress,
  'closed' => RequestStatus.closed,
  _ => RequestStatus.unknown,
};

String wireStatus(RequestStatus status) => switch (status) {
  RequestStatus.open => 'open',
  RequestStatus.inProgress => 'in_progress',
  RequestStatus.closed => 'closed',
  RequestStatus.unknown => 'unknown',
};

ServiceRequest parseRequest(Object? value) {
  if (value is! Map<String, dynamic>) throw const AppFailure('contract');
  try {
    final id = value['id'] as String;
    final owner = value['owner_id'] as String;
    final version = value['version'] as int;
    if (id.isEmpty || owner.isEmpty || version < 1) {
      throw const AppFailure('contract');
    }
    return ServiceRequest(
      id: id,
      ownerId: owner,
      title: value['title'] as String,
      description: value['description'] as String,
      status: parseStatus(value['status']),
      version: version,
      createdAt: DateTime.parse(value['created_at'] as String).toUtc(),
      scheduledAt: value['scheduled_at'] == null
          ? null
          : DateTime.parse(value['scheduled_at'] as String).toUtc(),
    );
  } on AppFailure {
    rethrow;
  } on Object {
    throw const AppFailure('contract');
  }
}

class HttpRequestRepository implements RequestRepository {
  HttpRequestRepository(this.dio);
  final Dio dio;

  // Credenciales ficticias exclusivas del servidor de laboratorio B.
  Options _options(String userId, {String? key}) => Options(
    headers: {'Authorization': 'Bearer lab-$userId', 'Idempotency-Key': ?key},
  );

  Future<Object?> _call(Future<Response<dynamic>> Function() send) async {
    try {
      final response = await send();
      final data = response.data;
      if (data is Map && data['has_error'] == true) {
        throw AppFailure(
          data['code'] == 'EEM030' ? 'session_expired' : 'business',
        );
      }
      return data;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        throw const AppFailure('cancelled');
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw const AppFailure('timeout');
      }
      final status = e.response?.statusCode;
      if (status == 422) {
        final body = e.response?.data;
        final fields = body is Map ? body['fields'] : null;
        throw AppFailure(
          'validation',
          fields: fields is Map
              ? fields.map((k, v) => MapEntry(k.toString(), v.toString()))
              : const {},
        );
      }
      throw AppFailure(switch (status) {
        401 => 'session_expired',
        403 => 'forbidden',
        404 => 'not_found',
        409 => 'conflict',
        429 => 'rate_limited',
        503 => 'unavailable',
        _ =>
          e.type == DioExceptionType.connectionError
              ? 'connection'
              : 'transport',
      });
    }
  }

  @override
  Future<RequestPage> list({
    required String userId,
    required String query,
    RequestStatus? status,
    String? cursor,
  }) async {
    final body = await _call(
      () => dio.get<dynamic>(
        '/requests',
        options: _options(userId),
        queryParameters: {
          'query': query,
          if (status != null) 'status': wireStatus(status),
          'cursor': ?cursor,
        },
      ),
    );
    if (body is! Map<String, dynamic> ||
        body['items'] is! List ||
        (body['next_cursor'] != null && body['next_cursor'] is! String)) {
      throw const AppFailure('contract');
    }
    return RequestPage(
      (body['items'] as List).map(parseRequest).toList(),
      body['next_cursor'] as String?,
    );
  }

  @override
  Future<ServiceRequest> get(String userId, String id) async => parseRequest(
    await _call(
      () => dio.get<dynamic>(
        '/requests/${Uri.encodeComponent(id)}',
        options: _options(userId),
      ),
    ),
  );

  @override
  Future<ServiceRequest> create({
    required String userId,
    required String title,
    required String description,
    required String idempotencyKey,
  }) async => parseRequest(
    await _call(
      () => dio.post<dynamic>(
        '/requests',
        options: _options(userId, key: idempotencyKey),
        data: {'title': title, 'description': description},
      ),
    ),
  );
}
