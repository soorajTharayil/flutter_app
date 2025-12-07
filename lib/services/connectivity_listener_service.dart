import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'offline_feedback_service.dart';
import '../pages/offline_sync_page.dart';

/// Service to listen for network connectivity changes
/// Shows snackbar when network becomes online and there are pending offline feedbacks
class ConnectivityListenerService {
  static Connectivity? _connectivity;
  static StreamSubscription<ConnectivityResult>? _subscription;
  static BuildContext? _context;
  static bool _hasShownSnackbar = false;

  /// Initialize connectivity listener
  /// Should be called once when app starts
  static void init(BuildContext context) {
    _context = context;
    _connectivity = Connectivity();
    
    // Listen for connectivity changes
    // For connectivity_plus 5.0.2, onConnectivityChanged returns Stream<ConnectivityResult>
    _subscription = _connectivity!.onConnectivityChanged.listen(
      (ConnectivityResult result) {
        _handleConnectivityChange(result);
      },
    );
  }

  /// Handle connectivity changes
  static Future<void> _handleConnectivityChange(
      ConnectivityResult result) async {
    // Check if online (not none)
    final isOnline = result != ConnectivityResult.none;

    if (isOnline && _context != null && _context!.mounted) {
      // Check if there are pending offline feedbacks
      try {
        final count = await OfflineFeedbackService.getOfflineFeedbackCount();
        
        if (count > 0 && !_hasShownSnackbar) {
          // Show snackbar with sync prompt
          ScaffoldMessenger.of(_context!).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.cloud_off, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'You have $count offline feedback${count != 1 ? 's' : ''} pending. Tap Sync.',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.orange.shade700,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Sync',
                textColor: Colors.white,
                onPressed: () {
                  // Navigate to sync page
                  Navigator.push(
                    _context!,
                    MaterialPageRoute(
                      builder: (context) => const OfflineFeedbackSyncPage(),
                    ),
                  );
                },
              ),
            ),
          );
          
          // Prevent showing multiple snackbars
          _hasShownSnackbar = true;
          
          // Reset flag after 10 seconds
          Future.delayed(const Duration(seconds: 10), () {
            _hasShownSnackbar = false;
          });
        }
      } catch (e) {
        // Ignore errors
      }
    }
  }

  /// Dispose the listener
  static void dispose() {
    _subscription?.cancel();
    _subscription = null;
    _context = null;
  }
}

