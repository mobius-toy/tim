import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'tim_method_channel.dart';

abstract class TimPlatform extends PlatformInterface {
  /// Constructs a TimPlatform.
  TimPlatform() : super(token: _token);

  static final Object _token = Object();

  static TimPlatform _instance = MethodChannelTim();

  /// The default instance of [TimPlatform] to use.
  ///
  /// Defaults to [MethodChannelTim].
  static TimPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [TimPlatform] when
  /// they register themselves.
  static set instance(TimPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
