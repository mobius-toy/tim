import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../rust/api/ble.dart';
import '../rust/api/cmd.dart';
import '../rust/api/task.dart';
import '../tim_exception.dart';
import '../tim_device.dart';
import '../utils/logger.dart';

/// 设备级隔离的蓝牙设备
/// 继承自 BleDevice，实现设备级队列管理和异步任务处理
final class BleDevice<T> extends TimDevice {
  late final BluetoothDevice _device;

  @protected
  final Map<String, BluetoothService> services = {};
  @protected
  final Map<String, BluetoothCharacteristic> characteristics = {};

  BleDevice(BluetoothDevice device) : _device = device {
    id = device.remoteId.str;
    name = device.platformName;
    isConnected = false;
    rssiValue = 0;
    batteryValue = 0;
    mac = '';
    fv = '';
    pid = '';
  }

  /// 获取蓝牙设备
  BluetoothDevice get bluetoothDevice => _device;

  /// 是否支持心跳
  bool get supportHeartbeat => false;

  Timer? _rssiTimer;
  StreamSubscription? _connectionSubscription;

  /// 最近的断开连接原因
  @override
  TimDisconnectReason? get disconnectReason => _device.disconnectReason != null
      ? TimDisconnectReason.fromReason(
          _device.disconnectReason!,
        )
      : null;

  /// 初始化设备
  @override
  Future<void> init() async {
    try {
      Logger.i('Device $simpleId connected, initializing...');
      await _discoverServices();
      await _initDeviceTaskStream();
      await _initDeviceInfo();
    } catch (e, s) {
      Logger.e('Device $simpleId initialization failed, $e, $s');
      throw TimException.fromException(e);
    }
  }

  /// 发现蓝牙服务
  Future<void> _discoverServices() async {
    try {
      Logger.i('Device $simpleId discovering services...');
      final discoveredServices = await _device.discoverServices();

      for (final service in discoveredServices) {
        services[service.uuid.toString()] = service;

        for (final characteristic in service.characteristics) {
          characteristics[characteristic.uuid.toString()] = characteristic;
        }
      }

      Logger.i('Device $simpleId discovered ${services.length} services and ${characteristics.length} characteristics');
    } catch (e) {
      Logger.e('Device $simpleId service discovery failed: $e');
      rethrow;
    }
  }

  StreamSubscription? _taskSubscription;

  /// 初始化设备队列
  Future<void> _initDeviceTaskStream() async {
    try {
      final taskStreamSink = createDeviceTaskStream(deviceId: id, deviceName: name);
      _taskSubscription = taskStreamSink.listen(_handleDeviceTask);
      Logger.i('Device $simpleId internal init');
    } catch (e) {
      Logger.e('Device $simpleId queue initialization failed: $e');
      rethrow;
    }
  }

  Future<void> _handleDeviceTask(BleTask task) async {
    try {
      Uint8List? data;
      if (task.op.isActionRead()) {
        final resultData = await readCharacteristic(task.uuid);
        data = Uint8List.fromList(resultData);
      } else if (task.op.isActionWrite()) {
        final writeData = task.op.data?.toList() ?? <int>[];
        await writeCharacteristic(task.uuid, writeData, !task.op.ack);
      } else if (task.op.isActionSubscribe()) {
        await subscribeCharacteristic(task.uuid);
      } else if (task.op.isActionUnsubscribe()) {
        await unsubscribeCharacteristic(task.uuid);
      } else if (task.op.isActionNotify() && task.op.cmd != null) {
        switch (task.op.cmd!) {
          case OpCmd.updateBattery:
            batteryValue = task.op.data?.indexOf(0) ?? 0;
            batteryController.add(batteryValue);
            break;
        }
      } else {
        Logger.w('Unsupported operation: $task');
      }
      await completeDeviceTask(
        deviceId: id,
        taskId: task.taskId,
        success: true,
        data: data,
      );
    } catch (e) {
      Logger.e('Task ${task.taskId} failed: $e');
      await completeDeviceTask(
        deviceId: id,
        taskId: task.taskId,
        success: false,
        error: e.toString(),
      );
    }
  }

  Future<void> _initDeviceInfo() async {
    try {
      Logger.i('Device reading information...');
      final info = await initializeDevice(deviceId: id);
      mac = info['mac'] ?? '';
      fv = info['firmware_version'] ?? '';
      pid = info['variant_code'] ?? '';
      batteryValue = int.tryParse(info['battery'] ?? '0') ?? 0;
      batteryController.add(batteryValue);
      Logger.i('Device $simpleId device information updated: ${info.toString()}');
    } catch (e) {
      Logger.e('Device $simpleId failed to read device information: $e');
      throw TimError.peripheralInfoIncomplete.exception();
    }
  }

