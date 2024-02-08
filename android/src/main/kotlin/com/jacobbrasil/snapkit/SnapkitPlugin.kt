package com.jacobbrasil.snapkit

import android.app.Activity
import android.content.pm.PackageManager
import android.content.pm.PackageManager.PackageInfoFlags
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
