import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

  /// Fetch activity data from API (placeholder for now)
  Future<void> _fetchActivityData() async {
    setState(() {
      _isLoading = true;
    });

    // TODO: Replace with actual API call
    // For now, using placeholder data
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      _fadeController.reset();
      setState(() {
        _isLoading = false;
        // Placeholder counts - replace with actual API response
        _ipDischargeFeedbacks = 0;
        _opFeedbacks = 0;
        _inpatientConcerns = 0;
        _internalRequestsRaised = 0;
        _internalRequestsUnaddressed = 0;
        _internalRequestsAssigned = 0;
        _internalRequestsResolved = 0;
        _incidentsReported = 0;
        _incidentsUnaddressed = 0;
        _incidentsAssigned = 0;
      });
      _fadeController.forward();
    }
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.grey[200],
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
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
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Left: Count with up arrow
              Row(
                children: [
                  Text(
                    count.toString().padLeft(3, '0'),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_upward,
                    size: 16,
                    color: efeedorBrandGreen,
                  ),
                ],
              ),
              const Spacer(),
              // Center: Label
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
              // Right: View List
              if (onViewList != null)
                InkWell(
                  onTap: onViewList,
                  child: const Text(
                    'View List',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      decoration: TextDecoration.underline,
                    ),
                  ),
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
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: const Text(
                'USER ACTIVITY DASHBOARD',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  letterSpacing: 0.5,
                ),
              ),
            ),

            // Horizontal divider
            const Divider(
              height: 1,
              thickness: 1,
              color: Colors.grey,
            ),

            // Description text
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Text(
                'This page gives you a brief summary of your activity across the different tools of Efeedor, highlighting the number of feedbacks, concerns, internal requests, and incidents recorded by you.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),
            ),

            // Date filter section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
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
                          Text(
                            _getPeriodLabel(_selectedPeriod),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
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
                      fontSize: 13,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

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
              const SizedBox(height: 8),

              // OP FEEDBACKS Section
              _buildSectionHeader('OP FEEDBACKS'),
              _buildActivityCard(
                label: 'OP Feedbacks collected',
                count: _opFeedbacks,
                onViewList: () {
                  // TODO: Navigate to OP Feedbacks list
                },
              ),
              const SizedBox(height: 8),

              // INPATIENT CONCERNS Section
              _buildSectionHeader('INPATIENT CONCERNS'),
              _buildActivityCard(
                label: 'Complaints captured',
                count: _inpatientConcerns,
                onViewList: () {
                  // TODO: Navigate to Concerns list
                },
              ),
              const SizedBox(height: 8),

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
              const SizedBox(height: 8),

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
