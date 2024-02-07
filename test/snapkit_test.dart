import 'package:flutter_test/flutter_test.dart';
import 'package:snapkit/snapkit_platform_interface.dart';
import 'package:snapkit/snapkit_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockSnapkitPlatform
    with MockPlatformInterfaceMixin
    implements SnapkitPlatform {
  @override
  Future<Map<String, String?>?> getCurrentUser() async {
    return Map<String, String?>.from({
      'displayName': 'Test User',
      'externalId': 'test-ext-id',
      'bitmoji2DAvatarUrl': 'https://example.com/avatar.png',
      'bitmojiAvatarId': 'test-bitmoji-id',
    });
  }

  @override
  Future<bool?> isLoggedIn() async {
    return true;
  }

  @override
  Future<bool?> isSnapchatInstalled() async {
    return true;
  }

  @override
  Future<void> login() async {
    throw UnimplementedError();
  }

  @override
  Future<void> logout() async {
    throw UnimplementedError();
  }

  @override
  Future<void> shareWithPhoto(String photoPath, Map<String, dynamic>? sticker,
      String? caption, String? link) {
    // TODO: implement shareWithPhoto
    throw UnimplementedError();
  }

  @override
  Future<void> shareToCamera(
      Map<String, dynamic>? sticker, String? caption, String? link) {
    // TODO: implement shareToCamera
    throw UnimplementedError();
  }
}

void main() {
  final SnapkitPlatform initialPlatform = SnapkitPlatform.instance;

  test('$MethodChannelSnapkit is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelSnapkit>());
  });

  // test('getCurrentUser', () async {
  //   Snapkit snapkitPlugin = Snapkit();
  //   MockSnapkitPlatform fakePlatform = MockSnapkitPlatform();
  //   SnapkitPlatform.instance = fakePlatform;

  //   await snapkitPlugin.getCurrentUser();

  //   expect(snapkitPlugin.currentUser?.externalId, 'test-ext-id');
  // });
}
