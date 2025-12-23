import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:devkitflutter/ui/signin.dart';
import 'package:devkitflutter/config/constant.dart';
import 'package:devkitflutter/services/device_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class DomainLoginPage extends StatefulWidget {
  const DomainLoginPage({Key? key, this.isChangingDomain = false})
      : super(key: key);

  final bool isChangingDomain;

  @override
  _DomainLoginPageState createState() => _DomainLoginPageState();
}

class _DomainLoginPageState extends State<DomainLoginPage> {
  final TextEditingController domainController = TextEditingController();
  bool _loading = false;
  bool _checkingApproval = true;

  @override
  void initState() {
    super.initState();
    _checkDeviceApproval();
  }

  Future<void> _checkDeviceApproval() async {
    // Skip device approval check if user is changing domain
    if (widget.isChangingDomain) {
      if (mounted) {
        setState(() {
          _checkingApproval = false;
        });
      }
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final domain = prefs.getString('domain') ?? '';

      if (domain.isNotEmpty) {
        // Domain exists - check if device is approved
        final deviceInfo = await DeviceService.getDeviceInfo();
        final deviceId = deviceInfo['device_id']!;
        final isApproved =
            await DeviceService.isDeviceApproved(deviceId, domain);

        if (isApproved && mounted) {
          // Device approved - skip domain page, go directly to login
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const SignIn()),
          );
          return;
        }
      }
    } catch (e) {
      print('Error checking device approval: $e');
    } finally {
      if (mounted) {
        setState(() {
          _checkingApproval = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading while checking approval
    if (_checkingApproval) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(efeedorBrandGreen),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header gradient with wave bottom and white branding
            ClipPath(
              clipper: _WaveClipper(),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.33,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      efeedorBrandGreen.withOpacity(0.95),
                      efeedorBrandGreen,
                    ],
                  ),
                ),
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
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // White Card
            Expanded(
              child: Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Enter your domain name',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                        fontFamily: 'Roboto',
                      ),
                    ),
                    SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: domainController,
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 16,
                            ),
                            inputFormatters: [
                              // Prevent spaces from being entered
                              FilteringTextInputFormatter.deny(RegExp(r'\s')),
                            ],
                            decoration: InputDecoration(
                              hintText: 'eg : abchospital',
                              hintStyle: TextStyle(
                                color: Colors.black.withOpacity(0.5),
                                fontSize: 16,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide:
                                    BorderSide(color: Colors.grey.shade400),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide:
                                    BorderSide(color: Colors.grey.shade400),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                    color: efeedorBrandGreen, width: 2),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          flex: 1,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                '.efeedor.com',
                                style: TextStyle(color: Colors.black87),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 30),
                    Center(
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _loading
                              ? null
                              : () async {
                                  await _validateAndProceed();
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: efeedorBrandGreen,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: _loading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : Text('Proceed',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  )),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Center(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                contentPadding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                content: Container(
                                  width:
                                      MediaQuery.of(context).size.width * 0.8,
                                  child: Image.asset(
                                    'assets/images/domain_help.png',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        icon:
                            Icon(Icons.help_outline, color: efeedorBrandGreen),
                        label: const Text('What is my domain name?'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: efeedorBrandGreen,
                          side:
                              BorderSide(color: efeedorBrandGreen, width: 1.2),
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                    Spacer(),
                    Center(
                      child: TextButton(
                        onPressed: () {
                          // Handle custom domain login
                        },
                        child: Text(
                          '',
                          style: TextStyle(
                            color: Colors.blueAccent,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _validateAndProceed() async {
    // Set loading state immediately when button is tapped
    if (mounted) {
      setState(() {
        _loading = true;
      });
    }

    try {
      // Trim leading and trailing spaces
      final String trimmedInput = domainController.text.trim();

      // Check if input is empty after trimming
      if (trimmedInput.isEmpty) {
        if (mounted) {
          setState(() {
            _loading = false;
          });
        }
        _showAlert('Please enter your domain.');
        return;
      }

      // Check for any spaces (leading, trailing, or middle)
      if (trimmedInput.contains(' ')) {
        if (mounted) {
          setState(() {
            _loading = false;
          });
        }
        _showAlert(
            'Domain cannot contain spaces. Please enter a valid domain name.');
        return;
      }

      // Convert to lowercase for validation
      final String input = trimmedInput.toLowerCase();

      final response = await http.get(Uri.parse(domainValidationApi));
      if (response.statusCode != 200) {
        _showAlert('Unable to validate domain. Please try again.');
        return;
      }

      final body = jsonDecode(response.body);
      bool exists = false;

      // API shape: { status: 'success', count: N, data: [ { link: 'https://krr.efeedor.com', ... }, ... ] }
      final dynamic rows = (body is Map && body['data'] is List)
          ? body['data']
          : (body is List ? body : []);

      if (rows is List) {
        for (final item in rows) {
          if (item is Map && item['link'] is String) {
            final String link = (item['link'] as String).trim();
            try {
              final uri = Uri.parse(link);
              final host = uri.host; // e.g., krr.efeedor.com
              final parts = host.split('.');
              if (parts.isNotEmpty) {
                final sub = parts.first.toLowerCase();
                if (sub == input) {
                  exists = true;
                  break;
                }
              }
            } catch (_) {
              // ignore malformed link rows
            }
          }
        }
      }

      if (exists) {
        // Domain is valid - save it first
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('domain', input);
        await prefs.setBool('domain_completed', true);

        // Navigate to login page (no device registration at this stage)
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => SignIn(),
          ),
        );
      } else {
        _showAlert('Domain not found. Please check and try again.');
      }
    } catch (e) {
      // Handle domain validation errors
      if (mounted) {
        _showAlert('Error validating domain: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _showAlert(String message) {
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
                    color: efeedorBrandGreen.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.error_outline,
                      color: Colors.redAccent, size: 34),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Efeedor',
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
                        backgroundColor: efeedorBrandGreen,
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
}

// Simple wave clipper for the header bottom edge
class _WaveClipper extends CustomClipper<Path> {
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