  @override
  Future<void> connect({Duration timeout = const Duration(seconds: 5)}) => _connect(timeout: timeout);

  /// 连接设备
  Future<void> _connect({
    Duration timeout = const Duration(seconds: 5),
    int? mtu = 512,
    bool autoConnect = false,
    int maxRetries = 2,
  }) async {
    int retryCount = 0;

    while (retryCount <= maxRetries) {
      try {
        Logger.i('Device $simpleId connecting... (attempt ${retryCount + 1}/${maxRetries + 1})');

        await _device.connect(autoConnect: autoConnect, mtu: mtu, timeout: timeout);

        // 监听连接状态变化
        _listenConnection();

        // 初始化设备（包括服务发现和队列初始化）
        await init();

        Logger.i('Device $simpleId connection and initialization completed');
        return; // 成功连接，退出重试循环
      } catch (e) {
        retryCount++;

        // 如果是最后一次尝试，抛出异常
        if (retryCount > maxRetries) {
          Logger.e('Device $simpleId connection failed after $maxRetries retries');
          throw TimException.fromException(e);
        }

        // 连接超时，等待更长时间后重试
        final delay = Duration(seconds: retryCount * 2);

        // 检查是否是特定错误，决定是否重试
        final exception = TimException.fromException(e);
        if (exception.error == TimError.connectionTimeout || exception.error == TimError.peripheralBusy) {
          Logger.i(
            'Device $simpleId ${exception.error}, '
            'retrying in ${delay.inSeconds} seconds...',
          );
          await Future.delayed(delay);
          continue;
        } else if (exception.error == TimError.peripheralNotFound) {
          Logger.e('Device $simpleId device not found, stopping retries');
          throw exception;
        }

        // 其他错误，等待后重试
        Logger.i(
          'Device $simpleId unknown error, '
          'retrying in ${delay.inSeconds} seconds...',
        );
        await Future.delayed(delay);
      }
    }
  }

  /// 监听连接状态变化
  void _listenConnection() {
    _connectionSubscription?.cancel();
    _connectionSubscription = _device.connectionState.listen((state) {
      if (state == BluetoothConnectionState.disconnected) {
        Logger.i('Device $simpleId connection state update: disconnected');
        isConnected = false;
        connectionController.add(false);
        _handleDisconnection();
      } else {
        Logger.i('Device $simpleId connection state update: connected');
        isConnected = true;
        connectionController.add(true);
        startRssiMonitoring();
      }
    });
  }

  Future<void> _handleDisconnection() async {
    try {
      _clearResources();
      await removeDeviceTaskStream(deviceId: id);
      Logger.i('Device $simpleId disconnection handled');
    } catch (e) {
      Logger.e('Device $simpleId disconnection handling failed: $e');
    }
  }

  /// 清理资源
  void _clearResources() {
    stopRssiMonitoring();
    services.clear();
    characteristics.clear();
    _connectionSubscription?.cancel();
    _connectionSubscription = null;
    _taskSubscription?.cancel();
    _taskSubscription = null;
  }

  /// 写入电机控制
  /// 这是唯一暴露的写入接口，其他写入操作由 Rust 处理
  List<int>? _prevPwmValues;
  @override
  Future<void> writeMotor(List<int> pwmValues) async {
    if (!_device.isConnected) {
      Logger.w('Device write motor failed: device not connected');
      return;
    }

    try {
      if (pwmValues.isEmpty) {
        throw TimException(message: 'PWM values must not be empty', error: null);
      }

      if (listEquals(_prevPwmValues ?? [], pwmValues)) {
        Logger.d('Device $simpleId motor control skipped: pwmValues unchanged');
        return;
      } else {
        _prevPwmValues = pwmValues;
      }

      await writeDeviceMotorControl(
        deviceId: id,
        pwmValues: pwmValues,
      );
    } catch (e) {
      Logger.e('Device $simpleId write motor failed: $e');
      throw TimException.fromException(e);
    }
  }

  /// 停止电机
  @override
  Future<void> writeMotorStop() async {
    if (!_device.isConnected) {
      Logger.w('Device motor stop failed: device not connected');
      return;
    }
    try {
      Logger.d('Device motor stop request');
      await writeDeviceMotorStop(deviceId: id);
    } catch (e) {
      Logger.e('Device write motor stop failed: $e');
      throw TimException.fromException(e);
    }
  }

