import 'package:flutter/material.dart';
import 'package:devkitflutter/config/constant.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:webview_flutter/webview_flutter.dart';

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
            onPageFinished: (String url) {
              setState(() {
                _isLoading = false;
                _loadingProgress = 1.0;
              });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: efeedorBrandGreen,
        title: Text(
          widget.title,
          style: const TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
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
      ),
      body: kIsWeb
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
                      valueColor: AlwaysStoppedAnimation<Color>(efeedorBrandGreen),
                    ),
                  ),
              ],
            ),
    );
  }
}

