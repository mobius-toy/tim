import 'src/tim_service.dart';
import 'src/tim_device.dart';

export 'src/tim_device.dart';
export 'src/tim_service.dart';
export 'src/tim_exception.dart';

class Tim {
  static final Tim _instance = Tim._internal();
  static Tim get instance => _instance;
  final TimService _service = TimService.instance;

  Tim._internal();

  Future<void> initialize() {
    return _service.init();
  }

  Future<List<TimDevice>> startScan({
    Duration timeout = const Duration(seconds: 10),
    List<String> withNames = const [],
    OnScanCallback? onFoundDevices,
  }) {
    return _service.scan(
      timeout: timeout,
      withNames: withNames,
      onFoundDevices: onFoundDevices,
    );
  }

  Future<void> stopScan() {
    return _service.stopScan();
  }
}
