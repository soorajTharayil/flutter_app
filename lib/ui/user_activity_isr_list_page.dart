import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../widgets/app_header_wrapper.dart';
import '../config/constant.dart';

/// User Activity ISR (Internal Service Requests) List Page
/// Uses API: GET view/user_activity_isr/{status}/{userId}
/// Status options: all, open, assigne, close
/// Displays ISR requests based on selected status
class UserActivityIsrListPage extends StatefulWidget {
  final String userId;
  final String status; // 'all', 'open', 'assigne', 'close'
  final String tdate; // older date (start)
  final String fdate; // newer date (end)

  const UserActivityIsrListPage({
    Key? key,
    required this.userId,
    required this.status,
    required this.tdate,
    required this.fdate,
  }) : super(key: key);

  @override
  State<UserActivityIsrListPage> createState() => _UserActivityIsrListPageState();
}

class _UserActivityIsrListPageState extends State<UserActivityIsrListPage> {
  List<Map<String, dynamic>> _requests = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  /// Get page title based on status
  String _getPageTitle() {
    switch (widget.status) {
      case 'all':
        return 'ALL ISR REQUESTS';
      case 'open':
        return 'UNADDRESSED ISR REQUESTS';
      case 'assigne':
        return 'ASSIGNED ISR REQUESTS';
      case 'close':
        return 'RESOLVED ISR REQUESTS';
      default:
        return 'ISR REQUESTS';
    }
  }

  /// Get API URL based on status
  /// Routes: view/user_activity_isr/{status}/{userId}?tdate=YYYY-MM-DD&fdate=YYYY-MM-DD
  String _getApiUrl(String domain, String userId, String status, String tdate, String fdate) {
    String baseUrl;
    switch (status) {
      case 'all':
        baseUrl = 'https://$domain.efeedor.com/view/user_activity_isr/all/$userId';
        break;
      case 'open':
        baseUrl = 'https://$domain.efeedor.com/view/user_activity_isr/open/$userId';
        break;
      case 'assigne':
        baseUrl = 'https://$domain.efeedor.com/view/user_activity_isr/assigne/$userId';
        break;
      case 'close':
        baseUrl = 'https://$domain.efeedor.com/view/user_activity_isr/close/$userId';
        break;
      default:
        baseUrl = 'https://$domain.efeedor.com/view/user_activity_isr/all/$userId';
    }
    return '$baseUrl?tdate=$tdate&fdate=$fdate';
  }

