import 'dart:async';

import 'package:flutter/foundation.dart';

abstract mixin class BaseBleDevice {
  @protected
  Future init() => Future.value();

  @protected
  final connectionController = StreamController<bool>.broadcast();

  @protected
  final rssiController = StreamController<int>.broadcast();

  @protected
  final batteryController = StreamController<int>.broadcast();
}
