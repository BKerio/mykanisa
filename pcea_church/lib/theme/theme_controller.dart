import 'package:flutter/material.dart';
import 'package:pcea_church/screen/color_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends ChangeNotifier {
  static final ThemeController instance = ThemeController._internal();
  ThemeController._internal();

  static const String _prefsA11y = 'app_accessibility_enabled';
  static const String _prefsTextScale = 'app_text_scale';
  static const String _prefsHighContrast = 'app_high_contrast';
  static const String _prefsBoldText = 'app_bold_text';

  bool _accessibilityEnabled = false;
  bool get accessibilityEnabled => _accessibilityEnabled;

  double _textScaleFactor = 1.0;
  double get textScaleFactor => _textScaleFactor;

  bool _highContrast = false;
  bool get highContrast => _highContrast;

  bool _boldText = false;
  bool get boldText => _boldText;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    _accessibilityEnabled = prefs.getBool(_prefsA11y) ?? false;
    _textScaleFactor =
        prefs.getDouble(_prefsTextScale) ?? (_accessibilityEnabled ? 1.2 : 1.0);
    _highContrast = prefs.getBool(_prefsHighContrast) ?? _accessibilityEnabled;
    _boldText = prefs.getBool(_prefsBoldText) ?? false;

    notifyListeners();
  }

  Future<void> setAccessibilityEnabled(bool enabled) async {
    _accessibilityEnabled = enabled;

    if (enabled) {
      _textScaleFactor = _textScaleFactor < 1.1 ? 1.2 : _textScaleFactor;
      _highContrast = true;
    } else {
      _textScaleFactor = 1.0;
      _highContrast = false;
    }

    await _savePrefs();
    notifyListeners();
  }

  Future<void> setTextScale(double scale) async {
    _textScaleFactor = scale.clamp(0.9, 1.8);
    await _savePrefs();
    notifyListeners();
  }

  Future<void> setHighContrast(bool value) async {
    _highContrast = value;
    await _savePrefs();
    notifyListeners();
  }

  Future<void> setBoldText(bool value) async {
    _boldText = value;
    await _savePrefs();
    notifyListeners();
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsA11y, _accessibilityEnabled);
    await prefs.setDouble(_prefsTextScale, _textScaleFactor);
    await prefs.setBool(_prefsHighContrast, _highContrast);
    await prefs.setBool(_prefsBoldText, _boldText);
  }

  /// Returns an adaptive theme that respects accessibility preferences.
  ThemeData getAdaptiveTheme({bool dark = false}) {
    final base = dark
        ? ThemeData.dark(useMaterial3: true)
        : ThemeData.light(useMaterial3: true);

    final scheme = base.colorScheme.copyWith(
      primary: dark
          ? FlexFundTheme.lightBlue
          : (_highContrast
                ? FlexFundTheme.darkGreen
                : FlexFundTheme.primaryGreen),
      secondary: dark
          ? FlexFundTheme.primaryBlue
          : (_highContrast
                ? FlexFundTheme.darkBlue
                : FlexFundTheme.primaryBlue),
      surface: dark ? const Color(0xFF0F1113) : FlexFundTheme.lightGray,
      onSurface: dark ? FlexFundTheme.white : FlexFundTheme.darkGray,
      error: FlexFundTheme.errorRed,
    );

    var themed = base.copyWith(
      colorScheme: scheme,
      textTheme: base.textTheme.apply(
        bodyColor: dark ? FlexFundTheme.white : FlexFundTheme.darkGray,
        displayColor: dark ? FlexFundTheme.white : FlexFundTheme.darkGray,
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );

    if (_boldText) {
      themed = themed.copyWith(
        textTheme: themed.textTheme.copyWith(
          bodyLarge: themed.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          bodyMedium: themed.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          bodySmall: themed.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
          titleLarge: themed.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          titleMedium: themed.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          titleSmall: themed.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return themed;
  }
}
