package com.jacobbrasil.snapkit;

import android.app.Activity;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.snap.corekit.utils.SnapUtils;
import com.snap.creativekit.SnapCreative;
import com.snap.creativekit.api.SnapCreativeKitApi;
import com.snap.creativekit.exceptions.SnapMediaSizeException;
import com.snap.creativekit.exceptions.SnapStickerSizeException;
import com.snap.creativekit.exceptions.SnapVideoLengthException;
import com.snap.creativekit.media.SnapMediaFactory;
import com.snap.creativekit.media.SnapPhotoFile;
import com.snap.creativekit.media.SnapSticker;
import com.snap.creativekit.media.SnapVideoFile;
import com.snap.creativekit.models.SnapContent;
import com.snap.creativekit.models.SnapLiveCameraContent;
import com.snap.creativekit.models.SnapPhotoContent;
import com.snap.creativekit.models.SnapVideoContent;
import com.snap.loginkit.BitmojiQuery;
import com.snap.loginkit.LoginStateCallback;
import com.snap.loginkit.SnapLogin;
import com.snap.loginkit.SnapLoginProvider;
import com.snap.loginkit.UserDataQuery;
import com.snap.loginkit.UserDataResultCallback;
import com.snap.loginkit.exceptions.LoginException;
import com.snap.loginkit.exceptions.UserDataException;
import com.snap.loginkit.models.BitmojiData;
import com.snap.loginkit.models.MeData;
import com.snap.loginkit.models.UserDataResult;

import java.io.File;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Objects;

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
public class SnapkitPlugin implements FlutterPlugin, MethodCallHandler, ActivityAware {
    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    @Nullable
    private MethodChannel channel;

    @Nullable
    private Activity _activity;

    @NonNull
    private Activity requireActivity() {
        return Objects.requireNonNull(_activity, "Snapkit plugin is not attached to an activity.");
    }

    @Nullable
    private SnapCreativeKitApi snapCreativeKitApi;

    @NonNull
    private SnapCreativeKitApi getSnapCreativeKitApi() {
        if (snapCreativeKitApi == null) snapCreativeKitApi = SnapCreative.getApi(requireActivity());
        return snapCreativeKitApi;
    }

    @Nullable
    private SnapMediaFactory snapMediaFactory;

    @NonNull
    private SnapMediaFactory getSnapMediaFactory() {
        if (snapMediaFactory == null)
            snapMediaFactory = SnapCreative.getMediaFactory(requireActivity());
        return snapMediaFactory;
    }

    @Nullable
    private SnapLogin snapLogin;

