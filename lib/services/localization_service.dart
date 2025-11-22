import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalizationService extends ChangeNotifier {
  static const String _languageKey = 'selected_language';
  static const String _defaultLanguage = 'en';
  
  static Map<String, dynamic> _localizedStrings = {};
  static String _currentLanguage = _defaultLanguage;
  static LocalizationService? _instance;
  
  LocalizationService._();
  
  static LocalizationService get instance {
    _instance ??= LocalizationService._();
    return _instance!;
  }

  /// Initialize localization service
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguage = prefs.getString(_languageKey) ?? _defaultLanguage;
    await loadLanguage(savedLanguage);
  }

  /// Load language JSON file
  static Future<void> loadLanguage(String languageCode) async {
    try {
      final jsonString = await rootBundle.loadString('assets/lang/$languageCode.json');
      _localizedStrings = jsonDecode(jsonString) as Map<String, dynamic>;
      _currentLanguage = languageCode;
      
      // Save selected language
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

  /// Get localized string
  static String translate(String key) {
    return _localizedStrings[key] ?? key;
  }

  /// Get current language code
  static String get currentLanguage => _currentLanguage;

  /// Get current language name
  static String get currentLanguageName {
    switch (_currentLanguage) {
      case 'en':
        return 'English';
      case 'kn':
        return 'ಕನ್ನಡ';
      case 'ml':
        return 'മലയാളം';
      default:
        return 'English';
    }
  }

  /// Set language and reload
  static Future<void> setLanguage(String languageCode) async {
    if (_currentLanguage != languageCode) {
      await loadLanguage(languageCode);
    }
  }
}

