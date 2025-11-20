import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/op_question_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<String> getDomainFromPrefs() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('domain') ?? ''; // default to empty string if not set
}

Future<List<QuestionSet>> fetchQuestionSets(String patientId, String department) async {
  final domain = await getDomainFromPrefs();
  final prefs = await SharedPreferences.getInstance();
  final cacheKey = 'questionSets_${domain}_$department';

  // Check cache first (cache for 10 minutes since questions change less frequently)
  final cached = prefs.getString(cacheKey);
  if (cached != null) {
    try {
      final cachedData = jsonDecode(cached);
      final timestamp = cachedData['timestamp'] as int?;
      if (timestamp != null && 
          DateTime.now().millisecondsSinceEpoch - timestamp < 600000) { // 10 minutes
        final questionSets = cachedData['data']['question_set'] as List<dynamic>;
        return questionSets.map((json) => QuestionSet.fromJson(json)).toList();
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
      final questionSets = data['question_set'] as List<dynamic>;
      final result = questionSets.map((json) => QuestionSet.fromJson(json)).toList();
      
      // Cache the result
      await prefs.setString(cacheKey, jsonEncode({
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'data': data,
      }));
      
      return result;
    } else {
      throw Exception('Failed to load questions');
    }
  } catch (e) {
    // If fetch fails, try to return cached data even if expired
    if (cached != null) {
      try {
        final cachedData = jsonDecode(cached);
        final questionSets = cachedData['data']['question_set'] as List<dynamic>;
        return questionSets.map((json) => QuestionSet.fromJson(json)).toList();
      } catch (e) {
        // If cache also fails, throw original error
      }
    }
    rethrow;
  }
}
