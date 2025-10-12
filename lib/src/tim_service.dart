import 'dart:async';
import 'dart:io';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'ble/ble_device.dart';
import 'rust/api/ble.dart';
import 'tim_exception.dart';
import 'tim_device.dart';
import 'rust/frb_generated.dart';
import 'utils/logger.dart';

enum TimState { unavailable, unauthorized, on, off, unknown }

typedef OnScanCallback = bool Function(List<TimDevice> devices);

class TimService {
  static final TimService _instance = TimService._internal();
  static TimService get instance => _instance;

  TimService._internal();

  final Map<String, TimDevice> _deviceCache = {};

  final StreamController<TimState> _stateController = StreamController.broadcast();
  Stream<TimState> get state => _stateController.stream;
  TimState currState = TimState.unknown;

  Stream<String> get logger => Logger.logs;

  bool _initialized = false;
  Future<void> init() async {
    if (_initialized) return Future.value();

    Logger.i('Initialize service');

    FlutterBluePlus.setLogLevel(LogLevel.none);
    _listenAdapterState();

    await RustLib.init();
    initDeviceRegistry();

    _initialized = true;

    Logger.i('Initialize service completed');
  }

  void _listenAdapterState() {
    FlutterBluePlus.adapterState.listen((s) {
      final state = switch (s) {
        BluetoothAdapterState.unknown => TimState.unknown,
        BluetoothAdapterState.unavailable => TimState.unavailable,
        BluetoothAdapterState.unauthorized => TimState.unauthorized,
        BluetoothAdapterState.turningOn => null,
        BluetoothAdapterState.on => TimState.on,
        BluetoothAdapterState.turningOff => null,
        BluetoothAdapterState.off => TimState.off,
      };

      if (state != null) {
        _stateController.add(state);
        currState = state;
        Logger.i('Service state update $state');
      }
    });
  }

  // Get or create device instance
  TimDevice _getOrCreateDevice({ScanResult? scanResult, String? remoteId}) {
    final key = scanResult?.device.remoteId.str ?? remoteId;

    assert(scanResult != null || remoteId != null);

    if (_deviceCache.containsKey(key)) {
      return _deviceCache[key]!;
    }

    if (scanResult != null) {
      return _deviceCache[key!] = BleDevice(scanResult.device);
    } else {
      return _deviceCache[key!] = BleDevice(BluetoothDevice.fromId(key));
    }
  }

  Future stopScan() async => await FlutterBluePlus.stopScan();

  /// Scan Bluetooth devices
  ///
  /// - [timeout]: Single scan window (recommended 8–15s)
  /// - [withNames]: Whether to parse device names (recommended off for power saving, unless needed for display)
  /// - [onFoundDevices]: Callback for each batch update; return true to end early
  Future<List<TimDevice>> scan({
    Duration timeout = const Duration(seconds: 10),
    List<String> withNames = const [],
    OnScanCallback? onFoundDevices,
  }) async {
    if (FlutterBluePlus.isScanningNow) {
      await FlutterBluePlus.stopScan();
    }

    final completer = Completer<List<TimDevice>>();
    final devices = <TimDevice>[];
    StreamSubscription? sub;
    Timer? deadline;

    Future<void> completeSafely([List<TimDevice>? result]) async {
      try {
        await sub?.cancel();
        sub = null;
      } catch (_) {}
      try {
        deadline?.cancel();
        deadline = null;
      } catch (_) {}
      try {
        await FlutterBluePlus.stopScan();
      } catch (_) {}

      if (!completer.isCompleted) {
        completer.complete(result ?? const <TimDevice>[]);
      }
    }

    sub = FlutterBluePlus.onScanResults.listen((results) {
      devices.clear();
      for (var result in results) {
        devices.add(_getOrCreateDevice(scanResult: result));
      }
      Logger.i('scan results: ${devices.map((e) => e.toString()).join('\n')}');

      if (devices.isNotEmpty) {
        // Already found toys that need processing, end scanning
        final shouldStop = onFoundDevices?.call(devices) ?? false;
        if (shouldStop) {
          completeSafely(devices);
        }
      }
    });

    deadline = Timer(timeout, () => completeSafely(devices));

    try {
      Logger.i('start scan, timeout=${timeout.inSeconds}, names=${withNames.join(' | ')}');

      int divisor = Platform.isAndroid ? 8 : 1;
      await FlutterBluePlus.startScan(
        continuousUpdates: false,
        continuousDivisor: divisor,
        oneByOne: false,
        withNames: withNames,
      );
    } catch (e) {
      throw TimException.fromException(e);
    }

    return completer.future;
  }

  TimDevice retrieveDevice(String remoteID) {
    return _getOrCreateDevice(remoteId: remoteID);
  }
}
