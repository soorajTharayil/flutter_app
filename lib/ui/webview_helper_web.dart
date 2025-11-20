// Web-specific implementation
import 'package:flutter/widgets.dart';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

// Track registered view types to avoid duplicate registration
final Set<String> _registeredViews = <String>{};

String setupWebIframe(String url) {
  final viewType = 'webview-${url.hashCode}';
  
  // Only register if not already registered
  if (!_registeredViews.contains(viewType)) {
    final iframe = html.IFrameElement()
      ..src = url
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%';

    ui_web.platformViewRegistry.registerViewFactory(
      viewType,
      (int viewId) => iframe,
    );
    
    _registeredViews.add(viewType);
  }
  
  return viewType;
}

Widget buildWebView(String viewType) {
  // ignore: avoid_web_libraries_in_flutter
  return HtmlElementView(viewType: viewType);
}

