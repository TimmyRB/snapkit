
import 'snapkit_platform_interface.dart';

class Snapkit {
  Future<String?> getPlatformVersion() {
    return SnapkitPlatform.instance.getPlatformVersion();
  }
}
