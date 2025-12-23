import 'package:flutter/material.dart';
import 'package:devkitflutter/config/constant.dart';
import 'package:devkitflutter/widgets/app_header_wrapper.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Conditional imports for web vs other platforms
import 'webview_helper_stub.dart'
    if (dart.library.html) 'webview_helper_web.dart' as webview_helper;

class WebViewPage extends StatefulWidget {
  final String url;
  final String title;

  const WebViewPage({
    Key? key,
    required this.url,
    required this.title,
  }) : super(key: key);

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  WebViewController? _controller;
  bool _isLoading = true;
  double _loadingProgress = 0;
  String? _webViewType;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      // Only initialize WebView for mobile platforms
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (String url) {
              setState(() {
                _isLoading = true;
                _loadingProgress = 0;
              });
            },
            onProgress: (int progress) {
              setState(() {
                _loadingProgress = progress / 100;
              });
            },
            onPageFinished: (String url) async {
              setState(() {
                _isLoading = false;
                _loadingProgress = 1.0;
              });
              // Check if web session should be invalidated
              await _checkAndInvalidateWebSession();
              // Auto-fill credentials if available
              await _autoFillCredentials();
            },
            onWebResourceError: (WebResourceError error) {
              setState(() {
                _isLoading = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error loading page: ${error.description}'),
                  backgroundColor: Colors.red,
                ),
              );
            },
          ),
        )
        ..loadRequest(Uri.parse(widget.url));
    } else {
      // For web platform, set up iframe
      _webViewType = webview_helper.setupWebIframe(widget.url);
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _checkAndInvalidateWebSession() async {
    if (_controller == null) return;

    final prefs = await SharedPreferences.getInstance();
    final shouldInvalidate = prefs.getBool('web_session_invalidated') ?? false;

    if (shouldInvalidate) {
      // Clear the flag first
      await prefs.remove('web_session_invalidated');

      // Try to logout from the web dashboard by clicking logout buttons or clearing session
      final jsCode = '''
        (function() {
          console.log('Invalidating web session...');

          // Try to find and click logout buttons
          var logoutBtn = document.querySelector('a[href*="logout"]') ||
                          document.querySelector('button[onclick*="logout" i]') ||
                          document.querySelector('button[id*="logout" i]') ||
                          document.querySelector('a[onclick*="logout" i]') ||
                          document.querySelector('a[id*="logout" i]') ||
                          document.querySelector('button:contains("Logout")') ||
                          document.querySelector('a:contains("Logout")');

          if (logoutBtn) {
            console.log('Found logout button, clicking...');
            logoutBtn.click();
            return;
          }

          // If no logout button found, try to clear session storage and local storage
          console.log('No logout button found, clearing storage...');
          localStorage.clear();
          sessionStorage.clear();

          // Try to navigate to logout URL if it exists
          var logoutUrl = '/logout' || '/signout' || '/exit';
          if (window.location.href.includes(logoutUrl)) {
            window.location.href = logoutUrl;
          } else {
            // As a last resort, reload the page to force re-authentication
            window.location.reload();
          }
        })();
      ''';
      await _controller!.runJavaScript(jsCode);
    }
  }

  Future<void> _autoFillCredentials() async {
    if (_controller == null) return;

    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('email') ?? '';
    final password = prefs.getString('password') ?? '';

    if (email.isNotEmpty && password.isNotEmpty) {
      // Inject JavaScript to auto-fill the form fields
      // Try multiple selectors and add logging
      final jsCode = '''
        (function() {
          console.log('Auto-fill script running for email: $email');
          var emailField = document.querySelector('input[name="email"]') ||
                           document.querySelector('input[name="username"]') ||
                           document.querySelector('input[name="userid"]') ||
                           document.querySelector('input[type="email"]') ||
                           document.querySelector('input[type="text"]') ||
                           document.querySelector('input[placeholder*="email" i]') ||
                           document.querySelector('input[placeholder*="user" i]') ||
                           document.querySelector('input[id*="email" i]') ||
                           document.querySelector('input[id*="user" i]');
          var passwordField = document.querySelector('input[name="password"]') ||
                              document.querySelector('input[type="password"]') ||
                              document.querySelector('input[placeholder*="pass" i]') ||
                              document.querySelector('input[id*="pass" i]');

          if (emailField) {
            emailField.value = '$email';
            console.log('Filled email field with: $email');
          } else {
            console.log('Email field not found');
          }
          if (passwordField) {
            passwordField.value = '$password';
            console.log('Filled password field');
          } else {
            console.log('Password field not found');
          }

          // Also try to submit the form if there's a submit button
          var submitBtn = document.querySelector('button[type="submit"]') ||
                          document.querySelector('input[type="submit"]') ||
                          document.querySelector('button[onclick*="login" i]') ||
                          document.querySelector('button[id*="login" i]');
          if (submitBtn && emailField && passwordField) {
            console.log('Attempting to auto-submit form');
            // Optional: uncomment to auto-submit
            // submitBtn.click();
          }
        })();
      ''';
      await _controller!.runJavaScript(jsCode);
    } else {
      print(
          'Credentials not found: email=$email, password=${password.isNotEmpty ? "present" : "empty"}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppHeaderWrapper(
      title: widget.title,
      showLogo: false,
      showLanguageSelector: false,
      actions: [
        if (!kIsWeb && _controller != null)
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              _controller?.reload();
            },
          ),
        if (kIsWeb)
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              setState(() {
                // Reload by rebuilding
              });
            },
          ),
      ],
      child: kIsWeb
          ? (_webViewType != null
              ? webview_helper.buildWebView(_webViewType!)
              : const Center(child: CircularProgressIndicator()))
          : Stack(
              children: [
                if (_controller != null)
                  WebViewWidget(controller: _controller!),
                if (_isLoading)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: LinearProgressIndicator(
                      value: _loadingProgress,
                      backgroundColor: Colors.grey[200],
                      valueColor:
                          AlwaysStoppedAnimation<Color>(efeedorBrandGreen),
                    ),
                  ),
              ],
            ),
    );
  }
}
