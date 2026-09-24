import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/requests/domain/request.dart';
import '../features/requests/domain/draft.dart';
import '../features/requests/data/memory_drafts.dart';
import '../features/requests/data/memory_request_repository.dart';
import '../features/requests/data/http_request_repository.dart';

final repositoryProvider = Provider<RequestRepository>((ref) {
  const useHttp = bool.fromEnvironment('USE_HTTP');
  if (!useHttp) return MemoryRequestRepository();
  const base = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8080',
  );
  const fault = String.fromEnvironment('LAB_FAULT');
  final dio = Dio(
    BaseOptions(
      baseUrl: base,
      connectTimeout: const Duration(seconds: 3),
      sendTimeout: const Duration(seconds: 3),
      receiveTimeout: const Duration(seconds: 3),
      headers: {if (fault.isNotEmpty) 'X-Lab-Fault': fault},
    ),
  );
  ref.onDispose(() => dio.close(force: true));
  return HttpRequestRepository(dio);
});

final draftRepositoryProvider = Provider<DraftRepository>(
  (ref) => MemoryDraftRepository(),
);

final localeProvider = NotifierProvider<LocaleSetting, Locale?>(
  LocaleSetting.new,
);

class LocaleSetting extends Notifier<Locale?> {
  @override
  Locale? build() => null;
  void change(String? language) =>
      state = language == null ? null : Locale(language);
}
