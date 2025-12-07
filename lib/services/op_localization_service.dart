import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// OP-specific localization service
/// This service only affects OP (Outpatient) module pages
/// Dashboard and other modules remain in English
class OPLocalizationService extends ChangeNotifier {
  static const String _languageKey = 'op_selected_language';
  static const String _defaultLanguage = 'en';
  
  static Map<String, dynamic> _localizedStrings = {};
  static String _currentLanguage = _defaultLanguage;
  static OPLocalizationService? _instance;
  
  OPLocalizationService._();
  
  static OPLocalizationService get instance {
    _instance ??= OPLocalizationService._();
    return _instance!;
  }

  /// Initialize OP localization service
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguage = prefs.getString(_languageKey) ?? _defaultLanguage;
    await loadLanguage(savedLanguage);
  }

  /// Load language JSON file for OP module only
  static Future<void> loadLanguage(String languageCode) async {
    try {
      final jsonString = await rootBundle.loadString('assets/lang/$languageCode.json');
      _localizedStrings = jsonDecode(jsonString) as Map<String, dynamic>;
      _currentLanguage = languageCode;
      
      // Save selected language (OP module only)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, languageCode);
      
      // Notify listeners
      instance.notifyListeners();
    } catch (e) {
      // If language file not found, try to load English
      if (languageCode != _defaultLanguage) {
        await loadLanguage(_defaultLanguage);
      }
    }
  }

  /// Get localized string for OP module
  static String translate(String key) {
    return _localizedStrings[key] ?? key;
  }

  /// Get current language code
  static String get currentLanguage => _currentLanguage;

  /// Set language and reload (OP module only)
  static Future<void> setLanguage(String languageCode) async {
    if (_currentLanguage != languageCode) {
      await loadLanguage(languageCode);
    }
  }

  /// Reset to English (for when leaving OP module)
  static Future<void> resetToEnglish() async {
    if (_currentLanguage != _defaultLanguage) {
      await loadLanguage(_defaultLanguage);
    }
  }
}

