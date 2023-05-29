import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'snapkit_platform_interface.dart';

/// An implementation of [SnapkitPlatform] that uses method channels.
class MethodChannelSnapkit extends SnapkitPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('snapkit');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
