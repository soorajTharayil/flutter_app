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
        // Use just the model name (e.g., "OnePlus CPH2467", not "OnePlus OnePlus CPH2467")
        deviceName = androidInfo.model.isNotEmpty 
            ? androidInfo.model 
            : androidInfo.device;
        // Platform should be just "Android", not "Android version"
        platform = 'Android';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfoPlugin.iosInfo;
        // Use device name (e.g., "iPhone", "iPad") or model as fallback
        deviceName = iosInfo.name.isNotEmpty 
            ? iosInfo.name 
            : (iosInfo.model.isNotEmpty ? iosInfo.model : 'iPhone');
        // Platform should be just "iOS", not "iOS version"
        platform = 'iOS';
      }
    } catch (e) {
      print('Error getting mobile device info: $e');
    }

    return {
      'device_name': deviceName,
      'platform': platform,
    };
  }
}

