import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/dependencies.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../auth/presentation/session.dart';
import '../domain/request.dart';
import '../domain/draft.dart';
import 'providers.dart';

String statusText(AppLocalizations l, RequestStatus status) => switch (status) {
  RequestStatus.open => l.open,
  RequestStatus.inProgress => l.inProgress,
  RequestStatus.closed => l.closed,
  RequestStatus.unknown => l.unknown,
};

String failureText(AppLocalizations l, Object error) => switch (error) {
  AppFailure(code: 'not_found') => l.notFound,
  AppFailure(code: 'forbidden') => l.forbidden,
  AppFailure(code: 'session_expired') => l.expired,
  AppFailure(code: 'validation') => l.validationError,
  AppFailure(code: 'conflict') => l.conflict,
  _ => l.genericError,
};

void reportUnexpected(Object error, StackTrace stack) {
  FlutterError.reportError(
    FlutterErrorDetails(
      exception: error,
      stack: stack,
      library: 'portal',
      context: ErrorDescription('Unexpected operation failure'),
    ),
  );
}

class FailurePanel extends StatelessWidget {
  const FailurePanel({super.key, required this.error, required this.retry});
  final Object error;
  final VoidCallback retry;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(failureText(l, error)),
            const SizedBox(height: 12),
            FilledButton(onPressed: retry, child: Text(l.retry)),
          ],
        ),
      ),
    );
  }
}

class RequestEditor extends StatefulWidget {
  const RequestEditor({
    super.key,
    required this.requestId,
    required this.title,
  });

  final String requestId;
  final String title;

  @override
  State<RequestEditor> createState() => _RequestEditorState();
}

class _RequestEditorState extends State<RequestEditor> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(widget.title),
      subtitle: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          labelText: 'Motivo',
        ),
      ),
    );
  }
}

