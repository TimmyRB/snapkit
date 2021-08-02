import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:snapkit/snapkit.dart';

class SnapchatButton extends StatelessWidget {
  /// Additional Font Options to change text
  final SnapchatButtonFontOptions? fontOptions;

  /// Desired Button Color
  final SnapchatButtonColors buttonColor;

  /// Snapkit Object used by button to Login
  final Snapkit snapkit;

  /// Creates a new `SnapchatButton` that by default conforms to
  /// Snapchat's Brand Guidelines
  const SnapchatButton({
    Key? key,
    required this.snapkit,
    this.buttonColor = SnapchatButtonColors.YELLOW,
    this.fontOptions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextButtonTheme(
      data: TextButtonThemeData(
          style: ButtonStyle(
              shape: MaterialStateProperty.resolveWith<OutlinedBorder>(
                (states) => RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              backgroundColor: MaterialStateProperty.resolveWith<Color?>(
                  (states) => buttonColor.color),
              padding: MaterialStateProperty.resolveWith<EdgeInsetsGeometry>(
                  (states) => EdgeInsets.only(
                      left: 22, top: 20, right: 22, bottom: 20)))),
      child: TextButton(
        onPressed: () => this.snapkit.login(),
        style: ButtonStyle(
            padding: MaterialStateProperty.resolveWith<EdgeInsets>(
                (states) => EdgeInsets.all(16.0))),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.only(right: 16.0),
              child: Image(
                image: buttonColor.ghost,
                fit: BoxFit.contain,
                height: 32.0,
                width: 32.0,
              ),
            ),
            Text(
              "Login with Snapchat",
              style: TextStyle(
                color: this.buttonColor.textColor,
                fontFamily: this.fontOptions?.fontFamily,
                fontFamilyFallback: this.fontOptions?.fontFamilyFallback,
                fontFeatures: this.fontOptions?.fontFeatures,
                fontSize: this.fontOptions?.fontSize,
                fontStyle: this.fontOptions?.fontStyle,
                fontWeight: this.fontOptions?.fontWeight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum SnapchatButtonColors {
  /// Snapchat Yellow
  YELLOW,

  /// Snapchat Black
  BLACK,

  /// Snapchat White
  WHITE,

  /// Snapchat Gray
  GRAY
}

class SnapchatButtonFontOptions {
  /// Change the `Text` font size
  final double? fontSize;

  /// Change the `Text` font weight
  final FontWeight? fontWeight;

  /// Change the `Text` font family
  final String? fontFamily;

  /// Change the `Text` font family fallback(s)
  final List<String>? fontFamilyFallback;

  /// Change the `Text` font features
  final List<FontFeature>? fontFeatures;

  /// Change the `Text` font style
  final FontStyle? fontStyle;

  /// Custom Font Options
  ///
  /// WARNING: Changing these will mean the button no longer follows
  /// Snapchat's Brand Guidelines
  SnapchatButtonFontOptions({
    this.fontSize,
    this.fontWeight,
    this.fontFamily,
    this.fontFamilyFallback,
    this.fontFeatures,
    this.fontStyle,
  });
}

extension SnapchatButtonExtension on SnapchatButtonColors {
  /// Gets the Button Color value associated with ENUM
  Color get color {
    switch (this) {
      case SnapchatButtonColors.YELLOW:
        return const Color.fromRGBO(255, 252, 0, 1);
      case SnapchatButtonColors.BLACK:
        return const Color.fromRGBO(0, 0, 0, 1);
      case SnapchatButtonColors.WHITE:
        return const Color.fromRGBO(255, 255, 255, 1);
      case SnapchatButtonColors.GRAY:
        return const Color.fromRGBO(244, 244, 244, 1);
    }
  }

  /// Gets the Text Color to contrast button color
  Color get textColor {
    switch (this) {
      case SnapchatButtonColors.BLACK:
        return const Color.fromRGBO(255, 255, 255, 1);
      default:
        return const Color.fromRGBO(0, 0, 0, 1);
    }
  }

  /// Gets the Image to contrast button color
  AssetImage get ghost {
    switch (this) {
      case SnapchatButtonColors.BLACK:
        return AssetImage('assets/images/GhostLogoDark.png',
            package: 'snapkit');
      default:
        return AssetImage('assets/images/GhostLogoLight.png',
            package: 'snapkit');
    }
  }
}
