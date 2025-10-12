import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'tim_platform_interface.dart';

/// An implementation of [TimPlatform] that uses method channels.
class MethodChannelTim extends TimPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('tim');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
