import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

part 'ble/ble_exception.dart';

enum TimError {
  unknown(
    'An unknown error has occurred.',
  ),
  bluetoothUnavailable(
    'Bluetooth is unavailable on this device or has been disabled.',
  ),
  bluetoothStateOff(
    'Bluetooth is supported but currently turned off. Please enable it in system settings.',
  ),
  unsupportedFeature(
    'The requested functionality is not supported by the device or platform.',
  ),
  scanningInProgress(
    'A scan is already in progress. Please wait until the current scan completes before starting a new one.',
  ),
  peripheralNotFound(
    'The target peripheral could not be found (not discovered or disconnected).',
  ),
  peripheralTimeout(
    'The operation timed out while waiting for the peripheral to respond.',
  ),
  peripheralInfoIncomplete(
    'The peripheral information is incomplete or invalid.',
  ),
  peripheralBusy(
    'The device is busy and cannot process the request.',
  ),
  connectionTimeout(
    'The connection timed out while waiting for the peripheral to respond.',
  ),
  connectionFailed(
    'The connection failed to establish or maintain.',
  ),
  otaPlatformUnsupported(
    'The requested OTA platform is not supported.',
  ),
  otaFileNotExist(
    'The specified OTA firmware file does not exist.',
  ),
  otaFileDataEmpty(
    'The specified OTA firmware data is empty.',
  ),
  otaAlreadyInProgress(
    'OTA update is already in progress for this device.',
  ),
  otaNotInProgress(
    'No OTA update is currently in progress for this device.',
  ),
  otaTransmissionFailed(
    'OTA data transmission failed.',
  ),
  otaCrcError(
    'OTA data CRC verification failed.',
  ),
  otaTimeout(
    'OTA operation timed out.',
  ),
  otaDeviceNotConnected(
    'Device is not connected for OTA operation.',
  );

  final String message;

  const TimError(this.message);

  TimException exception({original}) => TimException(message: message, error: this, original: original);
}

class TimException implements Exception {
  final String message;
  final TimError? error;
  final Object? original;

  TimException({required this.message, required this.error, this.original});

  @override
  String toString() {
    return 'TimException $error, $message, $original';
  }

  factory TimException.fromException(Object exception) {
    return _fromException(exception) ??
        TimException(
          message: exception.toString(),
          error: TimError.unknown,
          original: exception,
        );
  }
}

enum TimDisconnectCode {
  normal(0, 'Disconnected intentionally by the app or user'),
  remote(1, 'Disconnected by the remote device'),
  connectionTimeout(2, 'Disconnected due to connection timeout'),
  gattError(3, 'Generic GATT error or internal failure'),

  unknown(999, '');

  final int value;
  final String reason;

  const TimDisconnectCode(this.value, this.reason);
}

class TimDisconnectReason {
  late final String platform;
  late final int code; // specific to platform
  late final String description;

  TimDisconnectReason._internal();

  factory TimDisconnectReason.fromReason(DisconnectReason reason) => _fromFlutterBlueDisconnectReason(reason);

  @override
  String toString() {
    return 'platform: $platform, '
        'code: $code, '
        '$description';
  }
}
