import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../config/constant.dart';
import '../services/ticket_api_service.dart';
import '../model/ticket_dashboard_summary.dart';
import '../widgets/app_header_wrapper.dart';
import 'ticket_list_page.dart';

/// Module options for ticket filtering
class TicketModule {
  final String name;
  final String code;

  const TicketModule(this.name, this.code);
}

/// Period options for date filtering
enum TicketPeriod {
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

class TicketDashboardPage extends StatefulWidget {
  const TicketDashboardPage({Key? key}) : super(key: key);

  @override
  State<TicketDashboardPage> createState() => _TicketDashboardPageState();
}

class _TicketDashboardPageState extends State<TicketDashboardPage>
    with SingleTickerProviderStateMixin {
  // Module options
  static const List<TicketModule> _modules = [
    TicketModule('IP Feedback Tickets', 'IP'),
    TicketModule('OP Feedback Tickets', 'OP'),
    TicketModule('IP Complaints/Requests', 'PCF'),
    TicketModule('Internal Service Requests', 'ISR'),
    TicketModule('Incidents', 'INCIDENT'),
  ];

  // State
  TicketModule _selectedModule = _modules[0]; // Default: IP Feedback Tickets
  TicketPeriod _selectedPeriod = TicketPeriod.last30Days; // Default: Last 30 Days
  DateTime? _customFromDate;
  DateTime? _customToDate;
  
  TicketDashboardSummary? _summary;
  bool _isLoading = false;
  String? _errorMessage;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

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
    _fetchDashboardData();
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
      case TicketPeriod.today:
        return {'from': today, 'to': today};
      
      case TicketPeriod.previousDay:
        final yesterday = today.subtract(const Duration(days: 1));
        return {'from': yesterday, 'to': yesterday};
      
      case TicketPeriod.last24Hours:
        final last24Hours = now.subtract(const Duration(hours: 24));
        return {'from': last24Hours, 'to': now};
      
      case TicketPeriod.last7Days:
        return {
          'from': today.subtract(const Duration(days: 7)),
          'to': today,
        };
      
      case TicketPeriod.last30Days:
        return {
          'from': today.subtract(const Duration(days: 30)),
          'to': today,
        };
      
      case TicketPeriod.last90Days:
        return {
          'from': today.subtract(const Duration(days: 90)),
          'to': today,
        };
      
      case TicketPeriod.currentMonth:
        final firstDayOfMonth = DateTime(now.year, now.month, 1);
        return {'from': firstDayOfMonth, 'to': today};
      
      case TicketPeriod.previousMonth:
        final firstDayOfPreviousMonth = DateTime(now.year, now.month - 1, 1);
        final lastDayOfPreviousMonth = DateTime(now.year, now.month, 0);
        return {'from': firstDayOfPreviousMonth, 'to': lastDayOfPreviousMonth};
      
      case TicketPeriod.last365Days:
        return {
          'from': today.subtract(const Duration(days: 365)),
          'to': today,
        };
      
      case TicketPeriod.customDate:
        if (_customFromDate != null && _customToDate != null) {
          return {'from': _customFromDate!, 'to': _customToDate!};
        }
        // Fallback to last 30 days if custom date not set
        return {
          'from': today.subtract(const Duration(days: 30)),
          'to': today,
        };
    }
  }

  /// Fetch dashboard data from API
  Future<void> _fetchDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get domain and user ID
      final prefs = await SharedPreferences.getInstance();
      final domain = prefs.getString('domain') ?? '';
      final uid = prefs.getString('userid') ?? '';

      if (domain.isEmpty) {
        throw Exception('Domain not found. Please login again.');
      }
      if (uid.isEmpty) {
        throw Exception('User ID not found. Please login again.');
      }

      // Get date range
      final dateRange = _getDateRange();
      final fromDate = dateRange['from']!;
      final toDate = dateRange['to']!;

      // Fetch data
      final summary = await TicketApiService.fetchTicketDashboard(
        domain: domain,
        uid: uid,
        moduleCode: _selectedModule.code,
        fromDate: fromDate,
        toDate: toDate,
      );

      if (mounted) {
        _fadeController.reset();
        setState(() {
          _summary = summary;
          _isLoading = false;
        });
        _fadeController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  /// Show period dropdown selector
  void _showPeriodDropdown() {
    showModalBottomSheet(
      context: context,
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
            // Period options - Scrollable list
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  RadioListTile<TicketPeriod>(
                    title: const Text('Today'),
                    value: TicketPeriod.today,
                    groupValue: _selectedPeriod,
                    onChanged: (value) {
                      if (value != null) {
                        Navigator.pop(context);
                        _selectPeriod(value);
                      }
                    },
                  ),
                  RadioListTile<TicketPeriod>(
                    title: const Text('Previous Day'),
                    value: TicketPeriod.previousDay,
                    groupValue: _selectedPeriod,
                    onChanged: (value) {
                      if (value != null) {
                        Navigator.pop(context);
                        _selectPeriod(value);
                      }
                    },
                  ),
                  RadioListTile<TicketPeriod>(
                    title: const Text('Last 24 Hours'),
                    value: TicketPeriod.last24Hours,
                    groupValue: _selectedPeriod,
                    onChanged: (value) {
                      if (value != null) {
                        Navigator.pop(context);
                        _selectPeriod(value);
                      }
                    },
                  ),
                  RadioListTile<TicketPeriod>(
                    title: const Text('Last 7 Days'),
                    value: TicketPeriod.last7Days,
                    groupValue: _selectedPeriod,
                    onChanged: (value) {
                      if (value != null) {
                        Navigator.pop(context);
                        _selectPeriod(value);
                      }
                    },
                  ),
                  RadioListTile<TicketPeriod>(
                    title: const Text('Last 30 Days'),
                    value: TicketPeriod.last30Days,
                    groupValue: _selectedPeriod,
                    onChanged: (value) {
                      if (value != null) {
                        Navigator.pop(context);
                        _selectPeriod(value);
                      }
                    },
                  ),
                  RadioListTile<TicketPeriod>(
                    title: const Text('Last 90 Days'),
                    value: TicketPeriod.last90Days,
                    groupValue: _selectedPeriod,
                    onChanged: (value) {
                      if (value != null) {
                        Navigator.pop(context);
                        _selectPeriod(value);
                      }
                    },
                  ),
                  RadioListTile<TicketPeriod>(
                    title: const Text('Current Month'),
                    value: TicketPeriod.currentMonth,
                    groupValue: _selectedPeriod,
                    onChanged: (value) {
                      if (value != null) {
                        Navigator.pop(context);
                        _selectPeriod(value);
                      }
                    },
                  ),
                  RadioListTile<TicketPeriod>(
                    title: const Text('Previous Month'),
                    value: TicketPeriod.previousMonth,
                    groupValue: _selectedPeriod,
                    onChanged: (value) {
                      if (value != null) {
                        Navigator.pop(context);
                        _selectPeriod(value);
                      }
                    },
                  ),
                  RadioListTile<TicketPeriod>(
                    title: const Text('Last 365 Days'),
                    value: TicketPeriod.last365Days,
                    groupValue: _selectedPeriod,
                    onChanged: (value) {
                      if (value != null) {
                        Navigator.pop(context);
                        _selectPeriod(value);
                      }
                    },
                  ),
                  RadioListTile<TicketPeriod>(
                    title: const Text('Custom Date'),
                    value: TicketPeriod.customDate,
                    groupValue: _selectedPeriod,
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

  /// Show module selector bottom sheet
  void _showModuleSelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 5,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Text(
                'Select Module',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ),
            const Divider(),
            // Module options
            ..._modules.map((module) => RadioListTile<TicketModule>(
              title: Text(module.name),
              value: module,
              groupValue: _selectedModule,
              onChanged: (value) {
                if (value != null) {
                  Navigator.pop(context);
                  setState(() {
                    _selectedModule = value;
                  });
                  _fetchDashboardData();
                }
              },
            )),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  /// Show date range picker for custom range
  Future<void> _showCustomDateRangePicker() async {
    final now = DateTime.now();
    final initialRange = _customFromDate != null && _customToDate != null
        ? DateTimeRange(start: _customFromDate!, end: _customToDate!)
        : DateTimeRange(
            start: now.subtract(const Duration(days: 30)),
            end: now,
          );

    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: initialRange,
      firstDate: DateTime(2020),
      lastDate: now,
      helpText: 'Select Date Range',
    );

      if (picked != null) {
      setState(() {
        _customFromDate = picked.start;
        _customToDate = picked.end;
        _selectedPeriod = TicketPeriod.customDate;
      });
      _fetchDashboardData();
    }
  }

  /// Handle period selection
  void _selectPeriod(TicketPeriod period) {
    if (period == TicketPeriod.customDate) {
      _showCustomDateRangePicker();
    } else {
      setState(() {
        _selectedPeriod = period;
        _customFromDate = null;
        _customToDate = null;
      });
      _fetchDashboardData();
    }
  }

  /// Get period label for dropdown display
  String _getPeriodLabel(TicketPeriod period) {
    switch (period) {
      case TicketPeriod.today:
        return 'Today';
      case TicketPeriod.previousDay:
        return 'Previous Day';
      case TicketPeriod.last24Hours:
        return 'Last 24 Hours';
      case TicketPeriod.last7Days:
        return 'Last 7 Days';
      case TicketPeriod.last30Days:
        return 'Last 30 Days';
      case TicketPeriod.last90Days:
        return 'Last 90 Days';
      case TicketPeriod.currentMonth:
        return 'Current Month';
      case TicketPeriod.previousMonth:
        return 'Previous Month';
      case TicketPeriod.last365Days:
        return 'Last 365 Days';
      case TicketPeriod.customDate:
        if (_customFromDate != null && _customToDate != null) {
          // Format dates for display
          final format = DateFormat('MMM dd, yyyy');
          return '${format.format(_customFromDate!)} - ${format.format(_customToDate!)}';
        }
        return 'Custom Date';
    }
  }

  /// Get display range text with module name and date range
  /// Format: "Showing <Module Name> from <Start Date> to <End Date>"
  /// Dates are formatted as DD-MM-YYYY
  String _getDisplayRangeText() {
    final dateRange = _getDateRange();
    final fromDate = dateRange['from']!;
    final toDate = dateRange['to']!;
    
    // Format dates as DD-MM-YYYY
    final dateFormat = DateFormat('dd-MM-yyyy');
    final fromDateStr = dateFormat.format(fromDate);
    final toDateStr = dateFormat.format(toDate);
    
    return 'Showing ${_selectedModule.name} from $fromDateStr to $toDateStr';
  }

  /// Navigate to ticket list page
  void _navigateToTicketList(String filterType) {
    final dateRange = _getDateRange();
    final fromDate = dateRange['from']!;
    final toDate = dateRange['to']!;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TicketListPage(
          moduleCode: _selectedModule.code,
          moduleName: _selectedModule.name,
          fromDate: fromDate,
          toDate: toDate,
          filterType: filterType,
        ),
      ),
    );
  }

  /// Build summary card - Rectangular centered card with Row layout
  Widget _buildSummaryCard({
    required String label,
    required int count,
    required List<Color> gradientColors,
    required Color buttonColor,
    required String filterType,
  }) {
    return Opacity(
      opacity: _fadeAnimation.value > 0 ? _fadeAnimation.value : 1.0,
      child: Container(
        width: double.infinity,
        height: 130,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Row(
            children: [
              // Left: Big number
              Expanded(
                flex: 2,
                child: Center(
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ),
              // Right: Label + View List button
              Expanded(
                flex: 3,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildViewListButton(buttonColor, filterType),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build View List button with micro-interaction
  Widget _buildViewListButton(Color buttonColor, String filterType) {
    return AnimatedScale(
      scale: 1.0,
      duration: const Duration(milliseconds: 150),
      child: InkWell(
        onTap: () => _navigateToTicketList(filterType),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: buttonColor,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(
                Icons.remove_red_eye,
                size: 16,
                color: Colors.white,
              ),
              SizedBox(width: 6),
              Text(
                'View List',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
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
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
                  // Page Title
                  const Padding(
                    padding: EdgeInsets.only(top: 8, bottom: 12),
                    child: Text(
                      'MANAGE TICKETS',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                        letterSpacing: 0.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  // Description text
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      'Select the module from the filter and click on the necessary buttons to take relevant actions on the tickets assigned to you.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        height: 1.4,
                      ),
                    ),
                  ),

                  // Filter section - Soft elevated container
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        // Module selector pill
                        InkWell(
                          onTap: _showModuleSelector,
                          borderRadius: BorderRadius.circular(22),
                          child: Container(
                            height: 44,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: efeedorBrandGreen,
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    _selectedModule.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                    overflow: TextOverflow.ellipsis,
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

                        // Period selector dropdown
                        InkWell(
                          onTap: _showPeriodDropdown,
                          borderRadius: BorderRadius.circular(22),
                          child: Container(
                            height: 44,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: efeedorBrandGreen,
                              borderRadius: BorderRadius.circular(22),
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
                                const Icon(
                                  Icons.keyboard_arrow_down,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Divider + "Showing module" text
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: Colors.grey.shade300,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      _getDisplayRangeText(),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

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

                  // Error state
                  if (_errorMessage != null && !_isLoading)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Column(
                        children: [
                          Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _fetchDashboardData,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: efeedorBrandGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),

                  // Summary cards - Centered rectangular cards
                  if (_summary != null && !_isLoading)
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: 380,
                        ),
                        child: Column(
                          children: [
                            const SizedBox(height: 12),
                            _buildSummaryCard(
                              label: 'TOTAL REQUESTS',
                              count: _summary!.totalTicket,
                              gradientColors: const [
                                Color(0xFF009688), // Teal
                                Color(0xFF00796B), // Darker teal
                              ],
                              buttonColor: const Color(0xFF004D40),
                              filterType: 'TOTAL',
                            ),
                            const SizedBox(height: 16),
                            _buildSummaryCard(
                              label: 'OPEN REQUESTS',
                              count: _summary!.openTicket,
                              gradientColors: const [
                                Color(0xFF4CAF50), // Green
                                Color(0xFF2E7D32), // Darker green
                              ],
                              buttonColor: const Color(0xFF1B5E20),
                              filterType: 'OPEN',
                            ),
                            const SizedBox(height: 16),
                            _buildSummaryCard(
                              label: 'CLOSED REQUESTS',
                              count: _summary!.closedTicket,
                              gradientColors: [
                                Colors.orange.shade700,
                                Colors.orange.shade900,
                              ],
                              buttonColor: Colors.orange.shade900,
                              filterType: 'CLOSED',
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

}

