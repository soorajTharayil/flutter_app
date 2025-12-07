import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing offline feedback storage and syncing
/// Uses Hive for local storage
class OfflineFeedbackService {
  static const String _boxName = 'offline_feedbacks';
  static Box? _box;

  /// Initialize Hive and open the offline feedbacks box
  static Future<void> init() async {
    try {
      await Hive.initFlutter();
      _box = await Hive.openBox(_boxName);
    } catch (e) {
      // If box already open, just get reference
      _box = Hive.box(_boxName);
    }
  }

  /// Get the Hive box instance
  static Box get box {
    if (_box == null) {
      throw Exception('OfflineFeedbackService not initialized. Call init() first.');
    }
    return _box!;
  }

  /// Save feedback payload to local storage when offline
  /// 
  /// [payload] - The complete feedback JSON payload (same structure as online)
  /// Returns the ID of the saved feedback entry
  static Future<String> saveOfflineFeedback(Map<String, dynamic> payload) async {
    try {
      await init();
      
      // Generate unique ID using timestamp
      final String id = DateTime.now().millisecondsSinceEpoch.toString();
      
      // Create entry with id, payload, and synced status
      final entry = {
        'id': id,
        'payload': payload,
        'synced': false,
        'createdAt': DateTime.now().toIso8601String(),
      };
      
      // Store in Hive box
      await box.put(id, entry);
      
      return id;
    } catch (e) {
      throw Exception('Failed to save offline feedback: $e');
    }
  }

  /// Get all offline feedbacks that are not yet synced
  /// 
  /// Returns list of feedback entries with id, payload, and synced status
  static Future<List<Map<String, dynamic>>> getOfflineFeedbacks() async {
    try {
      await init();
      
      final List<Map<String, dynamic>> feedbacks = [];
      
      // Iterate through all entries in the box
      for (var key in box.keys) {
        final entry = box.get(key) as Map<dynamic, dynamic>?;
        if (entry != null) {
          // Convert to Map<String, dynamic>
          final feedback = Map<String, dynamic>.from(entry);
          
          // Only return unsynced feedbacks
          if (feedback['synced'] == false) {
            feedbacks.add(feedback);
          }
        }
      }
      
      // Sort by createdAt (oldest first)
      feedbacks.sort((a, b) {
        final aDate = DateTime.parse(a['createdAt'] as String);
        final bDate = DateTime.parse(b['createdAt'] as String);
        return aDate.compareTo(bDate);
      });
      
      return feedbacks;
    } catch (e) {
      throw Exception('Failed to get offline feedbacks: $e');
    }
  }

  /// Get count of unsynced offline feedbacks
  static Future<int> getOfflineFeedbackCount() async {
    try {
      final feedbacks = await getOfflineFeedbacks();
      return feedbacks.length;
    } catch (e) {
      return 0;
    }
  }

  /// Delete a specific offline feedback entry by ID
  /// 
  /// [id] - The ID of the feedback entry to delete
  static Future<void> deleteOfflineFeedback(String id) async {
    try {
      await init();
      await box.delete(id);
    } catch (e) {
      throw Exception('Failed to delete offline feedback: $e');
    }
  }

  /// Mark a feedback entry as synced (but keep it for reference)
  /// 
  /// [id] - The ID of the feedback entry to mark as synced
  static Future<void> markAsSynced(String id) async {
    try {
      await init();
      final entry = box.get(id) as Map<dynamic, dynamic>?;
      if (entry != null) {
        final updatedEntry = Map<String, dynamic>.from(entry);
        updatedEntry['synced'] = true;
        updatedEntry['syncedAt'] = DateTime.now().toIso8601String();
        await box.put(id, updatedEntry);
      }
    } catch (e) {
      throw Exception('Failed to mark feedback as synced: $e');
    }
  }

  /// Sync all offline feedbacks to the server
  /// 
  /// [domain] - The domain name (without .efeedor.com)
  /// Returns true if all feedbacks synced successfully, false otherwise
  /// Throws exception if sync fails
  static Future<bool> syncAll(String domain) async {
    try {
      await init();
      
      // Get all unsynced feedbacks
      final feedbacks = await getOfflineFeedbacks();
      
      if (feedbacks.isEmpty) {
        return true; // Nothing to sync
      }

      // API endpoint for syncing
      final uri = Uri.parse('https://$domain.efeedor.com/api/sinkdataip.php');
      
      // Sync each feedback one by one
      for (final feedback in feedbacks) {
        final id = feedback['id'] as String;
        final payload = feedback['payload'] as Map<String, dynamic>;
        
        try {
          // Make POST request to sync endpoint
          final response = await http.post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          );

          // Check if response indicates success
          // Adjust this based on your actual API response format
          if (response.statusCode == 200) {
            final responseData = jsonDecode(response.body);
            
            // Check if response indicates success
            // Common success indicators: status == 'success' or statusCode == 200
            if (responseData['status'] == 'success' || 
                responseData['statusCode'] == 200 ||
                response.statusCode == 200) {
              // Mark as synced and delete from local storage
              await markAsSynced(id);
              await deleteOfflineFeedback(id);
            } else {
              // If one fails, stop and throw error
              throw Exception('Sync failed for feedback $id: ${responseData['message'] ?? 'Unknown error'}');
            }
          } else {
            // HTTP error - stop syncing
            throw Exception('Sync failed for feedback $id: HTTP ${response.statusCode}');
          }
        } catch (e) {
          // If any single feedback fails, stop and throw
          throw Exception('Failed to sync feedback $id: $e');
        }
      }
      
      return true;
    } catch (e) {
      throw Exception('Sync failed: $e');
    }
  }

  /// Clear all synced feedbacks (cleanup old synced entries)
  static Future<void> clearSyncedFeedbacks() async {
    try {
      await init();
      
      final keysToDelete = <String>[];
      
      // Find all synced entries
      for (var key in box.keys) {
        final entry = box.get(key) as Map<dynamic, dynamic>?;
        if (entry != null) {
          final feedback = Map<String, dynamic>.from(entry);
          if (feedback['synced'] == true) {
            keysToDelete.add(key.toString());
          }
        }
      }
      
      // Delete all synced entries
      for (final key in keysToDelete) {
        await box.delete(key);
      }
    } catch (e) {
      // Ignore errors during cleanup
    }
  }
}

