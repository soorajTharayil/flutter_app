import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../model/ward_model.dart';
import '../model/op_question_model.dart';
import 'ip_question_service.dart';
import '../config/constant.dart' show getDomainFromPrefs;

/// Pre-loads all IP related master data for a given mobile number
/// Stores data locally for offline use
class IPDataLoader {
  // Use same cache key format as ward_service.dart for consistency
  static String _getWardCacheKey(String mobileNumber, String domain) {
    return 'ip_wards_${domain}_$mobileNumber';
  }
  
  // Use same cache key format as ip_question_service.dart for consistency
  static String _getQuestionSetCacheKey(String mobileNumber, String domain) {
    return 'ip_questionSets_${domain}_$mobileNumber';
  }

  /// Preload IP data when user taps IP Discharge Feedback on dashboard
  /// Uses a placeholder mobile number to preload general IP data
  /// This ensures data is cached before user enters their mobile number
  static Future<void> preloadIpDataOnDashboard() async {
    try {
      final domain = await getDomainFromPrefs();
      
      if (domain.isEmpty) {
        return;
      }

      // Use placeholder mobile number for preloading at dashboard level
      // This will cache general ward structure and question sets
      // When user enters their actual mobile, we'll check for cached data for that mobile
      const String placeholderMobile = '0000000000';
      
      // Load wards and question sets in parallel
      await Future.wait([
        _loadWards(placeholderMobile, domain),
        _loadQuestionSets(placeholderMobile, domain),
      ]);
    } catch (e) {
      // Silently fail - will use cached data if available
      // Don't throw - allow navigation even if preload fails
    }
  }

  /// Preload all IP data for a given mobile number
  /// This should be called when user enters mobile number and clicks Next
  /// Tries API first, falls back to cached data (even if expired) if API fails
  /// Never blocks navigation - always allows user to proceed
  static Future<void> preloadIpData(String mobileNumber) async {
    try {
      final domain = await getDomainFromPrefs();
      
      if (domain.isEmpty) {
        // If no domain, check for cached data anyway
        return;
      }

      // Load wards and question sets in parallel
      await Future.wait([
        _loadWards(mobileNumber, domain),
        _loadQuestionSets(mobileNumber, domain),
      ]);
    } catch (e) {
      // Silently fail - will use cached data if available
      // Don't throw - allow navigation even if preload fails
    }
  }

  /// Load wards from ward.php and cache them
  /// Tries API first, falls back to cached data (even expired) if API fails
  static Future<void> _loadWards(String mobileNumber, String domain) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _getWardCacheKey(mobileNumber, domain);
      