    @NonNull
    private SnapLogin getSnapLogin() {
        if (snapLogin == null) snapLogin = SnapLoginProvider.get(requireActivity());
        return snapLogin;
    }

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "snapkit");
        channel.setMethodCallHandler(this);
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull final Result result) {
        switch (call.method) {
            case "callLogin":
                callLogin(result);
                break;
            case "getUser":
                getUser(result);
                break;
            case "sendMedia":
                final String imagePath = call.argument("imagePath");
                final String videoPath = call.argument("videoPath");
                final Map<String, Object> sticker = call.argument("sticker");
                sendMedia(
                        Objects.requireNonNull(call.argument("mediaType")),
                        imagePath == null ? null : new File(imagePath),
                        videoPath == null ? null : new File(videoPath),
                        sticker == null ? null : StickerArguments.fromMap(sticker),
                        call.argument("caption"),
                        call.argument("attachmentUrl"),
                        result
                );
                break;
            case "verifyNumber":
                List<String> res = new ArrayList<>();
                res.add("");
                res.add("");
                result.success(res);
                break;
            case "callLogout":
                callLogout(result);
                break;
            case "isInstalled":
                result.success(SnapUtils.isSnapchatInstalled(
                        requireActivity().getPackageManager(),
                        "com.snapchat.android"
                ));
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
        Objects.requireNonNull(channel).setMethodCallHandler(null);
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
        _activity = null;
    }

    // Creative Kit: https://docs.snap.com/snap-kit/creative-kit/Tutorials/android

    void sendMedia(
            @NonNull String mediaType,
            @Nullable File imagePath,
            @Nullable File videoPath,
            @Nullable StickerArguments sticker,
            @Nullable String caption,
            @Nullable String attachmentUrl,
            @NonNull MethodChannel.Result result
    ) {
        final SnapMediaFactory mediaFactory = getSnapMediaFactory();

        SnapContent content;
        switch (mediaType) {
            case "PHOTO":
                if (imagePath == null) {
                    result.error(
                            "SendMediaError",
                            "mediaType is set to photo but imagePath is null.",
                            null
                    );
                    return;
                }

                SnapPhotoFile photoFile;
                try {
                    photoFile = mediaFactory.getSnapPhotoFromFile(imagePath);
                } catch (SnapMediaSizeException e) {
                    result.error("SendMediaError", "Could not create SnapPhotoFile", e);
                    return;
                } catch (NullPointerException e) {
                    result.error("SendMediaError", "Could not find image file", e);
                    return;
                }

                content = new SnapPhotoContent(photoFile);
                break;
            case "VIDEO":
                if (videoPath == null) {
                    result.error(
                            "SendMediaError",
                            "mediaType is set to video but videoPath is null.",
                            null
                    );
                    return;
                }

                SnapVideoFile videoFile;
                try {
                    videoFile = mediaFactory.getSnapVideoFromFile(videoPath);
                } catch (SnapMediaSizeException | SnapVideoLengthException e) {
                    result.error("SendMediaError", "Could not create SnapVideoFile", e);
                    return;
                } catch (NullPointerException e) {
                    result.error("SendMediaError", "Could not find video file", e);
                    return;
                }

                content = new SnapVideoContent(videoFile);
                break;
            default:
                content = new SnapLiveCameraContent();
                break;
        }

        content.setCaptionText(caption);
        content.setAttachmentUrl(attachmentUrl);

        if (sticker != null) {
            SnapSticker snapSticker;
            try {
                snapSticker = mediaFactory.getSnapStickerFromFile(sticker.image);
            } catch (SnapStickerSizeException e) {
                result.error("SendMediaError", "Could not create SnapSticker", e);
                return;
            } catch (NullPointerException e) {
                result.error("SendMediaError", "Could not find sticker file", e);
                return;
            }

            snapSticker.setWidthDp(sticker.width);
            snapSticker.setHeightDp(sticker.height);
            snapSticker.setPosX(sticker.offsetX);
            snapSticker.setPosY(sticker.offsetY);
            snapSticker.setRotationDegreesClockwise(sticker.rotation);
            content.setSnapSticker(snapSticker);
        }

        getSnapCreativeKitApi().send(content);
    }

    static class StickerArguments {
        @NonNull
        File image;
        float width;
        float height;
        float offsetX;
        float offsetY;
        float rotation;

        public StickerArguments(
                @NonNull File image,
                float width,
                float height,
                float offsetX,
                float offsetY,
                float rotation
        ) {
            this.image = image;
            this.width = width;
            this.height = height;
            this.offsetX = offsetX;
            this.offsetY = offsetY;
            this.rotation = rotation;
        }

        static StickerArguments fromMap(Map<String, Object> map) {
            return new StickerArguments(
                    new File((String) Objects.requireNonNull(map.get("imagePath"))),
                    ((Double) Objects.requireNonNull(map.get("width"))).floatValue(),
                    ((Double) Objects.requireNonNull(map.get("height"))).floatValue(),
                    ((Double) Objects.requireNonNull(map.get("offsetX"))).floatValue(),
                    ((Double) Objects.requireNonNull(map.get("offsetY"))).floatValue(),
                    ((Double) Objects.requireNonNull(map.get("rotation"))).floatValue()
            );
        }
    }

    // Login Kit: https://docs.snap.com/snap-kit/login-kit/Tutorials/android

    void callLogin(@NonNull MethodChannel.Result result) {
        final SnapLogin snapLogin = getSnapLogin();
        final LoginStateCallback callback = new LoginStateCallback() {
            @Override
            public void onStart() {
            }

            @Override
            public void onSuccess(@NonNull String s) {
                result.success("Login Success");
                snapLogin.removeLoginStateCallback(this);
            }

            @Override
            public void onFailure(@NonNull LoginException e) {
                result.error("LoginError", "Error Logging In", e);
                snapLogin.removeLoginStateCallback(this);
            }

            @Override
            public void onLogout() {
                snapLogin.removeLoginStateCallback(this);
            }
        };
        snapLogin.addLoginStateCallback(callback);
        snapLogin.startTokenGrant();
    }

    void getUser(@NonNull MethodChannel.Result result) {
        final BitmojiQuery bitmojiQuery = BitmojiQuery.newBuilder()
                .withTwoDAvatarUrl()
                .build();
        final UserDataQuery userDataQuery = UserDataQuery.newBuilder()
                .withExternalId()
                .withDisplayName()
                .withBitmoji(bitmojiQuery)
                .build();
        getSnapLogin().fetchUserData(userDataQuery, new UserDataResultCallback() {
            @Override
            public void onSuccess(@NonNull UserDataResult userDataResult) {
                if (userDataResult.getData() == null)
                    return;


                final MeData meData = userDataResult.getData().getMeData();
                if (meData == null) {
                    result.error("GetUserError", "Returned MeData was null", null);
                    return;
                }
                final BitmojiData bitmojiData = meData.getBitmojiData();

                List<String> res = new ArrayList<>();
                res.add(meData.getExternalId());
                res.add(meData.getDisplayName());
                res.add(bitmojiData == null ? null : bitmojiData.getTwoDAvatarUrl());
                result.success(res);
            }

            @Override
            public void onFailure(@NonNull UserDataException e) {
                UserDataException.Status status = null;
                for (UserDataException.Status s : UserDataException.Status.values()) {
                    if (s.code == e.getStatusCode()) {
                        status = s;
                        break;
                    }
                }
                Objects.requireNonNull(status);
                result.error("UnknownGetUserError", status.message, status.code);
            }
        });
    }

    void callLogout(@NonNull MethodChannel.Result result) {
        final SnapLogin snapLogin = getSnapLogin();
        LoginStateCallback callback = new LoginStateCallback() {
            @Override
            public void onStart() {
            }

            @Override
            public void onSuccess(@NonNull String s) {
                snapLogin.removeLoginStateCallback(this);
            }

            @Override
            public void onFailure(@NonNull LoginException e) {
                result.error("LogoutError", "Error Logging In", e);
                snapLogin.removeLoginStateCallback(this);
            }

            @Override
            public void onLogout() {
                result.success("Logout Success");
                snapLogin.removeLoginStateCallback(this);
            }
        };
        snapLogin.addLoginStateCallback(callback);
        snapLogin.clearToken();
    }
}
