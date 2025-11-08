part of '../tim_exception.dart';

TimError _handleFbpError(FlutterBluePlusException exception) {
  final code = FbpErrorCode.values.elementAtOrNull(exception.code ?? 0);

  return switch (code) {
    FbpErrorCode.success => TimError.unknown,
    FbpErrorCode.timeout => TimError.connectionTimeout,
    FbpErrorCode.androidOnly => TimError.unsupportedFeature,
    FbpErrorCode.applePlatformOnly => TimError.unsupportedFeature,
    FbpErrorCode.createBondFailed => TimError.connectionFailed,
    FbpErrorCode.removeBondFailed => TimError.connectionFailed,
    FbpErrorCode.deviceIsDisconnected => TimError.peripheralNotFound,
    FbpErrorCode.serviceNotFound => TimError.peripheralInfoIncomplete,
    FbpErrorCode.characteristicNotFound => TimError.peripheralInfoIncomplete,
    FbpErrorCode.adapterIsOff => TimError.bluetoothStateOff,
    FbpErrorCode.connectionCanceled => TimError.connectionFailed,
    FbpErrorCode.userRejected => TimError.connectionFailed,
    _ => TimError.unknown,
  };
}

TimError _handleAndroidError(FlutterBluePlusException exception) {
  // Android specific error code handling
  final code = exception.code;
  if (code == null) return TimError.unknown;

  return switch (code) {
    // ERROR_INSUFFICIENT_RESOURCES - Insufficient resources/device busy
    8 => TimError.peripheralBusy,
    // ERROR_DEVICE_NOT_FOUND - Device not found
    19 => TimError.peripheralNotFound,
    // ERROR_CONNECTION_FAILED - Connection failed
    62 => TimError.connectionFailed,
    // ERROR_TIMEOUT - Connection timeout
    133 => TimError.connectionTimeout,
    // ERROR_INVALID_ARGUMENT - Invalid argument
    22 => TimError.peripheralInfoIncomplete,
    // ERROR_NOT_ENABLED - Bluetooth not enabled
    1 => TimError.bluetoothStateOff,
    // ERROR_NOT_SUPPORTED - Bluetooth not supported
    2 => TimError.bluetoothUnavailable,
    // ERROR_BUSY - Device busy
    3 => TimError.peripheralBusy,
    // ERROR_FAILED - Operation failed
    4 => TimError.connectionFailed,
    // ERROR_NOT_FOUND - Device not found
    5 => TimError.peripheralNotFound,
    // ERROR_NOT_CONNECTED - Device not connected
    6 => TimError.connectionFailed,
    // ERROR_ALREADY_CONNECTED - Already connected
    7 => TimError.connectionFailed,
    _ => TimError.unknown,
  };
}

TimError _handleAppleError(FlutterBluePlusException exception) {
  final code = exception.code;
  if (code == null) return TimError.unknown;

  return switch (code) {
    // CBErrorUnknown - Unknown error
    1 => TimError.bluetoothUnavailable,
    // CBErrorInvalidParameters - Invalid parameters
    2 => TimError.bluetoothStateOff,
    // CBErrorInvalidHandle - Invalid handle
    3 => TimError.peripheralNotFound,
    // CBErrorNotConnected - Not connected
    4 => TimError.connectionFailed,
    // CBErrorOutOfSpace - Out of space
    5 => TimError.peripheralBusy,
    // CBErrorOperationCancelled - Operation cancelled
    6 => TimError.connectionTimeout,
    // CBErrorConnectionTimeout - Connection timeout
    7 => TimError.connectionTimeout,
    // CBErrorPeripheralDisconnected - Peripheral disconnected
    8 => TimError.peripheralInfoIncomplete,
    // CBErrorUUIDNotAllowed - UUID not allowed
    9 => TimError.unsupportedFeature,
    // CBErrorAlreadyAdvertising - Already advertising
    10 => TimError.peripheralInfoIncomplete,
    // CBErrorConnectionFailed - Connection failed
    11 => TimError.connectionFailed,
    // CBErrorConnectionLimitReached - Connection limit reached
    12 => TimError.peripheralNotFound,
    // CBErrorUnsupportedOperation - Unsupported operation
    13 => TimError.unsupportedFeature,
    _ => TimError.unknown,
  };
}

TimError _fromPlatformException(PlatformException exception) => switch (exception.code) {
      'connect' => TimError.peripheralNotFound,
      'timeout' => TimError.connectionTimeout,
      'bluetooth_unavailable' => TimError.bluetoothUnavailable,
      'bluetooth_state_off' => TimError.bluetoothStateOff,
      'device_not_found' => TimError.peripheralNotFound,
      'connection_failed' => TimError.connectionFailed,
      'device_busy' => TimError.peripheralBusy,
      'unsupported_feature' => TimError.unsupportedFeature,
      'invalid_argument' => TimError.peripheralInfoIncomplete,
      _ => TimError.unknown,
    };

TimError _fromFlutterBlueException(FlutterBluePlusException exception) => switch (exception.platform) {
      ErrorPlatform.fbp => _handleFbpError(exception),
      ErrorPlatform.apple => _handleAppleError(exception),
      ErrorPlatform.android => _handleAndroidError(exception),
    };

TimException? _fromException(Object exception) {
  if (exception is PlatformException) {
    return _fromPlatformException(exception).exception(original: exception);
  }
  if (exception is FlutterBluePlusException) {
    return _fromFlutterBlueException(exception).exception(original: exception);
  }
  return null;
}

TimDisconnectCode _handleAppleDisconnectReason(DisconnectReason reason) {
  return switch (reason.code) {
    7 => TimDisconnectCode.remote,
    6 => TimDisconnectCode.connectionTimeout,
    _ => TimDisconnectCode.unknown,
  };
}

TimDisconnectCode _handleAndroidDisconnectReason(DisconnectReason reason) {
  return switch (reason.code) {
    0 => TimDisconnectCode.normal,
    19 => TimDisconnectCode.remote,
    8 => TimDisconnectCode.connectionTimeout,
    133 => TimDisconnectCode.gattError,
    _ => TimDisconnectCode.unknown,
  };
}

/// https://developer.apple.com/documentation/corebluetooth/cberror-swift.struct
///
TimDisconnectReason _fromFlutterBlueDisconnectReason(DisconnectReason reason) {
  final r = TimDisconnectReason._internal();
  r.platform = reason.platform.name;

  final code = switch (r.platform) {
    'android' => _handleAndroidDisconnectReason(reason),
    'apple' => _handleAppleDisconnectReason(reason),
    _ => TimDisconnectCode.unknown,
  };

  r.code = code.value;
  r.description = code == TimDisconnectCode.unknown ? reason.description ?? '' : code.reason;
  return r;
}
