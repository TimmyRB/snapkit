package com.jacobbrasil.snapkit

import android.app.Activity
import android.content.pm.PackageManager
import android.content.pm.PackageManager.PackageInfoFlags
import com.snap.loginkit.BitmojiQuery
import com.snap.loginkit.LoginResultCallback
import com.snap.loginkit.SnapLoginProvider
import com.snap.loginkit.UserDataQuery
import com.snap.loginkit.UserDataResultCallback
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
import java.util.Objects


/** SnapkitPlugin */
class SnapkitPlugin: FlutterPlugin, MethodCallHandler, ActivityAware {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel

  private var _activity : Activity? = null

  private fun requireActivity(): Activity {
    return Objects.requireNonNull<Activity>(_activity, "Snapkit plugin is not attached to an activity.")
  }

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "snapkit")
    channel.setMethodCallHandler(this)
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
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
        result.success(SnapLoginProvider.get(requireActivity().applicationContext).isUserLoggedIn)
      }
      "login" -> {
        SnapLoginProvider.get(requireActivity().applicationContext).startTokenGrant(object: LoginResultCallback {
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
        val userDataQuery = UserDataQuery.newBuilder().withExternalId().withDisplayName().withBitmoji(bitmojiQuery).build()

        SnapLoginProvider.get(requireActivity().applicationContext).fetchUserData(userDataQuery, object: UserDataResultCallback {
          override fun onSuccess(userDataResult: UserDataResult) {
            if (userDataResult.data?.meData == null) {
              result.error("GetUserError", "User data was null", null)
              return
            }

            val meData = userDataResult.data!!.meData!!
            val map: HashMap<String, String?> = HashMap<String, String?>()
            map["externalId"] = meData.externalId
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
      "logout" -> {
        SnapLoginProvider.get(requireActivity().applicationContext).clearToken()
        result.success("Logout Success")
      }
      else -> {
        result.notImplemented()
      }
    }
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
