import 'dart:convert';
import 'package:http/http.dart' as http;
import 'offline_storage_service.dart';
import 'connectivity_helper.dart';
import '../config/constant.dart';

/// Sync service matching Cordova behavior exactly
class SyncService {
  /// Sync all OP offline feedbacks to server using sinkdata.php
  /// Matches Cordova: $http.post($rootScope.baseurl_main + '/sinkdata.php', dataset, {timeout:20000})
  static Future<Map<String, int>> syncOPFeedbacks() async {
    int successCount = 0;
    int failCount = 0;

    try {
      // Check internet
      final online = await isOnline();
      if (!online) {
        throw Exception('No internet connection');
      }

      // Get domain
      final domain = await getDomainFromPrefs();
      if (domain.isEmpty) {
        throw Exception('Domain not found');
      }

      // Get all OP feedback payloads as array (matching Cordova dataset)
      final dataset = await OfflineStorageService.getAllOPFeedbackPayloads();
      
      if (dataset.isEmpty) {
        return {'success': 0, 'failed': 0};
      }

      // POST to OP API (matching Cordova exactly)
      final uri = Uri.parse('https://$domain.efeedor.com/api/sinkdata.php');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(dataset), // Send array directly (matching Cordova)
      ).timeout(
        const Duration(seconds: 20), // Matching Cordova timeout: 20000
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      // Check response
      if (response.statusCode == 200) {
        try {
          final responseData = jsonDecode(response.body);
          
          // Check if backend indicates success
          if (responseData['status'] == 'success' || 
              responseData['success'] == true ||
              responseData['message']?.toString().toLowerCase().contains('success') == true) {
            
            // Clear all OP offline feedbacks (matching Cordova: localStorage.setItem("feedbackstore", '[]'))
            await OfflineStorageService.clearAllOfflineOPFeedback();
            successCount = dataset.length;
          } else {
            // Backend returned error
            failCount = dataset.length;
          }
        } catch (e) {
          // If response is not JSON or parsing fails, check status code
          if (response.statusCode == 200 && response.body.trim().isEmpty) {
            // Empty 200 response might indicate success
            await OfflineStorageService.clearAllOfflineOPFeedback();
            successCount = dataset.length;
          } else {
            failCount = dataset.length;
          }
        }
      } else {
        failCount = dataset.length;
      }
    } catch (e) {
      // On error, count all as failed (matching Cordova: alert('Internet Error Try Again'))
      final dataset = await OfflineStorageService.getAllOPFeedbackPayloads();
      failCount = dataset.length;
    }

    return {'success': successCount, 'failed': failCount};
  }

  /// Sync all IP offline feedbacks to server using sinkdataip.php
  /// Matches Cordova: $http.post($rootScope.baseurl_main + '/sinkdataip.php', dataset, {timeout:20000})
  static Future<Map<String, int>> syncIPFeedbacks() async {
    int successCount = 0;
    int failCount = 0;

    try {
      // Check internet
      final online = await isOnline();
      if (!online) {
        throw Exception('No internet connection');
      }

      // Get domain
      final domain = await getDomainFromPrefs();
      if (domain.isEmpty) {
        throw Exception('Domain not found');
      }

      // Get all IP feedback payloads as array (matching Cordova dataset)
      final dataset = await OfflineStorageService.getAllIPFeedbackPayloads();
      
      if (dataset.isEmpty) {
        return {'success': 0, 'failed': 0};
      }

      // POST to IP API (matching Cordova exactly)
      final uri = Uri.parse('https://$domain.efeedor.com/api/sinkdataip.php');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(dataset), // Send array directly (matching Cordova)
      ).timeout(
        const Duration(seconds: 20), // Matching Cordova timeout: 20000
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      // Check response
      if (response.statusCode == 200) {
        try {
          final responseData = jsonDecode(response.body);
          
          // Check if backend indicates success
          if (responseData['status'] == 'success' || 
              responseData['success'] == true ||
              responseData['message']?.toString().toLowerCase().contains('success') == true) {
            
            // Clear all IP offline feedbacks
            await OfflineStorageService.clearAllOfflineIPFeedback();
            successCount = dataset.length;
          } else {
            // Backend returned error
            failCount = dataset.length;
          }
        } catch (e) {
          // If response is not JSON or parsing fails, check status code
          if (response.statusCode == 200 && response.body.trim().isEmpty) {
            // Empty 200 response might indicate success
            await OfflineStorageService.clearAllOfflineIPFeedback();
            successCount = dataset.length;
          } else {
            failCount = dataset.length;
          }
        }
      } else {
        failCount = dataset.length;
      }
    } catch (e) {
      // On error, count all as failed
      final dataset = await OfflineStorageService.getAllIPFeedbackPayloads();
      failCount = dataset.length;
    }

    return {'success': successCount, 'failed': failCount};
  }

  /// Sync all offline feedbacks to server (legacy - syncs OP only for backward compatibility)
  /// @deprecated Use syncOPFeedbacks or syncIPFeedbacks instead
  static Future<Map<String, int>> syncAllFeedbacks() async {
    return await syncOPFeedbacks();
  }
}

