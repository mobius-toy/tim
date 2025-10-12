import 'dart:async';

import 'package:flutter/foundation.dart';
import '../tim_exception.dart';

abstract mixin class BaseBleDevice {
  @protected
  @mustCallSuper
  Future init() => Future.value();

  TimDisconnectReason? get disconnectReason => throw TimError.unsupportedFeature.exception();

  Future<void> connect({Duration timeout = const Duration(seconds: 5), int? mtu = 512, bool autoConnect = false}) =>
      throw TimError.unsupportedFeature.exception();

  Future<void> disconnect() => throw TimError.unsupportedFeature.exception();

  @protected
  final connectionController = StreamController<bool>.broadcast();

  @protected
  final rssiController = StreamController<int>.broadcast();

  @protected
  final batteryController = StreamController<int>.broadcast();

  // Toy peripherals
  // Write vibration (0xA0)
  Future<void> writeMotor(List<int> pwmValues) => throw TimError.unsupportedFeature.exception();

  Future<void> writeMotorStop() => throw TimError.unsupportedFeature.exception();

  Future ota({
    required String platform,
    required String remoteID,
    required String filepath,
    required ValueChanged<double> onProgress,
  }) => throw TimError.unsupportedFeature.exception();
}