      // Try to fetch fresh data first
      try {
        // Cache the full ward data (including bedno arrays)
        // We need to store the raw API response to preserve bedno data
        final response = await _fetchWardApiResponse(mobileNumber, domain);
        if (response != null) {
          // Use same cache format as ward_service.dart
          await prefs.setString(cacheKey, jsonEncode({
            'timestamp': DateTime.now().millisecondsSinceEpoch,
            'data': response,
          }));
          return; // Successfully fetched and cached
        }
      } catch (e) {
        // API fetch failed - check if we have cached data (even expired)
        final cached = prefs.getString(cacheKey);
        if (cached != null) {
          // We have cached data, keep it (even if expired) for offline use
          // Don't throw - allow pages to use cached data
          return;
        }
        // No cache available, but don't throw - let pages handle it gracefully
      }
    } catch (e) {
      // Silently fail - allow navigation to proceed
    }
  }

  /// Load question sets from ward.php and cache them
  /// Tries API first, falls back to cached data (even expired) if API fails
  static Future<void> _loadQuestionSets(String mobileNumber, String domain) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _getQuestionSetCacheKey(mobileNumber, domain);
      
      // Try to fetch fresh data first
      try {
        final questionSets = await fetchIPQuestionSets(mobileNumber);
        
        // Cache the question sets (using same format as ip_question_service.dart)
        final questionSetsJson = questionSets.map((qs) => qs.toJson()).toList();
        await prefs.setString(cacheKey, jsonEncode({
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'data': {'question_set': questionSetsJson},
        }));
        return; // Successfully fetched and cached
      } catch (e) {
        // API fetch failed - check if we have cached data (even expired)
        final cached = prefs.getString(cacheKey);
        if (cached != null) {
          // We have cached data, keep it (even if expired) for offline use
          // Don't throw - allow pages to use cached data
          return;
        }
        // No cache available, but don't throw - let pages handle it gracefully
      }
    } catch (e) {
      // Silently fail - allow navigation to proceed
    }
  }

  /// Fetch raw ward.php API response (for caching full data including bedno)
  static Future<Map<String, dynamic>?> _fetchWardApiResponse(String mobileNumber, String domain) async {
    try {
      final response = await http.get(
        Uri.parse('https://$domain.efeedor.com/api/ward.php?mobile=$mobileNumber'),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      // Return null on error
    }
    return null;
  }

  /// Get cached wards for a mobile number
  /// Returns cached data even if expired (for offline support)
  /// Falls back to placeholder mobile cache if specific mobile cache not found
  static Future<List<Ward>> getCachedWards(String mobileNumber) async {
    try {
      final domain = await getDomainFromPrefs();
      if (domain.isEmpty) {
        return [];
      }
      
      final prefs = await SharedPreferences.getInstance();
      
      // First try to get cached data for the specific mobile number
      String cacheKey = _getWardCacheKey(mobileNumber, domain);
      String? cached = prefs.getString(cacheKey);
      
      // If no cache for specific mobile, try placeholder mobile cache (from dashboard preload)
      if (cached == null) {
        const String placeholderMobile = '0000000000';
        cacheKey = _getWardCacheKey(placeholderMobile, domain);
        cached = prefs.getString(cacheKey);
      }
      
      if (cached != null) {
        try {
          final cachedData = jsonDecode(cached);
          final data = cachedData['data'] as Map<String, dynamic>?;
          
          if (data != null) {
            final List<dynamic> wards = data['ward'] ?? [];
            return wards
                .where((item) => item['title'] != 'ALL' && item['title'] != null)
                .map((json) => Ward.fromJson(json))
                .toList();
          }
        } catch (e) {
          // If parsing fails, return empty list
        }
      }
    } catch (e) {
      // Silently fail
    }
    return [];
  }

  /// Get cached question sets for a mobile number
  /// Returns cached data even if expired (for offline support)
  /// Falls back to placeholder mobile cache if specific mobile cache not found
  static Future<List<QuestionSet>> getCachedQuestionSets(String mobileNumber) async {
    try {
      final domain = await getDomainFromPrefs();
      if (domain.isEmpty) {
        return [];
      }
      
      final prefs = await SharedPreferences.getInstance();
      
      // First try to get cached data for the specific mobile number
      String cacheKey = _getQuestionSetCacheKey(mobileNumber, domain);
      String? cached = prefs.getString(cacheKey);
      
      // If no cache for specific mobile, try placeholder mobile cache (from dashboard preload)
      if (cached == null) {
        const String placeholderMobile = '0000000000';
        cacheKey = _getQuestionSetCacheKey(placeholderMobile, domain);
        cached = prefs.getString(cacheKey);
      }
      
      if (cached != null) {
        try {
          final cachedData = jsonDecode(cached);
          final data = cachedData['data'] as Map<String, dynamic>?;
          
          if (data != null) {
            final questionSetsData = data['question_set'] as List<dynamic>?;
            if (questionSetsData != null) {
              return questionSetsData.map((json) => QuestionSet.fromJson(json)).toList();
            }
          }
        } catch (e) {
          // If parsing fails, return empty list
        }
      }
    } catch (e) {
      // Silently fail
    }
    return [];
  }
  
  /// Check if cached IP data exists (for any mobile number or placeholder)
  static Future<bool> hasCachedIpData() async {
    try {
      final domain = await getDomainFromPrefs();
      if (domain.isEmpty) {
        return false;
      }
      
      final prefs = await SharedPreferences.getInstance();
      const String placeholderMobile = '0000000000';
      
      // Check if we have cached ward data
      final wardCacheKey = _getWardCacheKey(placeholderMobile, domain);
      final wardCached = prefs.getString(wardCacheKey);
      
      // Check if we have cached question set data
      final questionCacheKey = _getQuestionSetCacheKey(placeholderMobile, domain);
      final questionCached = prefs.getString(questionCacheKey);
      
      // Return true if we have at least one type of cached data
      return (wardCached != null) || (questionCached != null);
    } catch (e) {
      return false;
    }
  }
}

