import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/op_question_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'department_service.dart'; // For getDomainFromPrefs

/// Fetch question sets from ward.php API for IP Discharge Feedback
/// Uses ward.php instead of department.php
Future<List<QuestionSet>> fetchIPQuestionSets(String mobileNumber) async {
  final domain = await getDomainFromPrefs();
  final prefs = await SharedPreferences.getInstance();
  final cacheKey = 'ip_questionSets_${domain}_$mobileNumber';

  // Check cache first (cache for 10 minutes)
  final cached = prefs.getString(cacheKey);
  if (cached != null) {
    try {
      final cachedData = jsonDecode(cached);
      final timestamp = cachedData['timestamp'] as int?;
      if (timestamp != null && 
          DateTime.now().millisecondsSinceEpoch - timestamp < 600000) { // 10 minutes
        final questionSets = cachedData['data']['question_set'] as List<dynamic>;
        
        // Check if cached data has translations
        bool hasTranslations = false;
        for (int i = 0; i < questionSets.length; i++) {
          final questionSet = questionSets[i] as Map<String, dynamic>;
          final categoryk = questionSet['categoryk'];
          if (categoryk != null && categoryk.toString().trim().isNotEmpty) {
            hasTranslations = true;
            break;
          }
        }
        
        if (!hasTranslations) {
          await prefs.remove(cacheKey);
        } else {
          return questionSets.map((json) => QuestionSet.fromJson(json)).toList();
        }
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
      final questionSets = data['question_set'] as List<dynamic>;
      
      final result = questionSets.map((json) => QuestionSet.fromJson(json)).toList();
      
      // Cache the result
      await prefs.setString(cacheKey, jsonEncode({
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'data': data,
      }));
      
      return result;
    } else {
      throw Exception('Failed to load questions from ward.php');
    }
  } catch (e) {
    // If fetch fails, try to return cached data even if expired (for offline support)
    if (cached != null) {
      try {
        final cachedData = jsonDecode(cached);
        final questionSets = cachedData['data']['question_set'] as List<dynamic>?;
        if (questionSets != null && questionSets.isNotEmpty) {
          // Return cached data even if expired - better than nothing when offline
          return questionSets.map((json) => QuestionSet.fromJson(json)).toList();
        }
      } catch (e) {
        // If cache parsing fails, continue to throw original error
      }
    }
    rethrow;
  }
}

/// Fetch question sets from ward2.php API for IP Complaints/Requests (PCF module)
/// Extracts question_set array (not ward array) for department dropdown
Future<List<QuestionSet>> fetchWard2QuestionSets(String uid) async {
  final domain = await getDomainFromPrefs();
  final prefs = await SharedPreferences.getInstance();
  final cacheKey = 'ward2_questionSets_$domain';

  // Check cache first (cache for 5 minutes)
  final cached = prefs.getString(cacheKey);
  if (cached != null) {
    try {
      final cachedData = jsonDecode(cached);
      final timestamp = cachedData['timestamp'] as int?;
      if (timestamp != null && 
          DateTime.now().millisecondsSinceEpoch - timestamp < 300000) { // 5 minutes
        final questionSets = cachedData['data']['question_set'] as List<dynamic>?;
        if (questionSets != null) {
          return questionSets.map((json) => QuestionSet.fromJson(json)).toList();
        }
      }
    } catch (e) {
      // If cache parsing fails, continue to fetch
    }
  }

  try {
    final response = await http.post(
      Uri.parse('https://$domain.efeedor.com/api/ward2.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'uid': uid}),
    ).timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        throw Exception('Request timeout. Please check your connection.');
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final questionSets = data['question_set'] as List<dynamic>? ?? [];
      
      final result = questionSets.map((json) => QuestionSet.fromJson(json)).toList();
      
      // Cache the result
      await prefs.setString(cacheKey, jsonEncode({
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'data': data,
      }));
      
      return result;
    } else {
      throw Exception('Failed to load question sets from ward2.php');
    }
  } catch (e) {
    // If fetch fails, try to return cached data even if expired
    if (cached != null) {
      try {
        final cachedData = jsonDecode(cached);
        final questionSets = cachedData['data']['question_set'] as List<dynamic>?;
        if (questionSets != null && questionSets.isNotEmpty) {
          return questionSets.map((json) => QuestionSet.fromJson(json)).toList();
        }
      } catch (e) {
        // If cache also fails, throw original error
      }
    }
    rethrow;
  }
}

/// Fetch question sets from esr_wards.php API for Internal Service Requests (ISR module)
/// Extracts question_set array (not ward array) for department dropdown
Future<List<QuestionSet>> fetchEsrWardsQuestionSets(String uid) async {
  final domain = await getDomainFromPrefs();
  final prefs = await SharedPreferences.getInstance();
  final cacheKey = 'esr_wards_questionSets_$domain';

  // Check cache first (cache for 5 minutes)
  final cached = prefs.getString(cacheKey);
  if (cached != null) {
    try {
      final cachedData = jsonDecode(cached);
      final timestamp = cachedData['timestamp'] as int?;
      if (timestamp != null && 
          DateTime.now().millisecondsSinceEpoch - timestamp < 300000) { // 5 minutes
        final questionSets = cachedData['data']['question_set'] as List<dynamic>?;
        if (questionSets != null) {
          return questionSets.map((json) => QuestionSet.fromJson(json)).toList();
        }
      }
    } catch (e) {
      // If cache parsing fails, continue to fetch
    }
  }

  try {
    final response = await http.post(
      Uri.parse('https://$domain.efeedor.com/api/esr_wards.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'uid': uid}),
    ).timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        throw Exception('Request timeout. Please check your connection.');
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final questionSets = data['question_set'] as List<dynamic>? ?? [];
      
      final result = questionSets.map((json) => QuestionSet.fromJson(json)).toList();
      
      // Cache the result
      await prefs.setString(cacheKey, jsonEncode({
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'data': data,
      }));
      
      return result;
    } else {
      throw Exception('Failed to load question sets from esr_wards.php');
    }
  } catch (e) {
    // If fetch fails, try to return cached data even if expired
    if (cached != null) {
      try {
        final cachedData = jsonDecode(cached);
        final questionSets = cachedData['data']['question_set'] as List<dynamic>?;
        if (questionSets != null && questionSets.isNotEmpty) {
          return questionSets.map((json) => QuestionSet.fromJson(json)).toList();
        }
      } catch (e) {
        // If cache also fails, throw original error
      }
    }
    rethrow;
  }
}

/// Fetch question sets from incident_wards.php API for Incidents module
/// Extracts question_set array (not ward array) for department dropdown
Future<List<QuestionSet>> fetchIncidentWardsQuestionSets(String uid) async {
  final domain = await getDomainFromPrefs();
  final prefs = await SharedPreferences.getInstance();
  final cacheKey = 'incident_wards_questionSets_$domain';

  // Check cache first (cache for 5 minutes)
  final cached = prefs.getString(cacheKey);
  if (cached != null) {
    try {
      final cachedData = jsonDecode(cached);
      final timestamp = cachedData['timestamp'] as int?;
      if (timestamp != null && 
          DateTime.now().millisecondsSinceEpoch - timestamp < 300000) { // 5 minutes
        final questionSets = cachedData['data']['question_set'] as List<dynamic>?;
        if (questionSets != null) {
          return questionSets.map((json) => QuestionSet.fromJson(json)).toList();
        }
      }
    } catch (e) {
      // If cache parsing fails, continue to fetch
    }
  }

  try {
    final response = await http.post(
      Uri.parse('https://$domain.efeedor.com/api/incident_wards.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'uid': uid}),
    ).timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        throw Exception('Request timeout. Please check your connection.');
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final questionSets = data['question_set'] as List<dynamic>? ?? [];
      
      final result = questionSets.map((json) => QuestionSet.fromJson(json)).toList();
      
      // Cache the result
      await prefs.setString(cacheKey, jsonEncode({
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'data': data,
      }));
      
      return result;
    } else {
      throw Exception('Failed to load question sets from incident_wards.php');
    }
  } catch (e) {
    // If fetch fails, try to return cached data even if expired
    if (cached != null) {
      try {
        final cachedData = jsonDecode(cached);
        final questionSets = cachedData['data']['question_set'] as List<dynamic>?;
        if (questionSets != null && questionSets.isNotEmpty) {
          return questionSets.map((json) => QuestionSet.fromJson(json)).toList();
        }
      } catch (e) {
        // If cache also fails, throw original error
      }
    }
    rethrow;
  }
}
