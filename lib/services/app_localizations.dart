import 'package:flutter/material.dart';
import 'localization_service.dart';

class AppLocalizations {
  static String translate(String key) {
    return LocalizationService.translate(key);
  }

  static String get currentLanguage => LocalizationService.currentLanguage;
}

extension AppLocalizationsExtension on BuildContext {
  String translate(String key) {
    return AppLocalizations.translate(key);
  }
}

