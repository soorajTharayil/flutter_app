import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/department_model.dart';
import '../model/op_question_model.dart';
import 'department_service.dart' as dept_service;
import 'op_question_service.dart' as op_question_service;
import '../config/constant.dart' show getDomainFromPrefs;

/// Pre-loads all OP related master data when user clicks "Outpatient Feedback" on dashboard
/// Stores data locally for offline use
class OPDataLoader {
  static const String _departmentsKey = 'op_departments_cache';
  static const String _questionSetsKeyPrefix = 'op_question_sets_';

  /// Load all OP master data (departments and question sets for all departments)
  static Future<void> loadOutpatientData() async {
    try {
      final domain = await getDomainFromPrefs();
      
      if (domain.isEmpty) {
        throw Exception('Domain not found');
      }

      // Load departments
      await _loadDepartments(domain);
      
      // Load question sets for all departments
      await _loadQuestionSetsForAllDepartments(domain);
    } catch (e) {
      // Silently fail - will use cached data if available
    }
  }

  /// Load departments and cache them
  static Future<void> _loadDepartments(String domain) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final departments = await dept_service.fetchDepartments('123');
      
      // Cache departments
      final departmentsJson = departments.map((d) => d.toJson()).toList();
      await prefs.setString(_departmentsKey, jsonEncode({
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'data': departmentsJson,
      }));
    } catch (e) {
      // Use cached data if fetch fails
    }
  }

  /// Load question sets for all departments and cache them
  static Future<void> _loadQuestionSetsForAllDepartments(String domain) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get cached departments
      final departmentsJson = prefs.getString(_departmentsKey);
      if (departmentsJson == null) {
        return;
      }
      
      final cachedData = jsonDecode(departmentsJson);
      final List<dynamic> departmentsData = cachedData['data'] ?? [];
      
      // Load question sets for each department
      for (final deptData in departmentsData) {
        try {
          final departmentTitle = deptData['title'] as String?;
          if (departmentTitle == null || departmentTitle == 'ALL') {
            continue;
          }
          
          final questionSets = await op_question_service.fetchQuestionSets('123', departmentTitle);
          
          // Cache question sets for this department
          final cacheKey = '$_questionSetsKeyPrefix$departmentTitle';
          final questionSetsJson = questionSets.map((qs) => qs.toJson()).toList();
          await prefs.setString(cacheKey, jsonEncode({
            'timestamp': DateTime.now().millisecondsSinceEpoch,
            'data': {'question_set': questionSetsJson},
          }));
        } catch (e) {
          // Continue with next department if one fails
        }
      }
    } catch (e) {
      // Silently fail
    }
  }

  /// Get cached departments
  static Future<List<Department>> getCachedDepartments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_departmentsKey);
      
      if (cached != null) {
        final cachedData = jsonDecode(cached);
        final List<dynamic> departmentsData = cachedData['data'] ?? [];
        return departmentsData.map((json) => Department.fromJson(json)).toList();
      }
    } catch (e) {
      // Silently fail
    }
    return [];
  }

  /// Get cached question sets for a department
  static Future<List<QuestionSet>> getCachedQuestionSets(String department) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_questionSetsKeyPrefix$department';
      final cached = prefs.getString(cacheKey);
      
      if (cached != null) {
        final cachedData = jsonDecode(cached);
        final timestamp = cachedData['timestamp'] as int?;
        
        // Use cached data even if expired (for offline mode)
        if (timestamp != null) {
          final questionSetsData = cachedData['data']['question_set'] as List<dynamic>?;
          if (questionSetsData != null) {
            return questionSetsData.map((json) => QuestionSet.fromJson(json)).toList();
          }
        }
      }
    } catch (e) {
      // Silently fail
    }
    return [];
  }
}

