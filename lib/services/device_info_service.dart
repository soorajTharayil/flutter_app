import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:devkitflutter/services/device_info_service_web_stub.dart' if (dart.library.html) 'package:devkitflutter/services/device_info_service_web.dart';

/// Service to get detailed device information
class DeviceInfoService {
  /// Get device name and platform information
  /// Returns: {'device_name': '...', 'platform': '...'}
  static Future<Map<String, String>> getDeviceInfo() async {
    if (kIsWeb) {
      return _getWebDeviceInfo();
    } else {
      return _getMobileDeviceInfo();
    }
  }

  /// Get web device information
  static Future<Map<String, String>> _getWebDeviceInfo() async {
    String deviceName = 'Web Browser';
    String platform = 'Web Browser';

    try {
      if (kIsWeb) {
        // Use the web-specific implementation with dart:html
        final webInfo = DeviceInfoServiceWeb.getDeviceInfo();
        deviceName = webInfo['device_name'] ?? 'Web Browser';
        platform = webInfo['platform'] ?? 'Web Browser';
      }
    } catch (e) {
      print('Error getting web device info: $e');
    }

    return {
      'device_name': deviceName,
      'platform': platform,
    };
  }

  /// Get mobile device information (Android/iOS)
  static Future<Map<String, String>> _getMobileDeviceInfo() async {
    final deviceInfoPlugin = DeviceInfoPlugin();
    String deviceName = 'Unknown Device';
    String platform = 'Unknown Platform';

    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfoPlugin.androidInfo;
        deviceName = getAndroidDeviceName(androidInfo);
        // Platform should be just "Android", not "Android version"
        platform = 'Android';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfoPlugin.iosInfo;
        deviceName = getIOSDeviceName(iosInfo);
        // Platform should be just "iOS", not "iOS version"
        platform = 'iOS';
      }
    } catch (e) {
      print('Error getting mobile device info: $e');
      // Set fallback based on platform
      if (Platform.isAndroid) {
        deviceName = 'Android Device';
        platform = 'Android';
      } else if (Platform.isIOS) {
        deviceName = 'iPhone Device';
        platform = 'iOS';
      }
    }

    return {
      'device_name': deviceName,
      'platform': platform,
    };
  }

  /// Get proper device name for Android
  /// Extracts human-readable device name, filtering out build IDs
  static String getAndroidDeviceName(AndroidDeviceInfo androidInfo) {
    try {
      String manufacturer = androidInfo.manufacturer.trim();
      String model = androidInfo.model.trim();
      String device = androidInfo.device.trim();
      
      // Check if model looks like a build ID (e.g., "AQ3A.240912.001", "UKQ1.230924.001")
      // Build IDs typically have patterns like: LETTERS.DIGITS.DIGITS or similar
      bool looksLikeBuildId = _isBuildIdPattern(model);
      
      // If model is empty or looks like a build ID, try device field
      if (model.isEmpty || looksLikeBuildId) {
        // Try using device field if it's not empty and doesn't look like build ID
        if (device.isNotEmpty && !_isBuildIdPattern(device)) {
          // Combine manufacturer + device if manufacturer is available and different
          if (manufacturer.isNotEmpty && !device.toLowerCase().contains(manufacturer.toLowerCase())) {
            return '${_capitalizeFirst(manufacturer)} $device';
          }
          return device;
        }
        
        // If device also looks like build ID, try brand
        String brand = androidInfo.brand.trim();
        if (brand.isNotEmpty && !_isBuildIdPattern(brand)) {
          if (manufacturer.isNotEmpty && manufacturer != brand && !brand.toLowerCase().contains(manufacturer.toLowerCase())) {
            return '${_capitalizeFirst(manufacturer)} ${_capitalizeFirst(brand)}';
          }
          return _capitalizeFirst(brand);
        }
        
        // Fallback
        return 'Android Device';
      }
      
      // Model looks valid, combine with manufacturer if appropriate
      if (manufacturer.isNotEmpty) {
        // Check if model already contains manufacturer name
        if (model.toLowerCase().contains(manufacturer.toLowerCase())) {
          return model;
        }
        // Check if manufacturer already contains model (avoid duplication)
        if (!manufacturer.toLowerCase().contains(model.toLowerCase())) {
          return '${_capitalizeFirst(manufacturer)} $model';
        }
      }
      
      return model;
    } catch (e) {
      print('Error extracting Android device name: $e');
      return 'Android Device';
    }
  }

  /// Get proper device name for iOS
  static String getIOSDeviceName(IosDeviceInfo iosInfo) {
    try {
      // Try name first (e.g., "John's iPhone", "iPad Pro")
      if (iosInfo.name.isNotEmpty) {
        String name = iosInfo.name.trim();
        // Remove owner name if present (e.g., "John's iPhone" -> "iPhone")
        if (name.contains("'s ")) {
          List<String> parts = name.split("'s ");
          if (parts.length > 1) {
            return parts[1];
          }
        }
        return name;
      }
      
      // Try model (e.g., "iPhone14,2")
      if (iosInfo.model.isNotEmpty) {
        String model = iosInfo.model.trim();
        // Convert model identifier to readable name if possible
        return _iosModelToName(model);
      }
      
      // Fallback
      return 'iPhone Device';
    } catch (e) {
      print('Error extracting iOS device name: $e');
      return 'iPhone Device';
    }
  }

  /// Check if a string looks like a build ID pattern
  /// Build IDs typically have patterns like: "AQ3A.240912.001", "UKQ1.230924.001"
  static bool _isBuildIdPattern(String value) {
    if (value.isEmpty) return false;
    
    // Pattern: Contains dots with alphanumeric segments
    // Examples: "AQ3A.240912.001", "UKQ1.230924.001", "OS2.0.203.0.VNUINXM"
    RegExp buildIdPattern = RegExp(r'^[A-Z0-9]+\.[0-9]+\.[0-9]+(\.[0-9]+)*(\.[A-Z0-9]+)*$');
    
    // Also check for patterns like: "AQ3A.240912.001" with 3+ segments separated by dots
    if (value.contains('.')) {
      List<String> parts = value.split('.');
      if (parts.length >= 3) {
        // Check if most parts are numeric or short alphanumeric
        int numericOrShortParts = 0;
        for (String part in parts) {
          if (RegExp(r'^[0-9]+$').hasMatch(part) || 
              (part.length <= 5 && RegExp(r'^[A-Z0-9]+$').hasMatch(part))) {
            numericOrShortParts++;
          }
        }
        // If most parts match the pattern, likely a build ID
        if (numericOrShortParts >= parts.length * 0.7) {
          return true;
        }
      }
    }
    
    return buildIdPattern.hasMatch(value);
  }

  /// Capitalize first letter of each word
  static String _capitalizeFirst(String value) {
    if (value.isEmpty) return value;
    List<String> words = value.split(' ');
    return words.map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  /// Convert iOS model identifier to readable name
  static String _iosModelToName(String model) {
    // Common iOS model identifiers mapping
    Map<String, String> modelMap = {
      'iPhone': 'iPhone',
      'iPad': 'iPad',
      'iPod': 'iPod touch',
    };
    
    // Check if it starts with known prefixes
    for (String prefix in modelMap.keys) {
      if (model.startsWith(prefix)) {
        return modelMap[prefix]!;
      }
    }
    
    // Return as-is if no match
    return model;
  }
}

