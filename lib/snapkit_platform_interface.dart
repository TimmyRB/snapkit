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

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
