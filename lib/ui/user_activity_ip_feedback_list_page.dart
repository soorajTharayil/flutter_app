import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../widgets/app_header_wrapper.dart';
import '../config/constant.dart';

/// User Activity IP Feedback List Page
/// Uses API: GET view/user_activity_ipd/all/{userId}
/// Displays ALL IP Feedback records for the user (no date filtering)
class UserActivityIpFeedbackListPage extends StatefulWidget {
  final String userId;
  final String tdate; // older date (start)
  final String fdate; // newer date (end)

  const UserActivityIpFeedbackListPage({
    Key? key,
    required this.userId,
    required this.tdate,
    required this.fdate,
  }) : super(key: key);

  @override
  State<UserActivityIpFeedbackListPage> createState() => _UserActivityIpFeedbackListPageState();
}

class _UserActivityIpFeedbackListPageState extends State<UserActivityIpFeedbackListPage> {
  List<Map<String, dynamic>> _feedbacks = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchFeedbacks();
  }

  /// Fetch IP feedbacks from User Activity API
  /// API: GET view/user_activity_ipd/all/{userId}
  Future<void> _fetchFeedbacks({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final domain = prefs.getString('domain') ?? '';

      if (domain.isEmpty) {
        throw Exception('Domain not found. Please login again.');
      }

      // Call User Activity API: view/user_activity_ipd/all/{userId}?tdate=YYYY-MM-DD&fdate=YYYY-MM-DD
      final apiUrl = 'https://$domain.efeedor.com/view/user_activity_ipd/all/${widget.userId}?tdate=${widget.tdate}&fdate=${widget.fdate}';
      final uri = Uri.parse(apiUrl);

      print('🔵 [USER ACTIVITY IP LIST] ========================================');
      print('🔵 [USER ACTIVITY IP LIST] Calling User Activity API');
      print('🔵 [USER ACTIVITY IP LIST] API: view/user_activity_ipd/all/{userId}?tdate=...&fdate=...');
      print('🔵 [USER ACTIVITY IP LIST] URL: $apiUrl');
      print('🔵 [USER ACTIVITY IP LIST] User ID: ${widget.userId}');
      print('🔵 [USER ACTIVITY IP LIST] tdate (older): ${widget.tdate}');
      print('🔵 [USER ACTIVITY IP LIST] fdate (newer): ${widget.fdate}');
      print('🔵 [USER ACTIVITY IP LIST] ========================================');

      final response = await http.get(uri).timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      print('🟢 [USER ACTIVITY IP LIST] Response Status: ${response.statusCode}');
      print('🟢 [USER ACTIVITY IP LIST] Response Body Length: ${response.body.length}');
      print('🟢 [USER ACTIVITY IP LIST] Full Response Body:');
      print(response.body);
      print('🟢 [USER ACTIVITY IP LIST] ========================================');

      if (response.statusCode == 200) {
        if (response.body.trim().isEmpty) {
          print('🔴 [USER ACTIVITY IP LIST] Response body is EMPTY!');
          if (mounted) {
            setState(() {
              _feedbacks = [];
              _isLoading = false;
            });
          }
          return;
        }

        try {
          final decoded = jsonDecode(response.body);
          print('🟢 [USER ACTIVITY IP LIST] Decoded Response Type: ${decoded.runtimeType}');
          print('🟢 [USER ACTIVITY IP LIST] Decoded Response: $decoded');
          
          List<dynamic>? feedbacksList;
          
          if (decoded is List) {
            feedbacksList = decoded;
            print('🟢 [USER ACTIVITY IP LIST] ✅ Response is directly a List: ${feedbacksList.length} items');
          } else if (decoded is Map<String, dynamic>) {
            print('🟢 [USER ACTIVITY IP LIST] Response is Map. Keys: ${decoded.keys.toList()}');
            
            if (decoded.containsKey('data') && decoded['data'] is List) {
              feedbacksList = decoded['data'] as List<dynamic>;
              print('🟢 [USER ACTIVITY IP LIST] ✅ Found data key (List): ${feedbacksList.length} items');
            } else if (decoded.containsKey('ip_feedbacks') && decoded['ip_feedbacks'] is List) {
              feedbacksList = decoded['ip_feedbacks'] as List<dynamic>;
              print('🟢 [USER ACTIVITY IP LIST] ✅ Found ip_feedbacks key: ${feedbacksList.length} items');
            } else if (decoded.containsKey('list') && decoded['list'] is List) {
              feedbacksList = decoded['list'] as List<dynamic>;
              print('🟢 [USER ACTIVITY IP LIST] ✅ Found list key: ${feedbacksList.length} items');
            } else {
              // Search all keys for list data
              for (var key in decoded.keys) {
                final value = decoded[key];
                if (value is List && value.isNotEmpty) {
                  final firstItem = value[0];
                  if (firstItem is Map) {
                    final itemKeys = (firstItem as Map).keys.toList();
                    if (itemKeys.any((k) => ['patient_id', 'uhid', 'patient_name', 'ward', 'bed_no', 'patinet'].contains(k.toString().toLowerCase()))) {
                      feedbacksList = value;
                      print('🟢 [USER ACTIVITY IP LIST] ✅ Found list in key "$key": ${feedbacksList.length} items');
                      break;
                    }
                  }
                }
              }
            }
          }

          final finalList = feedbacksList ?? [];
          print('🟢 [USER ACTIVITY IP LIST] Final list length: ${finalList.length}');

          if (finalList.isNotEmpty) {
            final firstItem = finalList[0] as Map<String, dynamic>;
            print('🟢 [USER ACTIVITY IP LIST] Sample first item keys: ${firstItem.keys.toList()}');
            print('🟢 [USER ACTIVITY IP LIST] Sample first item: ${firstItem}');
            
            // Log specific fields to verify structure
            print('🟢 [USER ACTIVITY IP LIST] ========================================');
            print('🟢 [USER ACTIVITY IP LIST] FIELD MAPPING VERIFICATION:');
            print('🟢 [USER ACTIVITY IP LIST]   patientid: ${firstItem['patientid']}');
            print('🟢 [USER ACTIVITY IP LIST]   dataset: ${firstItem['dataset']}');
            if (firstItem.containsKey('dataset') && firstItem['dataset'] is Map) {
              final dataset = firstItem['dataset'] as Map;
              print('🟢 [USER ACTIVITY IP LIST]   dataset.name: ${dataset['name']}');
            }
            print('🟢 [USER ACTIVITY IP LIST]   ward: ${firstItem['ward']}');
            print('🟢 [USER ACTIVITY IP LIST]   bed_no: ${firstItem['bed_no']}');
            print('🟢 [USER ACTIVITY IP LIST]   datetime: ${firstItem['datetime']}');
            print('🟢 [USER ACTIVITY IP LIST] ========================================');
          }

          if (mounted) {
            setState(() {
              _feedbacks = finalList.map((item) {
                if (item is Map<String, dynamic>) {
                  return item;
                } else {
                  return {'raw': item.toString()};
                }
              }).toList();
              _isLoading = false;
            });
            
            print('🟢 [USER ACTIVITY IP LIST] ✅ State updated. _feedbacks.length = ${_feedbacks.length}');
          }
        } catch (e) {
          print('🔴 [USER ACTIVITY IP LIST] ❌ JSON Parse Error: $e');
          print('🔴 [USER ACTIVITY IP LIST] Response body that failed to parse: ${response.body}');
          if (mounted) {
            setState(() {
              _errorMessage = 'Failed to parse API response: $e';
              _isLoading = false;
            });
          }
        }
      } else {
        print('🔴 [USER ACTIVITY IP LIST] API error: ${response.statusCode} - ${response.body}');
        if (mounted) {
          setState(() {
            _errorMessage = 'API error: ${response.statusCode}';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('🔴 [USER ACTIVITY IP LIST] ❌ Error: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Error: $e';
          _isLoading = false;
        });
      }
    }
  }

  /// Format date time for display
  String _formatDateTime(dynamic dateTime) {
    if (dateTime == null) return 'N/A';
    
    try {
      // Try parsing as DateTime string
      if (dateTime is String) {
        // Try common formats
        try {
          final dt = DateTime.parse(dateTime);
          return DateFormat('dd-MM-yyyy HH:mm').format(dt);
        } catch (_) {
          // If parsing fails, return as is
          return dateTime.toString();
        }
      }
      return dateTime.toString();
    } catch (e) {
      return dateTime.toString();
    }
  }

  /// Get field value safely
  String _getField(Map<String, dynamic> item, String key, {String defaultValue = 'N/A'}) {
    final value = item[key] ?? item[key.toLowerCase()] ?? item[key.toUpperCase()];
    if (value == null || value.toString().trim().isEmpty) {
      return defaultValue;
    }
    return value.toString();
  }

  /// Get Patient UHID from patientid field (matches Cordova: feedback.patientid)
  String _getPatientUhid(Map<String, dynamic> item) {
    final uhid = item['patientid'] ?? item['patient_id'] ?? item['uhid'];
    if (uhid == null || uhid.toString().trim().isEmpty) {
      return 'N/A';
    }
    return uhid.toString();
  }

  /// Get Patient Name from dataset.name (matches Cordova: feedback.dataset.name)
  String _getPatientName(Map<String, dynamic> item) {
    // Check nested dataset.name structure (matches Cordova)
    if (item.containsKey('dataset') && item['dataset'] is Map) {
      final dataset = item['dataset'] as Map<String, dynamic>;
      final name = dataset['name'] ?? dataset['Name'] ?? dataset['NAME'];
      if (name != null && name.toString().trim().isNotEmpty) {
        return name.toString();
      }
    }
    
    // Fallback to direct patient_name if dataset.name doesn't exist
    final name = item['patient_name'] ?? item['patientName'] ?? item['name'];
    if (name != null && name.toString().trim().isNotEmpty) {
      return name.toString();
    }
    
    return 'N/A';
  }

  @override
  Widget build(BuildContext context) {
    return AppHeaderWrapper(
      title: 'ALL IP FEEDBACKS',
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red[700], fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => _fetchFeedbacks(forceRefresh: true),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _feedbacks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'No Feedbacks Found',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => _fetchFeedbacks(forceRefresh: true),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _feedbacks.length,
                          itemBuilder: (context, index) {
                            final feedback = _feedbacks[index];
                            
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Patient UHID (from patientid - matches Cordova: feedback.patientid)
                                    Row(
                                      children: [
                                        Icon(Icons.badge_outlined, size: 16, color: Colors.grey[600]),
                                        const SizedBox(width: 8),
                                        Text(
                                          'UHID: ${_getPatientUhid(feedback)}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    
                                    // Patient Name (from dataset.name - matches Cordova: feedback.dataset.name)
                                    Row(
                                      children: [
                                        Icon(Icons.person_outline, size: 16, color: Colors.grey[600]),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _getPatientName(feedback),
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    
                                    // Floor / Ward
                                    Row(
                                      children: [
                                        Icon(Icons.location_on_outlined, size: 16, color: Colors.grey[600]),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Ward: ${_getField(feedback, 'ward')}',
                                            style: const TextStyle(fontSize: 13),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    
                                    // Room / Bed No
                                    Row(
                                      children: [
                                        Icon(Icons.bed_outlined, size: 16, color: Colors.grey[600]),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Bed: ${_getField(feedback, 'bed_no')}',
                                            style: const TextStyle(fontSize: 13),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    
                                    // Date & Time
                                    Row(
                                      children: [
                                        Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _formatDateTime(feedback['date'] ?? feedback['datetime'] ?? feedback['created_at']),
                                            style: const TextStyle(fontSize: 13),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
      ),
    );
  }
}
