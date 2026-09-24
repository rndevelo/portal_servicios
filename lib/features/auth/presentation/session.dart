import 'package:flutter_riverpod/flutter_riverpod.dart';

class Session {
  const Session(this.userId, this.epoch);
  final String userId;
  final int epoch;
}

final sessionProvider = NotifierProvider<LabSession, Session?>(LabSession.new);

class LabSession extends Notifier<Session?> {
  int _epoch = 0;
  @override
  Session? build() => null;
  void login(String userId) {
    if (!{'ana', 'bruno'}.contains(userId)) {
      throw ArgumentError('Unknown lab user');
    }
    state = Session(userId, ++_epoch);
  }

  void logout() {
    _epoch++;
    state = null;
  }
}
