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
        case "callLogin":
            SCSDKLoginClient.login(from: (UIApplication.shared.keyWindow?.rootViewController)!) { (success: Bool, error: Error?) in
                if (!success) {
                    result(FlutterError(code: "LoginError", message: error.debugDescription, details: error.debugDescription))
                } else {
                    result("Login Success")
                }
            }
        case "getUser":
            let query = "{me{externalId, displayName, bitmoji{selfie}}}"
            let variables = ["page": "bitmoji"]
            
            SCSDKLoginClient.fetchUserData(withQuery: query, variables: variables, success: { (resources: [AnyHashable: Any]?) in
                guard let resources = resources,
                      let data = resources["data"] as? [String: Any],
                      let me = data["me"] as? [String: Any] else { return }
                
                let externalId = me["externalId"] as? String
                let displayName = me["displayName"] as? String
                var bitmojiAvatarUrl: String?
                if let bitmoji = me["bitmoji"] as? [String: Any] {
                    bitmojiAvatarUrl = bitmoji["selfie"] as? String
                }
                
                result([externalId, displayName, bitmojiAvatarUrl])
            }, failure: { (error: Error?, isUserLoggedOut: Bool) in
                if (isUserLoggedOut) {
                    result(FlutterError(code: "GetUserError", message: "User Not Logged In", details: nil))
                } else if (error != nil) {
                    result(FlutterError(code: "GetUserError", message: error.debugDescription, details: nil))
                } else {
                    result(FlutterError(code: "UnknownGetUserError", message: "Unknown", details: nil))
                }
            })
        case "callLogout":
            SCSDKLoginClient.clearToken()
            result("Logout Success")
        case "sendMedia":
            switch (call.arguments) {
            case .none:
                result(FlutterError(code: "MediaShareError", message: "Args was null", details: nil))
            case .some(let args):
                print(args)
                result("Success")
            }
        case "isInstalled":
            let appScheme = "snapchat://app"
            let appUrl = URL(string: appScheme)
            result(UIApplication.shared.canOpenURL(appUrl! as URL))
        case "getPlatformVersion":
            result("iOS " + UIDevice.current.systemVersion)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
