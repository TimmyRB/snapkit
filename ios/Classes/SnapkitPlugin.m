#import "SnapkitPlugin.h"
#if __has_include(<snapkit/snapkit-Swift.h>)
#import <snapkit/snapkit-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "snapkit-Swift.h"
#endif

@implementation SnapkitPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftSnapkitPlugin registerWithRegistrar:registrar];
}
@end