class RequestsPage extends ConsumerWidget {
  const RequestsPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final filter = ref.watch(filterProvider);
    final data = ref.watch(requestsProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.requests),
        actions: [
          IconButton(
            tooltip: l.refresh,
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(requestsProvider),
          ),
          IconButton(
            tooltip: l.settings,
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
          IconButton(
            tooltip: l.logout,
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(sessionProvider.notifier).logout(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('new-request'),
        onPressed: () => context.push('/requests/new'),
        icon: const Icon(Icons.add),
        label: Text(l.newRequest),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              key: const Key('search'),
              decoration: InputDecoration(
                labelText: l.search,
                border: const OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.search,
              onChanged: ref.read(filterProvider.notifier).search,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DropdownButton<RequestStatus?>(
              isExpanded: true,
              value: filter.status,
              hint: Text(l.all),
              items: [
                DropdownMenuItem<RequestStatus?>(
                  value: null,
                  child: Text(l.all),
                ),
                for (final status in RequestStatus.values)
                  DropdownMenuItem(
                    value: status,
                    child: Text(statusText(l, status)),
                  ),
              ],
              onChanged: ref.read(filterProvider.notifier).selectStatus,
            ),
          ),
          
          Expanded(
            child: data.when(
              skipLoadingOnRefresh: false,
              skipLoadingOnReload: false,
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => FailurePanel(
                error: e,
                retry: () => ref.invalidate(requestsProvider),
              ),
              data: (page) => ListView.builder(
                padding: const EdgeInsets.only(bottom: 96),
                itemCount: page.items.length + 2,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        page.items.isEmpty
                            ? l.empty
                            : l.loadedCount(page.items.length),
                      ),
                    );
                  }
                  if (index <= page.items.length) {
                    final item = page.items[index - 1];
                    return ListTile(
                      key: ValueKey(item.id),
                      title: Text(item.title),
                      subtitle: Text(statusText(l, item.status)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push(
                        '/requests/${Uri.encodeComponent(item.id)}',
                      ),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        if (page.moreFailure != null)
                          Text(failureText(l, page.moreFailure!)),
                        if (page.isLoadingMore)
                          const CircularProgressIndicator()
                        else if (page.nextCursor != null)
                          OutlinedButton(
                            key: const Key('load-more'),
                            onPressed: () => unawaited(
                              ref.read(requestsProvider.notifier).loadMore(),
                            ),
                            child: Text(
                              page.moreFailure == null ? l.more : l.retry,
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RequestDetailPage extends ConsumerWidget {
  const RequestDetailPage({super.key, required this.id});
  final String id;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.requests)),
      body: ref
          .watch(detailProvider(id))
          .when(
            skipLoadingOnReload: false,
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => FailurePanel(
              error: e,
              retry: () => ref.invalidate(detailProvider(id)),
            ),
            data: (item) => ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  item.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                Text(item.description),
                const SizedBox(height: 16),
                Text(statusText(l, item.status)),
                Text(l.requestVersion(item.version)),
                const SizedBox(height: 24),
                OutlinedButton(
                  onPressed: () => context.go('/requests'),
                  child: Text(l.backToList),
                ),
              ],
            ),
          ),
    );
  }
}

String newOperationKey() {
  final random = Random.secure();
  return List.generate(
    16,
    (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
}

class CreateRequestPage extends ConsumerStatefulWidget {
  const CreateRequestPage({super.key});
  @override
  ConsumerState<CreateRequestPage> createState() => _CreateRequestPageState();
}

class _CreateRequestPageState extends ConsumerState<CreateRequestPage> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  Session? _owner;
  String _operationKey = newOperationKey();
  int _revision = 0;
  Future<void> _draftQueue = Future.value();
  bool _restoring = true;
  bool _sending = false;
  bool _unknown = false;
  bool _restored = false;
  bool _draftFailed = false;
  Object? _failure;
  Map<String, String> _fields = {};

  bool get _current =>
      mounted &&
      _owner != null &&
      ref.read(sessionProvider)?.epoch == _owner!.epoch;

  @override
  void initState() {
    super.initState();
    _owner = ref.read(sessionProvider);
    unawaited(_restore());
  }

  Future<void> _restore() async {
    final owner = _owner;
    if (owner == null) {
      _restoring = false;
      return;
    }
    try {
      final draft = await ref
          .read(draftRepositoryProvider)
          .read(owner.userId, 'new');
      if (!_current) return;
      if (draft != null) {
        _title.text = draft.title;
        _description.text = draft.description;
        _revision = draft.revision;
        _operationKey = draft.idempotencyKey;
        _unknown = draft.resultUnknown;
        _restored = true;
      }
    } on Object catch (e, s) {
      if (e is! AppFailure) reportUnexpected(e, s);
      if (_current) _draftFailed = true;
    } finally {
      if (_current) setState(() => _restoring = false);
    }
  }

  Future<void> _saveDraft() async {
    if (!_current) return;
    final snapshot = RequestDraft(
      userId: _owner!.userId,
      requestId: 'new',
      title: _title.text,
      description: _description.text,
      revision: ++_revision,
      idempotencyKey: _operationKey,
      resultUnknown: _unknown,
    );
    final repository = ref.read(draftRepositoryProvider);
    final previous = _draftQueue;
    final gate = Completer<void>();
    _draftQueue = gate.future;
    try {
      await previous;
      await repository.save(snapshot);
      if (_current) setState(() => _draftFailed = false);
    } on Object catch (e, s) {
      if (e is! AppFailure) reportUnexpected(e, s);
      if (_current) setState(() => _draftFailed = true);
    } finally {
      gate.complete();
    }
  }

  void _changed(String _) {
    _fields = {};
    unawaited(_saveDraft());
  }

  Future<void> _submit() async {
    if (!_current ||
        _sending ||
        _restoring ||
        !_form.currentState!.validate()) {
      return;
    }
    final owner = _owner!;
    final repository = ref.read(repositoryProvider);
    final drafts = ref.read(draftRepositoryProvider);
    final previouslyUnknown = _unknown;
    setState(() {
      _sending = true;
      _failure = null;
      _fields = {};
    });
    try {
      // Persistir la intención antes de enviarla protege un cierre del proceso.
      _unknown = true;
      await _saveDraft();
      if (!_current) return;
      if (_draftFailed) throw const AppFailure('draft_storage');
      final revision = _revision;
      final result = await repository.create(
        userId: owner.userId,
        title: _title.text.trim(),
        description: _description.text.trim(),
        idempotencyKey: _operationKey,
      );
      if (!_current) return;
      await drafts.deleteIfRevision(owner.userId, 'new', revision);
      if (!mounted) return;
      if (!_current) return;
      ref.invalidate(requestsProvider);
      context.go('/requests/${Uri.encodeComponent(result.id)}');
    } on AppFailure catch (error) {
      if (!_current) return;
      setState(() {
        _failure = error;
        _fields = error.fields;
        _unknown =
            previouslyUnknown ||
            {
              'timeout',
              'connection',
              'transport',
              'contract',
            }.contains(error.code);
      });
      await _saveDraft();
    } on Object catch (error, stack) {
      reportUnexpected(error, stack);
      if (_current) {
        setState(() {
          _failure = error;
          _unknown = true;
        });
      }
      if (_current) await _saveDraft();
    } finally {
      if (_current) setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final blocked = _sending || _restoring || _unknown;
    return PopScope(
      canPop: !_sending && !_unknown,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l.newRequest),
          actions: [
            IconButton(
              tooltip: l.logout,
              onPressed: () => ref.read(sessionProvider.notifier).logout(),
              icon: const Icon(Icons.logout),
            ),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Form(
              key: _form,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  if (_restoring) const LinearProgressIndicator(),
                  if (_restored) Text(l.draftRestored),
                  if (_draftFailed) Text(l.draftError),
                  TextFormField(
                    key: const Key('request-title'),
                    controller: _title,
                    enabled: !blocked,
                    onChanged: _changed,
                    decoration: InputDecoration(
                      labelText: l.titleLabel,
                      errorText: _fields.containsKey('title')
                          ? l.titleLength
                          : null,
                    ),
                    validator: (v) =>
                        validateRequest(
                          v ?? '',
                          _description.text,
                        ).containsKey('title')
                        ? l.titleLength
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('request-reason'),
                    controller: _description,
                    enabled: !blocked,
                    minLines: 3,
                    maxLines: 8,
                    onChanged: _changed,
                    decoration: InputDecoration(
                      labelText: l.reasonLabel,
                      errorText: _fields.containsKey('description')
                          ? l.reasonLength
                          : null,
                    ),
                    validator: (v) =>
                        validateRequest(
                          _title.text,
                          v ?? '',
                        ).containsKey('description')
                        ? l.reasonLength
                        : null,
                  ),
                  const SizedBox(height: 24),
                  if (_failure != null)
                    Semantics(
                      liveRegion: true,
                      child: Text(failureText(l, _failure!)),
                    ),
                  if (_unknown && !_sending) Text(l.unknownResult),
                  FilledButton(
                    key: const Key('request-submit'),
                    onPressed: _sending || _restoring
                        ? null
                        : () => unawaited(_submit()),
                    child: Text(
                      _sending
                          ? l.sending
                          : _unknown
                          ? l.retry
                          : l.save,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
