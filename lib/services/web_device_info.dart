import 'package:flutter/foundation.dart' show kIsWeb;

/// Web-specific device information service
/// Uses conditional imports for web platform
class WebDeviceInfo {
  static Future<Map<String, String>> getDeviceInfo() async {
    if (!kIsWeb) {
      return {
        'device_name': 'Unknown',
        'platform': 'Unknown',
        'browser': 'Unknown',
      };
    }

    // For web, we need to use dart:html
    // Since we can't use conditional imports in this shared file,
    // we'll return a placeholder that will be handled by the calling code
    // The actual implementation will be in a web-specific file
    
    // This is a fallback - actual implementation should use dart:html
    return {
      'device_name': 'Web Browser',
      'platform': 'Web Browser',
      'browser': 'Unknown',
    };
  }
}

