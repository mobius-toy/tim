import 'dart:async';
import 'package:flutter/foundation.dart';

enum _LogLevel {
  error('ERR'),
  warning('WARN'),
  info('INFO'),
  debug('DEBUG');

  final String value;

  const _LogLevel(this.value);
}

class Logger {
  static final _logsController = StreamController<String>.broadcast();
  static Stream<String> get logs => _logsController.stream;

  static final _logLevelColors = {
    _LogLevel.debug: "\x1B[38;5;15m",
    _LogLevel.info: "\x1B[38;5;46m",
    _LogLevel.warning: "\x1B[38;5;220m",
    _LogLevel.error: "\x1B[38;5;196m",
  };

  static void _print(_LogLevel level, String s, String tag) {
    final now = DateTime.now().toLocal();
    final dt =
        '${now.hour.toString().padLeft(2, '0')}'
        ':'
        '${now.minute.toString().padLeft(2, '0')}'
        ':'
        '${now.second.toString().padLeft(2, '0')}'
        ':'
        '${now.millisecond.toString().padLeft(3, '0')}';
    final color = _logLevelColors[level] ?? _logLevelColors[_LogLevel.debug];
    final output = kDebugMode ? '$dt $color[TIM-${level.value}] $s \x1B[0m' : '$dt [TIM-${level.value}] $s';

    if (level != _LogLevel.debug) {
      _logsController.add(output);
    }

    if (kDebugMode) {
      print(output);
    }
  }

  static void d(String s, {String tag = ''}) {
    _print(_LogLevel.debug, s, tag);
  }

  static void i(String s, {String tag = ''}) {
    _print(_LogLevel.info, s, tag);
  }

  static void e(String s, {String tag = ''}) {
    _print(_LogLevel.error, s, tag);
  }

  static void w(String s, {String tag = ''}) {
    _print(_LogLevel.warning, s, tag);
  }
}
