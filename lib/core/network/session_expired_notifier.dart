import 'dart:async';

/// Stream global que emite cuando el servidor retorna 401 (token expirado).
/// Los widgets raíz pueden suscribirse para redirigir a login.
class SessionExpiredNotifier {
  SessionExpiredNotifier._();
  static final SessionExpiredNotifier instance = SessionExpiredNotifier._();

  final StreamController<void> _controller = StreamController<void>.broadcast();

  Stream<void> get stream => _controller.stream;

  void notify() {
    if (!_controller.isClosed) {
      _controller.add(null);
    }
  }

  void dispose() {
    _controller.close();
  }
}
