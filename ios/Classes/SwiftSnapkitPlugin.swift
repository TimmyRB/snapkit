import Flutter
import UIKit

// Snapkit Imports
import SCSDKCoreKit
import SCSDKLoginKit
import SCSDKCreativeKit
import SCSDKBitmojiKit

public class SwiftSnapkitPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "snapkit", binaryMessenger: registrar.messenger())
    let instance = SwiftSnapkitPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
        result("iOS " + UIDevice.current.systemVersion)
    default:
        result(FlutterMethodNotImplemented)
    }
  }
}
