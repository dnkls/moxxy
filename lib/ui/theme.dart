import 'package:flutter/material.dart';
import 'package:moxxyv2/ui/constants.dart';

/// A theme extension for Moxxy specific colors.
@immutable
class MoxxyThemeData extends ThemeExtension<MoxxyThemeData> {
  const MoxxyThemeData({
    required this.conversationTextFieldColor,
    required this.profileFallbackBackgroundColor,
    required this.profileFallbackTextColor,
  });

  /// The color of the conversation TextField
  final Color conversationTextFieldColor;

  /// The color of the background of a user with no avatar
  final Color profileFallbackBackgroundColor;

  /// The text color of a user with no avatar
  final Color profileFallbackTextColor;

  @override
  MoxxyThemeData copyWith({Color? conversationTextFieldColor, Color? profileFallbackBackgroundColor, Color? profileFallbackTextColor}) {
    return MoxxyThemeData(
      conversationTextFieldColor: conversationTextFieldColor ?? this.conversationTextFieldColor,
      profileFallbackBackgroundColor: profileFallbackBackgroundColor ?? this.profileFallbackBackgroundColor,
      profileFallbackTextColor: profileFallbackTextColor ?? this.profileFallbackTextColor,
    );
  }

  @override
  MoxxyThemeData lerp(ThemeExtension<MoxxyThemeData>? other, double t) {
    return this;
  }
}

/// Helper function for quickly generating MaterialStateProperty instances that
/// only differentiate between a color for the element's disabled state and for all
/// other states.
MaterialStateProperty<Color> _makeEnabledDisabledProperty(Color enabled, Color disabled) {
  return MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
    if (states.contains(MaterialState.disabled)) return disabled;
    return enabled;
  });
}

// NOTE: Inspired by syphon's code: https://github.com/syphon-org/syphon/blob/dev/lib/global/themes.dart
ThemeData getThemeData(BuildContext context, Brightness brightness) {
  return ThemeData(
    brightness: brightness,
    backgroundColor: const Color(0xff303030),

    // NOTE: Mainly for the SettingsSection
    colorScheme: brightness == Brightness.dark ?
      const ColorScheme.dark(secondary: primaryColor) :
      const ColorScheme.light(secondary: primaryColor),

    // UI elements
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        foregroundColor: _makeEnabledDisabledProperty(Colors.white, textColorDisabled),
        backgroundColor: _makeEnabledDisabledProperty(primaryColor, primaryColorDisabled),
      ),
    ),
    checkboxTheme: CheckboxTheme.of(context).copyWith(
      fillColor: MaterialStateProperty.all(primaryColor),
    ),
    switchTheme: SwitchTheme.of(context).copyWith(
      trackColor: MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
        if (states.contains(MaterialState.disabled)) {
          return primaryColorDisabled;
        } else if (!states.contains(MaterialState.selected)) {
          return primaryColorDisabled;
        }

        return primaryColorAlt;
      }),
      thumbColor: MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
        if (states.contains(MaterialState.disabled)) {
          return Colors.white;
        } else if (!states.contains(MaterialState.selected)) {
          return Colors.white;
        }

        return primaryColor;
      }),
    ),

    extensions: [
      if (brightness == Brightness.dark)
        const MoxxyThemeData(
          conversationTextFieldColor: conversationTextFieldColorDark,
          profileFallbackBackgroundColor: profileFallbackBackgroundColorDark,
          profileFallbackTextColor: profileFallbackTextColorDark,
        )
      else
        const MoxxyThemeData(
          conversationTextFieldColor: conversationTextFieldColorLight,
          profileFallbackBackgroundColor: profileFallbackBackgroundColorLight,
          profileFallbackTextColor: profileFallbackTextColorLight,
        ),
    ],
  );
}
