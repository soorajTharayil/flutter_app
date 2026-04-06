/*
this is constant pages
 */

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<String> getDomainFromPrefs() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('domain') ?? ''; // default to empty string if not set
}

/// Bare subdomain for `https://{sub}.efeedor.com/...` (e.g. `sagarjnrwc`).
/// Handles prefs stored as `hospital`, `hospital.efeedor.com`, or `https://hospital.efeedor.com/`.
/// Without this, `https://$domain.efeedor.com` can become `*.efeedor.com.efeedor.com` and fail DNS on device WebViews.
String normalizeEfeedorSubdomain(String raw) {
  final t = raw.trim();
  if (t.isEmpty) return '';
  if (!t.contains('.')) return t.toLowerCase();
  final Uri? u =
      t.contains('://') ? Uri.tryParse(t) : Uri.tryParse('https://$t');
  if (u == null || u.host.isEmpty) return t.toLowerCase();
  final host = u.host.toLowerCase();
  const suffix = '.efeedor.com';
  if (host.endsWith(suffix)) {
    return host.substring(0, host.length - suffix.length);
  }
  return host;
}

/// Fixes WebView URLs if the host was built as `tenant.efeedor.com.efeedor.com` (unresolvable).
String normalizeEfeedorAppUrl(String urlString) {
  final u = Uri.tryParse(urlString.trim());
  if (u == null || u.host.isEmpty) return urlString;
  var host = u.host.toLowerCase();
  const doubleSuffix = '.efeedor.com.efeedor.com';
  if (host.endsWith(doubleSuffix)) {
    host = host.substring(0, host.length - '.efeedor.com'.length);
    return u.replace(host: host).toString();
  }
  return urlString;
}

const String appName = 'Efeedor';

// color for apps
const Color primaryColor = Color(0xFF07ac12);
const Color assentColor = Color(0xFFe75f3f);
// Requested brand green for headers/buttons (adjust hex if you have a specific one)
const Color efeedorBrandGreen = Color(0xFF009688);

const Color blackGrey = Color(0xff777777);
const Color black21 = Color(0xFF212121);
const Color black55 = Color(0xFF555555);
const Color black77 = Color(0xFF777777);
const Color softGrey = Color(0xFFaaaaaa);
const Color softBlue = Color(0xff01aed6);

const String errorOccured = 'Error occured, please try again later';

const int limitPage = 8;

const String globalUrl = 'https://ijtechnology.net/assets/images/api/devkit';
//const String globalUrl = 'http://192.168.0.4/devkit';
//const String globalUrl = 'http://192.168.100.9/devkit';

const String localImagesUrl = 'assets/images';
// constants/config.dart

// Base API URL
Future<String> getLoginEndpoint() async {
  final domain = await getDomainFromPrefs();
  return 'https://$domain.efeedor.com/api/login.php';
}

// Device approval request endpoint
Future<String> getDeviceApprovalRequestEndpoint() async {
  final domain = await getDomainFromPrefs();
  return 'https://$domain.efeedor.com/deviceApproval/requestAccess';
}

// Device status check endpoint
Future<String> getDeviceStatusEndpoint() async {
  final domain = await getDomainFromPrefs();
  return 'https://$domain.efeedor.com/deviceApproval/checkStatus';
}

// Generic error message
const String errorOccuredApi = 'Error occurred, please try again later';

// Domain validation API (provide actual URL)
// Expected response: list/array of objects containing hospital/domain info.
// We'll check if the entered subdomain exists in any of the string fields.
const String domainValidationApi =
    'https://h.efeedor.com/flutter_apk_api/domain_verification.php';
