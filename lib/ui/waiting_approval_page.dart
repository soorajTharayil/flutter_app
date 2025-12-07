import 'package:flutter/material.dart';
import 'package:devkitflutter/config/constant.dart';
import 'package:devkitflutter/services/device_service.dart';
import 'package:devkitflutter/ui/home_module_button.dart';
import 'package:devkitflutter/ui/signin.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class WaitingApprovalPage extends StatefulWidget {
  const WaitingApprovalPage({Key? key}) : super(key: key);

  @override
  State<WaitingApprovalPage> createState() => _WaitingApprovalPageState();
}

class _WaitingApprovalPageState extends State<WaitingApprovalPage> {
  Timer? _pollingTimer;
  bool _isPolling = false;
  DateTime? _startTime;
  DateTime? _approvalExpiresAt;
  static const int _timeoutHours = 48; // 48 hours instead of 10 minutes

  @override
  void initState() {
    super.initState();
    _initializeWaitingState();
    _startPolling();
  }

  Future<void> _initializeWaitingState() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Get approval requested time from SharedPreferences
    final approvalRequestedAtStr = prefs.getString('approval_requested_at');
    if (approvalRequestedAtStr != null) {
      _startTime = DateTime.parse(approvalRequestedAtStr);
    } else {
      _startTime = DateTime.now();
      // Save if not already saved
      await prefs.setString('approval_requested_at', _startTime!.toIso8601String());
    }
    
    // Ensure waiting state is saved
    await prefs.setBool('waiting_for_approval', true);
    
    // Get device_id if not already saved
    final deviceInfo = await DeviceService.getDeviceInfo();
    final deviceId = deviceInfo['device_id']!;
    
    if (deviceId.isNotEmpty) {
      await prefs.setString('device_id', deviceId);
    }
    
    // Calculate expiry time (48 hours from start)
    _approvalExpiresAt = _startTime!.add(const Duration(hours: _timeoutHours));
  }

  @override
  void dispose() {
    _stopPolling();
    super.dispose();
  }

  void _startPolling() {
    if (_isPolling) return;
    
    _isPolling = true;
    // Check immediately
    _checkStatus();
    
    // Then check every 5 seconds
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _checkStatus();
    });
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _isPolling = false;
  }

  Future<void> _checkStatus() async {
    if (!mounted) return;

    try {
      final result = await DeviceService.checkDeviceStatus();
      
      if (!mounted) return;

      if (result['success'] == true) {
        final status = result['status'] as String;
        final approvalExpiresAtStr = result['approval_expires_at'] as String?;
        
        // Update expiry time from backend if available
        if (approvalExpiresAtStr != null) {
          _approvalExpiresAt = DateTime.parse(approvalExpiresAtStr);
        }

        switch (status) {
          case 'approved':
            _stopPolling();
            // Clear waiting state
            await _clearWaitingState();
            // Save login state (Scenario A)
            await _saveLoginState();
            // Navigate to dashboard
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => HomePage()),
            );
            break;

          case 'blocked':
            _stopPolling();
            await _clearWaitingState();
            _showBlockedDialog();
            break;

          case 'expired':
            _stopPolling();
            await _clearWaitingState();
            _showExpiredDialog();
            break;

          case 'pending':
            // Continue polling - check if expired locally
            if (_approvalExpiresAt != null && DateTime.now().isAfter(_approvalExpiresAt!)) {
              _stopPolling();
              await _clearWaitingState();
              _showExpiredDialog();
            }
            break;

          default:
            // Unknown status, continue polling
            break;
        }
      } else {
        // Error checking status, but continue polling
        print('Error checking status: ${result['message']}');
      }
    } catch (e) {
      // Error occurred, but continue polling
      print('Exception checking status: $e');
    }

    // Check timeout (48 hours)
    if (_approvalExpiresAt != null) {
      if (DateTime.now().isAfter(_approvalExpiresAt!)) {
        _stopPolling();
        await _clearWaitingState();
        _showExpiredDialog();
      }
    } else if (_startTime != null) {
      // Fallback: check elapsed time
      final elapsed = DateTime.now().difference(_startTime!);
      if (elapsed.inHours >= _timeoutHours) {
        _stopPolling();
        await _clearWaitingState();
        _showExpiredDialog();
      }
    }
  }

  Future<void> _clearWaitingState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('waiting_for_approval');
    await prefs.remove('approval_requested_at');
    // Keep device_id and domain as they're needed for other flows
  }

  Future<void> _saveLoginState() async {
    final prefs = await SharedPreferences.getInstance();
    final deviceId = prefs.getString('device_id') ?? '';
    final domain = prefs.getString('domain') ?? '';
    
    if (deviceId.isNotEmpty && domain.isNotEmpty) {
      await prefs.setBool('is_logged_in', true);
      await prefs.setInt('last_active_timestamp', DateTime.now().millisecondsSinceEpoch);
      await prefs.setString('device_id', deviceId);
      await prefs.setString('domain', domain);
    }
  }

  void _showBlockedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Device Blocked',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Your device has been blocked. Please contact your administrator for assistance.',
            style: TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const SignIn()),
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: efeedorBrandGreen,
                shape: const StadiumBorder(),
              ),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showExpiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Request Expired',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Your approval request has expired. Please login again.',
            style: TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const SignIn()),
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: efeedorBrandGreen,
                shape: const StadiumBorder(),
              ),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  String _getElapsedTime() {
    if (_startTime == null) return '0:00';
    final elapsed = DateTime.now().difference(_startTime!);
    final hours = elapsed.inHours;
    final minutes = elapsed.inMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Image.asset(
                  'assets/images/efeedor_square_logo.png',
                  height: 48,
                  color: efeedorBrandGreen,
                  colorBlendMode: BlendMode.srcIn,
                ),
                const SizedBox(height: 30),

                // Loading indicator
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(efeedorBrandGreen),
                ),
                const SizedBox(height: 30),

                // Title
                Text(
                  'Waiting for Approval',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: black21,
                  ),
                ),
                const SizedBox(height: 16),

                // Message
                Text(
                  'Login successful.\nWaiting for admin approval...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: black77,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 40),

                // Timer
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: efeedorBrandGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.access_time,
                        color: efeedorBrandGreen,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Elapsed: ${_getElapsedTime()}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: efeedorBrandGreen,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Info text
                Text(
                  'This request will expire in ${_timeoutHours} hours',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: softGrey,
                  ),
                ),
                const SizedBox(height: 40),

                // Cancel button
                TextButton(
                  onPressed: () async {
                    _stopPolling();
                    await _clearWaitingState();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const SignIn()),
                    );
                  },
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: efeedorBrandGreen,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

