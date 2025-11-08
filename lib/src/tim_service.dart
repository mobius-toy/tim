import 'dart:async';
import 'dart:io';

import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
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

    fbp.FlutterBluePlus.setLogLevel(fbp.LogLevel.none);
    _listenAdapterState();

    ExternalLibrary? externalLibrary;
    if (Platform.isIOS || Platform.isMacOS) {
      externalLibrary = ExternalLibrary.process(iKnowHowToUseIt: true);
    }

    try {
      await RustLib.init(externalLibrary: externalLibrary);

      initDeviceRegistry();
    } catch (e) {
      Logger.e('init TimService failed. $e');
    }

    _initialized = true;

    Logger.i('Initialize service completed');
  }

  void _listenAdapterState() {
    fbp.FlutterBluePlus.adapterState.listen((s) {
      final state = switch (s) {
        fbp.BluetoothAdapterState.unknown => TimState.unknown,
        fbp.BluetoothAdapterState.unavailable => TimState.unavailable,
        fbp.BluetoothAdapterState.unauthorized => TimState.unauthorized,
        fbp.BluetoothAdapterState.turningOn => null,
        fbp.BluetoothAdapterState.on => TimState.on,
        fbp.BluetoothAdapterState.turningOff => null,
        fbp.BluetoothAdapterState.off => TimState.off,
      };

      if (state != null) {
        _stateController.add(state);
        currState = state;
        Logger.i('Service state update $state');
      }
    });
  }

  // Get or create device instance
  TimDevice _getOrCreateDevice({fbp.ScanResult? scanResult, String? remoteId}) {
    final key = scanResult?.device.remoteId.str ?? remoteId;

    assert(scanResult != null || remoteId != null);

    if (_deviceCache.containsKey(key)) {
      final device = _deviceCache[key]!;
      if (scanResult != null) {
        device.name = scanResult.advertisementData.advName;
      }
      return device;
    }

    if (scanResult != null) {
      return _deviceCache[key!] = BleDevice(scanResult.device);
    } else {
      return _deviceCache[key!] = BleDevice(fbp.BluetoothDevice.fromId(key));
    }
  }

  Future stopScan() async => await fbp.FlutterBluePlus.stopScan();

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
    if (fbp.FlutterBluePlus.isScanningNow) {
      await fbp.FlutterBluePlus.stopScan();
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
        await fbp.FlutterBluePlus.stopScan();
      } catch (_) {}

      if (!completer.isCompleted) {
        completer.complete(result ?? const <TimDevice>[]);
      }
    }

    sub = fbp.FlutterBluePlus.onScanResults.listen((results) {
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
      await fbp.FlutterBluePlus.startScan(
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
