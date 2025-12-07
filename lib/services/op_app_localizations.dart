import 'package:flutter/material.dart';
import 'op_localization_service.dart';

/// OP-specific localization helper
/// Use this extension only in OP module pages
extension OPLocalizationsExtension on BuildContext {
  String opTranslate(String key) {
    return OPLocalizationService.translate(key);
  }
}

