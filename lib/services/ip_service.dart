import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

/// Service to get device IP address
class IpService {
  /// Get device IP address
  /// For web: Gets public IP from ipify.org
  /// For mobile: Gets local IP from network interfaces
  static Future<String> getDeviceIp() async {
    if (kIsWeb) {
      // For web, get public IP from ipify service
      try {
        final response = await http.get(
          Uri.parse('https://api.ipify.org?format=json'),
        ).timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            throw Exception('IP fetch timeout');
          },
        );
        
        if (response.statusCode == 200) {
          final data = response.body;
          // Parse JSON response: {"ip":"xxx.xxx.xxx.xxx"}
          final ipMatch = RegExp(r'"ip"\s*:\s*"([^"]+)"').firstMatch(data);
          if (ipMatch != null) {
            return ipMatch.group(1)!;
          }
          // Fallback: try to extract IP directly
          final ipPattern = RegExp(r'\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b');
          final match = ipPattern.firstMatch(data);
          if (match != null) {
            return match.group(0)!;
          }
        }
      } catch (e) {
        print('Error getting public IP: $e');
      }
      // Fallback: return placeholder, backend will get it from headers
      return '0.0.0.0';
    }

    // For Android/iOS, get IP from network interfaces
    try {
      for (var interface in await NetworkInterface.list()) {
        for (var addr in interface.addresses) {
          // Skip loopback and link-local addresses
          if (!addr.isLoopback && 
              !addr.isLinkLocal && 
              addr.type == InternetAddressType.IPv4) {
            return addr.address;
          }
        }
      }
    } catch (e) {
      print('Error getting IP address: $e');
    }

    // Fallback: return placeholder, backend will get actual IP
    return '0.0.0.0';
  }
}
