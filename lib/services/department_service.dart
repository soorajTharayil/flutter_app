import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/department_model.dart'; // adjust the path based on your folder structure
import 'package:shared_preferences/shared_preferences.dart';

Future<String> getDomainFromPrefs() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('domain') ?? ''; // default to empty string if not set
}

Future<List<Department>> fetchDepartments(String patientId) async {
  final domain = await getDomainFromPrefs();
  final prefs = await SharedPreferences.getInstance();
  final cacheKey = 'departments_$domain';

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
            .map((json) => Department.fromJson(json))
            .toList();
      }
    } catch (e) {
      // If cache parsing fails, continue to fetch
    }
  }

  try {
    final response = await http.get(
      Uri.parse('https://$domain.efeedor.com/api/department.php?patientid=$patientId'),
    ).timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        throw Exception('Request timeout. Please check your connection.');
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> wards = data['ward'] ?? [];
      final departments = wards
          .where((item) => item['title'] != 'ALL')
          .map((json) => Department.fromJson(json))
          .toList();
      
      // Cache the result
      await prefs.setString(cacheKey, jsonEncode({
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'data': data,
      }));
      
      return departments;
    } else {
      throw Exception('Failed to load departments');
    }
  } catch (e) {
    // If fetch fails, try to return cached data even if expired
    if (cached != null) {
      try {
        final cachedData = jsonDecode(cached);
        final List<dynamic> wards = cachedData['data']['ward'] ?? [];
        return wards
            .where((item) => item['title'] != 'ALL')
            .map((json) => Department.fromJson(json))
            .toList();
      } catch (e) {
        // If cache also fails, throw original error
      }
    }
    rethrow;
  }
}

