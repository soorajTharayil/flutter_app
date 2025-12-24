import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/offline_feedback_entry.dart';

class OfflineStorageService {
  static const String _opStorageKey = 'offline_op_feedback_list';
  static const String _ipStorageKey = 'offline_ip_feedback_list';

  // Notifier to signal when offline feedback is saved (for immediate UI updates)
  static final ValueNotifier<void> feedbackSavedNotifier = ValueNotifier<void>(null);

  // ==================== OP FEEDBACK METHODS ====================
  
  /// Save OP feedback payload to local storage
  static Future<void> saveOfflineOPFeedback(Map<String, dynamic> feedbackJson) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Generate UUID using timestamp
      final String id = DateTime.now().millisecondsSinceEpoch.toString();
      
      // Create entry
      final entry = OfflineFeedbackEntry(
        id: id,
        payload: feedbackJson,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );
      
      // Load existing entries
      final existingEntries = await loadOfflineOPFeedback();
      
      // Add new entry
      existingEntries.add(entry);
      
      // Convert to JSON list
      final jsonList = existingEntries.map((e) => e.toJson()).toList();
      
      // Store as JSON string
      await prefs.setString(_opStorageKey, jsonEncode(jsonList));
      
      // Notify listeners that feedback was saved (for immediate UI updates)
      feedbackSavedNotifier.value = null;
    } catch (e) {
      throw Exception('Failed to save offline OP feedback: $e');
    }
  }

  /// Load all OP offline feedback entries
  static Future<List<OfflineFeedbackEntry>> loadOfflineOPFeedback() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_opStorageKey);
      
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }
      
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => OfflineFeedbackEntry.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Delete a specific OP offline feedback by ID
  static Future<void> deleteOfflineOPFeedback(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final entries = await loadOfflineOPFeedback();
      
      // Remove entry with matching ID
      entries.removeWhere((entry) => entry.id == id);
      
      // Save updated list
      final jsonList = entries.map((e) => e.toJson()).toList();
      await prefs.setString(_opStorageKey, jsonEncode(jsonList));
    } catch (e) {
      throw Exception('Failed to delete offline OP feedback: $e');
    }
  }

  /// Get all OP feedback payloads as array (for sync)
  static Future<List<Map<String, dynamic>>> getAllOPFeedbackPayloads() async {
    try {
      final entries = await loadOfflineOPFeedback();
      return entries.map((e) => e.payload).toList();
    } catch (e) {
      return [];
    }
  }

  /// Clear all OP offline feedback entries
  static Future<void> clearAllOfflineOPFeedback() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_opStorageKey);
    } catch (e) {
      throw Exception('Failed to clear offline OP feedback: $e');
    }
  }

  // ==================== IP FEEDBACK METHODS ====================
  
  /// Save IP feedback payload to local storage
  static Future<void> saveOfflineIPFeedback(Map<String, dynamic> feedbackJson) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Generate UUID using timestamp
      final String id = DateTime.now().millisecondsSinceEpoch.toString();
      
      // Ensure feedbackType is set
      final payloadWithType = Map<String, dynamic>.from(feedbackJson);
      payloadWithType['feedbackType'] = 'IP';
      
      // Create entry
      final entry = OfflineFeedbackEntry(
        id: id,
        payload: payloadWithType,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );
      
      // Load existing entries
      final existingEntries = await loadOfflineIPFeedback();
      
      // Add new entry
      existingEntries.add(entry);
      
      // Convert to JSON list
      final jsonList = existingEntries.map((e) => e.toJson()).toList();
      
      // Store as JSON string
      await prefs.setString(_ipStorageKey, jsonEncode(jsonList));
      
      // Notify listeners that feedback was saved (for immediate UI updates)
      feedbackSavedNotifier.value = null;
    } catch (e) {
      throw Exception('Failed to save offline IP feedback: $e');
    }
  }

  /// Load all IP offline feedback entries
  static Future<List<OfflineFeedbackEntry>> loadOfflineIPFeedback() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_ipStorageKey);
      
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }
      
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => OfflineFeedbackEntry.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Delete a specific IP offline feedback by ID
  static Future<void> deleteOfflineIPFeedback(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final entries = await loadOfflineIPFeedback();
      
      // Remove entry with matching ID
      entries.removeWhere((entry) => entry.id == id);
      
      // Save updated list
      final jsonList = entries.map((e) => e.toJson()).toList();
      await prefs.setString(_ipStorageKey, jsonEncode(jsonList));
    } catch (e) {
      throw Exception('Failed to delete offline IP feedback: $e');
    }
  }

  /// Get all IP feedback payloads as array (for sync)
  static Future<List<Map<String, dynamic>>> getAllIPFeedbackPayloads() async {
    try {
      final entries = await loadOfflineIPFeedback();
      return entries.map((e) => e.payload).toList();
    } catch (e) {
      return [];
    }
  }

  /// Clear all IP offline feedback entries
  static Future<void> clearAllOfflineIPFeedback() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_ipStorageKey);
    } catch (e) {
      throw Exception('Failed to clear offline IP feedback: $e');
    }
  }

  // ==================== LEGACY METHODS (for backward compatibility with OP) ====================
  
  /// Save feedback payload to local storage (legacy - saves as OP)
  /// @deprecated Use saveOfflineOPFeedback or saveOfflineIPFeedback instead
  static Future<void> saveOfflineFeedback(Map<String, dynamic> feedbackJson) async {
    await saveOfflineOPFeedback(feedbackJson);
  }

  /// Load all offline feedback entries (legacy - loads OP only)
  /// @deprecated Use loadOfflineOPFeedback or loadOfflineIPFeedback instead
  static Future<List<OfflineFeedbackEntry>> loadOfflineFeedback() async {
    return await loadOfflineOPFeedback();
  }

  /// Delete a specific offline feedback by ID (legacy - deletes OP only)
  /// @deprecated Use deleteOfflineOPFeedback or deleteOfflineIPFeedback instead
  static Future<void> deleteOfflineFeedback(String id) async {
    await deleteOfflineOPFeedback(id);
  }

  /// Get all feedback payloads as array (legacy - gets OP only)
  /// @deprecated Use getAllOPFeedbackPayloads or getAllIPFeedbackPayloads instead
  static Future<List<Map<String, dynamic>>> getAllFeedbackPayloads() async {
    return await getAllOPFeedbackPayloads();
  }

  /// Clear all offline feedback entries (legacy - clears OP only)
  /// @deprecated Use clearAllOfflineOPFeedback or clearAllOfflineIPFeedback instead
  static Future<void> clearAllOfflineFeedback() async {
    await clearAllOfflineOPFeedback();
  }
}

