import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Conditional imports for web vs other platforms
import 'package:devkitflutter/ui/webview_helper_stub.dart'
    if (dart.library.html) 'package:devkitflutter/ui/webview_helper_web.dart'
    as webview_helper;

class WebViewPage extends StatefulWidget {
  final String url;
  final String title;

  /// For KPI Forms: pass the FULL login.php response map here (status, email, empid, name, mobile, KPI1..KPI33, etc.)
  final Map<String, dynamic>? permissionData;

  const WebViewPage({
    Key? key,
    required this.url,
    required this.title,
    this.permissionData,
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
            onProgress: (int progress) async {
              setState(() {
                _loadingProgress = progress / 100;
              });

              // Early injection only for KPI Forms page
              if (widget.permissionData != null &&
                  _isKpiFormsUrl(widget.url) &&
                  progress >= 40 &&
                  progress < 100) {
                await _injectKpiSessionAndProfilen(widget.permissionData!,
                    phase: 'early');
              }
            },
            onPageFinished: (String url) async {
              setState(() {
                _isLoading = false;
                _loadingProgress = 1.0;
              });

              await _checkAndInvalidateWebSession();
              await _autoFillCredentials();

              // Final injection on finish for KPI Forms page
              if (widget.permissionData != null && _isKpiFormsUrl(url)) {
                await _injectKpiSessionAndProfilen(widget.permissionData!,
                    phase: 'finish');

                // One more delayed injection for safety (Angular timing)
                await Future.delayed(const Duration(milliseconds: 600));
                await _injectKpiSessionAndProfilen(widget.permissionData!,
                    phase: 'delayed');
              }
            },
            onWebResourceError: (WebResourceError error) {
              setState(() {
                _isLoading = false;
              });

              // Check if this is a module that should ignore certain non-critical errors
              final isIncidentModule = widget.url.contains('/inn');
              final isKpiFormsModule = widget.url.contains('/qim_forms');
              final isAuditFormsModule = widget.url.contains('/audit_forms');
              final isMonthlyReportsModule =
                  widget.url.contains('/monthly_audit_reports');

              final errorDescription = error.description.toLowerCase();

              // ORB errors are non-critical WebView security errors that don't prevent page functionality
              // They occur when WebView blocks sub-resources (JS, CSS, images, APIs) but the main page loads correctly
              final isOrbError =
                  errorDescription.contains('err_blocked_by_orb') ||
                      errorDescription.contains('orb') ||
                      errorDescription.contains('opaque response');

              // ERR_NAME_NOT_RESOLVED is a DNS resolution error for sub-resources
              // Healthcare Audit Forms may have external resources that fail to resolve
              // but the main page loads and functions correctly
              final isNameNotResolvedError =
                  errorDescription.contains('err_name_not_resolved') ||
                      errorDescription.contains('name_not_resolved');

              // Determine which errors to suppress based on module
              bool shouldSuppressError = false;

              if (isIncidentModule ||
                  isKpiFormsModule ||
                  isAuditFormsModule ||
                  isMonthlyReportsModule) {
                // Suppress ORB errors for all these modules
                if (isOrbError) {
                  shouldSuppressError = true;
                }

                // Suppress ERR_NAME_NOT_RESOLVED specifically for Healthcare Audit Forms
                if (isAuditFormsModule && isNameNotResolvedError) {
                  shouldSuppressError = true;
                }
              }

              // Only show error snackbar for errors that should not be suppressed
              if (!shouldSuppressError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error loading page: ${error.description}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
              // Silently ignore ORB errors for Incident Module, Quality KPI Forms,
              // Healthcare Audit Forms, and Departmental Monthly Reports
              // Also ignore ERR_NAME_NOT_RESOLVED for Healthcare Audit Forms
              // as these errors don't prevent page functionality
            },
          ),
        )
        ..loadRequest(Uri.parse(widget.url));
    } else {
      _webViewType = webview_helper.setupWebIframe(widget.url);
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Check if URL is a module that requires permission injection
  /// These modules use Angular ng-if conditions based on profilen permissions
  bool _isKpiFormsUrl(String url) {
    // Modules that require permission injection: Quality KPI Forms, Healthcare Audit Forms, Departmental Monthly Reports
    return url.contains('/qim_forms') ||
        url.contains('/audit_forms') ||
        url.contains('/monthly_audit_reports');
  }

  String _escapeForSingleQuotedJsString(String input) {
    // Escape for JS single-quoted string
    return input
        .replaceAll(r'\', r'\\')
        .replaceAll("'", r"\'")
        .replaceAll('\n', r'\n')
        .replaceAll('\r', r'\r');
  }

  /// ✅ MAIN FIX:
  /// Inject BOTH:
  /// - localStorage.ehandor (required by your Angular code)
  /// - window.profilen + localStorage.profilen (for ng-if checks)
  /// Then push profilen into Angular $rootScope and trigger digest.
  Future<void> _injectKpiSessionAndProfilen(
    Map<String, dynamic> loginResponse, {
    required String phase,
  }) async {
    if (_controller == null) return;

    try {
      // Build "ehandor" object EXACTLY as your Angular expects
      final ehandor = {
        "email": loginResponse["email"] ?? "",
        "empid": loginResponse["empid"] ?? "",
        "data": {
          "name": loginResponse["name"] ?? "",
          "mobile": loginResponse["mobile"] ?? "",
        }
      };

      // Build "profilen" permissions map (exclude non-permission keys)
      final profilen = <String, dynamic>{};
      loginResponse.forEach((key, value) {
        if (key == 'status' ||
            key == 'userid' ||
            key == 'email' ||
            key == 'empid' ||
            key == 'name' ||
            key == 'mobile' ||
            key == 'designation' ||
            key == 'picture' ||
            key == 'data' ||
            key == 'message') {
          return;
        }
        profilen[key] = value;
      });

      final ehandorJson = jsonEncode(ehandor);
      final profilenJson = jsonEncode(profilen);

      final ehandorEsc = _escapeForSingleQuotedJsString(ehandorJson);
      final profilenEsc = _escapeForSingleQuotedJsString(profilenJson);

      debugPrint(
          "KPI Inject [$phase] -> ehandor bytes=${ehandorJson.length}, profilen keys=${profilen.length}");

      final js = '''
(function () {
  try {
    console.log('Flutter KPI Inject: phase=$phase');

    // 1) Inject ehandor (MANDATORY for your Angular controller)
    var ehandorStr = '$ehandorEsc';
    localStorage.setItem('ehandor', ehandorStr);

    // 2) Inject profilen (permissions)
    var profilenStr = '$profilenEsc';
    localStorage.setItem('profilen', profilenStr);
    sessionStorage.setItem('profilen', profilenStr);

    // Also keep in window for direct access
    window.profilen = JSON.parse(profilenStr);

    // 3) Push into AngularJS runtime (NO Angular code change)
    function injectIntoAngular() {
      try {
        if (typeof angular === 'undefined') {
          console.log('Flutter KPI Inject: angular undefined');
          return false;
        }

        var hostEl = document.querySelector('[ng-app], [data-ng-app]') || document.body;
        var injector = angular.element(hostEl).injector();
        if (!injector) {
          console.log('Flutter KPI Inject: injector not ready');
          return false;
        }

        var \$rootScope = injector.get('\$rootScope');
        if (!\$rootScope) return false;

        // IMPORTANT: set BOTH rootScope + window scope usage
        \$rootScope.profilen = window.profilen;

        // Trigger digest safely
        try {
          \$rootScope.\$applyAsync();
        } catch (e) {}

        console.log('Flutter KPI Inject: injected into \$rootScope', \$rootScope.profilen);
        return true;
      } catch (e) {
        console.log('Flutter KPI Inject: injectIntoAngular error', e);
        return false;
      }
    }

    // Try now + retry (Angular loads async in WebView)
    if (!injectIntoAngular()) {
      setTimeout(injectIntoAngular, 300);
      setTimeout(injectIntoAngular, 800);
      setTimeout(injectIntoAngular, 1500);
    }

  } catch (e) {
    console.error('Flutter KPI Inject: failed', e);
  }
})();
''';

      await _controller!.runJavaScript(js);
    } catch (e) {
      debugPrint('KPI Inject error: $e');
    }
  }

  Future<void> _checkAndInvalidateWebSession() async {
    if (_controller == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final shouldInvalidate = prefs.getBool('invalidate_web_session') ?? false;

      if (shouldInvalidate) {
        final jsCode = '''
(function() {
  console.log('Invalidating web session...');
  try {
    localStorage.clear();
    sessionStorage.clear();
  } catch(e) {}
  try { window.location.reload(); } catch(e) {}
})();
''';
        await _controller!.runJavaScript(jsCode);
        await prefs.setBool('invalidate_web_session', false);
      }
    } catch (e) {
      debugPrint('Error invalidating web session: $e');
    }
  }

  Future<void> _autoFillCredentials() async {
    if (_controller == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('email') ?? '';
      final password = prefs.getString('password') ?? '';

      if (email.isNotEmpty && password.isNotEmpty) {
        final emailEsc = _escapeForSingleQuotedJsString(email);
        final passEsc = _escapeForSingleQuotedJsString(password);

        final jsCode = '''
(function() {
  try {
    console.log('Auto-filling credentials...');
    var emailInput = document.querySelector('input[type="email"]') ||
                     document.querySelector('input[name="email"]') ||
                     document.querySelector('input[name="userid"]') ||
                     document.querySelector('input[id*="email" i]') ||
                     document.querySelector('input[placeholder*="email" i]');

    var passwordInput = document.querySelector('input[type="password"]') ||
                        document.querySelector('input[name="password"]') ||
                        document.querySelector('input[id*="password" i]') ||
                        document.querySelector('input[placeholder*="password" i]');

    if (emailInput && passwordInput) {
      emailInput.value = '$emailEsc';
      passwordInput.value = '$passEsc';

      emailInput.dispatchEvent(new Event('input', { bubbles: true }));
      passwordInput.dispatchEvent(new Event('input', { bubbles: true }));

      console.log('Credentials auto-filled');
    }
  } catch(e) {
    console.log('Auto-fill failed', e);
  }
})();
''';
        await _controller!.runJavaScript(jsCode);
      }
    } catch (e) {
      debugPrint('Error auto-filling credentials: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => setState(() {}),
            ),
          ],
        ),
        body: webview_helper.buildWebView(_webViewType ?? ''),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _controller?.reload(),
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_controller != null) WebViewWidget(controller: _controller!),
          if (_isLoading)
            LinearProgressIndicator(
              value: _loadingProgress,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
        ],
      ),
    );
  }
}
