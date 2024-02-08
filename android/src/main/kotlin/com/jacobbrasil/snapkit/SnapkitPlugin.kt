package com.jacobbrasil.snapkit

import android.app.Activity
import android.content.pm.PackageManager
import android.content.pm.PackageManager.PackageInfoFlags
import com.snap.creativekit.SnapCreative
import com.snap.creativekit.api.SnapCreativeKitApi
import com.snap.creativekit.api.SnapCreativeKitCompletionCallback
import com.snap.creativekit.api.SnapCreativeKitSendError
import com.snap.creativekit.exceptions.SnapMediaSizeException
import com.snap.creativekit.exceptions.SnapStickerSizeException
import com.snap.creativekit.exceptions.SnapVideoLengthException
import com.snap.creativekit.media.SnapMediaFactory
import com.snap.creativekit.media.SnapPhotoFile
import com.snap.creativekit.media.SnapSticker
import com.snap.creativekit.models.SnapContent
import com.snap.creativekit.models.SnapLiveCameraContent
import com.snap.creativekit.models.SnapPhotoContent
import com.snap.creativekit.models.SnapVideoContent
import com.snap.loginkit.AccessTokenResultCallback
import com.snap.loginkit.BitmojiQuery
import com.snap.loginkit.LoginResultCallback
import com.snap.loginkit.SnapLogin
import com.snap.loginkit.SnapLoginProvider
import com.snap.loginkit.UserDataQuery
import com.snap.loginkit.UserDataResultCallback
import com.snap.loginkit.exceptions.AccessTokenException
import com.snap.loginkit.exceptions.LoginException
import com.snap.loginkit.exceptions.UserDataException
import com.snap.loginkit.models.UserDataResult
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.File
import java.util.Objects


/** SnapkitPlugin */
class SnapkitPlugin: FlutterPlugin, MethodCallHandler, ActivityAware {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel

  private var _activity : Activity? = null

  private var _snapApi : SnapCreativeKitApi? = null
  private var _snapMediaFactory : SnapMediaFactory? = null

  private fun requireActivity(): Activity {
    return Objects.requireNonNull<Activity>(_activity, "Snapkit plugin is not attached to an activity.")
  }

  private fun getSnapApi(): SnapCreativeKitApi {
    if (_snapApi == null) {
      _snapApi = SnapCreative.getApi(requireActivity())
    }

    return _snapApi!!
  }

