import 'package:shared_preferences/shared_preferences.dart';
import 'op_data_loader.dart';
import 'ip_data_loader.dart';
import '../config/constant.dart' show getDomainFromPrefs;

/// Preloads all feedback data (IP + OP) after successful login
/// This ensures both modules work fully offline
class FeedbackPreloader {
  static const String _preloadCompletedKey = 'feedback_preload_completed';

  /// Preload all IP and OP feedback data
  /// This should be called once after admin approval when navigating to dashboard
  /// Runs silently in background - does not block navigation
  static Future<void> preloadAllFeedbackData() async {
    try {
      final domain = await getDomainFromPrefs();
      
      if (domain.isEmpty) {
        return;
      }

      // Preload OP and IP data in parallel for faster loading
      await Future.wait([
        _preloadOPData(),
        _preloadIPData(),
      ]);

      // Mark preload as completed
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_preloadCompletedKey, true);
    } catch (e) {
      // Silently fail - will use cached data if available
      // Don't throw - allow app to continue
    }
  }

  /// Preload OP feedback data
  static Future<void> _preloadOPData() async {
    try {
      await OPDataLoader.loadOutpatientData();
    } catch (e) {
      // Silently fail - will use cached data if available
    }
  }

  /// Preload IP feedback data
  static Future<void> _preloadIPData() async {
    try {
      await IPDataLoader.preloadIpDataOnDashboard();
    } catch (e) {
      // Silently fail - will use cached data if available
    }
  }

  /// Check if preload has been completed
  static Future<bool> isPreloadCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_preloadCompletedKey) ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Reset preload flag (useful for testing or forced refresh)
  static Future<void> resetPreloadFlag() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_preloadCompletedKey);
    } catch (e) {
      // Silently fail
    }
  }
}