  /// 获取特征
  @protected
  BluetoothCharacteristic? getCharacteristic(String characteristicUuid) {
    return characteristics[characteristicUuid];
  }

  /// 读取特征值
  @protected
  Future<List<int>> readCharacteristic(String characteristicUuid) async {
    final characteristic = getCharacteristic(characteristicUuid);
    if (characteristic == null) {
      throw TimException(message: 'Characteristic $characteristicUuid not found', error: null);
    }

    try {
      final value = await characteristic.read();
      Logger.d('Device read characteristic $characteristicUuid: ${value.length} bytes');
      return value;
    } catch (e) {
      Logger.e('Device read characteristic $characteristicUuid failed: $e');
      throw TimException.fromException(e);
    }
  }

  @protected
  Future<void> subscribeCharacteristic(String characteristicUuid) async {
    final characteristic = getCharacteristic(characteristicUuid);
    if (characteristic == null) {
      throw TimException(message: 'Characteristic $characteristicUuid not found', error: null);
    }

    try {
      if (!characteristic.isNotifying) {
        await characteristic.setNotifyValue(true);
      }
      Logger.d('Device subscribe characteristic $characteristicUuid');
    } catch (e) {
      Logger.e('Device subscribe characteristic $characteristicUuid failed: $e');
      throw TimException.fromException(e);
    }
  }

  @protected
  Future<void> unsubscribeCharacteristic(String characteristicUuid) async {
    final characteristic = getCharacteristic(characteristicUuid);
    if (characteristic == null) {
      throw TimException(message: 'Characteristic $characteristicUuid not found', error: null);
    }

    try {
      if (characteristic.isNotifying) {
        await characteristic.setNotifyValue(false);
      }
      Logger.d('Device subscribe characteristic $characteristicUuid');
    } catch (e) {
      Logger.e('Device subscribe characteristic $characteristicUuid failed: $e');
      throw TimException.fromException(e);
    }
  }

  @protected
  Future<void> writeCharacteristic(String characteristicUuid, List<int> value, bool noRsp) async {
    final characteristic = getCharacteristic(characteristicUuid);
    if (characteristic == null) {
      throw TimException(message: 'Characteristic $characteristicUuid not found', error: null);
    }

    try {
      await characteristic.write(value, withoutResponse: noRsp);
      Logger.d('Device write characteristic $characteristicUuid: ${value.length} bytes');
    } catch (e) {
      Logger.e('Device write characteristic $characteristicUuid failed: $e');
      throw TimException.fromException(e);
    }
  }

  /// 开始RSSI监控
  @protected
  void startRssiMonitoring() {
    if (!supportHeartbeat) return;

    _rssiTimer?.cancel();
    _rssiTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      try {
        await _device.readRssi();
        // RSSI 设置暂时注释，因为 DeviceInfo 可能没有 rssi 字段
      } catch (e) {
        Logger.w('Device $simpleId RSSI monitoring failed: $e');
      }
    });
  }

  /// 停止RSSI监控
  @protected
  void stopRssiMonitoring() {
    _rssiTimer?.cancel();
    _rssiTimer = null;
  }

  /// 断开连接
  @override
  Future<void> disconnect() async {
    try {
      // 先断开蓝牙连接
      await _device.disconnect();

      // 使用统一的断开处理逻辑
      await _handleDisconnection();

      Logger.i('Device $simpleId disconnected (active)');
    } catch (e) {
      Logger.e('Device $simpleId disconnect failed: $e');
      throw TimException.fromException(e);
    }
  }

  /// 清理资源
  void dispose() {
    _clearResources();
    // super.dispose(); // 暂时注释，因为父类可能没有 dispose 方法
  }

  String get simpleId {
    // id有可能是mac和uuid，该方法是打印日志时调用，需要缩短UUID、Mac的显示
    if (id.contains(':')) {
      // 可能是MAC地址，形如 "XX:XX:XX:XX:XX:XX"
      // 缩写为前2组和后2组
      final parts = id.split(':');
      if (parts.length == 6) {
        return '${parts[0]}:${parts[1]}...${parts[4]}:${parts[5]}';
      } else if (parts.length > 2) {
        return '${parts.first}:${parts[1]}...${parts[parts.length - 2]}:${parts.last}';
      }
    }
    // 如果看起来是UUID（带-），只保留前8位和后4位
    if (id.length > 12 && id.contains('-')) {
      return '${id.substring(0, 2)}...${id.substring(id.length - 4)}';
    }
    // 太长的纯ID，也缩短显示（前6后4）
    if (id.length > 12) {
      return '${id.substring(0, 6)}...${id.substring(id.length - 4)}';
    }
    return id;
  }
}
