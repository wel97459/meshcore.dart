abstract class EventEmitter {
  final Map<dynamic, List<Function(dynamic)>> _listeners = {};

  void on(dynamic event, Function(dynamic) callback) {
    if (!_listeners.containsKey(event)) {
      _listeners[event] = [];
    }
    _listeners[event]!.add(callback);
  }

  void off(dynamic event, Function(dynamic) callback) {
    if (_listeners.containsKey(event)) {
      _listeners[event]!.remove(callback);
      if (_listeners[event]!.isEmpty) {
        _listeners.remove(event);
      }
    }
  }

  void once(dynamic event, Function(dynamic) callback) {
    late Function(dynamic) wrapper;
    wrapper = (data) {
      off(event, wrapper);
      callback(data);
    };
    on(event, wrapper);
  }

  void emit(dynamic event, [dynamic data]) {
    //print('Emitting event: $event');
    if (_listeners.containsKey(event)) {
      final callbacks = List<Function(dynamic)>.from(_listeners[event]!);
      for (final callback in callbacks) {
        callback(data);
      }
    }
  }
}
