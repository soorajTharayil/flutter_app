import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:universal_io/io.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:devkitflutter/config/constant.dart'; // adjust this import path
import 'package:devkitflutter/ui/home_module_button.dart';
import 'package:devkitflutter/services/device_service.dart';
import 'package:devkitflutter/services/ip_service.dart';
import 'package:devkitflutter/ui/waiting_approval_page.dart';

class SignIn extends StatefulWidget {
  const SignIn({Key? key}) : super(key: key);

  @override
  State<SignIn> createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscureText = true;
  IconData _iconVisible = Icons.visibility_off;
  bool _isSigningIn = false; // Loading state for Sign-In button

  // Efeedor themed colors (UI only)
  final Color _mainColor = efeedorBrandGreen; // primary action color
  final Color _underlineColor = const Color(0xFFDDDDDD);

  void _toggleObscureText() {
    setState(() {
      _obscureText = !_obscureText;
      _iconVisible = _obscureText ? Icons.visibility_off : Icons.visibility;
    });
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: _mainColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.error_outline,
                      color: Colors.redAccent, size: 34),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Sign in failed',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 14, color: Colors.black87, height: 1.3),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 10),
                        foregroundColor: Colors.white,
                        backgroundColor: _mainColor,
                        shape: const StadiumBorder(),
                      ),
                      child: const Text('OK'),
                    )
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _loginUser() async {
    // Set loading state
    if (mounted) {
      setState(() {
        _isSigningIn = true;
      });
    }

    try {
      // Get domain
      final prefs = await SharedPreferences.getInstance();
      final domain = prefs.getString('domain') ?? '';

      if (domain.isEmpty) {
        _showErrorDialog('Domain not found. Please enter domain first.');
        return;
      }

      // Step 1: Login using existing login.php endpoint
      final loginUrl = await getLoginEndpoint();

      // Prepare login request (email and password only for login.php)
      final loginBody = {
        "userid": _emailController.text, // login.php expects "userid"
        "password": _passwordController.text,
      };

      print('Login URL: $loginUrl');
      print('Login Body: $loginBody');

      final response = await http.post(
        Uri.parse(loginUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(loginBody),
      );

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      // Parse JSON with proper error handling
      Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (e) {
        // If JSON parsing fails, check if it's HTML or PHP error
        final body = response.body;
        if (body.contains('<html') || body.contains('<!DOCTYPE')) {
          _showErrorDialog(
              'Server returned HTML instead of JSON. Please check server configuration.');
        } else if (body.contains('Warning:') || body.contains('Notice:')) {
          _showErrorDialog(
              'Server error detected. Please contact administrator.');
        } else if (body.trim().isEmpty) {
          _showErrorDialog('Empty response from server. Please try again.');
        } else {
          _showErrorDialog('Invalid response format. Please try again.');
        }
        print('JSON Parse Error: $e');
        print('Response body: $body');
        return;
      }

      // Check login status
      if (response.statusCode == 200 && responseData['status'] == 'success') {
        // Login successful - extract user data
        final userId = responseData['userid']?.toString() ?? '';
        final email = responseData['email']?.toString() ?? '';
        final name = responseData['name']?.toString() ?? email;
        final mobile = responseData['mobile']?.toString() ?? '';

        // Save user data
        final permissions = <String, dynamic>{};
        responseData.forEach((key, value) {
          if (key != 'status' &&
              key != 'userid' &&
              key != 'email' &&
              key != 'name' &&
              key != 'mobile') {
            permissions[key] = value;
          }
        });
        await prefs.setString('user_permissions', jsonEncode(permissions));
        await prefs.setString('userid', userId);
        await prefs.setString('email', email);
        await prefs.setString('name', name);
        await prefs.setString('mobile', mobile);

        // Step 2: Check if device is already approved (one-time approval)
        final deviceInfo = await DeviceService.getDeviceInfo();
        final deviceId = deviceInfo['device_id']!;

        final isApproved =
            await DeviceService.isDeviceApproved(deviceId, domain);

        if (isApproved) {
          // Device already approved - save login state and go directly to dashboard
          await prefs.setBool('is_logged_in', true);
          await prefs.setInt(
              'last_active_timestamp', DateTime.now().millisecondsSinceEpoch);
          await prefs.setString('device_id', deviceId);
          await prefs.setString('domain', domain);

          Fluttertoast.showToast(msg: "Login successful");
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => HomePage()),
          );
          return;
        }

        // Step 3: Send device details to requestAccess endpoint
        final deviceName = deviceInfo['device_name']!;
        final platform = deviceInfo['platform']!;
        // Get IP address (for mobile) or let backend get it (for web)
        final ipAddress = await IpService.getDeviceIp();

        final requestResult = await DeviceService.requestDeviceApproval(
          userId: userId,
          name: name,
          email: email,
          deviceId: deviceId,
          deviceName: deviceName,
          platform: platform,
          ipAddress: ipAddress,
          domain: domain,
        );

        if (requestResult['success'] == true) {
          // Save waiting state to SharedPreferences (Scenario 1)
          await prefs.setBool('waiting_for_approval', true);
          await prefs.setString('device_id', deviceId);
          await prefs.setString('domain', domain);
          await prefs.setString(
              'approval_requested_at', DateTime.now().toIso8601String());

          // Navigate to waiting approval page
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const WaitingApprovalPage()),
          );
        } else {
          _showErrorDialog(
              requestResult['message'] ?? 'Failed to request device approval');
        }
      } else {
        // Login failed
        final message =
            responseData['message'] ?? 'Incorrect username or password';
        _showErrorDialog(message);
      }
    } catch (e) {
      print('Login Error: $e');
      _showErrorDialog("Error: ${e.toString()}");
    } finally {
      // Always restore button state when login completes
      if (mounted) {
        setState(() {
          _isSigningIn = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        body: AnnotatedRegion<SystemUiOverlayStyle>(
          value: Platform.isIOS
              ? SystemUiOverlayStyle.light
              : const SystemUiOverlayStyle(
                  statusBarIconBrightness: Brightness.light),
          child: Stack(
            children: <Widget>[
              // Top header gradient with wave bottom and white branding
              ClipPath(
                clipper: _WaveClipperLogin(),
                child: Container(
                  height: MediaQuery.of(context).size.height / 3.2,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _mainColor.withOpacity(0.95),
                        _mainColor,
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height / 3.2,
                width: double.infinity,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/images/efeedor_square_logo.png',
                        height: 48,
                        color: Colors.white,
                        colorBlendMode: BlendMode.srcIn,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        '',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Login card
              ListView(
                children: <Widget>[
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 6,
                    margin: EdgeInsets.fromLTRB(24,
                        MediaQuery.of(context).size.height / 3.2 - 48, 24, 0),
                    color: Colors.white,
                    child: Container(
                        margin: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const SizedBox(height: 16),
                            Text(
                              'Sign in',
                              style: TextStyle(
                                  color: black21,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Access your Efeedor account',
                              style: TextStyle(
                                  color: Colors.grey[700], fontSize: 13),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 16,
                              ),
                              decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.grey[100],
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 14),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide:
                                        BorderSide(color: _underlineColor),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide:
                                        BorderSide(color: _underlineColor),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: _mainColor),
                                  ),
                                  hintText: 'Username or email',
                                  hintStyle: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 16,
                                  )),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _passwordController,
                              obscureText: _obscureText,
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 16,
                              ),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.grey[100],
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 14),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide:
                                      BorderSide(color: _underlineColor),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide:
                                      BorderSide(color: _underlineColor),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: _mainColor),
                                ),
                                hintText: 'Password',
                                hintStyle: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                                suffixIcon: IconButton(
                                    icon: Icon(_iconVisible,
                                        color: Colors.grey[700], size: 20),
                                    onPressed: _toggleObscureText),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const SizedBox(height: 18),
                            SizedBox(
                              width: double.maxFinite,
                              child: TextButton(
                                  style: ButtonStyle(
                                    backgroundColor: MaterialStateProperty
                                        .resolveWith<Color>((_) => _mainColor),
                                    overlayColor: MaterialStateProperty.all(
                                        Colors.transparent),
                                    shape: MaterialStateProperty.all(
                                        RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24),
                                    )),
                                  ),
                                  onPressed: _isSigningIn ? null : _loginUser,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    child: _isSigningIn
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.4,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                      Colors.white),
                                            ),
                                          )
                                        : Text(
                                            'Sign in',
                                            style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600),
                                            textAlign: TextAlign.center,
                                          ),
                                  )),
                            ),
                          ],
                        )),
                  ),
                ],
              )
            ],
          ),
        ));
  }
}

// Wave clipper for login header
class _WaveClipperLogin extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final Path path = Path();
    path.lineTo(0, size.height - 40);
    final firstControlPoint = Offset(size.width * 0.25, size.height);
    final firstEndPoint = Offset(size.width * 0.5, size.height - 28);
    path.quadraticBezierTo(firstControlPoint.dx, firstControlPoint.dy,
        firstEndPoint.dx, firstEndPoint.dy);

    final secondControlPoint = Offset(size.width * 0.75, size.height - 56);
    final secondEndPoint = Offset(size.width, size.height - 28);
    path.quadraticBezierTo(secondControlPoint.dx, secondControlPoint.dy,
        secondEndPoint.dx, secondEndPoint.dy);

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
