import 'dart:async';

import 'package:devkitflutter/config/constant.dart';
import 'package:devkitflutter/ui/onboarding.dart';
import 'package:devkitflutter/ui/domain_login_page.dart';
import 'package:devkitflutter/ui/waiting_approval_page.dart';
import 'package:devkitflutter/ui/home_module_button.dart';
import 'package:devkitflutter/ui/signin.dart';
import 'package:devkitflutter/services/device_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SplashScreenPage extends StatefulWidget {
  const SplashScreenPage({Key? key}) : super(key: key);

  @override
  State<SplashScreenPage> createState() => _SplashScreenPageState();
}

class _SplashScreenPageState extends State<SplashScreenPage>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  int _second = 3;
  late final AnimationController _controller;
  late final Animation<double> _rotation;
  late final Animation<double> _scale;
  late final Animation<double> _lift;

  void _startTimer() {
    const period = Duration(seconds: 1);
    _timer = Timer.periodic(period, (timer) {
      setState(() {
        _second--;
      });
      if (_second == 0) {
        _cancelFlashsaleTimer();
        _navigateNext();
      }
    });
  }

  /// Check if user is fully onboarded locally (without API calls)
  /// Returns true if all required local session values exist
  Future<bool> _isUserFullyOnboardedLocally(SharedPreferences prefs) async {
    // Check all required flags
    final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
    final deviceId = prefs.getString('device_id') ?? '';
    final domain = prefs.getString('domain') ?? '';
    final domainCompleted = prefs.getBool('domain_completed') ?? false;
    
    // User is fully onboarded if:
    // 1. User is logged in
    // 2. Device ID exists
    // 3. Domain exists and is completed
    // 4. Not waiting for approval (already approved)
    final waitingForApproval = prefs.getBool('waiting_for_approval') ?? false;
    
    return isLoggedIn && 
           deviceId.isNotEmpty && 
           domain.isNotEmpty && 
           domainCompleted &&
           !waitingForApproval;
  }

  Future<void> _navigateNext() async {
    final prefs = await SharedPreferences.getInstance();

    // Check 15-day inactivity BEFORE updating timestamp (Scenario B)
    final lastActiveTimestamp = prefs.getInt('last_active_timestamp');
    if (lastActiveTimestamp != null) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final daysInactive = (now - lastActiveTimestamp) / (1000 * 60 * 60 * 24);

      if (daysInactive > 15) {
        // Auto-logout after 15 days of inactivity
        await _clearLoginState(prefs);
        if (mounted) {
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (context) => const DomainLoginPage()));
        }
        return;
      }
    }

    // Update last_active_timestamp on every app open (Scenario B)
    await prefs.setInt(
        'last_active_timestamp', DateTime.now().millisecondsSinceEpoch);

    // CRITICAL: Check local onboarding state FIRST (before any API calls)
    // This ensures offline navigation works correctly
    final isFullyOnboarded = await _isUserFullyOnboardedLocally(prefs);
    if (isFullyOnboarded) {
      // User is fully onboarded locally - navigate directly to dashboard
      // No API calls needed - works completely offline
      if (mounted) {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => HomePage()));
      }
      return;
    }

    // If not fully onboarded locally, continue with existing flow
    // Check if user is logged in (but might need API verification)
    final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
    if (isLoggedIn) {
      final deviceId = prefs.getString('device_id') ?? '';
      final domain = prefs.getString('domain') ?? '';

      if (deviceId.isNotEmpty && domain.isNotEmpty) {
        // Try to check device approval (non-blocking, will fallback if offline)
        try {
          final isApproved =
              await DeviceService.isDeviceApproved(deviceId, domain)
                  .timeout(const Duration(seconds: 5));

          if (isApproved) {
            // User is logged in and device is approved - go directly to dashboard
            if (mounted) {
              Navigator.pushReplacement(
                  context, MaterialPageRoute(builder: (context) => HomePage()));
            }
            return;
          }
        } catch (e) {
          // API call failed (offline) - but user might still be onboarded
          // Check local flags again as fallback
          if (await _isUserFullyOnboardedLocally(prefs)) {
            if (mounted) {
              Navigator.pushReplacement(
                  context, MaterialPageRoute(builder: (context) => HomePage()));
            }
            return;
          }
          // If not fully onboarded, continue to waiting approval check
        }
      }
    }

    // Check if user is waiting for approval (Scenario 1 & 2)
    final waitingForApproval = prefs.getBool('waiting_for_approval') ?? false;

    if (waitingForApproval) {
      // User was waiting for approval - check status
      await _handleWaitingApprovalState(prefs);
      return;
    }

    // Check if domain is completed but user not logged in (CHANGE 1)
    final domainCompleted = prefs.getBool('domain_completed') ?? false;
    final domain = prefs.getString('domain') ?? '';
    
    if (domainCompleted && !isLoggedIn && domain.isNotEmpty) {
      // Domain exists but user not logged in - go directly to login page
      if (mounted) {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) => SignIn()));
      }
      return;
    }

    // Normal flow
    final hasOnboarded = prefs.getBool('hasOnboarded') ?? false;
    if (hasOnboarded) {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (context) => const DomainLoginPage()));
    } else {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (context) => const OnBoardingPage()));
    }
  }

  Future<void> _handleWaitingApprovalState(SharedPreferences prefs) async {
    try {
      final deviceId = prefs.getString('device_id') ?? '';
      final domain = prefs.getString('domain') ?? '';
      final approvalRequestedAtStr = prefs.getString('approval_requested_at');

      if (deviceId.isEmpty || domain.isEmpty) {
        // Missing required data - clear and go to domain page
        await _clearWaitingState(prefs);
        if (mounted) {
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (context) => const DomainLoginPage()));
        }
        return;
      }

      // Check if approval request has expired locally (48 hours)
      if (approvalRequestedAtStr != null) {
        final approvalRequestedAt = DateTime.parse(approvalRequestedAtStr);
        final now = DateTime.now();
        final elapsed = now.difference(approvalRequestedAt);

        // If more than 48 hours have passed, clear state and go to domain page
        if (elapsed.inHours >= 48) {
          await _clearWaitingState(prefs);
          if (mounted) {
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => const DomainLoginPage()));
          }
          return;
        }
      }

      // Check backend status (Scenario 2: admin might have approved while app was closed)
      // Use timeout to prevent blocking when offline
      Map<String, dynamic> statusResult;
      try {
        statusResult = await DeviceService.checkDeviceStatus()
            .timeout(const Duration(seconds: 5));
      } catch (e) {
        // API call failed (offline) - show waiting page
        // User can still use the app when online again
        if (mounted) {
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => const WaitingApprovalPage()));
        }
        return;
      }

      if (!mounted) return;

      if (statusResult['success'] == true) {
        final status = statusResult['status'] as String;
        final approvalExpiresAtStr =
            statusResult['approval_expires_at'] as String?;

        // Check if expired based on backend timestamp
        if (approvalExpiresAtStr != null) {
          final approvalExpiresAt = DateTime.parse(approvalExpiresAtStr);
          final now = DateTime.now();

          if (now.isAfter(approvalExpiresAt)) {
            // Expired - clear state and go to domain page
            await _clearWaitingState(prefs);
            if (mounted) {
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const DomainLoginPage()));
            }
            return;
          }
        }

        switch (status) {
          case 'approved':
            // Admin approved while app was closed - save login state and go directly to dashboard
            await _clearWaitingState(prefs);
            await _saveLoginState(prefs, deviceId, domain);
            if (mounted) {
              Navigator.pushReplacement(
                  context, MaterialPageRoute(builder: (context) => HomePage()));
            }
            break;

          case 'pending':
            // Still pending - show waiting page
            if (mounted) {
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const WaitingApprovalPage()));
            }
            break;

          case 'blocked':
            // Device blocked - clear state and go to login
            await _clearWaitingState(prefs);
            if (mounted) {
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const DomainLoginPage()));
            }
            break;

          case 'expired':
            // Request expired - clear state and go to domain page
            await _clearWaitingState(prefs);
            if (mounted) {
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const DomainLoginPage()));
            }
            break;

          default:
            // Unknown status - show waiting page
            if (mounted) {
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const WaitingApprovalPage()));
            }
            break;
        }
      } else {
        // Error checking status - show waiting page anyway
        if (mounted) {
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => const WaitingApprovalPage()));
        }
      }
    } catch (e) {
      print('Error handling waiting approval state: $e');
      // On error, clear state and go to domain page
      await _clearWaitingState(prefs);
      if (mounted) {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) => const DomainLoginPage()));
      }
    }
  }

  Future<void> _clearWaitingState(SharedPreferences prefs) async {
    await prefs.remove('waiting_for_approval');
    await prefs.remove('approval_requested_at');
    // Keep device_id and domain as they're needed for other flows
  }

  Future<void> _saveLoginState(
      SharedPreferences prefs, String deviceId, String domain) async {
    await prefs.setBool('is_logged_in', true);
    await prefs.setInt(
        'last_active_timestamp', DateTime.now().millisecondsSinceEpoch);
    await prefs.setString('device_id', deviceId);
    await prefs.setString('domain', domain);
  }

  Future<void> _clearLoginState(SharedPreferences prefs) async {
    await prefs.remove('is_logged_in');
    await prefs.remove('last_active_timestamp');
    await prefs.remove('device_id');
    await prefs.remove('userid');
    await prefs.remove('email');
    await prefs.remove('name');
    await prefs.remove('user_permissions');
    // DO NOT clear domain-related keys: domain, stored_domain, domain_completed, domain_url
    // Do NOT clear device approval from backend
  }

  void _cancelFlashsaleTimer() {
    if (_timer != null) {
      _timer!.cancel();
      _timer = null;
    }
  }

  @override
  void initState() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
    );

    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600))
      ..repeat(reverse: true);

    _rotation = Tween<double>(begin: -0.06, end: 0.06).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _scale = Tween<double>(begin: 0.98, end: 1.02).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _lift = Tween<double>(begin: -6, end: 6).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (_second != 0) _startTimer();
    super.initState();
  }

  @override
  void dispose() {
    _cancelFlashsaleTimer();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PopScope(
        canPop: false,
        child: Container(
          color: Colors.white,
          child: Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final Matrix4 transform = Matrix4.identity()
                  ..setEntry(3, 2, 0.0012)
                  ..rotateX(_rotation.value * 0.6)
                  ..rotateY(_rotation.value)
                  ..scale(_scale.value);

                return Stack(
                  alignment: Alignment.center,
                  children: [
                    Transform.translate(
                      offset: Offset(0, _lift.value),
                      child: Transform(
                        transform: transform,
                        alignment: Alignment.center,

                        // ⭐ ADDED SHINING EFFECT HERE ⭐
                        child: ShaderMask(
                          shaderCallback: (Rect bounds) {
                            return LinearGradient(
                              begin: Alignment(-1.5, -0.5),
                              end: Alignment(1.5, 0.5),
                              colors: [
                                Colors.white.withOpacity(0.0),
                                Colors.white.withOpacity(0.6),
                                Colors.white.withOpacity(0.0),
                              ],
                              stops: const [0.0, 0.5, 1.0],
                              transform:
                                  GradientRotation(_controller.value * 6.28),
                            ).createShader(bounds);
                          },
                          blendMode: BlendMode.srcATop,
                          child: Image.asset(
                            '$localImagesUrl/efeedor_logo.png',
                            width: MediaQuery.of(context).size.width / 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
