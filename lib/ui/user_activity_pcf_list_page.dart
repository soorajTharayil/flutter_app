import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../widgets/app_header_wrapper.dart';
import '../config/constant.dart';

/// User Activity PCF (Patient Complaints) List Page
/// Uses API: GET view/user_activity_pcf/all/{userId}
/// Displays ALL Patient Complaint records for the user (no date filtering)
class UserActivityPcfListPage extends StatefulWidget {
  final String userId;
  final String tdate; // older date (start)
  final String fdate; // newer date (end)

  const UserActivityPcfListPage({
    Key? key,
    required this.userId,
    required this.tdate,
    required this.fdate,
  }) : super(key: key);

  @override
  State<UserActivityPcfListPage> createState() => _UserActivityPcfListPageState();
}

class _UserActivityPcfListPageState extends State<UserActivityPcfListPage> {
  List<Map<String, dynamic>> _complaints = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchComplaints();
  }

  /// Fetch PCF complaints from User Activity API
  /// API: GET view/user_activity_pcf/all/{userId}
  Future<void> _fetchComplaints({bool forceRefresh = false}) async {
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

      // Call User Activity API: view/user_activity_pcf/all/{userId}?tdate=YYYY-MM-DD&fdate=YYYY-MM-DD
      final apiUrl = 'https://$domain.efeedor.com/view/user_activity_pcf/all/${widget.userId}?tdate=${widget.tdate}&fdate=${widget.fdate}';
      final uri = Uri.parse(apiUrl);

      print('🔵 [USER ACTIVITY PCF LIST] ========================================');
      print('🔵 [USER ACTIVITY PCF LIST] Calling User Activity API');
      print('🔵 [USER ACTIVITY PCF LIST] API: view/user_activity_pcf/all/{userId}');
      print('🔵 [USER ACTIVITY PCF LIST] URL: $apiUrl');
      print('🔵 [USER ACTIVITY PCF LIST] User ID: ${widget.userId}');
      print('🔵 [USER ACTIVITY PCF LIST] ========================================');

      final response = await http.get(uri).timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      print('🟢 [USER ACTIVITY PCF LIST] Response Status: ${response.statusCode}');
      print('🟢 [USER ACTIVITY PCF LIST] Response Body: ${response.body}');

      if (response.statusCode == 200) {
        if (response.body.trim().isEmpty) {
          if (mounted) {
            setState(() {
              _complaints = [];
              _isLoading = false;
            });
          }
          return;
        }

        try {
          final decoded = jsonDecode(response.body);
          List<dynamic>? complaintsList;
          
          if (decoded is List) {
            complaintsList = decoded;
          } else if (decoded is Map<String, dynamic>) {
            if (decoded.containsKey('data') && decoded['data'] is List) {
              complaintsList = decoded['data'] as List<dynamic>;
            } else if (decoded.containsKey('pcf') && decoded['pcf'] is List) {
              complaintsList = decoded['pcf'] as List<dynamic>;
            } else if (decoded.containsKey('complaints') && decoded['complaints'] is List) {
              complaintsList = decoded['complaints'] as List<dynamic>;
            } else if (decoded.containsKey('list') && decoded['list'] is List) {
              complaintsList = decoded['list'] as List<dynamic>;
            } else {
              for (var key in decoded.keys) {
                final value = decoded[key];
                if (value is List && value.isNotEmpty) {
                  final firstItem = value[0];
                  if (firstItem is Map) {
                    final itemKeys = (firstItem as Map).keys.toList();
                    if (itemKeys.any((k) => ['patient_id', 'uhid', 'patient_name', 'complaint'].contains(k.toString().toLowerCase()))) {
                      complaintsList = value;
                      break;
                    }
                  }
                }
              }
            }
          }

          final finalList = complaintsList ?? [];

          if (finalList.isNotEmpty) {
            final firstItem = finalList[0] as Map<String, dynamic>;
            print('🟢 [USER ACTIVITY PCF LIST] Sample first item keys: ${firstItem.keys.toList()}');
            print('🟢 [USER ACTIVITY PCF LIST] Sample first item: ${firstItem}');
            
            // Log specific fields to verify structure
            print('🟢 [USER ACTIVITY PCF LIST] ========================================');
            print('🟢 [USER ACTIVITY PCF LIST] FIELD MAPPING VERIFICATION:');
            print('🟢 [USER ACTIVITY PCF LIST]   patientid: ${firstItem['patientid']}');
            print('🟢 [USER ACTIVITY PCF LIST]   dataset: ${firstItem['dataset']}');
            if (firstItem.containsKey('dataset') && firstItem['dataset'] is Map) {
              final dataset = firstItem['dataset'] as Map;
              print('🟢 [USER ACTIVITY PCF LIST]   dataset.name: ${dataset['name']}');
            }
            print('🟢 [USER ACTIVITY PCF LIST]   datetime: ${firstItem['datetime']}');
            print('🟢 [USER ACTIVITY PCF LIST] ========================================');
          }

          if (mounted) {
            setState(() {
              _complaints = finalList.map((item) {
                if (item is Map<String, dynamic>) {
                  return item;
                } else {
                  return {'raw': item.toString()};
                }
              }).toList();
              _isLoading = false;
            });
          }
        } catch (e) {
          if (mounted) {
            setState(() {
              _errorMessage = 'Failed to parse API response: $e';
              _isLoading = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'API error: ${response.statusCode}';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error: $e';
          _isLoading = false;
        });
      }
    }
  }

  String _formatDateTime(dynamic dateTime) {
    if (dateTime == null) return 'N/A';
    try {
      if (dateTime is String) {
        try {
          final dt = DateTime.parse(dateTime);
          return DateFormat('dd-MM-yyyy HH:mm').format(dt);
        } catch (_) {
          return dateTime.toString();
        }
      }
      return dateTime.toString();
    } catch (e) {
      return dateTime.toString();
    }
  }

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
      title: 'ALL PATIENT COMPLAINTS',
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
                          onPressed: () => _fetchComplaints(forceRefresh: true),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _complaints.isEmpty
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
                        onRefresh: () => _fetchComplaints(forceRefresh: true),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _complaints.length,
                          itemBuilder: (context, index) {
                            final complaint = _complaints[index];
                            
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
                                          'UHID: ${_getPatientUhid(complaint)}',
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
                                            _getPatientName(complaint),
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _formatDateTime(complaint['date'] ?? complaint['datetime'] ?? complaint['created_at']),
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