  /// Fetch ISR requests from User Activity API
  /// API: GET view/user_activity_isr/{status}/{userId}
  Future<void> _fetchRequests({bool forceRefresh = false}) async {
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

      print('🔵 [USER ACTIVITY ISR LIST] ========================================');
      print('🔵 [USER ACTIVITY ISR LIST] Calling User Activity API');
      print('🔵 [USER ACTIVITY ISR LIST] Status: ${widget.status}');
      print('🔵 [USER ACTIVITY ISR LIST] API: view/user_activity_isr/${widget.status}/{userId}?tdate=...&fdate=...');
      print('🔵 [USER ACTIVITY ISR LIST] URL: $apiUrl');
      print('🔵 [USER ACTIVITY ISR LIST] User ID: ${widget.userId}');
      print('🔵 [USER ACTIVITY ISR LIST] tdate (older): ${widget.tdate}');
      print('🔵 [USER ACTIVITY ISR LIST] fdate (newer): ${widget.fdate}');
      print('🔵 [USER ACTIVITY ISR LIST] ========================================');

      final response = await http.get(uri).timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      print('🟢 [USER ACTIVITY ISR LIST] Response Status: ${response.statusCode}');
      print('🟢 [USER ACTIVITY ISR LIST] Response Body Length: ${response.body.length}');
      print('🟢 [USER ACTIVITY ISR LIST] Full Response Body:');
      print(response.body);
      print('🟢 [USER ACTIVITY ISR LIST] ========================================');

      if (response.statusCode == 200) {
        if (response.body.trim().isEmpty) {
          print('🔴 [USER ACTIVITY ISR LIST] Response body is EMPTY!');
          if (mounted) {
            setState(() {
              _requests = [];
              _isLoading = false;
            });
          }
          return;
        }

        try {
          final decoded = jsonDecode(response.body);
          print('🟢 [USER ACTIVITY ISR LIST] Decoded Response Type: ${decoded.runtimeType}');
          print('🟢 [USER ACTIVITY ISR LIST] Decoded Response: $decoded');
          
          List<dynamic>? requestsList;
          
          if (decoded is List) {
            requestsList = decoded;
            print('🟢 [USER ACTIVITY ISR LIST] ✅ Response is directly a List: ${requestsList.length} items');
          } else if (decoded is Map<String, dynamic>) {
            print('🟢 [USER ACTIVITY ISR LIST] Response is Map. Keys: ${decoded.keys.toList()}');
            
            if (decoded.containsKey('data') && decoded['data'] is List) {
              requestsList = decoded['data'] as List<dynamic>;
              print('🟢 [USER ACTIVITY ISR LIST] ✅ Found data key (List): ${requestsList.length} items');
            } else if (decoded.containsKey('isr') && decoded['isr'] is List) {
              requestsList = decoded['isr'] as List<dynamic>;
              print('🟢 [USER ACTIVITY ISR LIST] ✅ Found isr key: ${requestsList.length} items');
            } else if (decoded.containsKey('requests') && decoded['requests'] is List) {
              requestsList = decoded['requests'] as List<dynamic>;
              print('🟢 [USER ACTIVITY ISR LIST] ✅ Found requests key: ${requestsList.length} items');
            } else if (decoded.containsKey('list') && decoded['list'] is List) {
              requestsList = decoded['list'] as List<dynamic>;
              print('🟢 [USER ACTIVITY ISR LIST] ✅ Found list key: ${requestsList.length} items');
            } else {
              // Search all keys for list data
              for (var key in decoded.keys) {
                final value = decoded[key];
                if (value is List && value.isNotEmpty) {
                  final firstItem = value[0];
                  if (firstItem is Map) {
                    final itemKeys = (firstItem as Map).keys.toList();
                    if (itemKeys.any((k) => ['request_id', 'ticket_id', 'category', 'status', 'assigned_to'].contains(k.toString().toLowerCase()))) {
                      requestsList = value;
                      print('🟢 [USER ACTIVITY ISR LIST] ✅ Found list in key "$key": ${requestsList.length} items');
                      break;
                    }
                  }
                }
              }
            }
          }

          final finalList = requestsList ?? [];
          print('🟢 [USER ACTIVITY ISR LIST] Final list length: ${finalList.length}');

          if (finalList.isNotEmpty) {
            final firstItem = finalList[0] as Map<String, dynamic>;
            print('🟢 [USER ACTIVITY ISR LIST] Sample first item keys: ${firstItem.keys.toList()}');
            print('🟢 [USER ACTIVITY ISR LIST] Sample first item: ${firstItem}');
            debugPrint('ITEM RAW: ${firstItem}');
            debugPrint('DEPARTMENT: ${firstItem["department"]}');
            debugPrint('PATINET: ${firstItem["patinet"]}');
            
            // Log specific fields to verify structure - using exact API keys
            print('🟢 [USER ACTIVITY ISR LIST] ========================================');
            print('🟢 [USER ACTIVITY ISR LIST] FIELD MAPPING VERIFICATION:');
            print('🟢 [USER ACTIVITY ISR LIST] All keys in first item: ${firstItem.keys.toList()}');
            print('🟢 [USER ACTIVITY ISR LIST]');
            print('🟢 [USER ACTIVITY ISR LIST] Request ID (API key: requestid):');
            print('🟢 [USER ACTIVITY ISR LIST]   requestid: ${firstItem['requestid']}');
            print('🟢 [USER ACTIVITY ISR LIST]');
            print('🟢 [USER ACTIVITY ISR LIST] Category (API key: department.description):');
            print('🟢 [USER ACTIVITY ISR LIST]   department: ${firstItem['department']}');
            if (firstItem.containsKey('department') && firstItem['department'] is Map) {
              final dept = firstItem['department'] as Map;
              print('🟢 [USER ACTIVITY ISR LIST]   department.description: ${dept['description']}');
              print('🟢 [USER ACTIVITY ISR LIST]   department.name: ${dept['name']}');
            }
            print('🟢 [USER ACTIVITY ISR LIST]');
            print('🟢 [USER ACTIVITY ISR LIST] Assigned To (API key: assign_to_name):');
            print('🟢 [USER ACTIVITY ISR LIST]   assign_to_name: ${firstItem['assign_to_name']}');
            print('🟢 [USER ACTIVITY ISR LIST]');
            print('🟢 [USER ACTIVITY ISR LIST] Status (API key: status):');
            print('🟢 [USER ACTIVITY ISR LIST]   status: ${firstItem['status']}');
            print('🟢 [USER ACTIVITY ISR LIST]');
            print('🟢 [USER ACTIVITY ISR LIST] Date/Time (API key: lastmodified):');
            print('🟢 [USER ACTIVITY ISR LIST]   lastmodified: ${firstItem['lastmodified']}');
            print('🟢 [USER ACTIVITY ISR LIST] ========================================');
          }

          if (mounted) {
            setState(() {
              _requests = finalList.map((item) {
                if (item is Map<String, dynamic>) {
                  return item;
                } else {
                  return {'raw': item.toString()};
                }
              }).toList();
              _isLoading = false;
            });
            
            print('🟢 [USER ACTIVITY ISR LIST] ✅ State updated. _requests.length = ${_requests.length}');
          }
        } catch (e) {
          print('🔴 [USER ACTIVITY ISR LIST] ❌ JSON Parse Error: $e');
          print('🔴 [USER ACTIVITY ISR LIST] Response body that failed to parse: ${response.body}');
          if (mounted) {
            setState(() {
              _errorMessage = 'Failed to parse API response: $e';
              _isLoading = false;
            });
          }
        }
      } else {
        print('🔴 [USER ACTIVITY ISR LIST] API error: ${response.statusCode} - ${response.body}');
        if (mounted) {
          setState(() {
            _errorMessage = 'API error: ${response.statusCode}';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('🔴 [USER ACTIVITY ISR LIST] ❌ Error: $e');
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

  /// Get Request ID from ISR item (matches API response structure)
  /// Format: "ISR-" + item.id
  String _getRequestId(Map<String, dynamic> item) {
    final id = item['id'];
    if (id == null || id.toString().trim().isEmpty) {
      return 'N/A';
    }
    return 'ISR-${id.toString()}';
  }

  /// Get Service Request title from ISR item
  /// Source: item.department.name
  String _getServiceRequest(Map<String, dynamic> item) {
    if (item.containsKey('department') && item['department'] is Map) {
      final department = item['department'] as Map<String, dynamic>;
      final name = department['name'];
      if (name != null && name.toString().trim().isNotEmpty) {
        return name.toString();
      }
    }
    return 'N/A';
  }

  /// Get Category from ISR item
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

  /// Get Raised By from ISR item
  /// Format: item.patinet.name + " (" + item.patinet.patient_id + ")"
  String _getRaisedBy(Map<String, dynamic> item) {
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

  /// Get Assigned To from ISR item
  /// Source: item.assign_to_name ?? "-"
  String _getAssignedTo(Map<String, dynamic> item) {
    final assignedTo = item['assign_to_name'];
    if (assignedTo == null || assignedTo.toString().trim().isEmpty) {
      return '-';
    }
    return assignedTo.toString().trim();
  }

  /// Get Status from ISR item (matches API response structure)
  String _getStatus(Map<String, dynamic> item) {
    // Status is already working, but ensure we handle all variations
    final status = item['status'] ?? 
                   item['Status'] ?? 
                   item['STATUS'] ??
                   item['state'];
    
    if (status == null || status.toString().trim().isEmpty) {
      return 'N/A';
    }
    return status.toString();
  }

  /// Get status color for User Activity Dashboard
  /// Local method - only used in this screen
  Color _getStatusColor(String status) {
    if (status == null || status.toString().trim().isEmpty || status == 'N/A') {
      return Colors.grey;
    }
    
    final statusUpper = status.toString().toUpperCase().trim();
    
    switch (statusUpper) {
      case 'OPEN':
        return Colors.red;
      case 'CLOSED':
      case 'CLOSE':
        return Colors.green;
      case 'ADDRESSED':
      case 'ASSIGNE':
        return Colors.orange;
      case 'TRANSFERRED':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  /// Get Reported On from ISR item
  /// Source: item.created_on
  String _getReportedOn(Map<String, dynamic> item) {
    final createdOn = item['created_on'];
    if (createdOn == null) {
      return 'N/A';
    }
    return _formatDateTime(createdOn);
  }

  /// Get Updated On from ISR item
  /// Source: item.last_modified
  String _getUpdatedOn(Map<String, dynamic> item) {
    final lastModified = item['last_modified'];
    if (lastModified == null) {
      return 'N/A';
    }
    return _formatDateTime(lastModified);
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
                          onPressed: () => _fetchRequests(forceRefresh: true),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _requests.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'No Requests Found',
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
                        onRefresh: () => _fetchRequests(forceRefresh: true),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _requests.length,
                          itemBuilder: (context, index) {
                            final request = _requests[index];
                            
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
                                    // Request ID
                                    Row(
                                      children: [
                                        Icon(Icons.tag_outlined, size: 16, color: Colors.grey[600]),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Request ID: ${_getRequestId(request)}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    
                                    // Raised by
                                    Row(
                                      children: [
                                        Icon(Icons.person_outline, size: 16, color: Colors.grey[600]),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Raised by: ${_getRaisedBy(request)}',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    
                                    // Service Request
                                    Row(
                                      children: [
                                        Icon(Icons.description_outlined, size: 16, color: Colors.grey[600]),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Service Request: ${_getServiceRequest(request)}',
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
                                            'Category: ${_getCategory(request)}',
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
                                            'Assigned To: ${_getAssignedTo(request)}',
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
                                          child: RichText(
                                            text: TextSpan(
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: Colors.black87,
                                              ),
                                              children: [
                                                const TextSpan(text: 'Status: '),
                                                TextSpan(
                                                  text: _getStatus(request),
                                                  style: TextStyle(
                                                    color: _getStatusColor(_getStatus(request)),
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
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
                                            'Reported on: ${_getReportedOn(request)}',
                                            style: const TextStyle(fontSize: 13),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    
                                    // Updated on
                                    Row(
                                      children: [
                                        Icon(Icons.update, size: 16, color: Colors.grey[600]),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Updated on: ${_getUpdatedOn(request)}',
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
