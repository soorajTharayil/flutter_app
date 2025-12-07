import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/ward_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'department_service.dart'; // For getDomainFromPrefs

/// Fetch wards/floors from ward.php API
/// Returns wards with title/titlek/titlem and bedno array
Future<List<Ward>> fetchWards(String mobileNumber) async {
  final domain = await getDomainFromPrefs();
  final prefs = await SharedPreferences.getInstance();
  final cacheKey = 'ip_wards_${domain}_$mobileNumber';

  // Check cache first (cache for 5 minutes)
  final cached = prefs.getString(cacheKey);
  if (cached != null) {
    try {
      final cachedData = jsonDecode(cached);
      final timestamp = cachedData['timestamp'] as int?;
      if (timestamp != null && 
          DateTime.now().millisecondsSinceEpoch - timestamp < 300000) { // 5 minutes
        final List<dynamic> wards = cachedData['data']['ward'] ?? [];
        return wards
            .where((item) => item['title'] != 'ALL')
            .map((json) => Ward.fromJson(json))
            .toList();
      }
    } catch (e) {
      // If cache parsing fails, continue to fetch
    }
  }

  try {
    final response = await http.get(
      Uri.parse('https://$domain.efeedor.com/api/ward.php?mobile=$mobileNumber'),
    ).timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        throw Exception('Request timeout. Please check your connection.');
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> wards = data['ward'] ?? [];
      final wardList = wards
          .where((item) => item['title'] != 'ALL' && item['title'] != null)
          .map((json) => Ward.fromJson(json))
          .toList();
      
      // Cache the result
      await prefs.setString(cacheKey, jsonEncode({
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'data': data,
      }));
      
      return wardList;
    } else {
      throw Exception('Failed to load wards');
    }
  } catch (e) {
    // If fetch fails, try to return cached data even if expired (for offline support)
    if (cached != null) {
      try {
        final cachedData = jsonDecode(cached);
        final List<dynamic> wards = cachedData['data']['ward'] ?? [];
        final wardList = wards
            .where((item) => item['title'] != 'ALL' && item['title'] != null)
            .map((json) => Ward.fromJson(json))
            .toList();
        // Return cached data even if expired - better than nothing when offline
        if (wardList.isNotEmpty) {
          return wardList;
        }
      } catch (e) {
        // If cache parsing fails, continue to throw original error
      }
    }
    rethrow;
  }
}

/// Get bed numbers for a specific ward
/// This extracts bedno array from the already-fetched ward data
List<String> getBedNumbersForWard(List<Ward> wards, String selectedWardTitle) {
  try {
    final ward = wards.firstWhere(
      (w) => w.title == selectedWardTitle,
      orElse: () => Ward(title: '', id: ''),
    );
    return ward.bedno;
  } catch (e) {
    return [];
  }
}