  private fun getSnapMediaFactory(): SnapMediaFactory {
    if (_snapMediaFactory == null) {
      _snapMediaFactory = SnapCreative.getMediaFactory(requireActivity())
    }

    return _snapMediaFactory!!
  }

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "snapkit")
    channel.setMethodCallHandler(this)
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      "sdkVersion" -> {
        result.success(SnapLoginProvider.getVersion())
      }
      "isSnapchatInstalled" -> {
        try {
          val pm: PackageManager = requireActivity().packageManager
          pm.getPackageInfo("com.snapchat.android", PackageInfoFlags.of(0))
          result.success(true)
        } catch (e: PackageManager.NameNotFoundException) {
          result.success(false)
        }
      }
      "isLoggedIn" -> {
        result.success(SnapLoginProvider.get(requireActivity()).isUserLoggedIn)
      }
      "login" -> {
        SnapLoginProvider.get(requireActivity()).startTokenGrant(object: LoginResultCallback {
          override fun onStart() {
            // Nothing is done here
          }

          override fun onSuccess(accessToken: String) {
            result.success("Login Success")
          }

          override fun onFailure(exception: LoginException) {
            result.error("LoginError", exception.localizedMessage, null)
          }
        })
      }
      "getCurrentUser" -> {
        val bitmojiQuery = BitmojiQuery.newBuilder().withAvatarId().withTwoDAvatarUrl().build()
        val userDataQuery = UserDataQuery.newBuilder().withExternalId().withIdToken().withDisplayName().withBitmoji(bitmojiQuery).build()

        SnapLoginProvider.get(requireActivity()).fetchUserData(userDataQuery, object: UserDataResultCallback {
          override fun onSuccess(userDataResult: UserDataResult) {
            if (userDataResult.data?.meData == null) {
              result.error("GetUserError", "User data was null", null)
              return
            }

            val meData = userDataResult.data!!.meData!!
            val map: HashMap<String, String?> = HashMap<String, String?>()
            map["externalId"] = meData.externalId
            map["openIdToken"] = meData.idToken
            map["displayName"] = meData.displayName
            map["bitmoji2DAvatarUrl"] = meData.bitmojiData?.twoDAvatarUrl
            map["bitmojiAvatarId"] = meData.bitmojiData?.avatarId
            map["errors"] = null

            result.success(map)
          }

          override fun onFailure(exception: UserDataException) {
            result.error("GetUserError", exception.localizedMessage, exception)
          }
        })
      }
      "getAccessToken" -> {
        SnapLoginProvider.get(requireActivity()).fetchAccessToken(object: AccessTokenResultCallback {
          override fun onSuccess(token: String) {
            result.success(token)
          }

          override fun onFailure(e: AccessTokenException) {
            result.error("GetAccessTokenError", e.localizedMessage, e)
          }

        })
      }
      "logout" -> {
        SnapLoginProvider.get(requireActivity()).clearToken()
        result.success("Logout Success")
      }
      "shareToCamera" -> {
        if (call.arguments !is Map<*, *>) {
          return
        }

        val args = call.arguments as Map<*, *>

        try {
          val content = handleCommonShare(args, SnapLiveCameraContent())

          getSnapApi().sendWithCompletionHandler(content, object: SnapCreativeKitCompletionCallback {
            override fun onSendSuccess() {
              result.success("ShareToCamera Success")
            }

            override fun onSendFailed(e: SnapCreativeKitSendError?) {
              result.error("ShareToCameraError", e?.name, e)
            }
          })
        } catch (e: SnapStickerSizeException) {
          result.error("ShareToCameraError", e.localizedMessage, e)
        } catch (e: SnapKitException) {
          result.error("ShareToCameraError", e.localizedMessage, "Error caused by handleCommonShare")
        }
      }
      "shareWithPhoto" -> {
        if (call.arguments !is Map<*, *>) {
          return
        }

        val args = call.arguments as Map<*, *>

        try {
          val photo = File(args["photoPath"].toString())

          if (!photo.exists()) {
            result.error("ShareWithPhotoError","Photo could not be found in filesystem", null)
          }

          val content = handleCommonShare(args, SnapPhotoContent(getSnapMediaFactory().getSnapPhotoFromFile(photo)))

          getSnapApi().sendWithCompletionHandler(content, object: SnapCreativeKitCompletionCallback {
            override fun onSendSuccess() {
              result.success("ShareWithPhoto Success")
            }

            override fun onSendFailed(e: SnapCreativeKitSendError?) {
              result.error("ShareWithPhotoError", e?.name, e)
            }
          })
        } catch (e: SnapMediaSizeException) {
          result.error("ShareWithPhotoError", e.localizedMessage, e)
        } catch (e: SnapStickerSizeException) {
          result.error("ShareWithPhotoError", e.localizedMessage, e)
        } catch (e: SnapKitException) {
          result.error("ShareWithPhotoError", e.localizedMessage, "Error caused by handleCommonShare")
        }
      }
      "shareWithVideo" -> {
        if (call.arguments !is Map<*, *>) {
          return
        }

        val args = call.arguments as Map<*, *>

        try {
          val video = File(args["videoPath"].toString())

          if (!video.exists()) {
            result.error("ShareWithVideoError","Video could not be found in filesystem", null)
          }

          val content = handleCommonShare(args, SnapVideoContent(getSnapMediaFactory().getSnapVideoFromFile(video)))

          getSnapApi().sendWithCompletionHandler(content, object: SnapCreativeKitCompletionCallback {
            override fun onSendSuccess() {
              result.success("ShareWithVideo Success")
            }

            override fun onSendFailed(e: SnapCreativeKitSendError?) {
              result.error("ShareWithVideoError", e?.name, e)
            }
          })
        } catch (e: SnapMediaSizeException) {
          result.error("ShareWithVideoError", e.localizedMessage, e)
        } catch (e: SnapVideoLengthException) {
          result.error("ShareWithVideoError", e.localizedMessage, e)
        } catch (e: SnapStickerSizeException) {
          result.error("ShareWithVideoError", e.localizedMessage, e)
        } catch (e: SnapKitException) {
          result.error("ShareWithVideoError", e.localizedMessage, "Error caused by handleCommonShare")
        }
      }
      else -> {
        result.notImplemented()
      }
    }
  }

  private fun handleCommonShare(args: Map<*, *>, content: SnapContent): SnapContent {
    content.captionText = args["caption"].toString()
    content.attachmentUrl = args["link"].toString()

    if (args["sticker"] is Map<*, *>) {
      val sticker = args["sticker"] as Map<*, *>

      val image = File(sticker["imagePath"].toString())

      if (!image.exists()) {
        throw SnapKitException("Image could not be found in filesystem")
      }

      try {
        val snapSticker = getSnapMediaFactory().getSnapStickerFromFile(image)

        if (sticker["size"] is Map<*, *>) {
          val size = sticker["size"] as Map<*, *>
          snapSticker.setWidthDp(size["width"] as Float)
          snapSticker.setHeightDp(size["height"] as Float)
        }

        if (sticker["offset"] is Map<*, *>) {
          val offset = sticker["offset"] as Map<*, *>
          snapSticker.setPosX(offset["x"] as Float)
          snapSticker.setPosY(offset["y"] as Float)
        }

        if (sticker["rotation"] is Map<*, *>) {
          val rotation = sticker["rotation"] as Map<*, *>
          snapSticker.setRotationDegreesClockwise(rotation["angle"] as Float)
        }

        content.snapSticker = snapSticker
      } catch (e: SnapStickerSizeException) {
        throw e
      }
    }

    return content
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    _activity = binding.activity
  }

  override fun onDetachedFromActivity() {
    _activity = null
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {  }

  override fun onDetachedFromActivityForConfigChanges() {  }
}

class SnapKitException(message: String): Exception(message)
