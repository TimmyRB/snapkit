import Flutter
import UIKit

	// Snapkit Imports
import SCSDKCoreKit
import SCSDKLoginKit
import SCSDKCreativeKit

extension String: Error {}

public class SnapkitPlugin: NSObject, FlutterPlugin {
	public static func register(with registrar: FlutterPluginRegistrar) {
		let channel = FlutterMethodChannel(name: "snapkit", binaryMessenger: registrar.messenger())
		let instance = SnapkitPlugin()
		registrar.addMethodCallDelegate(instance, channel: channel)
	}
	
	var _snapApi: SCSDKSnapAPI?
	
	public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
		switch call.method {
			case "isSnapchatInstalled":
				let appScheme = "snapchat://app"
				let appUrl = URL(string: appScheme)
				result(UIApplication.shared.canOpenURL(appUrl! as URL))
			case "isLoggedIn":
				result(SCSDKLoginClient.isUserLoggedIn)
				break
			case "login":
				let uiViewController = UIApplication.shared.delegate?.window??.rootViewController
				
				if (uiViewController == nil) {
					result(FlutterError(code: "LoginError", message: "Could not get UI View Controller from iOS", details: nil))
				}
				
				SCSDKLoginClient.login(from: uiViewController, completion: { (success: Bool, error: Error?) in
					if (success) {
						result("Login Success")
					} else if (!success && error != nil) {
						result(FlutterError(code: "LoginError", message: error.debugDescription, details: nil))
					} else {
						result(FlutterError(code: "LoginError", message: "An unknown error occurred while trying to login", details: nil))
					}
				})
				break
			case "getCurrentUser":
				let queryBuilder = SCSDKUserDataQueryBuilder().withExternalId().withDisplayName().withBitmojiAvatarID().withBitmojiTwoDAvatarUrl()
				let query = queryBuilder.build()
				SCSDKLoginClient.fetchUserData(with: query,
											   success: {(userdata: SCSDKUserData?, partialError: Error?) in
					guard let data = userdata else { return }
					
					let map: [String: String?] = [
						"externalId": data.externalID,
						"displayName": data.displayName,
						"bitmoji2DAvatarUrl": data.bitmojiTwoDAvatarUrl,
						"bitmojiAvatarId": data.bitmojiAvatarID,
						"errors": partialError != nil ? partialError.debugDescription : nil
					]
					
					result(map)
				},
											   failure: {(error: Error?, isUserLoggedOut: Bool) in
					if (isUserLoggedOut) {
						result(FlutterError(code: "GetUserError", message: "User Not Logged In", details: error))
					} else if (error != nil) {
						result(FlutterError(code: "GetUserError", message: error.debugDescription, details: error))
					} else {
						result(FlutterError(code: "GetUserError", message: "An unknown error ocurred while trying to retrieve user data", details: error))
					}
				})
				break
			case "logout":
				SCSDKLoginClient.clearToken()
				result("Logout Success")
				break
			case "shareToCamera":
				guard let arguments = call.arguments,
					  let args = arguments as? [String: Any] else { return }
				
				do {
					var content = try self.handleCommonShare(args: args, content: SCSDKNoSnapContent())
					
					if (_snapApi == nil) {
						_snapApi = SCSDKSnapAPI()
					}
					
					_snapApi?.startSending(content, completionHandler: { (error: Error?) in
						if (error != nil) {
							result(FlutterError(code: "ShareToCameraError", message: error?.localizedDescription, details: "Error occurred while trying to send"))
						} else {
							result("ShareToCamera Success")
						}
					})
				} catch (let e) {
					result(FlutterError(code: "ShareToCameraError", message: e.localizedDescription, details: "Error caused by handleCommonShare"))
				}
				
				break
			case "shareWithPhoto":
				guard let arguments = call.arguments,
					  let args = arguments as? [String: Any] else { return }
				
				do {
					guard let photoPath = args["photoPath"] as? String else {
						result(FlutterError(code: "ShareWithPhotoError", message: "Photo Path not provided", details: nil))
						return
					}
					
					if (!FileManager.default.fileExists(atPath: photoPath)) {
						throw "Image could not be found in filesystem"
					}
					
					guard let uiImage = UIImage(contentsOfFile: photoPath) else {
						throw "Image could not be loaded into UIImage"
					}
					
					var photo = SCSDKSnapPhoto(image: uiImage)
					var content = try self.handleCommonShare(args: args, content: SCSDKPhotoSnapContent(snapPhoto: photo))
					
					if (_snapApi == nil) {
						_snapApi = SCSDKSnapAPI()
					}
					
					_snapApi?.startSending(content, completionHandler: { (error: Error?) in
						if (error != nil) {
							result(FlutterError(code: "ShareWithPhotoError", message: error?.localizedDescription, details: "Error occurred while trying to send"))
						} else {
							result("ShareWithPhoto Success")
						}
					})
				} catch (let e) {
					result(FlutterError(code: "ShareWithPhotoError", message: e.localizedDescription, details: "Error caused by handleCommonShare"))
				}
				break
			case "shareWithVideo":
				guard let arguments = call.arguments,
					  let args = arguments as? [String: Any] else { return }
				
				do {
					guard let videoPath = args["videoPath"] as? String else {
						result(FlutterError(code: "ShareWithVideoError", message: "Video Path not provided", details: nil))
						return
					}
					
					if (!FileManager.default.fileExists(atPath: videoPath)) {
						throw "Video could not be found in filesystem"
					}
					
					var video = SCSDKSnapVideo(videoUrl: URL(fileURLWithPath: videoPath))
					var content = try self.handleCommonShare(args: args, content: SCSDKVideoSnapContent(snapVideo: video))
					
					if (_snapApi == nil) {
						_snapApi = SCSDKSnapAPI()
					}
					
					_snapApi?.startSending(content, completionHandler: { (error: Error?) in
						if (error != nil) {
							result(FlutterError(code: "ShareWithVideoError", message: error?.localizedDescription, details: "Error occurred while trying to send"))
						} else {
							result("ShareWithVideo Success")
						}
					})
				} catch (let e) {
					result(FlutterError(code: "ShareWithVideoError", message: e.localizedDescription, details: "Error caused by handleCommonShare"))
				}
				break
			default:
				result(FlutterMethodNotImplemented)
		}
	}
	
	public func handleCommonShare(args: [String: Any], content: SCSDKSnapContent) throws -> SCSDKSnapContent {
		content.caption = args["caption"] as? String
		content.attachmentUrl = args["link"] as? String
		
		if let sticker = args["sticker"] as? [String: Any] {
			let imagePath = sticker["imagePath"] as? String
			
			if (!FileManager.default.fileExists(atPath: imagePath!)) {
				throw "Image could not be found in filesystem"
			}
			
			guard let uiImage = UIImage(contentsOfFile: imagePath!) else {
				throw "Image could not be loaded into UIImage"
			}
			
			let snapSticker = SCSDKSnapSticker(stickerImage: uiImage)
			
			if let size = sticker["size"] as? [String: Any] {
				snapSticker.width = size["width"] as! CGFloat
				snapSticker.height = size["height"] as! CGFloat
			}
			
			if let offset = sticker["offset"] as? [String: Any] {
				snapSticker.posX = offset["x"] as! CGFloat
				snapSticker.posY = offset["y"] as! CGFloat
			}
			
			if let rotation = sticker["rotation"] as? [String: Any] {
				snapSticker.rotation = rotation["angle"] as! CGFloat
			}
			
			content.sticker = snapSticker
		}
		
		return content
	}
}
