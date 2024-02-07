import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'snapkit_method_channel.dart';

abstract class SnapkitPlatform extends PlatformInterface {
  /// Constructs a SnapkitPlatform.
  SnapkitPlatform() : super(token: _token);

  static final Object _token = Object();

  static SnapkitPlatform _instance = MethodChannelSnapkit();

  /// The default instance of [SnapkitPlatform] to use.
  ///
  /// Defaults to [MethodChannelSnapkit].
  static SnapkitPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [SnapkitPlatform] when
  /// they register themselves.
  static set instance(SnapkitPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<bool?> isSnapchatInstalled() {
    throw UnimplementedError('isSnapchatInstalled() has not been implemented.');
  }

  Future<bool?> isLoggedIn() {
    throw UnimplementedError('isLoggedIn() has not been implemented.');
  }

  Future<void> login() {
    throw UnimplementedError('login() has not been implemented.');
  }

  Future<Map<String, String?>?> getCurrentUser() {
    throw UnimplementedError('getCurrentUser() has not been implemented.');
  }

  Future<void> logout() {
    throw UnimplementedError('logout() has not been implemented.');
  }

  Future<void> shareToCamera(
    Map<String, dynamic>? sticker,
    String? caption,
    String? link,
  ) {
    throw UnimplementedError('shareToCamera() has not been implemented.');
  }

  Future<void> shareWithPhoto(
    String photoPath,
    Map<String, dynamic>? sticker,
    String? caption,
    String? link,
  ) {
    throw UnimplementedError('shareWithPhoto() has not been implemented.');
  }
}
