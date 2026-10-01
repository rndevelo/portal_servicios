class LatestSearch<T> {
  LatestSearch({
    required this.fetch,
    required this.onData,
    required this.onError,
  });

  final Future<T> Function(String query) fetch;
  final void Function(T value) onData;
  final void Function(Object error, StackTrace stack) onError;
  int _revision = 0;
  bool _closed = false;

  Future<void> run(String query) async {
    if (_closed) return;
    final revision = ++_revision;
    try {
      final result = await fetch(query);
      if (!_closed && revision == _revision) onData(result);
    } catch (error, stack) {
      if (!_closed && revision == _revision) onError(error, stack);
    }
  }

  void close() {
    _closed = true;
    _revision++;
  }
}