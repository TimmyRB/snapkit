import 'package:snapkit/snapkit_platform_interface.dart';

export 'loginkit.dart';
export 'creativekit.dart';

class SnapKit {
  /// The instance of [SnapKit] to use.
  static SnapKit I = SnapKit();

  /// Checks if the Snapchat app is installed on the device.
  Future<bool> isSnapchatInstalled() async {
    return (await SnapkitPlatform.instance.isSnapchatInstalled()) ?? false;
  }

  /// Gets the version of the Snap SDK running on your device.
  Future<String> getSnapSDKVersion() async {
    return (await SnapkitPlatform.instance.getSnapSDKVersion()) ?? 'Unknown';
  }
}
