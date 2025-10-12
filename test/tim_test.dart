import 'package:flutter_test/flutter_test.dart';
import 'package:tim/tim.dart';
import 'package:tim/tim_platform_interface.dart';
import 'package:tim/tim_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockTimPlatform
    with MockPlatformInterfaceMixin
    implements TimPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final TimPlatform initialPlatform = TimPlatform.instance;

  test('$MethodChannelTim is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelTim>());
  });

  test('getPlatformVersion', () async {
    Tim timPlugin = Tim();
    MockTimPlatform fakePlatform = MockTimPlatform();
    TimPlatform.instance = fakePlatform;

    expect(await timPlugin.getPlatformVersion(), '42');
  });
}
