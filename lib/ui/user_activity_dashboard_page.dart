import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constant.dart';
import '../widgets/app_header_wrapper.dart';

/// Period options for date filtering
enum ActivityPeriod {
  today,
  previousDay,
  last24Hours,
  last7Days,
  last30Days,
  last90Days,
  currentMonth,
  previousMonth,
  last365Days,
  customDate,
}

class UserActivityDashboardPage extends StatefulWidget {
  const UserActivityDashboardPage({Key? key}) : super(key: key);

  @override
  State<UserActivityDashboardPage> createState() => _UserActivityDashboardPageState();
}

class _UserActivityDashboardPageState extends State<UserActivityDashboardPage>
    with SingleTickerProviderStateMixin {
  // State
  ActivityPeriod _selectedPeriod = ActivityPeriod.today; // Default: Today
  DateTime? _customFromDate;
  DateTime? _customToDate;
  
  bool _isLoading = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Placeholder data - will be replaced with API calls later
  int _ipDischargeFeedbacks = 0;
  int _opFeedbacks = 0;
  int _inpatientConcerns = 0;
  int _internalRequestsRaised = 0;
  int _internalRequestsUnaddressed = 0;
  int _internalRequestsAssigned = 0;
  int _internalRequestsResolved = 0;
  int _incidentsReported = 0;
  int _incidentsUnaddressed = 0;
  int _incidentsAssigned = 0;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fadeController.forward();
    _fetchActivityData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  /// Calculate date range based on selected period
  Map<String, DateTime> _getDateRange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    switch (_selectedPeriod) {
      case ActivityPeriod.today:
        return {'from': today, 'to': today};
      
      case ActivityPeriod.previousDay:
        final yesterday = today.subtract(const Duration(days: 1));
        return {'from': yesterday, 'to': yesterday};
      
      case ActivityPeriod.last24Hours:
        final last24Hours = now.subtract(const Duration(hours: 24));
        return {'from': last24Hours, 'to': now};
      
      case ActivityPeriod.last7Days:
        return {
          'from': today.subtract(const Duration(days: 7)),
          'to': today,
        };
      
      case ActivityPeriod.last30Days:
        return {
          'from': today.subtract(const Duration(days: 30)),
          'to': today,
        };
      
      case ActivityPeriod.last90Days:
        return {
          'from': today.subtract(const Duration(days: 90)),
          'to': today,
        };
      
      case ActivityPeriod.currentMonth:
        final firstDayOfMonth = DateTime(now.year, now.month, 1);
        return {'from': firstDayOfMonth, 'to': today};
      
      case ActivityPeriod.previousMonth:
        final firstDayOfPreviousMonth = DateTime(now.year, now.month - 1, 1);
        final lastDayOfPreviousMonth = DateTime(now.year, now.month, 0);
        return {'from': firstDayOfPreviousMonth, 'to': lastDayOfPreviousMonth};
      
      case ActivityPeriod.last365Days:
        return {
          'from': today.subtract(const Duration(days: 365)),
          'to': today,
        };
      
      case ActivityPeriod.customDate:
        if (_customFromDate != null && _customToDate != null) {
          return {'from': _customFromDate!, 'to': _customToDate!};
        }
        // Fallback to today if custom date not set
        return {'from': today, 'to': today};
    }
  }

  /// Format date for display
  String _formatDate(DateTime date) {
    return DateFormat('dd-MM-yyyy').format(date);
  }

  /// Get date range display text
  String _getDateRangeDisplay() {
    final dateRange = _getDateRange();
    final fromDate = dateRange['from']!;
    final toDate = dateRange['to']!;
    return 'Date range: ${_formatDate(fromDate)} - ${_formatDate(toDate)}';
  }

  /// Preload ward/department APIs on page load
  Future<void> _preloadWardDepartmentApis() async {
    try {
      // Get domain from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final domain = prefs.getString('domain') ?? '';
      final uid = prefs.getString('userid') ?? '';

      if (domain.isEmpty) {
        print('🔴 [USER ACTIVITY] Domain not found, skipping API preload');
        return;
      }

      print('🔵 [USER ACTIVITY] ========================================');
      print('🔵 [USER ACTIVITY] PRELOADING WARD/DEPARTMENT APIS');
      print('🔵 [USER ACTIVITY] Domain: $domain');
      print('🔵 [USER ACTIVITY] ========================================');

      // Call all 5 APIs in parallel for better performance
      await Future.wait([
        _callWardApi(domain, uid),
        _callDepartmentApi(domain, uid),
        _callWard2Api(domain, uid),
        _callEsrWardApi(domain, uid),
        _callIncidentWardsApi(domain, uid),
      ], eagerError: false); // Don't fail all if one fails

      print('🟢 [USER ACTIVITY] ========================================');
      print('🟢 [USER ACTIVITY] ALL API PRELOADS COMPLETED');
      print('🟢 [USER ACTIVITY] ========================================');
    } catch (e) {
      print('🔴 [USER ACTIVITY] Error during API preload: $e');
    }
  }

  /// Call ward.php API
  Future<void> _callWardApi(String domain, String uid) async {
    try {
      final apiUrl = 'https://$domain.efeedor.com/api/ward.php';
      final uri = Uri.parse(apiUrl);

      print('🔵 [USER ACTIVITY] Calling ward.php...');

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'uid': uid,
        }),
      ).timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          print('🔴 [USER ACTIVITY] ward.php timeout');
          throw Exception('Request timeout');
        },
      );

      if (response.statusCode == 200) {
        print('🟢 [USER ACTIVITY] ward.php success');
      } else {
        print('🔴 [USER ACTIVITY] ward.php failed: ${response.statusCode}');
      }
    } catch (e) {
      print('🔴 [USER ACTIVITY] ward.php error: $e');
    }
  }

  /// Call department.php API
  Future<void> _callDepartmentApi(String domain, String uid) async {
    try {
      final apiUrl = 'https://$domain.efeedor.com/api/department.php';
      final uri = Uri.parse(apiUrl);

      print('🔵 [USER ACTIVITY] Calling department.php...');

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'uid': uid,
        }),
      ).timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          print('🔴 [USER ACTIVITY] department.php timeout');
          throw Exception('Request timeout');
        },
      );

      if (response.statusCode == 200) {
        print('🟢 [USER ACTIVITY] department.php success');
      } else {
        print('🔴 [USER ACTIVITY] department.php failed: ${response.statusCode}');
      }
    } catch (e) {
      print('🔴 [USER ACTIVITY] department.php error: $e');
    }
  }

  /// Call ward2.php API
  Future<void> _callWard2Api(String domain, String uid) async {
    try {
      final apiUrl = 'https://$domain.efeedor.com/api/ward2.php';
      final uri = Uri.parse(apiUrl);

      print('🔵 [USER ACTIVITY] Calling ward2.php...');

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'uid': uid,
        }),
      ).timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          print('🔴 [USER ACTIVITY] ward2.php timeout');
          throw Exception('Request timeout');
        },
      );

      if (response.statusCode == 200) {
        print('🟢 [USER ACTIVITY] ward2.php success');
      } else {
        print('🔴 [USER ACTIVITY] ward2.php failed: ${response.statusCode}');
      }
    } catch (e) {
      print('🔴 [USER ACTIVITY] ward2.php error: $e');
    }
  }

  /// Call esr_wards.php API
  Future<void> _callEsrWardApi(String domain, String uid) async {
    try {
      final apiUrl = 'https://$domain.efeedor.com/api/esr_wards.php';
      final uri = Uri.parse(apiUrl);

      print('🔵 [USER ACTIVITY] Calling esr_wards.php...');

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'uid': uid,
        }),
      ).timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          print('🔴 [USER ACTIVITY] esr_wards.php timeout');
          throw Exception('Request timeout');
        },
      );

      if (response.statusCode == 200) {
        print('🟢 [USER ACTIVITY] esr_wards.php success');
      } else {
        print('🔴 [USER ACTIVITY] esr_wards.php failed: ${response.statusCode}');
      }
    } catch (e) {
      print('🔴 [USER ACTIVITY] esr_wards.php error: $e');
    }
  }

  /// Call incident_wards.php API
  Future<void> _callIncidentWardsApi(String domain, String uid) async {
    try {
      final apiUrl = 'https://$domain.efeedor.com/api/incident_wards.php';
      final uri = Uri.parse(apiUrl);

      print('🔵 [USER ACTIVITY] Calling incident_wards.php...');

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'uid': uid,
        }),
      ).timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          print('🔴 [USER ACTIVITY] incident_wards.php timeout');
          throw Exception('Request timeout');
        },
      );

      if (response.statusCode == 200) {
        print('🟢 [USER ACTIVITY] incident_wards.php success');
      } else {
        print('🔴 [USER ACTIVITY] incident_wards.php failed: ${response.statusCode}');
      }
    } catch (e) {
      print('🔴 [USER ACTIVITY] incident_wards.php error: $e');
    }
  }

  /// Fetch activity data from existing backend API
  /// Calls: /view/user_activity_api/{user_id}
  Future<void> _fetchActivityData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get domain and user ID from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final domain = prefs.getString('domain') ?? '';
      final userId = prefs.getString('userid') ?? '';

      if (domain.isEmpty) {
        throw Exception('Domain not found. Please login again.');
      }

      if (userId.isEmpty) {
        throw Exception('User ID not found. Please login again.');
      }

      // Call existing backend API: /view/user_activity_api/{user_id}
      final apiUrl = 'https://$domain.efeedor.com/view/user_activity_api/$userId';
      final uri = Uri.parse(apiUrl);

      print('🔵 [USER ACTIVITY] ========================================');
      print('🔵 [USER ACTIVITY] Calling user_activity_api');
      print('🔵 [USER ACTIVITY] URL: $apiUrl');
      print('🔵 [USER ACTIVITY] User ID: $userId');
      print('🔵 [USER ACTIVITY] ========================================');

      final response = await http.get(uri).timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      print('🟢 [USER ACTIVITY] Response Status: ${response.statusCode}');
      print('🟢 [USER ACTIVITY] Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        
        // Parse JSON response and bind to UI fields
        if (mounted) {
          _fadeController.reset();
          setState(() {
            _isLoading = false;
            
            // Map response data to state variables
            // Adjust field names based on actual API response structure
            final data = responseData['data'] ?? responseData;
            
            // IP Discharge Feedbacks
            _ipDischargeFeedbacks = _parseInt(data['ip_discharge_feedbacks']) ?? 
                                   _parseInt(data['ip_feedback_count']) ?? 0;
            
            // OP Feedbacks
            _opFeedbacks = _parseInt(data['op_feedbacks']) ?? 
                          _parseInt(data['op_feedback_count']) ?? 0;
            
            // Inpatient Concerns
            _inpatientConcerns = _parseInt(data['inpatient_concerns']) ?? 
                               _parseInt(data['pc_feedback_count']) ?? 0;
            
            // Internal Service Requests (ISR)
            final isrData = data['internal_requests'] ?? data['isr_tickets'] ?? {};
            _internalRequestsRaised = _parseInt(isrData['raised']) ?? 
                                     _parseInt(isrData['all']) ?? 
                                     _parseInt(data['isr_raised']) ?? 0;
            _internalRequestsUnaddressed = _parseInt(isrData['unaddressed']) ?? 
                                          _parseInt(isrData['open']) ?? 
                                          _parseInt(data['isr_unaddressed']) ?? 0;
            _internalRequestsAssigned = _parseInt(isrData['assigned']) ?? 
                                       _parseInt(data['isr_assigned']) ?? 0;
            _internalRequestsResolved = _parseInt(isrData['resolved']) ?? 
                                       _parseInt(isrData['closed']) ?? 
                                       _parseInt(data['isr_resolved']) ?? 0;
            
            // Incidents
            final incidentData = data['incidents'] ?? data['incident_tickets'] ?? {};
            _incidentsReported = _parseInt(incidentData['reported']) ?? 
                               _parseInt(incidentData['all']) ?? 
                               _parseInt(data['incident_reported']) ?? 0;
            _incidentsUnaddressed = _parseInt(incidentData['unaddressed']) ?? 
                                   _parseInt(incidentData['open']) ?? 
                                   _parseInt(data['incident_unaddressed']) ?? 0;
            _incidentsAssigned = _parseInt(incidentData['assigned']) ?? 
                               _parseInt(data['incident_assigned']) ?? 0;
          });
          _fadeController.forward();
        }
      } else {
        throw Exception('API error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('🔴 [USER ACTIVITY] Error fetching activity data: $e');
      
      if (mounted) {
        _fadeController.reset();
        setState(() {
          _isLoading = false;
          // Keep existing values or set to 0 on error
        });
        _fadeController.forward();
      }
    }
  }

  /// Helper method to safely parse integer from dynamic value
  int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  /// Show period dropdown selector
  void _showPeriodDropdown() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 5,
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Text(
                'Select Period',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ),
            const Divider(),
            // Period options
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  RadioListTile<ActivityPeriod>(
                    title: const Text(
                      'Today',
                      style: TextStyle(color: Colors.black87),
                    ),
                    value: ActivityPeriod.today,
                    groupValue: _selectedPeriod,
                    activeColor: efeedorBrandGreen,
                    onChanged: (value) {
                      if (value != null) {
                        Navigator.pop(context);
                        _selectPeriod(value);
                      }
                    },
                  ),
                  RadioListTile<ActivityPeriod>(
                    title: const Text(
                      'Previous Day',
                      style: TextStyle(color: Colors.black87),
                    ),
                    value: ActivityPeriod.previousDay,
                    groupValue: _selectedPeriod,
                    activeColor: efeedorBrandGreen,
                    onChanged: (value) {
                      if (value != null) {
                        Navigator.pop(context);
                        _selectPeriod(value);
                      }
                    },
                  ),
                  RadioListTile<ActivityPeriod>(
                    title: const Text(
                      'Last 24 Hours',
                      style: TextStyle(color: Colors.black87),
                    ),
                    value: ActivityPeriod.last24Hours,
                    groupValue: _selectedPeriod,
                    activeColor: efeedorBrandGreen,
                    onChanged: (value) {
                      if (value != null) {
                        Navigator.pop(context);
                        _selectPeriod(value);
                      }
                    },
                  ),
                  RadioListTile<ActivityPeriod>(
                    title: const Text(
                      'Last 7 Days',
                      style: TextStyle(color: Colors.black87),
                    ),
                    value: ActivityPeriod.last7Days,
                    groupValue: _selectedPeriod,
                    activeColor: efeedorBrandGreen,
                    onChanged: (value) {
                      if (value != null) {
                        Navigator.pop(context);
                        _selectPeriod(value);
                      }
                    },
                  ),
                  RadioListTile<ActivityPeriod>(
                    title: const Text(
                      'Last 30 Days',
                      style: TextStyle(color: Colors.black87),
                    ),
                    value: ActivityPeriod.last30Days,
                    groupValue: _selectedPeriod,
                    activeColor: efeedorBrandGreen,
                    onChanged: (value) {
                      if (value != null) {
                        Navigator.pop(context);
                        _selectPeriod(value);
                      }
                    },
                  ),
                  RadioListTile<ActivityPeriod>(
                    title: const Text(
                      'Last 90 Days',
                      style: TextStyle(color: Colors.black87),
                    ),
                    value: ActivityPeriod.last90Days,
                    groupValue: _selectedPeriod,
                    activeColor: efeedorBrandGreen,
                    onChanged: (value) {
                      if (value != null) {
                        Navigator.pop(context);
                        _selectPeriod(value);
                      }
                    },
                  ),
                  RadioListTile<ActivityPeriod>(
                    title: const Text(
                      'Current Month',
                      style: TextStyle(color: Colors.black87),
                    ),
                    value: ActivityPeriod.currentMonth,
                    groupValue: _selectedPeriod,
                    activeColor: efeedorBrandGreen,
                    onChanged: (value) {
                      if (value != null) {
                        Navigator.pop(context);
                        _selectPeriod(value);
                      }
                    },
                  ),
                  RadioListTile<ActivityPeriod>(
                    title: const Text(
                      'Previous Month',
                      style: TextStyle(color: Colors.black87),
                    ),
                    value: ActivityPeriod.previousMonth,
                    groupValue: _selectedPeriod,
                    activeColor: efeedorBrandGreen,
                    onChanged: (value) {
                      if (value != null) {
                        Navigator.pop(context);
                        _selectPeriod(value);
                      }
                    },
                  ),
                  RadioListTile<ActivityPeriod>(
                    title: const Text(
                      'Last 365 Days',
                      style: TextStyle(color: Colors.black87),
                    ),
                    value: ActivityPeriod.last365Days,
                    groupValue: _selectedPeriod,
                    activeColor: efeedorBrandGreen,
                    onChanged: (value) {
                      if (value != null) {
                        Navigator.pop(context);
                        _selectPeriod(value);
                      }
                    },
                  ),
                  RadioListTile<ActivityPeriod>(
                    title: const Text(
                      'Custom Date',
                      style: TextStyle(color: Colors.black87),
                    ),
                    value: ActivityPeriod.customDate,
                    groupValue: _selectedPeriod,
                    activeColor: efeedorBrandGreen,
                    onChanged: (value) {
                      if (value != null) {
                        Navigator.pop(context);
                        _selectPeriod(value);
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  /// Show custom date range picker modal
  Future<void> _showCustomDateRangePicker() async {
    DateTime? tempStartDate = _customFromDate;
    DateTime? tempEndDate = _customToDate;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Select Custom Date Range',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const SizedBox(height: 16),
                  // Start Date
                  const Text(
                    'Start Date:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: tempStartDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setDialogState(() {
                          tempStartDate = picked;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            tempStartDate != null
                                ? _formatDate(tempStartDate!)
                                : 'Select start date',
                            style: TextStyle(
                              fontSize: 14,
                              color: tempStartDate != null
                                  ? Colors.black87
                                  : Colors.grey[600],
                            ),
                          ),
                          Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // End Date
                  const Text(
                    'End Date:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: tempEndDate ?? DateTime.now(),
                        firstDate: tempStartDate ?? DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setDialogState(() {
                          tempEndDate = picked;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            tempEndDate != null
                                ? _formatDate(tempEndDate!)
                                : 'Select end date',
                            style: TextStyle(
                              fontSize: 14,
                              color: tempEndDate != null
                                  ? Colors.black87
                                  : Colors.grey[600],
                            ),
                          ),
                          Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (tempStartDate != null && tempEndDate != null) {
                      setState(() {
                        _customFromDate = tempStartDate;
                        _customToDate = tempEndDate;
                        _selectedPeriod = ActivityPeriod.customDate;
                      });
                      Navigator.of(context).pop();
                      _fetchActivityData();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: const Text(
                    'Apply',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Handle period selection
  void _selectPeriod(ActivityPeriod period) {
    if (period == ActivityPeriod.customDate) {
      _showCustomDateRangePicker();
    } else {
      setState(() {
        _selectedPeriod = period;
        _customFromDate = null;
        _customToDate = null;
      });
      _fetchActivityData();
    }
  }

  /// Get period label for dropdown display
  String _getPeriodLabel(ActivityPeriod period) {
    switch (period) {
      case ActivityPeriod.today:
        return 'Today';
      case ActivityPeriod.previousDay:
        return 'Previous Day';
      case ActivityPeriod.last24Hours:
        return 'Last 24 Hours';
      case ActivityPeriod.last7Days:
        return 'Last 7 Days';
      case ActivityPeriod.last30Days:
        return 'Last 30 Days';
      case ActivityPeriod.last90Days:
        return 'Last 90 Days';
      case ActivityPeriod.currentMonth:
        return 'Current Month';
      case ActivityPeriod.previousMonth:
        return 'Previous Month';
      case ActivityPeriod.last365Days:
        return 'Last 365 Days';
      case ActivityPeriod.customDate:
        if (_customFromDate != null && _customToDate != null) {
          return '${_formatDate(_customFromDate!)} - ${_formatDate(_customToDate!)}';
        }
        return 'Custom Date';
    }
  }

  /// Build section header
  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      margin: const EdgeInsets.only(top: 16, bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          left: BorderSide(
            color: efeedorBrandGreen,
            width: 4,
          ),
        ),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey[800],
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  /// Build activity card (white card with count, arrow, label, View List)
  Widget _buildActivityCard({
    required String label,
    required int count,
    VoidCallback? onViewList,
  }) {
    return Opacity(
      opacity: _fadeAnimation.value > 0 ? _fadeAnimation.value : 1.0,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        constraints: const BoxConstraints(
          minHeight: 80,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top row: Count and arrow on left, View List on right
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left: Count with up arrow
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        count.toString(),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          height: 1.0,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.arrow_upward,
                        size: 18,
                        color: efeedorBrandGreen,
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Right: View List button
                  if (onViewList != null)
                    InkWell(
                      onTap: onViewList,
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.remove_red_eye,
                              size: 16,
                              color: Colors.grey[700],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'View List',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              // Bottom: Label
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[800],
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppHeaderWrapper(
      title: '',
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Title
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: const Text(
                'USER ACTIVITY DASHBOARD',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  letterSpacing: 0.3,
                ),
              ),
            ),

            // Description text
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: Text(
                'This page gives you a brief summary of your activity across the different tools of Efeedor, highlighting the number of feedbacks, concerns, internal requests, and incidents recorded by you.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
              ),
            ),

            // Date filter section
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey[200]!,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Period selector dropdown
                  InkWell(
                    onTap: _showPeriodDropdown,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: efeedorBrandGreen,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              _getPeriodLabel(_selectedPeriod),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.white,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Date range display
                  Text(
                    _getDateRangeDisplay(),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Loading state
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 60),
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(efeedorBrandGreen),
                  ),
                ),
              ),

            // Activity sections
            if (!_isLoading) ...[
              // IP DISCHARGE FEEDBACKS Section
              _buildSectionHeader('IP DISCHARGE FEEDBACKS'),
              _buildActivityCard(
                label: 'IP Feedbacks collected',
                count: _ipDischargeFeedbacks,
                onViewList: () {
                  // TODO: Navigate to IP Feedbacks list
                },
              ),

              // OP FEEDBACKS Section
              _buildSectionHeader('OP FEEDBACKS'),
              _buildActivityCard(
                label: 'OP Feedbacks collected',
                count: _opFeedbacks,
                onViewList: () {
                  // TODO: Navigate to OP Feedbacks list
                },
              ),

              // INPATIENT CONCERNS Section
              _buildSectionHeader('INPATIENT CONCERNS'),
              _buildActivityCard(
                label: 'Complaints captured',
                count: _inpatientConcerns,
                onViewList: () {
                  // TODO: Navigate to Concerns list
                },
              ),

              // INTERNAL SERVICE REQUESTS Section
              _buildSectionHeader('INTERNAL SERVICE REQUESTS'),
              _buildActivityCard(
                label: 'Requests raised',
                count: _internalRequestsRaised,
                onViewList: () {
                  // TODO: Navigate to Requests raised list
                },
              ),
              _buildActivityCard(
                label: 'Requests unaddressed',
                count: _internalRequestsUnaddressed,
                onViewList: () {
                  // TODO: Navigate to Requests unaddressed list
                },
              ),
              _buildActivityCard(
                label: 'Requests assigned',
                count: _internalRequestsAssigned,
                onViewList: () {
                  // TODO: Navigate to Requests assigned list
                },
              ),
              _buildActivityCard(
                label: 'Requests resolved',
                count: _internalRequestsResolved,
                onViewList: () {
                  // TODO: Navigate to Requests resolved list
                },
              ),

              // INCIDENTS Section
              _buildSectionHeader('INCIDENTS'),
              _buildActivityCard(
                label: 'Incidents reported',
                count: _incidentsReported,
                onViewList: () {
                  // TODO: Navigate to Incidents reported list
                },
              ),
              _buildActivityCard(
                label: 'Incidents unaddressed',
                count: _incidentsUnaddressed,
                onViewList: () {
                  // TODO: Navigate to Incidents unaddressed list
                },
              ),
              _buildActivityCard(
                label: 'Incidents assigned',
                count: _incidentsAssigned,
                onViewList: () {
                  // TODO: Navigate to Incidents assigned list
                },
              ),
            ],

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
