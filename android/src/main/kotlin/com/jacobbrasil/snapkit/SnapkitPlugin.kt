package com.jacobbrasil.snapkit

import android.app.Activity
import android.os.Build
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import com.snapchat.kit.sdk.core.controller.LoginStateController.OnLoginStateChangedListener
import io.flutter.plugin.common.MethodChannel
import com.snapchat.kit.sdk.creative.api.SnapCreativeKitApi
import com.snapchat.kit.sdk.creative.media.SnapMediaFactory
import io.flutter.embedding.engine.plugins.FlutterPlugin.FlutterPluginBinding
import io.flutter.plugin.common.MethodCall
import com.snapchat.kit.sdk.SnapLogin
import com.snapchat.kit.sdk.login.networking.FetchUserDataCallback
import com.snapchat.kit.sdk.login.models.UserDataResponse
import com.snapchat.kit.sdk.login.models.MeData
import com.snapchat.kit.sdk.SnapCreative
import com.snapchat.kit.sdk.creative.models.SnapContent
import com.snapchat.kit.sdk.creative.media.SnapPhotoFile
import com.snapchat.kit.sdk.creative.models.SnapPhotoContent
import com.snapchat.kit.sdk.creative.exceptions.SnapMediaSizeException
import com.snapchat.kit.sdk.creative.media.SnapVideoFile
import com.snapchat.kit.sdk.creative.models.SnapVideoContent
import com.snapchat.kit.sdk.creative.exceptions.SnapVideoLengthException
import com.snapchat.kit.sdk.creative.models.SnapLiveCameraContent
import com.snapchat.kit.sdk.creative.media.SnapSticker
import com.snapchat.kit.sdk.creative.exceptions.SnapStickerSizeException
import com.snapchat.kit.sdk.util.SnapUtils
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import java.io.File
import java.lang.NullPointerException
import java.util.ArrayList

/**
 * SnapkitPlugin
 */
class SnapkitPlugin : FlutterPlugin, MethodCallHandler, ActivityAware, OnLoginStateChangedListener {
    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private var channel: MethodChannel? = null
    private var _activity: Activity? = null
    private var _result: MethodChannel.Result? = null
    private var creativeKitApi: SnapCreativeKitApi? = null
    private var mediaFactory: SnapMediaFactory? = null
    override fun onAttachedToEngine(flutterPluginBinding: FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "snapkit")
        channel!!.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "callLogin" -> {
                SnapLogin.getLoginStateController(_activity).addOnLoginStateChangedListener(this)
                SnapLogin.getAuthTokenManager(_activity).startTokenGrant()
                _result = result
            }
            "getUser" -> {
                val query = "{me{externalId, displayName, bitmoji{selfie}}}"
                SnapLogin.fetchUserData(_activity!!, query, null, object : FetchUserDataCallback {
                    override fun onSuccess(userDataResponse: UserDataResponse?) {
                        if (userDataResponse == null || userDataResponse.data == null) {
                            return
                        }
                        val meData = userDataResponse.data.me
                        if (meData == null) {
                            result.error("GetUserError", "Returned MeData was null", null)
                            return
                        }
                        val res: MutableList<String> = ArrayList()
                        res.add(meData.externalId)
                        res.add(meData.displayName)
                        res.add(meData.bitmojiData.selfie)
                        result.success(res)
                    }

                    override fun onFailure(isNetworkError: Boolean, statusCode: Int) {
                        if (isNetworkError) {
                            result.error("NetworkGetUserError", "Network Error", statusCode)
                        } else {
                            result.error("UnknownGetUserError", "Unknown Error", statusCode)
                        }
                    }
                })
            }
            "sendMedia" -> {
                if (creativeKitApi == null) creativeKitApi = SnapCreative.getApi(_activity!!)
                if (mediaFactory == null) mediaFactory = SnapCreative.getMediaFactory(_activity!!)
                val content: SnapContent
                content = when (call.argument<Any>("mediaType") as String?) {
                    "PHOTO" -> try {
                        val photoFile = mediaFactory!!.getSnapPhotoFromFile(File(call.argument<Any>("imagePath") as String?))
                        SnapPhotoContent(photoFile)
                    } catch (e: SnapMediaSizeException) {
                        result.error("SendMediaError", "Could not create SnapPhotoFile", e)
                        return
                    } catch (e: NullPointerException) {
                        result.error("SendMediaError", "Could not find Image file", e)
                        return
                    }
                    "VIDEO" -> try {
                        val videoFile = mediaFactory!!.getSnapVideoFromFile(File(call.argument<Any>("videoPath") as String?))
                        SnapVideoContent(videoFile)
                    } catch (e: SnapMediaSizeException) {
                        result.error("SendMediaError", "Could not create SnapVideoFile", e)
                        return
                    } catch (e: SnapVideoLengthException) {
                        result.error("SendMediaError", "Could not create SnapVideoFile", e)
                        return
                    } catch (e: NullPointerException) {
                        result.error("SendMediaError", "Could not find Video file", e)
                        return
                    }
                    else -> SnapLiveCameraContent()
                }
                content.captionText = call.argument<Any>("caption") as String?
                content.attachmentUrl = call.argument<Any>("attachmentUrl") as String?
                if (call.argument<Any?>("sticker") != null) {
                    val stickerMap = call.argument<Any>("sticker") as Map<String, Any>?
                    var sticker: SnapSticker? = null
                    sticker = try {
                        mediaFactory!!.getSnapStickerFromFile(File(stickerMap!!["imagePath"] as String?))
                    } catch (e: SnapStickerSizeException) {
                        result.error("SendMediaError", "Could not create SnapSticker", e)
                        return
                    } catch (e: NullPointerException) {
                        result.error("SendMediaError", "Could not find Sticker file", e)
                        return
                    }
                    if (sticker != null) {
                        sticker.setWidthDp(stickerMap["width"].toString().toFloat())
                        sticker.setHeightDp(stickerMap["height"].toString().toFloat())
                        sticker.setPosX(stickerMap["offsetX"].toString().toFloat())
                        sticker.setPosY(stickerMap["offsetY"].toString().toFloat())
                        sticker.setRotationDegreesClockwise(stickerMap["rotation"].toString().toFloat())
                        content.snapSticker = sticker
                    }
                }
                creativeKitApi!!.send(content)
            }
            "verifyNumber" -> {
                val res: MutableList<String> = ArrayList()
                res.add("")
                res.add("")
                result.success(res)
            }
            "callLogout" -> {
                SnapLogin.getAuthTokenManager(_activity).clearToken()
                _result = result
            }
            "isInstalled" -> result.success(SnapUtils.isSnapchatInstalled(_activity!!.packageManager, "com.snapchat.android"))
            "getPlatformVersion" -> result.success("Android " + Build.VERSION.RELEASE)
            else -> result.notImplemented()
        }
    }

    override fun onLoginSucceeded() {
        _result!!.success("Login Success")
    }

    override fun onLoginFailed() {
        _result!!.error("LoginError", "Error Logging In", null)
    }

    override fun onLogout() {
        _result!!.success("Logout Success")
    }

    override fun onDetachedFromEngine(binding: FlutterPluginBinding) {
        channel!!.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        _activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {}
    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {}
    override fun onDetachedFromActivity() {}
}