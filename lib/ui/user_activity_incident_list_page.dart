import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../widgets/app_header_wrapper.dart';
import '../config/constant.dart';

/// User Activity Incident List Page
/// Uses API: GET view/user_activity_incident/{status}/{userId}
/// Status options: all, open, assigne, close
/// Displays incidents based on selected status
class UserActivityIncidentListPage extends StatefulWidget {
  final String userId;
  final String status; // 'all', 'open', 'assigne', 'close'
  final String tdate; // older date (start)
  final String fdate; // newer date (end)

  const UserActivityIncidentListPage({
    Key? key,
    required this.userId,
    required this.status,
    required this.tdate,
    required this.fdate,
  }) : super(key: key);

  @override
  State<UserActivityIncidentListPage> createState() => _UserActivityIncidentListPageState();
}

class _UserActivityIncidentListPageState extends State<UserActivityIncidentListPage> {
  List<Map<String, dynamic>> _incidents = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchIncidents();
  }

  /// Get page title based on status
  String _getPageTitle() {
    switch (widget.status) {
      case 'all':
        return 'ALL INCIDENTS';
      case 'open':
        return 'UNADDRESSED INCIDENTS';
      case 'assigne':
        return 'ASSIGNED INCIDENTS';
      case 'close':
        return 'CLOSED INCIDENTS';
      default:
        return 'INCIDENTS';
    }
  }

  /// Get API URL based on status
  /// Routes: view/user_activity_incident/{status}/{userId}?tdate=YYYY-MM-DD&fdate=YYYY-MM-DD
  String _getApiUrl(String domain, String userId, String status, String tdate, String fdate) {
    return 'https://$domain.efeedor.com/view/user_activity_incident/$status/$userId?tdate=$tdate&fdate=$fdate';
  }

  /// Fetch incidents from User Activity API
  /// API: GET view/user_activity_incident/{status}/{userId}
  Future<void> _fetchIncidents({bool forceRefresh = false}) async {
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

      // Get API URL based on status with date parameters
      final apiUrl = _getApiUrl(domain, widget.userId, widget.status, widget.tdate, widget.fdate);
      final uri = Uri.parse(apiUrl);

      print('🔵 [USER ACTIVITY INCIDENT LIST] ========================================');
      print('🔵 [USER ACTIVITY INCIDENT LIST] Calling User Activity API');
      print('🔵 [USER ACTIVITY INCIDENT LIST] Status: ${widget.status}');
      print('🔵 [USER ACTIVITY INCIDENT LIST] API: view/user_activity_incident/${widget.status}/{userId}?tdate=...&fdate=...');
      print('🔵 [USER ACTIVITY INCIDENT LIST] URL: $apiUrl');
      print('🔵 [USER ACTIVITY INCIDENT LIST] User ID: ${widget.userId}');
      print('🔵 [USER ACTIVITY INCIDENT LIST] tdate (older): ${widget.tdate}');
      print('🔵 [USER ACTIVITY INCIDENT LIST] fdate (newer): ${widget.fdate}');
      print('🔵 [USER ACTIVITY INCIDENT LIST] ========================================');

      final response = await http.get(uri).timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      print('🟢 [USER ACTIVITY INCIDENT LIST] Response Status: ${response.statusCode}');
      print('🟢 [USER ACTIVITY INCIDENT LIST] Response Body Length: ${response.body.length}');
      print('🟢 [USER ACTIVITY INCIDENT LIST] Full Response Body:');
      print(response.body);
      print('🟢 [USER ACTIVITY INCIDENT LIST] ========================================');

      if (response.statusCode == 200) {
        if (response.body.trim().isEmpty) {
          print('🔴 [USER ACTIVITY INCIDENT LIST] Response body is EMPTY!');
          if (mounted) {
            setState(() {
              _incidents = [];
              _isLoading = false;
            });
          }
          return;
        }

        try {
          final decoded = jsonDecode(response.body);
          print('🟢 [USER ACTIVITY INCIDENT LIST] Decoded Response Type: ${decoded.runtimeType}');
          print('🟢 [USER ACTIVITY INCIDENT LIST] Decoded Response: $decoded');
          
          List<dynamic>? incidentsList;
          
          if (decoded is List) {
            incidentsList = decoded;
            print('🟢 [USER ACTIVITY INCIDENT LIST] ✅ Response is directly a List: ${incidentsList.length} items');
          } else if (decoded is Map<String, dynamic>) {
            print('🟢 [USER ACTIVITY INCIDENT LIST] Response is Map. Keys: ${decoded.keys.toList()}');
            
            if (decoded.containsKey('data') && decoded['data'] is List) {
              incidentsList = decoded['data'] as List<dynamic>;
              print('🟢 [USER ACTIVITY INCIDENT LIST] ✅ Found data key (List): ${incidentsList.length} items');
            } else if (decoded.containsKey('incidents') && decoded['incidents'] is List) {
              incidentsList = decoded['incidents'] as List<dynamic>;
              print('🟢 [USER ACTIVITY INCIDENT LIST] ✅ Found incidents key: ${incidentsList.length} items');
            } else if (decoded.containsKey('list') && decoded['list'] is List) {
              incidentsList = decoded['list'] as List<dynamic>;
              print('🟢 [USER ACTIVITY INCIDENT LIST] ✅ Found list key: ${incidentsList.length} items');
            } else {
              // Search all keys for list data
              for (var key in decoded.keys) {
                final value = decoded[key];
                if (value is List && value.isNotEmpty) {
                  final firstItem = value[0];
                  if (firstItem is Map) {
                    final itemKeys = (firstItem as Map).keys.toList();
                    if (itemKeys.any((k) => ['incident_id', 'ticket_id', 'category', 'status'].contains(k.toString().toLowerCase()))) {
                      incidentsList = value;
                      print('🟢 [USER ACTIVITY INCIDENT LIST] ✅ Found list in key "$key": ${incidentsList.length} items');
                      break;
                    }
                  }
                }
              }
            }
          }

          final finalList = incidentsList ?? [];
          print('🟢 [USER ACTIVITY INCIDENT LIST] Final list length: ${finalList.length}');

          if (finalList.isNotEmpty) {
            final firstItem = finalList[0] as Map<String, dynamic>;
            print('🟢 [USER ACTIVITY INCIDENT LIST] Sample first item keys: ${firstItem.keys.toList()}');
            print('🟢 [USER ACTIVITY INCIDENT LIST] Sample first item: ${firstItem}');
            debugPrint('ITEM RAW: ${firstItem}');
            debugPrint('DEPARTMENT: ${firstItem["department"]}');
            debugPrint('PATINET: ${firstItem["patinet"]}');
          }

          if (mounted) {
            setState(() {
              _incidents = finalList.map((item) {
                if (item is Map<String, dynamic>) {
                  return item;
                } else {
                  return {'raw': item.toString()};
                }
              }).toList();
              _isLoading = false;
            });
            
            print('🟢 [USER ACTIVITY INCIDENT LIST] ✅ State updated. _incidents.length = ${_incidents.length}');
          }
        } catch (e) {
          print('🔴 [USER ACTIVITY INCIDENT LIST] ❌ JSON Parse Error: $e');
          print('🔴 [USER ACTIVITY INCIDENT LIST] Response body that failed to parse: ${response.body}');
          if (mounted) {
            setState(() {
              _errorMessage = 'Failed to parse API response: $e';
              _isLoading = false;
            });
          }
        }
      } else {
        print('🔴 [USER ACTIVITY INCIDENT LIST] API error: ${response.statusCode} - ${response.body}');
        if (mounted) {
          setState(() {
            _errorMessage = 'API error: ${response.statusCode}';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('🔴 [USER ACTIVITY INCIDENT LIST] ❌ Error: $e');
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

  /// Get field value safely
  String _getField(Map<String, dynamic> item, String key, {String defaultValue = 'N/A'}) {
    final value = item[key] ?? item[key.toLowerCase()] ?? item[key.toUpperCase()];
    if (value == null || value.toString().trim().isEmpty) {
      return defaultValue;
    }
    return value.toString();
  }

  /// Get Incident ID from item
  /// Format: "INC-" + item.id
  String _getIncidentId(Map<String, dynamic> item) {
    final id = item['id'];
    if (id == null || id.toString().trim().isEmpty) {
      return 'N/A';
    }
    return 'INC-${id.toString()}';
  }

  /// Get Reported By from item
  /// Format: item.patinet.name + " (" + item.patinet.patient_id + ")"
  String _getReportedBy(Map<String, dynamic> item) {
    if (item.containsKey('patinet') && item['patinet'] is Map) {
      final patinet = item['patinet'] as Map<String, dynamic>;
      final name = patinet['name'];
      final patientId = patinet['patient_id'];
      
      if (name != null && name.toString().trim().isNotEmpty) {
        if (patientId != null && patientId.toString().trim().isNotEmpty) {
          return '${name.toString().trim()} (${patientId.toString().trim()})';
        }
        return name.toString().trim();
      }
    }
    return 'N/A';
  }

  /// Get Incident title from item
  /// Source: item.department.name
  String _getIncidentTitle(Map<String, dynamic> item) {
    if (item.containsKey('department') && item['department'] is Map) {
      final department = item['department'] as Map<String, dynamic>;
      final name = department['name'];
      if (name != null && name.toString().trim().isNotEmpty) {
        return name.toString();
      }
    }
    return 'N/A';
  }

  /// Get Category from item
  /// Source: item.department.description
  String _getCategory(Map<String, dynamic> item) {
    if (item.containsKey('department') && item['department'] is Map) {
      final department = item['department'] as Map<String, dynamic>;
      final description = department['description'];
      if (description != null && description.toString().trim().isNotEmpty) {
        return description.toString();
      }
    }
    return 'N/A';
  }

  /// Get Assigned To from item
  /// Source: item.assign_to_name ?? "-"
  String _getAssignedTo(Map<String, dynamic> item) {
    final assignedTo = item['assign_to_name'];
    if (assignedTo == null || assignedTo.toString().trim().isEmpty) {
      return '-';
    }
    return assignedTo.toString().trim();
  }

  /// Get Severity from item
  /// Source: item.incident_type
  String _getSeverity(Map<String, dynamic> item) {
    final incidentType = item['incident_type'];
    if (incidentType == null || incidentType.toString().trim().isEmpty) {
      return 'N/A';
    }
    return incidentType.toString();
  }

  /// Get Priority from item
  /// Source: item.priority
  String _getPriority(Map<String, dynamic> item) {
    final priority = item['priority'];
    if (priority == null || priority.toString().trim().isEmpty) {
      return 'N/A';
    }
    return priority.toString();
  }

  /// Get Status from item
  /// Source: item.status
  String _getStatus(Map<String, dynamic> item) {
    final status = item['status'];
    if (status == null || status.toString().trim().isEmpty) {
      return 'N/A';
    }
    return status.toString();
  }

  /// Get Reported On from item
  /// Source: item.created_on
  String _getReportedOn(Map<String, dynamic> item) {
    final createdOn = item['created_on'];
    if (createdOn == null) {
      return 'N/A';
    }
    return _formatDateTime(createdOn);
  }

  @override
  Widget build(BuildContext context) {
    return AppHeaderWrapper(
      title: _getPageTitle(),
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
                          onPressed: () => _fetchIncidents(forceRefresh: true),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _incidents.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'No Incidents Found',
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
                        onRefresh: () => _fetchIncidents(forceRefresh: true),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _incidents.length,
                          itemBuilder: (context, index) {
                            final incident = _incidents[index];
                            
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
                                    // Incident ID
                                    Row(
                                      children: [
                                        Icon(Icons.tag_outlined, size: 16, color: Colors.grey[600]),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Incident ID: ${_getIncidentId(incident)}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    
                                    // Reported by
                                    Row(
                                      children: [
                                        Icon(Icons.person_outline, size: 16, color: Colors.grey[600]),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Reported by: ${_getReportedBy(incident)}',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    
                                    // Incident
                                    Row(
                                      children: [
                                        Icon(Icons.description_outlined, size: 16, color: Colors.grey[600]),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Incident: ${_getIncidentTitle(incident)}',
                                            style: const TextStyle(fontSize: 13),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    
                                    // Category
                                    Row(
                                      children: [
                                        Icon(Icons.category_outlined, size: 16, color: Colors.grey[600]),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Category: ${_getCategory(incident)}',
                                            style: const TextStyle(fontSize: 13),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    
                                    // Assigned To
                                    Row(
                                      children: [
                                        Icon(Icons.assignment_ind_outlined, size: 16, color: Colors.grey[600]),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Assigned To: ${_getAssignedTo(incident)}',
                                            style: const TextStyle(fontSize: 13),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    
                                    // Severity
                                    Row(
                                      children: [
                                        Icon(Icons.warning_outlined, size: 16, color: Colors.grey[600]),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Severity: ${_getSeverity(incident)}',
                                            style: const TextStyle(fontSize: 13),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    
                                    // Priority
                                    Row(
                                      children: [
                                        Icon(Icons.priority_high_outlined, size: 16, color: Colors.grey[600]),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Priority: ${_getPriority(incident)}',
                                            style: const TextStyle(fontSize: 13),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    
                                    // Status
                                    Row(
                                      children: [
                                        Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Status: ${_getStatus(incident)}',
                                            style: const TextStyle(fontSize: 13),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    
                                    // Reported on
                                    Row(
                                      children: [
                                        Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Reported on: ${_getReportedOn(incident)}',
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
