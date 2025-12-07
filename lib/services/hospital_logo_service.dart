import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'department_service.dart';

class HospitalLogoService {
  static const String _logoCacheKey = 'hospital_logo_base64';
  static const String _logoTimestampKey = 'hospital_logo_timestamp';
  static const String _hospitalNameKey = 'hospital_name';
  static const int _cacheDurationMs = 24 * 60 * 60 * 1000; // 24 hours

  /// Fetches the hospital logo from the department.php API
  /// Returns the base64 string of the logo
  static Future<String?> fetchLogoFromApi() async {
    try {
      final domain = await getDomainFromPrefs();
      if (domain.isEmpty) {
        return null;
      }

      // Use patientid=1 as default (same as used in other services)
      final response = await http.get(
        Uri.parse('https://$domain.efeedor.com/api/department.php?patientid=1'),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final settingData = data['setting_data'] as Map<String, dynamic>?;
        
        if (settingData != null) {
          final prefs = await SharedPreferences.getInstance();
          
          // Cache logo
          if (settingData.containsKey('logo')) {
            final logoBase64 = settingData['logo'] as String?;
            if (logoBase64 != null && logoBase64.isNotEmpty) {
              await prefs.setString(_logoCacheKey, logoBase64);
            }
          }
          
          // Cache hospital name (try description or address as fallback)
          String? hospitalName;
          if (settingData.containsKey('description') && settingData['description'] != null) {
            hospitalName = settingData['description'] as String?;
          } else if (settingData.containsKey('address') && settingData['address'] != null) {
            hospitalName = settingData['address'] as String?;
          }
          
          if (hospitalName != null && hospitalName.isNotEmpty) {
            await prefs.setString(_hospitalNameKey, hospitalName);
          }
          
          await prefs.setInt(_logoTimestampKey, DateTime.now().millisecondsSinceEpoch);
          
          if (settingData.containsKey('logo')) {
            final logoBase64 = settingData['logo'] as String?;
            if (logoBase64 != null && logoBase64.isNotEmpty) {
              return logoBase64;
            }
          }
        }
      }
      return null;
    } catch (e) {
      // Return null on error, will fall back to cached logo
      return null;
    }
  }

  /// Gets the cached logo if available and not expired
  static Future<String?> getCachedLogo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedLogo = prefs.getString(_logoCacheKey);
      final timestamp = prefs.getInt(_logoTimestampKey);
      
      if (cachedLogo != null && cachedLogo.isNotEmpty) {
        // Check if cache is still valid
        if (timestamp != null) {
          final now = DateTime.now().millisecondsSinceEpoch;
          final age = now - timestamp;
          
          if (age < _cacheDurationMs) {
            return cachedLogo;
          }
        } else {
          // If no timestamp, return cached logo anyway (legacy cache)
          return cachedLogo;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Gets the logo, first from cache, then from API if needed
  static Future<String?> getLogo() async {
    // Try cache first
    final cachedLogo = await getCachedLogo();
    if (cachedLogo != null) {
      return cachedLogo;
    }
    
    // If cache miss or expired, fetch from API
    return await fetchLogoFromApi();
  }

  /// Converts base64 string to Uint8List for Image.memory()
  static Uint8List? base64ToBytes(String? base64String) {
    if (base64String == null || base64String.isEmpty) {
      return null;
    }
    
    try {
      // Handle data URI format: "data:image/png;base64,..."
      String base64Data = base64String;
      if (base64String.contains(',')) {
        base64Data = base64String.split(',')[1];
      }
      
      return base64Decode(base64Data);
    } catch (e) {
      return null;
    }
  }

  /// Gets the hospital name from cache
  static Future<String?> getHospitalName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString(_hospitalNameKey);
      if (name != null && name.isNotEmpty) {
        return name;
      }
      
      // Fallback: use domain name
      final domain = await getDomainFromPrefs();
      if (domain.isNotEmpty) {
        return domain.toUpperCase();
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Clears the cached logo
  static Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_logoCacheKey);
      await prefs.remove(_logoTimestampKey);
      await prefs.remove(_hospitalNameKey);
    } catch (e) {
      // Ignore errors
    }
  }
}

