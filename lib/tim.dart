
import 'tim_platform_interface.dart';

class Tim {
  Future<String?> getPlatformVersion() {
    return TimPlatform.instance.getPlatformVersion();
  }
}
