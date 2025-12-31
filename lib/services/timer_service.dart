import 'dart:async';
import 'package:flutter/foundation.dart';

class TimerService {
  Timer? _timer;
  int _secondsRemaining = 13;
  final Function(int)? onTick;
  final VoidCallback? onTimeout;

  TimerService({
    this.onTick,
    this.onTimeout,
  });

  void start() {
    _secondsRemaining = 13;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _secondsRemaining--;
      onTick?.call(_secondsRemaining);
      
      if (_secondsRemaining <= 0) {
        stop();
        onTimeout?.call();
      }
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void reset() {
    stop();
    _secondsRemaining = 13;
  }

  int get secondsRemaining => _secondsRemaining;

  void dispose() {
    stop();
  }
}

