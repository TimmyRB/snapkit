package com.jacobbrasil.snapkit;

import android.app.Activity;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.snapchat.kit.sdk.SnapLogin;
import com.snapchat.kit.sdk.core.controller.LoginStateController;
import com.snapchat.kit.sdk.login.models.MeData;
import com.snapchat.kit.sdk.login.models.UserDataResponse;
import com.snapchat.kit.sdk.login.networking.FetchUserDataCallback;
import com.snapchat.kit.sdk.util.SnapUtils;

import java.util.ArrayList;
import java.util.List;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

/**
 * SnapkitPlugin
 */
public class SnapkitPlugin implements FlutterPlugin, MethodCallHandler, ActivityAware, LoginStateController.OnLoginStateChangedListener {
    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private MethodChannel channel;
    private Activity _activity;
    private MethodChannel.Result _result;

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "snapkit");
        channel.setMethodCallHandler(this);
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull final Result result) {
        switch (call.method) {
            case "callLogin":
                SnapLogin.getLoginStateController(_activity).addOnLoginStateChangedListener(this);
                SnapLogin.getAuthTokenManager(_activity).startTokenGrant();
                this._result = result;
                break;
            case "getUser":
                String query = "{me{externalId, displayName, bitmoji{selfie}}}";
                SnapLogin.fetchUserData(_activity, query, null, new FetchUserDataCallback() {
                    @Override
                    public void onSuccess(@Nullable UserDataResponse userDataResponse) {
                        if (userDataResponse == null || userDataResponse.getData() == null) {
                            return;
                        }

                        MeData meData = userDataResponse.getData().getMe();
                        if (meData == null) {
                            result.error("GetUserError", "Returned MeData was null", null);
                            return;
                        }

                        List<String> res = new ArrayList<String>();
                        res.add(meData.getExternalId());
                        res.add(meData.getDisplayName());
                        res.add(meData.getBitmojiData().getSelfie());

                        result.success(res);
                    }

                    @Override
                    public void onFailure(boolean isNetworkError, int statusCode) {
                        if (isNetworkError) {
                            result.error("NetworkGetUserError", "Network Error", statusCode);
                        } else {
                            result.error("UnknownGetUserError", "Unknown Error", statusCode);
                        }
                    }
                });
                break;
            case "callLogout":
                SnapLogin.getAuthTokenManager(_activity).clearToken();
                this._result = result;
                break;
            case "isInstalled":
                result.success(SnapUtils.isSnapchatInstalled(_activity.getPackageManager(), "com.snapchat.android"));
                break;
            case "getPlatformVersion":
                result.success("Android " + android.os.Build.VERSION.RELEASE);
                break;
            default:
                result.notImplemented();
                break;
        }
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
    }

    @Override
    public void onLoginSucceeded() {
        this._result.success("Login Success");
    }

    @Override
    public void onLoginFailed() {
        this._result.error("LoginError", "Error Logging In", null);
    }

    @Override
    public void onLogout() {
        this._result.success("Logout Success");
    }

    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
        _activity = binding.getActivity();
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {

    }

    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {

    }

    @Override
    public void onDetachedFromActivity() {

    }
}
