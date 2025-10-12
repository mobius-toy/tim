import 'dart:async';
import 'package:flutter/foundation.dart';
import 'ble/ble_device_base.dart';
import 'tim_exception.dart';

abstract class TimDevice with BaseBleDevice {
  late final String id;
  late final String name;
  late final String mac;

  // 固件版本
  late final String fv;
  // 产品ID
  late final String pid;

  late bool isConnected;
  Stream<bool> get connection => connectionController.stream;
  late int rssiValue;
  Stream<int> get rssi => rssiController.stream;
  late int batteryValue;
  Stream<int> get battery => batteryController.stream;

  TimDisconnectReason? get disconnectReason;

  Future<void> connect({
    Duration timeout = const Duration(seconds: 5),
  });

  Future<void> disconnect();

  Future<void> writeMotor(List<int> pwmValues);

  Future<void> writeMotorStop();

  Future ota({
    required String platform,
    required String remoteID,
    required String filepath,
    required ValueChanged<double> onProgress,
  }) => throw UnimplementedError();

  @override
  String toString() {
    return 'TIM device $name $id';
  }
}
