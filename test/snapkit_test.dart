import 'package:flutter_test/flutter_test.dart';
import 'package:snapkit/snapkit.dart';
import 'package:snapkit/snapkit_platform_interface.dart';
import 'package:snapkit/snapkit_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockSnapkitPlatform
    with MockPlatformInterfaceMixin
    implements SnapkitPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final SnapkitPlatform initialPlatform = SnapkitPlatform.instance;

  test('$MethodChannelSnapkit is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelSnapkit>());
  });

  test('getPlatformVersion', () async {
    Snapkit snapkitPlugin = Snapkit();
    MockSnapkitPlatform fakePlatform = MockSnapkitPlatform();
    SnapkitPlatform.instance = fakePlatform;

    expect(await snapkitPlugin.getPlatformVersion(), '42');
  });
}
