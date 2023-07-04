import 'package:async/async.dart';

class Heartbeat {
  RestartableTimer? _hbtTimer;
  Function? _hbtFunction;

  /// Starts the heartbeat with a timeout of [timeoutMs]
  /// milliseconds.
  ///
  /// If a heartbeat is received [onHbt] is called.
  /// On timeout [onTimeout] is called.
  void start(int timeoutMs, Function onHbt, Function onTimeout) {
    _hbtTimer?.cancel();
    _hbtFunction = onHbt;
    _hbtTimer =
        RestartableTimer(Duration(milliseconds: timeoutMs), () => onTimeout());
  }

  /// Stops the heartbeat monitoring;
  void stop() {
    _hbtTimer?.cancel();
    _hbtTimer = null;
    _hbtFunction = null;
  }

  /// Feeds the heartbeat timer.
  void feed() {
    _hbtTimer?.reset();
    if (_hbtFunction != null) {
      _hbtFunction!();
    }
  }
}
