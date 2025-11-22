// Web-specific implementation
// This file should be used with conditional imports for web platform

import 'dart:html' as html;

/// Web-specific device information
class DeviceInfoServiceWeb {
  static Map<String, String> getDeviceInfo() {
    final userAgent = html.window.navigator.userAgent.toLowerCase();
    String deviceName = 'Unknown Device';
    String platform = 'Web Browser';
    String browser = 'Unknown Browser';
    String osVersion = 'Web Platform';

    // Detect device type
    if (userAgent.contains('mac')) {
      deviceName = 'Mac Laptop';
      platform = 'macOS';
      // Try to extract macOS version
      final macVersionMatch = RegExp(r'mac os x[_\s](\d+)[._](\d+)').firstMatch(userAgent);
      if (macVersionMatch != null) {
        osVersion = '${macVersionMatch.group(1)}.${macVersionMatch.group(2)}';
      }
    } else if (userAgent.contains('windows')) {
      deviceName = 'Windows PC';
      platform = 'Windows';
      // Try to extract Windows version
      if (userAgent.contains('windows nt 10')) {
        osVersion = '10';
      } else if (userAgent.contains('windows nt 6.3')) {
        osVersion = '8.1';
      } else if (userAgent.contains('windows nt 6.2')) {
        osVersion = '8';
      } else if (userAgent.contains('windows nt 6.1')) {
        osVersion = '7';
      }
    } else if (userAgent.contains('linux')) {
      deviceName = 'Linux PC';
      platform = 'Linux';
    } else if (userAgent.contains('iphone')) {
      deviceName = 'iPhone';
      platform = 'iOS';
      // Try to extract iOS version
      final iosVersionMatch = RegExp(r'os[_\s](\d+)[._](\d+)').firstMatch(userAgent);
      if (iosVersionMatch != null) {
        osVersion = '${iosVersionMatch.group(1)}.${iosVersionMatch.group(2)}';
      }
    } else if (userAgent.contains('ipad')) {
      deviceName = 'iPad';
      platform = 'iOS';
      // Try to extract iOS version
      final iosVersionMatch = RegExp(r'os[_\s](\d+)[._](\d+)').firstMatch(userAgent);
      if (iosVersionMatch != null) {
        osVersion = '${iosVersionMatch.group(1)}.${iosVersionMatch.group(2)}';
      }
    } else if (userAgent.contains('android')) {
      deviceName = 'Android Device';
      platform = 'Android';
      // Try to extract Android version
      final androidVersionMatch = RegExp(r'android[_\s](\d+(?:\.\d+)?)').firstMatch(userAgent);
      if (androidVersionMatch != null) {
        osVersion = androidVersionMatch.group(1)!;
      }
    }

    // Detect browser
    if (userAgent.contains('chrome') && !userAgent.contains('edg')) {
      browser = 'Chrome';
    } else if (userAgent.contains('safari') && !userAgent.contains('chrome')) {
      browser = 'Safari';
    } else if (userAgent.contains('firefox')) {
      browser = 'Firefox';
    } else if (userAgent.contains('edg')) {
      browser = 'Edge';
    } else if (userAgent.contains('opera')) {
      browser = 'Opera';
    }

    // Combine platform and browser
    final fullPlatform = '$platform $browser';

    return {
      'device_name': deviceName,
      'platform': fullPlatform,
      'os_version': osVersion,
    };
  }
}

