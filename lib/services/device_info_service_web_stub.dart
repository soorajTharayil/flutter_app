// Stub implementation for non-web platforms
// This file is used when dart:html is not available (mobile platforms)

/// Web-specific device information (stub for non-web platforms)
class DeviceInfoServiceWeb {
  static Map<String, String> getDeviceInfo() {
    // This should never be called on non-web platforms
    // Return generic values as fallback
    return {
      'device_name': 'Web Browser',
      'platform': 'Web Browser',
      'os_version': 'Web Platform',
    };
  }
}

