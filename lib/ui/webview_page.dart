import 'package:flutter/material.dart';
import 'package:devkitflutter/config/constant.dart';
import 'package:devkitflutter/widgets/app_header_wrapper.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';

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
  late final String _effectiveUrl;

  @override
  void initState() {
    super.initState();
    _effectiveUrl = normalizeEfeedorAppUrl(widget.url);
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
              // ISRF pages expect profile in localStorage (`ehandor`) for the menu/user block.
              // App auto-login fills credentials but doesn't populate that web localStorage.
              await _seedIsrfLocalStorageProfile();
              // Auto-fill credentials if available
              await _autoFillCredentials();
              // ISRF + `src=Link` (sagarjnrwc): same as web — submit login so user lands on the form.
              await _maybeAutoSubmitIsrfLogin();
              // Some form pages render an empty profile block in the menu on mobile WebView.
              // Fill it from app profile when backend binding is blank.
              await _hydrateWebMenuProfile();
            },
            onWebResourceError: (WebResourceError error) {
              setState(() {
                _isLoading = false;
              });
              // Only the main document failing should block the flow. Ads, analytics,
              // iframes, or other subresources often hit ERR_NAME_NOT_RESOLVED while
              // the page is already usable — avoid a scary red banner in that case.
              if (error.isForMainFrame != true) {
                return;
              }
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error loading page: ${error.description}'),
                  backgroundColor: Colors.red,
                ),
              );
            },
          ),
        );
      _registerAndroidFileUploadAndLoad();
    } else {
      // For web platform, set up iframe
      _webViewType = webview_helper.setupWebIframe(_effectiveUrl);
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Android WebView does not open the system file picker for `<input type="file">`
  /// unless [AndroidWebViewController.setOnShowFileSelector] is implemented.
  Future<void> _registerAndroidFileUploadAndLoad() async {
    final c = _controller;
    if (c == null) return;
    if (defaultTargetPlatform == TargetPlatform.android) {
      final AndroidWebViewController androidController =
          c.platform as AndroidWebViewController;
      await androidController.setOnShowFileSelector(_onAndroidFileSelector);
    }
    await c.loadRequest(Uri.parse(_effectiveUrl));
  }

  Future<List<String>> _onAndroidFileSelector(FileSelectorParams params) async {
    try {
      final acceptTypes = params.acceptTypes
          .map((e) => e.trim().toLowerCase())
          .where((e) => e.isNotEmpty)
          .toList();
      final shouldRestrictToImages =
          acceptTypes.any((t) => t == 'image/*' || t.startsWith('image/'));

      final result = await FilePicker.platform.pickFiles(
        allowMultiple: params.mode == FileSelectorMode.openMultiple,
        type: shouldRestrictToImages ? FileType.image : FileType.any,
        withData: true,
        withReadStream: true,
      );
      if (result == null || result.files.isEmpty) return [];

      final paths = <String>[];
      var skippedUnsupported = false;
      for (final f in result.files) {
        if (!_isAcceptedByInputAcceptTypes(f, acceptTypes)) {
          skippedUnsupported = true;
          continue;
        }
        var p = f.path;
        if (p == null || p.isEmpty) {
          final bytes = f.bytes;
          if (bytes != null && bytes.isNotEmpty) {
            final dir = await getTemporaryDirectory();
            final ext = (f.extension ?? '').trim().toLowerCase();
            final safeExt = ext.isEmpty ? 'jpg' : ext;
            final file = File(
              '${dir.path}/webview_upload_${DateTime.now().millisecondsSinceEpoch}_${f.name.hashCode}.$safeExt',
            );
            await file.writeAsBytes(bytes, flush: true);
            p = file.path;
          } else if (f.readStream != null) {
            final dir = await getTemporaryDirectory();
            final ext = (f.extension ?? '').trim().toLowerCase();
            final safeExt = ext.isEmpty ? 'jpg' : ext;
            final file = File(
              '${dir.path}/webview_upload_${DateTime.now().millisecondsSinceEpoch}_${f.name.hashCode}.$safeExt',
            );
            final sink = file.openWrite();
            try {
              await sink.addStream(f.readStream!);
            } finally {
              await sink.close();
            }
            p = file.path;
          }
        }
        if (p != null && p.isNotEmpty) {
          paths.add(p);
        } else {
          skippedUnsupported = true;
        }
      }

      if (skippedUnsupported && mounted) {
        final allowedHint = _buildAllowedFormatsHint(acceptTypes);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              allowedHint.isEmpty
                  ? 'Selected file type is not supported for this upload.'
                  : 'Selected file type is not supported. Allowed: $allowedHint',
            ),
          ),
        );
      }
      return paths;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to pick file. Please try again.'),
          ),
        );
      }
      return [];
    }
  }

  bool _isAcceptedByInputAcceptTypes(
    PlatformFile file,
    List<String> acceptTypes,
  ) {
    if (acceptTypes.isEmpty) return true;

    final fileName = file.name.toLowerCase();
    final ext = (file.extension ?? '').toLowerCase();

    final mimeToExt = <String, Set<String>>{
      'image/jpeg': {'jpg', 'jpeg'},
      'image/png': {'png'},
      'image/gif': {'gif'},
      'image/webp': {'webp'},
      'image/bmp': {'bmp'},
      'image/heic': {'heic'},
      'image/heif': {'heif'},
    };

    for (final accept in acceptTypes) {
      if (accept == '*/*') return true;

      // Extension rule from input accept (e.g. ".jpg")
      if (accept.startsWith('.')) {
        final ruleExt = accept.substring(1);
        if (ext == ruleExt || fileName.endsWith(accept)) return true;
      }

      // Wildcard image rule (e.g. "image/*")
      if (accept == 'image/*') {
        const imageExts = {
          'jpg',
          'jpeg',
          'png',
          'gif',
          'webp',
          'bmp',
          'heic',
          'heif',
        };
        if (imageExts.contains(ext)) return true;
      }

      // Explicit mime rule (e.g. "image/png")
      final mappedExts = mimeToExt[accept];
      if (mappedExts != null && mappedExts.contains(ext)) return true;
    }

    return false;
  }

  String _buildAllowedFormatsHint(List<String> acceptTypes) {
    if (acceptTypes.isEmpty) return '';

    final labels = <String>{};
    for (final accept in acceptTypes) {
      final a = accept.trim().toLowerCase();
      if (a.isEmpty || a == '*/*') continue;

      if (a == 'image/*') {
        labels.add('JPG');
        labels.add('JPEG');
        labels.add('PNG');
        labels.add('GIF');
        labels.add('WEBP');
        labels.add('BMP');
        labels.add('HEIC');
        labels.add('HEIF');
        continue;
      }

      if (a.startsWith('.')) {
        labels.add(a.substring(1).toUpperCase());
        continue;
      }

      if (a.startsWith('image/')) {
        labels.add(a.substring('image/'.length).toUpperCase());
      }
    }

    if (labels.isEmpty) return '';
    return labels.join(', ');
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

  bool _isIsrfLinkAutoLoginUrl() {
    try {
      final u = Uri.parse(_effectiveUrl);
      if (!u.path.toLowerCase().contains('/isrf')) return false;
      return (u.queryParameters['src'] ?? '').toLowerCase() == 'link';
    } catch (_) {
      return false;
    }
  }

  /// After credential fill on ISRF `?src=Link`, click LOGIN (matches web auto-login behaviour).
  Future<void> _maybeAutoSubmitIsrfLogin() async {
    if (_controller == null || !_isIsrfLinkAutoLoginUrl()) return;

    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('email') ?? '';
    final password = prefs.getString('password') ?? '';
    if (email.isEmpty || password.isEmpty) return;

    await Future.delayed(const Duration(milliseconds: 450));

    final jsCode = '''
      (function() {
        var btn = document.querySelector('button[type="submit"]') ||
                  document.querySelector('input[type="submit"]') ||
                  document.querySelector('button.btn-primary') ||
                  document.querySelector('button.btn-success');
        if (!btn) {
          var buttons = document.querySelectorAll('button');
          for (var i = 0; i < buttons.length; i++) {
            var t = (buttons[i].textContent || '').trim().toUpperCase();
            if (t === 'LOGIN' || t.indexOf('LOGIN') >= 0) {
              btn = buttons[i];
              break;
            }
          }
        }
        if (btn) {
          btn.click();
        }
      })();
    ''';
    try {
      await _controller!.runJavaScript(jsCode);
    } catch (_) {}
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

  String _jsEscape(String value) {
    return value
        .replaceAll(r'\', r'\\')
        .replaceAll("'", r"\'")
        .replaceAll('\n', r'\n')
        .replaceAll('\r', r'\r');
  }

  bool _isIsrfPageUrl() {
    try {
      final u = Uri.parse(_effectiveUrl);
      return u.path.toLowerCase().contains('/isrf');
    } catch (_) {
      return false;
    }
  }

  Future<void> _seedIsrfLocalStorageProfile() async {
    if (_controller == null || kIsWeb) return;
    if (!_isIsrfPageUrl()) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString('name') ?? '';
      final email = prefs.getString('email') ?? '';
      final mobile = prefs.getString('mobile') ?? '';
      final designation = prefs.getString('designation') ?? '';
      final userid = prefs.getString('userid') ?? '';
      var empid = prefs.getString('empid') ?? '';
      Map<String, dynamic> perms = const {};
      if (empid.trim().isEmpty) {
        final rawPerms = prefs.getString('user_permissions');
        if (rawPerms != null && rawPerms.trim().isNotEmpty) {
          try {
            final decoded = jsonDecode(rawPerms);
            if (decoded is Map) {
              perms = decoded.map((k, v) => MapEntry(k.toString(), v));
              empid = perms['empid']?.toString() ??
                  perms['emp_id']?.toString() ??
                  perms['employeeid']?.toString() ??
                  perms['employee_id']?.toString() ??
                  '';
            }
          } catch (_) {}
        }
      } else {
        final rawPerms = prefs.getString('user_permissions');
        if (rawPerms != null && rawPerms.trim().isNotEmpty) {
          try {
            final decoded = jsonDecode(rawPerms);
            if (decoded is Map) {
              perms = decoded.map((k, v) => MapEntry(k.toString(), v));
            }
          } catch (_) {}
        }
      }

      // If we have nothing, don't overwrite anything.
      if (name.trim().isEmpty &&
          email.trim().isEmpty &&
          mobile.trim().isEmpty &&
          userid.trim().isEmpty) {
        return;
      }

      final picture = (perms['picture']?.toString() ?? '').trim();

      final jsCode = '''
        (function() {
          function isBlank(v) {
            if (v === null || v === undefined) return true;
            var s = ('' + v).trim();
            return !s || s.indexOf('{{') >= 0 || s.toLowerCase() === 'null' || s.toLowerCase() === 'undefined';
          }

          function getRootScope() {
            try {
              var appEl = document.querySelector('[ng-app]') || document.body;
              if (!window.angular || !appEl) return null;
              var inj = angular.element(appEl).injector && angular.element(appEl).injector();
              if (!inj) return null;
              return inj.get('\$rootScope');
            } catch (e) {
              return null;
            }
          }

          function patchAngular(ehandor, profile) {
            try {
              if (!window.angular) return;
              var rs = getRootScope();
              if (rs && rs.\$applyAsync) {
                rs.\$applyAsync(function() {
                  rs.ehandor = rs.ehandor || {};
                  for (var k in ehandor) {
                    if (ehandor.hasOwnProperty(k) && isBlank(rs.ehandor[k]) && !isBlank(ehandor[k])) {
                      rs.ehandor[k] = ehandor[k];
                    }
                  }

                  rs.profilen = rs.profilen || {};
                  if (isBlank(rs.profilen.name) && !isBlank(profile.name)) rs.profilen.name = profile.name;
                  if (isBlank(rs.profilen.email) && !isBlank(profile.email)) rs.profilen.email = profile.email;
                  if (isBlank(rs.profilen.mobile) && !isBlank(profile.mobile)) rs.profilen.mobile = profile.mobile;
                  if (isBlank(rs.profilen.empid) && !isBlank(profile.empid)) rs.profilen.empid = profile.empid;
                  if (isBlank(rs.profilen.userid) && !isBlank(profile.userid)) rs.profilen.userid = profile.userid;
                  if (isBlank(rs.profilen.designation) && !isBlank(profile.designation)) rs.profilen.designation = profile.designation;
                  if (isBlank(rs.profilen.picture) && !isBlank(profile.picture)) rs.profilen.picture = profile.picture;

                  if (isBlank(rs.loginname) && !isBlank(profile.name)) rs.loginname = profile.name;
                  if (isBlank(rs.loginemail) && !isBlank(profile.email)) rs.loginemail = profile.email;
                  if (isBlank(rs.loginnumber) && !isBlank(profile.mobile)) rs.loginnumber = profile.mobile;
                  if (isBlank(rs.loginid) && !isBlank(profile.empid)) rs.loginid = profile.empid;
                });
                return;
              }

              // Fallback: patch body scope (some pages don't expose injector)
              var scope = angular.element(document.body).scope && angular.element(document.body).scope();
              if (!scope || !scope.\$applyAsync) return;
              scope.\$applyAsync(function() {
                scope.ehandor = scope.ehandor || {};
                for (var k2 in ehandor) {
                  if (ehandor.hasOwnProperty(k2) && isBlank(scope.ehandor[k2]) && !isBlank(ehandor[k2])) {
                    scope.ehandor[k2] = ehandor[k2];
                  }
                }

                scope.profilen = scope.profilen || {};
                if (isBlank(scope.profilen.name) && !isBlank(profile.name)) scope.profilen.name = profile.name;
                if (isBlank(scope.profilen.email) && !isBlank(profile.email)) scope.profilen.email = profile.email;
                if (isBlank(scope.profilen.mobile) && !isBlank(profile.mobile)) scope.profilen.mobile = profile.mobile;
                if (isBlank(scope.profilen.empid) && !isBlank(profile.empid)) scope.profilen.empid = profile.empid;
                if (isBlank(scope.profilen.userid) && !isBlank(profile.userid)) scope.profilen.userid = profile.userid;
                if (isBlank(scope.profilen.designation) && !isBlank(profile.designation)) scope.profilen.designation = profile.designation;
                if (isBlank(scope.profilen.picture) && !isBlank(profile.picture)) scope.profilen.picture = profile.picture;
              });
            } catch (e) {}
          }

          function ensureProfile() {
            try {
              var existing = localStorage.getItem('ehandor');
              var parsed = {};
              if (existing && existing.trim().length > 2) {
                try { parsed = JSON.parse(existing) || {}; } catch (e) {}
              }

              // Match login.php response shape as closely as possible so the web app
              // can read expected keys (status, userid, empid, designation, picture, permissions, etc).
              var ehandor = Object.assign({}, ${jsonEncode(perms)}, {
                status: 'success',
                userid: '${_jsEscape(userid)}',
                email: '${_jsEscape(email)}',
                empid: '${_jsEscape(empid.trim().isNotEmpty ? empid : userid)}',
                name: '${_jsEscape(name)}',
                mobile: '${_jsEscape(mobile)}',
                designation: '${_jsEscape(designation)}',
                picture: '${_jsEscape(picture)}'
              });

              var profile = {
                name: '${_jsEscape(name)}',
                email: '${_jsEscape(email)}',
                mobile: '${_jsEscape(mobile)}',
                empid: '${_jsEscape(empid.trim().isNotEmpty ? empid : userid)}',
                userid: '${_jsEscape(userid)}',
                designation: '${_jsEscape(designation)}',
                picture: '${_jsEscape(picture)}'
              };

              // Preserve any non-empty existing values on the device.
              if (!isBlank(parsed.name)) { profile.name = parsed.name; ehandor.name = parsed.name; }
              if (!isBlank(parsed.email)) { profile.email = parsed.email; ehandor.email = parsed.email; }
              if (!isBlank(parsed.mobile)) { profile.mobile = parsed.mobile; ehandor.mobile = parsed.mobile; }
              if (!isBlank(parsed.empid)) { profile.empid = parsed.empid; ehandor.empid = parsed.empid; }
              if (!isBlank(parsed.userid)) { profile.userid = parsed.userid; ehandor.userid = parsed.userid; }
              if (!isBlank(parsed.designation)) { profile.designation = parsed.designation; ehandor.designation = parsed.designation; }
              if (!isBlank(parsed.picture)) { profile.picture = parsed.picture; ehandor.picture = parsed.picture; }

              localStorage.setItem('ehandor', JSON.stringify(ehandor));

              // Directly patch the ISRF "Request reported by" table as a final fallback
              // so employee details are visible even if Angular bindings or scopes differ.
              try {
                function patchRequestReportedBy() {
                  var labels = [
                    { key: 'name', label: 'Employee name' },
                    { key: 'empid', label: 'Employee ID' },
                    { key: 'mobile', label: 'Mobile number' },
                    { key: 'email', label: 'Email ID' }
                  ];
                  var textMap = {
                    name: profile.name || ehandor.name,
                    empid: profile.empid || ehandor.empid,
                    mobile: profile.mobile || ehandor.mobile,
                    email: profile.email || ehandor.email
                  };
                  var tds = document.getElementsByTagName('td');
                  for (var i = 0; i < tds.length; i++) {
                    var cellText = (tds[i].textContent || '').trim();
                    if (!cellText) continue;
                    for (var j = 0; j < labels.length; j++) {
                      var lbl = labels[j];
                      if (cellText.toLowerCase() === lbl.label.toLowerCase()) {
                        var next = tds[i].nextElementSibling;
                        if (!next) continue;
                        var current = (next.textContent || '').trim();
                        var v = textMap[lbl.key] || '';
                        if (!current && v) {
                          next.textContent = v;
                        }
                      }
                    }
                  }
                }
                // Run once immediately, then retry briefly in case table renders late.
                patchRequestReportedBy();
                var triesRb = 0;
                var tRb = setInterval(function() {
                  triesRb++;
                  patchRequestReportedBy();
                  if (triesRb > 20) clearInterval(tRb);
                }, 250);
              } catch (e) {}

              patchAngular(ehandor, profile);
              return !!window.angular;
            } catch (e) {
              return false;
            }
          }

          // Angular + controller init can happen after `onPageFinished`.
          // Keep trying briefly so Step-4 ("reported by") and save payload populate.
          if (ensureProfile()) return;
          var tries = 0;
          var t = setInterval(function() {
            tries++;
            var ok = ensureProfile();
            if (ok || tries > 20) clearInterval(t);
          }, 250);
        })();
      ''';

      await _controller!.runJavaScript(jsCode);
    } catch (_) {
      // Ignore; page still works.
    }
  }

  Future<void> _hydrateWebMenuProfile() async {
    if (_controller == null || kIsWeb) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString('name') ?? '';
      final email = prefs.getString('email') ?? '';
      final mobile = prefs.getString('mobile') ?? '';
      if (name.trim().isEmpty && email.trim().isEmpty && mobile.trim().isEmpty) {
        return;
      }

      final jsCode = '''
        (function() {
          var fallbackName = '${_jsEscape(name)}';
          var fallbackEmail = '${_jsEscape(email)}';
          var fallbackMobile = '${_jsEscape(mobile)}';

          function patchAngular() {
            try {
              if (!window.angular) return;
              var scope = angular.element(document.body).scope();
              if (!scope) return;
              scope.\$applyAsync(function() {
                scope.profilen = scope.profilen || {};
                if ((!scope.profilen.name || ('' + scope.profilen.name).indexOf('{{') >= 0) && fallbackName) {
                  scope.profilen.name = fallbackName;
                }
                if ((!scope.profilen.email || ('' + scope.profilen.email).indexOf('{{') >= 0) && (fallbackEmail || fallbackMobile)) {
                  scope.profilen.email = fallbackEmail || fallbackMobile;
                }
              });
            } catch (e) {}
          }

          function applyProfile() {
            var blocks = document.querySelectorAll('.menu-dropdown .user-info');
            if (!blocks || blocks.length === 0) return false;

            for (var b = 0; b < blocks.length; b++) {
              var info = blocks[b];
              // Prefer the exact structure used by ISRF menu:
              // <div class="user-info"><i ...></i><div class="user-details"><div>{{ profilen.name }}</div><div>{{ profilen.email }}</div></div></div>
              var details = info.querySelector('.user-details') || info;
              var divs = details.querySelectorAll('div');
              var nameNode = null;
              var emailNode = null;
              for (var i = 0; i < divs.length; i++) {
                var t = (divs[i].textContent || '').trim();
                if (!nameNode && (t === '' || t.indexOf('profilen.name') >= 0 || t.indexOf('{{') >= 0)) {
                  nameNode = divs[i];
                  continue;
                }
                if (nameNode && !emailNode && (t === '' || t.indexOf('profilen.email') >= 0 || t.indexOf('{{') >= 0)) {
                  emailNode = divs[i];
                  break;
                }
              }
              // Fallback: first two divs inside details
              if (!nameNode && divs.length > 0) nameNode = divs[0];
              if (!emailNode && divs.length > 1) emailNode = divs[1];

              if (nameNode) {
                var currentName = (nameNode.textContent || '').trim();
                if ((!currentName || currentName.indexOf('{{') >= 0) && fallbackName) {
                  nameNode.textContent = fallbackName;
                }
              }
              if (emailNode) {
                var currentEmail = (emailNode.textContent || '').trim();
                if (!currentEmail || currentEmail.indexOf('{{') >= 0) {
                  if (fallbackEmail) {
                    emailNode.textContent = fallbackEmail;
                  } else if (fallbackMobile) {
                    emailNode.textContent = fallbackMobile;
                  }
                }
              }
            }
            patchAngular();
            return true;
          }

          if (applyProfile()) return;
          // Retry briefly; menu/profile block is Angular-rendered and can appear late.
          var tries = 0;
          var t = setInterval(function() {
            tries++;
            if (applyProfile() || tries > 12) clearInterval(t);
          }, 250);
        })();
      ''';
      await _controller!.runJavaScript(jsCode);
    } catch (_) {
      // Ignore profile hydration errors; page is still usable.
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
