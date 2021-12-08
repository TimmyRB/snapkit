package com.jacobbrasil.snapkit;

import android.app.Activity;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.snapchat.kit.sdk.SnapCreative;
import com.snapchat.kit.sdk.SnapLogin;
import com.snapchat.kit.sdk.core.controller.LoginStateController.OnLoginStateChangedListener;
import com.snapchat.kit.sdk.creative.api.SnapCreativeKitApi;
import com.snapchat.kit.sdk.creative.exceptions.SnapMediaSizeException;
import com.snapchat.kit.sdk.creative.exceptions.SnapStickerSizeException;
import com.snapchat.kit.sdk.creative.exceptions.SnapVideoLengthException;
import com.snapchat.kit.sdk.creative.media.SnapMediaFactory;
import com.snapchat.kit.sdk.creative.media.SnapPhotoFile;
import com.snapchat.kit.sdk.creative.media.SnapSticker;
import com.snapchat.kit.sdk.creative.media.SnapVideoFile;
import com.snapchat.kit.sdk.creative.models.SnapContent;
import com.snapchat.kit.sdk.creative.models.SnapLiveCameraContent;
import com.snapchat.kit.sdk.creative.models.SnapPhotoContent;
import com.snapchat.kit.sdk.creative.models.SnapVideoContent;
import com.snapchat.kit.sdk.login.models.MeData;
import com.snapchat.kit.sdk.login.models.UserDataResponse;
import com.snapchat.kit.sdk.login.networking.FetchUserDataCallback;
import com.snapchat.kit.sdk.util.SnapUtils;

import java.io.File;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

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
public class SnapkitPlugin implements FlutterPlugin, MethodCallHandler, ActivityAware, OnLoginStateChangedListener {
    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private MethodChannel channel;
    private Activity _activity;
    private MethodChannel.Result _result;
    private SnapCreativeKitApi creativeKitApi;
    private SnapMediaFactory mediaFactory;

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
                _result = result;
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
            case "sendMedia":
                if (creativeKitApi == null) creativeKitApi = SnapCreative.getApi(_activity);
                if (mediaFactory == null) mediaFactory = SnapCreative.getMediaFactory(_activity);

                SnapContent content;
                switch ((String)call.argument("mediaType")) {
                    case "PHOTO":
                        try {
                            SnapPhotoFile photoFile = mediaFactory.getSnapPhotoFromFile(new File((String) call.argument("imagePath")));
                            content = new SnapPhotoContent(photoFile);
                        } catch (SnapMediaSizeException e) {
                            result.error("SendMediaError", "Could not create SnapPhotoFile", e);
                            return;
                        } catch (NullPointerException e) {
                            result.error("SendMediaError", "Could not find Image file", e);
                            return;
                        }

                        break;
                    case "VIDEO":
                        try {
                            SnapVideoFile videoFile = mediaFactory.getSnapVideoFromFile(new File((String) call.argument("videoPath")));
                            content = new SnapVideoContent(videoFile);
                        } catch (SnapMediaSizeException | SnapVideoLengthException e) {
                            result.error("SendMediaError", "Could not create SnapVideoFile", e);
                            return;
                        } catch (NullPointerException e) {
                            result.error("SendMediaError", "Could not find Video file", e);
                            return;
                        }

                        break;
                    default:
                        content = new SnapLiveCameraContent();
                        break;
                }

                content.setCaptionText((String)call.argument("caption"));
                content.setAttachmentUrl((String)call.argument("attachmentUrl"));

                if (call.argument("sticker") != null) {
                    Map<String, Object> stickerMap = (Map<String, Object>) call.argument("sticker");
                    SnapSticker sticker = null;
                    try {
                        sticker = mediaFactory.getSnapStickerFromFile(new File((String) stickerMap.get("imagePath")));
                    } catch (SnapStickerSizeException e) {
                        result.error("SendMediaError", "Could not create SnapSticker", e);
                        return;
                    } catch (NullPointerException e) {
                        result.error("SendMediaError", "Could not find Sticker file", e);
                        return;
                    }

                    if (sticker != null) {
                        sticker.setWidthDp(Float.parseFloat(stickerMap.get("width").toString()));
                        sticker.setHeightDp(Float.parseFloat(stickerMap.get("height").toString()));

                        sticker.setPosX(Float.parseFloat(stickerMap.get("offsetX").toString()));
                        sticker.setPosY(Float.parseFloat(stickerMap.get("offsetY").toString()));

                        sticker.setRotationDegreesClockwise(Float.parseFloat(stickerMap.get("rotation").toString()));

                        content.setSnapSticker(sticker);
                    }
                }

                creativeKitApi.send(content);
                break;
            case "verifyNumber":
                List<String> res = new ArrayList<String>();
                res.add("");
                res.add("");
                result.success(res);
                break;
            case "callLogout":
                SnapLogin.getAuthTokenManager(_activity).clearToken();
                _result = result;
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
    public void onLoginSucceeded() {
        _result.success("Login Success");
    }

    @Override
    public void onLoginFailed() {
        _result.error("LoginError", "Error Logging In", null);
    }

    @Override
    public void onLogout() {
        _result.success("Logout Success");
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
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
