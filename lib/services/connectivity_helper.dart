import 'package:connectivity_plus/connectivity_plus.dart';

/// Helper function to check if device is online
/// Returns true if online, false if offline (no exception thrown)
Future<bool> isOnline() async {
  try {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  } catch (e) {
    // If check fails, assume offline
    return false;
  }
}

