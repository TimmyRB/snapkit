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
    
    var _snapApi: SCSDKSnapAPI?
    
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
            guard let arguments = call.arguments,
                  let args = arguments as? [String: Any] else { return }
            
            let mediaType = args["mediaType"] as? String
            let imagePath = args["imagePath"] as? String
            let videoUrl = args["videoUrl"] as? String
            
            var content: SCSDKSnapContent?
            
            switch (mediaType) {
            case "PHOTO":
                if (!FileManager.default.fileExists(atPath: imagePath!)) {
                    result(FlutterError(code: "SendMediaArgsError", message: "Image could not be found in filesystem", details: imagePath))
                }
                
                guard let uiImage = UIImage(contentsOfFile: imagePath!) else {
                    result(FlutterError(code: "SendMediaArgsError", message: "Image could not be loaded into UIImage", details: imagePath!))
                    return
                }
                
                let photo = SCSDKSnapPhoto(image: uiImage)
                content = SCSDKPhotoSnapContent(snapPhoto: photo)
            case "VIDEO":
                let video = SCSDKSnapVideo(videoUrl: URL(string: videoUrl!)!)
                content = SCSDKVideoSnapContent(snapVideo: video)
            case "NONE":
                content = SCSDKNoSnapContent()
            default:
                result(FlutterError(code: "SendMediaArgsError", message: "Invalid Media Type", details: mediaType))
                return
            }
            
            let caption = args["caption"] as? String
            let attachmentUrl = args["attachmentUrl"] as? String
            
            content?.caption = caption
            content?.attachmentUrl = attachmentUrl
            
            if let sticker = args["sticker"] as? [String: Any] {
                let imagePath = sticker["imagePath"] as? String
                
                if (!FileManager.default.fileExists(atPath: imagePath!)) {
                    result(FlutterError(code: "SendMediaArgsError", message: "Image could not be found in filesystem", details: imagePath))
                }
                
                guard let uiImage = UIImage(contentsOfFile: imagePath!) else {
                    result(FlutterError(code: "SendMediaArgsError", message: "Image could not be loaded into UIImage", details: imagePath!))
                    return
                }
                
                let snapSticker = SCSDKSnapSticker(stickerImage: uiImage)
                
                content?.sticker = snapSticker
            }
            
            if (self._snapApi == nil) {
                self._snapApi = SCSDKSnapAPI()
            }
            
            self._snapApi?.startSending(content!, completionHandler: { (error: Error?) in
                if (error != nil) {
                    result(FlutterError(code: "SendMediaSendError", message: error.debugDescription, details: nil))
                } else {
                    result("SendMedia Success")
                }
            })
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
