import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'package:devkitflutter/services/device_info_service.dart';
import 'package:devkitflutter/services/device_info_service_web_stub.dart' if (dart.library.html) 'package:devkitflutter/services/device_info_service_web.dart';

/// Service class for device registration and token verification
/// Handles communication with the CodeIgniter backend API
class DeviceService {
  /// Get the base API URL based on stored domain
  static Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final domain = prefs.getString('domain') ?? '';
    if (domain.isEmpty) {
      throw Exception('Domain not found. Please enter domain first.');
    }
    return 'https://$domain.efeedor.com/api';
  }

  /// Generate a unique device ID for web platform
  static Future<String> _generateWebDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? storedDeviceId = prefs.getString('web_device_id');
    
    if (storedDeviceId != null && storedDeviceId.isNotEmpty) {
      return storedDeviceId;
    }
    
    // Generate a unique ID based on timestamp and random string
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp * 1000).toString().substring(0, 8);
    final deviceId = 'web_${timestamp}_$random';
    
    // Store it for future use
    await prefs.setString('web_device_id', deviceId);
    return deviceId;
  }

  /// Get device information for web platform
  static Future<Map<String, String>> _getWebDeviceInfo() async {
    final deviceId = await _generateWebDeviceId();
    
    // Use dart:html to parse userAgent for web platform
    String deviceName = 'Web Browser';
    String platform = 'Web Browser';
    String osVersion = 'Web Platform';
    
    try {
      // Use the web-specific implementation with dart:html
      if (kIsWeb) {
        final webInfo = DeviceInfoServiceWeb.getDeviceInfo();
        deviceName = webInfo['device_name'] ?? 'Web Browser';
        platform = webInfo['platform'] ?? 'Web Browser';
        osVersion = webInfo['os_version'] ?? 'Web Platform';
      }
    } catch (e) {
      print('Error getting web device info: $e');
      // Fallback to generic values
    }
    
    return {
      'device_id': deviceId,
      'device_name': deviceName,
      'platform': platform,
      'os_version': osVersion,
    };
  }

  /// Register device with backend
  /// Returns registration token on success
  static Future<Map<String, dynamic>> registerDevice() async {
    try {
      String deviceId;
      String deviceName;
      String platform;
      String osVersion;

      // Handle web platform separately
      if (kIsWeb) {
        final webInfo = await _getWebDeviceInfo();
        deviceId = webInfo['device_id']!;
        deviceName = webInfo['device_name']!;
        platform = webInfo['platform']!;
        osVersion = webInfo['os_version']!;
      } else {
        // Mobile platforms (Android/iOS)
        final deviceInfo = DeviceInfoPlugin();

        if (Platform.isAndroid) {
          final androidInfo = await deviceInfo.androidInfo;
          // Use build fingerprint/incremental as device_id (e.g., "UKQ1.230924.001")
          // Fallback to Android ID if fingerprint not available
          deviceId = androidInfo.version.incremental.isNotEmpty 
              ? androidInfo.version.incremental 
              : androidInfo.id;
          // Use just the model name (e.g., "OnePlus CPH2467", not "OnePlus OnePlus CPH2467")
          deviceName = androidInfo.model.isNotEmpty 
              ? androidInfo.model 
              : androidInfo.device;
          platform = 'Android';
          osVersion = '${androidInfo.version.release} (SDK ${androidInfo.version.sdkInt})';
        } else if (Platform.isIOS) {
          final iosInfo = await deviceInfo.iosInfo;
          deviceId = iosInfo.identifierForVendor ?? 'unknown';
          // Use device name (e.g., "iPhone", "iPad") or model as fallback
          deviceName = iosInfo.name.isNotEmpty 
              ? iosInfo.name 
              : (iosInfo.model.isNotEmpty ? iosInfo.model : 'iPhone');
          platform = 'iOS';
          osVersion = iosInfo.systemVersion;
        } else {
          throw Exception('Unsupported platform');
        }
      }

      // Get domain from preferences
      final prefs = await SharedPreferences.getInstance();
      final domain = prefs.getString('domain') ?? '';
      if (domain.isEmpty) {
        throw Exception('Domain not found');
      }

      // Prepare request body
      final requestBody = {
        'domain': domain,
        'device_id': deviceId,
        'device_name': deviceName,
        'platform': platform,
        'os_version': osVersion,
      };

      // Make API call
      final baseUrl = await getBaseUrl();
      final response = await http.post(
        Uri.parse('$baseUrl/device/register'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout. Please check your connection.');
        },
      );

      // Parse response
      final responseData = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && responseData['status'] == 'success') {
        // Store device_id for later use
        await prefs.setString('device_id', deviceId);
        return {
          'success': true,
          'token': responseData['token'] as String,
          'message': responseData['message'] as String? ?? 'Device registered successfully',
        };
      } else {
        throw Exception(responseData['message'] as String? ?? 'Registration failed');
      }
    } catch (e) {
      return {
        'success': false,
        'message': e.toString().replaceFirst('Exception: ', ''),
      };
    }
  }

  /// Verify registration token
  /// Returns true if token is valid and device is approved
  static Future<Map<String, dynamic>> verifyToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final deviceId = prefs.getString('device_id') ?? '';
      
      if (deviceId.isEmpty) {
        throw Exception('Device ID not found. Please register device first.');
      }

      // Prepare request body
      final requestBody = {
        'device_id': deviceId,
        'token': token.trim().toUpperCase(),
      };

      // Make API call
      final baseUrl = await getBaseUrl();
      final response = await http.post(
        Uri.parse('$baseUrl/device/verify'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout. Please check your connection.');
        },
      );

      // Parse response
      final responseData = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && responseData['status'] == 'success') {
        return {
          'success': true,
          'message': responseData['message'] as String? ?? 'Token verified successfully',
        };
      } else {
        throw Exception(responseData['message'] as String? ?? 'Token verification failed');
      }
    } catch (e) {
      return {
        'success': false,
        'message': e.toString().replaceFirst('Exception: ', ''),
      };
    }
  }

  /// Get device information (device_id, device_name, platform)
  /// Returns device info map
  static Future<Map<String, String>> getDeviceInfo() async {
    String deviceId;
    String deviceName;
    String platform;

    // Handle web platform separately
    if (kIsWeb) {
      final webInfo = await _getWebDeviceInfo();
      deviceId = webInfo['device_id']!;
      // Use DeviceInfoService for better web detection
      final detailedInfo = await DeviceInfoService.getDeviceInfo();
      deviceName = detailedInfo['device_name']!;
      platform = detailedInfo['platform']!;
    } else {
      // Mobile platforms (Android/iOS) - use DeviceInfoService
      final detailedInfo = await DeviceInfoService.getDeviceInfo();
      deviceName = detailedInfo['device_name']!;
      platform = detailedInfo['platform']!;
      
      // Get device ID separately
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        // Use build fingerprint/incremental as device_id (e.g., "UKQ1.230924.001")
        // Fallback to Android ID if fingerprint not available
        deviceId = androidInfo.version.incremental.isNotEmpty 
            ? androidInfo.version.incremental 
            : androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor ?? 'unknown';
      } else {
        throw Exception('Unsupported platform');
      }
    }

    // Store device_id for later use
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('device_id', deviceId);

    return {
      'device_id': deviceId,
      'device_name': deviceName,
      'platform': platform,
    };
  }

  /// Check if device is already approved (one-time approval)
  static Future<bool> isDeviceApproved(String deviceId, String domain) async {
    try {
      final statusResult = await checkDeviceStatus();
      if (statusResult['success'] == true && statusResult['status'] == 'approved') {
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Request device approval
  /// Sends device details to /deviceApproval/requestAccess endpoint
  static Future<Map<String, dynamic>> requestDeviceApproval({
    required String userId,
    required String name,
    required String email,
    required String deviceId,
    required String deviceName,
    required String platform,
    required String ipAddress,
    required String domain,
  }) async {
    try {
      final requestUrl = await _getDeviceApprovalRequestUrl();
      
      final requestBody = {
        'user_id': userId,
        'name': name,
        'email': email,
        'device_id': deviceId,
        'device_name': deviceName,
        'platform': platform,
        'ip_address': ipAddress,
        'domain': domain,
      };

      print('Request Approval URL: $requestUrl');
      print('Request Body: $requestBody');

      final response = await http.post(
        Uri.parse(requestUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout. Please check your connection.');
        },
      );

      print('Request Approval Response Status: ${response.statusCode}');
      print('Request Approval Response Body: ${response.body}');

      // Parse response
      Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (e) {
        print('JSON Parse Error: $e');
        print('Response body: ${response.body}');
        return {
          'success': false,
          'message': 'Invalid response from server',
        };
      }

      if (response.statusCode == 200 && responseData['status'] == 'success') {
        return {
          'success': true,
          'message': responseData['message'] as String? ?? 'Device approval requested',
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] as String? ?? 'Failed to request device approval',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': e.toString().replaceFirst('Exception: ', ''),
      };
    }
  }

  /// Get device approval request URL
  static Future<String> _getDeviceApprovalRequestUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final domain = prefs.getString('domain') ?? '';
    if (domain.isEmpty) {
      throw Exception('Domain not found');
    }
    return 'https://$domain.efeedor.com/deviceApproval/requestAccess';
  }

  /// Check device approval status
  /// Returns status: 'approved', 'pending', 'blocked', or 'expired'
  static Future<Map<String, dynamic>> checkDeviceStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final deviceId = prefs.getString('device_id') ?? '';
      final domain = prefs.getString('domain') ?? '';

      if (deviceId.isEmpty) {
        throw Exception('Device ID not found');
      }

      if (domain.isEmpty) {
        throw Exception('Domain not found');
      }

      // Make API call to new endpoint
      final statusUrl = await _getDeviceStatusUrl();
      final url = Uri.parse(statusUrl).replace(queryParameters: {
        'device_id': deviceId,
        'domain': domain,
      });
      
      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout. Please check your connection.');
        },
      );

      // Parse response with error handling
      Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (e) {
        print('JSON Parse Error in checkDeviceStatus: $e');
        print('Response body: ${response.body}');
        return {
          'success': false,
          'status': 'error',
          'message': 'Invalid response from server',
        };
      }

      if (response.statusCode == 200) {
        return {
          'success': true,
          'status': responseData['status'] as String? ?? 'pending',
          'message': responseData['message'] as String? ?? '',
          'approval_expires_at': responseData['approval_expires_at'] as String?,
        };
      } else {
        return {
          'success': false,
          'status': 'error',
          'message': responseData['message'] as String? ?? 'Failed to check device status',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'status': 'error',
        'message': e.toString().replaceFirst('Exception: ', ''),
      };
    }
  }

  /// Get device status check URL
  static Future<String> _getDeviceStatusUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final domain = prefs.getString('domain') ?? '';
    if (domain.isEmpty) {
      throw Exception('Domain not found');
    }
    return 'https://$domain.efeedor.com/deviceApproval/checkStatus';
  }
}

