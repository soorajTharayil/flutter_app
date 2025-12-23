import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:devkitflutter/ui/op_feedback_page.dart'; // Adjust if needed
import 'package:devkitflutter/ui/webview_page.dart';
import 'package:devkitflutter/ui/signin.dart';
import 'package:devkitflutter/ui/ip_discharge_mobile_page.dart';
import 'package:devkitflutter/ui/update_app.dart';
import 'package:devkitflutter/ui/access_web_dashbaord.dart';
import 'package:devkitflutter/ui/share_page.dart';
import 'package:devkitflutter/ui/about.dart';
import 'package:devkitflutter/config/constant.dart';
import 'package:devkitflutter/widgets/app_header_wrapper.dart';
import 'package:devkitflutter/widgets/hospital_logo_widget.dart';
import 'package:devkitflutter/services/department_service.dart' as dept_service;
import 'package:devkitflutter/services/offline_storage_service.dart';
import 'package:devkitflutter/services/feedback_preloader.dart';
import 'package:devkitflutter/services/op_localization_service.dart';
import 'package:devkitflutter/pages/offline_sync_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  Map<String, dynamic> _permissions = {};
  bool _isLoadingPermissions = true;
  int _offlineFeedbackCount = 0;
  Map<int, bool> _hoveredItems = {};

  @override
  void initState() {
    super.initState();
    _loadPermissions();
    _loadOfflineFeedbackCount();
    // Preload all feedback data (IP + OP) on first dashboard load
    _preloadFeedbackDataOnFirstLoad();
    // Dashboard always uses English - no language listener needed
  }

  /// Preload all feedback data (IP + OP) on first dashboard load after login
  /// Runs silently in background - does not block UI
  Future<void> _preloadFeedbackDataOnFirstLoad() async {
    try {
      // Check if preload has already been completed
      final isPreloadCompleted = await FeedbackPreloader.isPreloadCompleted();

      if (!isPreloadCompleted) {
        // Preload all feedback data in background
        // This ensures both IP and OP modules work fully offline
        FeedbackPreloader.preloadAllFeedbackData();
      }
    } catch (e) {
      // Silently fail - app should continue working
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh offline count when returning to dashboard
    _refreshOfflineCount();
  }

  /// Load offline feedback count (combined OP + IP)
  Future<void> _loadOfflineFeedbackCount() async {
    try {
      final opFeedbacks = await OfflineStorageService.loadOfflineOPFeedback();
      final ipFeedbacks = await OfflineStorageService.loadOfflineIPFeedback();
      if (mounted) {
        setState(() {
          _offlineFeedbackCount = opFeedbacks.length + ipFeedbacks.length;
        });
      }
    } catch (e) {
      // Ignore errors
    }
  }

  /// Refresh offline count when returning to dashboard
  void _refreshOfflineCount() {
    _loadOfflineFeedbackCount();
  }

  // All available modules with their permission keys
  final List<Map<String, dynamic>> _allModules = [
    {
      'title': 'IP Discharge Feedback',
      'icon': Icons.exit_to_app,
      'color': Colors.blue,
      'desc': 'Submit feedback for in-patient discharge experience',
      'page':
          const IPDischargeMobilePage(), // Use Flutter page instead of WebView
      'permissionKey': 'IP-MODULE',
    },
    {
      'title': 'Outpatient Feedback',
      'icon': Icons.people_alt,
      'color': Colors.green,
      'desc': 'Share your outpatient visit experience',
      'page': const OpFeedbackPage(), // Keep internal navigation
      'permissionKey': 'OP-MODULE',
    },
    {
      'title': 'IP Concern / Request',
      'icon': Icons.warning_amber_rounded,
      'color': Colors.pinkAccent,
      'desc': 'Raise concerns or submit requests for in-patients',
      'urlPath': '/pcrf', // Web URL path
      'permissionKey': 'PCF-MODULE',
    },
    {
      'title': 'Raise Internal Request',
      'icon': Icons.add_circle_outline,
      'color': Colors.orange,
      'desc': 'Create and submit internal department requests',
      'urlPath': '/isrr', // Web URL path
      'permissionKey': 'ADDRESSED-REQUESTS', // Using this permission key
    },
    {
      'title': 'Report Incident',
      'icon': Icons.report_problem,
      'color': Colors.purple,
      'desc': 'Document and report healthcare incidents',
      'urlPath': '/inn', // Web URL path
      'permissionKey': 'INCIDENT-MODULE',
    },
    {
      'title': 'Quality KPI Forms',
      'icon': Icons.assessment,
      'color': Colors.teal,
      'desc': 'Access quality key performance indicator forms',
      'urlPath': '/qim_forms', // Web URL path
      'permissionKey': 'QUALITY-MODULE',
    },
    {
      'title': 'Healthcare Audit Forms',
      'icon': Icons.assignment,
      'color': Colors.indigo,
      'desc': 'Complete healthcare audit and compliance forms',
      'urlPath': '/audit_forms', // Web URL path
      'permissionKey': 'AUDIT-MODULE',
    },
    {
      'title': 'Departmental Monthly Reports',
      'icon': Icons.description,
      'color': Colors.brown,
      'desc': 'View and submit departmental monthly reports',
      'urlPath': '/monthly_audit_reports', // Web URL path
      'permissionKey': 'AUDIT-MODULE',
    },
    {
      'title': 'PREM Forms',
      'icon': Icons.medical_information,
      'color': Colors.red.shade400,
      'desc': 'Patient Reported Experience Measures forms',
      'urlPath': '/prems_forms', // Web URL path
      'permissionKey': 'PREMS-MODULE',
    },
    {
      'title': 'Register Asset',
      'icon': Icons.inventory_2,
      'color': Colors.deepPurple,
      'desc': 'Register and manage hospital assets',
      'urlPath': '/add_asset', // Web URL path
      'permissionKey': 'REGISTER-ASSET-FORM',
    },
  ];

  Future<void> _loadPermissions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final permissionsJson = prefs.getString('user_permissions');
      if (permissionsJson != null) {
        setState(() {
          _permissions = jsonDecode(permissionsJson) as Map<String, dynamic>;
          _isLoadingPermissions = false;
        });
      } else {
        setState(() {
          _isLoadingPermissions = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingPermissions = false;
      });
    }
  }

  // Get modules filtered by permissions
  List<Map<String, dynamic>> get modules {
    return _allModules.where((module) {
      final permissionKey = module['permissionKey'] as String;
      // Check if permission exists and is true
      final hasPermission = _permissions[permissionKey] == true;
      return hasPermission;
    }).toList();
  }

  List<Map<String, dynamic>> get _filteredModules {
    final filtered = modules;
    if (_query.isEmpty) return filtered;
    final q = _query.toLowerCase();
    return filtered.where((m) {
      final title = (m['title'] as String).toLowerCase();
      final desc = (m['desc'] as String).toLowerCase();
      return title.contains(q) || desc.contains(q);
    }).toList();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    Fluttertoast.showToast(msg: "Tapped: $index");
    // TODO: Navigate to respective bottom tab pages if needed
  }

  Future<void> _logout() async {
    // Show confirmation dialog
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Logout',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: efeedorBrandGreen,
              shape: const StadiumBorder(),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout != true) return;

    // Clear login state from SharedPreferences (CHANGE 1: Keep domain values)
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('is_logged_in');
    await prefs.remove('last_active_timestamp');
    await prefs.remove('device_id');
    await prefs.remove('userid');
    await prefs.remove('email');
    await prefs.remove('name');
    await prefs.remove('user_permissions');
    await prefs.remove('waiting_for_approval');
    // DO NOT clear domain-related keys: domain, stored_domain, domain_completed, domain_url
    // Do NOT clear device approval from backend

    // Navigate to login page (not domain page)
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => SignIn()),
        (route) => false, // Remove all previous routes
      );
    }
  }

  Future<void> _handleModuleTap(Map<String, dynamic> module) async {
    // Check if module has a web URL path
    if (module.containsKey('urlPath')) {
      try {
        // Get the domain from SharedPreferences
        final domain = await dept_service.getDomainFromPrefs();
        if (domain.isEmpty) {
          Fluttertoast.showToast(msg: "Domain not found. Please login again.");
          return;
        }

        // Build the full URL
        final urlPath = module['urlPath'] as String;
        final url = 'https://$domain.efeedor.com$urlPath';
        final title = module['title'] as String;

        // Navigate to WebView page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => WebViewPage(
              url: url,
              title: title,
            ),
          ),
        );
      } catch (e) {
        Fluttertoast.showToast(msg: "Error opening link: ${e.toString()}");
      }
    } else if (module.containsKey('page')) {
      // Navigate directly to module page
      // Data should already be preloaded when dashboard first loads
      // No need to preload again here - just navigate
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => module['page']));
    }
  }

  void _accessWebDashboard() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AccessWebDashboardPage()),
    );
  }

  void _syncData() {
    // Implement data sync logic
    Fluttertoast.showToast(msg: "Syncing data...");
  }

  void _updateApp() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => UpdateAppPage()),
    );
  }

  void _manageTickets() {
    // TODO: Implement manage tickets functionality
    Fluttertoast.showToast(msg: "Manage Tickets - Coming Soon");
  }

  void _userActivity() {
    // TODO: Implement user activity functionality
    Fluttertoast.showToast(msg: "User Activity - Coming Soon");
  }

  void _openMenuBottomSheet() {
    final List<Map<String, dynamic>> menuItems = [
      {
        'icon': Icons.dashboard,
        'title': 'Access Web Dashboard',
        'color': Colors.blue,
        'action': _accessWebDashboard,
      },
      {
        'icon': Icons.sync,
        'title': 'Refresh Data',
        'color': Colors.green,
        'action': _syncData,
      },
      {
        'icon': Icons.system_update,
        'title': 'Update App',
        'color': Colors.orange,
        'action': _updateApp,
      },
      {
        'icon': Icons.share,
        'title': 'Share',
        'color': Colors.grey, // visually disabled
        'action': () {
          // Blocked – no action
        },
      },
      {
        'icon': Icons.medical_services,
        'title': 'Support',
        'color': Colors.teal,
        'action': () {},
      },
      {
        'icon': Icons.person,
        'title': 'Profile',
        'color': Colors.purple,
        'action': _openProfileDrawer,
      },
      {
        'icon': Icons.history,
        'title': 'User Activity',
        'color': Colors.cyan,
        'action': _userActivity,
      },
      {
        'icon': Icons.info,
        'title': 'About',
        'color': Colors.indigo,
        'action': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AboutPage()),
          );
        },
      },
      {
        'icon': Icons.exit_to_app,
        'title': 'Logout',
        'color': Colors.red[600]!,
        'action': _logout,
      },
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 300),
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, (1 - value) * 100),
              child: Opacity(
                opacity: value,
                child: child,
              ),
            );
          },
          child: Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              children: [
                // Subtle handle
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
                const SizedBox(height: 16),
                // Enhanced grid layout with animations and better icons
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          // Access Web Dashboard
                          _buildMenuItem(menuItems[0], 0, isFullWidth: true),
                          const SizedBox(height: 16),
                          // Refresh Data next to Update App
                          Row(
                            children: [
                              Expanded(child: _buildMenuItem(menuItems[1], 1)),
                              const SizedBox(width: 16),
                              Expanded(child: _buildMenuItem(menuItems[2], 2)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Share App next to Support
                          Row(
                            children: [
                              Expanded(child: _buildMenuItem(menuItems[3], 3)),
                              const SizedBox(width: 16),
                              Expanded(child: _buildMenuItem(menuItems[4], 4)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Profile next to User Activity
                          Row(
                            children: [
                              Expanded(child: _buildMenuItem(menuItems[5], 5)),
                              const SizedBox(width: 16),
                              Expanded(child: _buildMenuItem(menuItems[6], 6)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // About next to Logout
                          Row(
                            children: [
                              Expanded(child: _buildMenuItem(menuItems[7], 7)),
                              const SizedBox(width: 16),
                              Expanded(child: _buildMenuItem(menuItems[8], 8)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Efeedor Logo at the bottom
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Center(
                    child: Image.asset(
                      'assets/images/Product_Branding_logo.png',
                      width: 120,
                      height: 120,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openProfileDrawer() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('name') ?? 'User Name';
    final email = prefs.getString('email') ?? 'user@example.com';
    final mobile = prefs.getString('mobile') ?? 'No mobile number provided';
    final designation =
        prefs.getString('designation') ?? 'No designation provided';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        efeedorBrandGreen.withOpacity(0.3),
                        efeedorBrandGreen.withOpacity(0.2),
                      ],
                    ),
                    border: Border.all(
                      color: efeedorBrandGreen.withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                  child:
                      const Icon(Icons.person, size: 40, color: Colors.white),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.normal,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  email,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  mobile,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  designation,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Divider(),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  // Helper method to build menu items
  Widget _buildMenuItem(Map<String, dynamic> item, int index,
      {bool isFullWidth = false}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 100)),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset((1 - value) * 50, 0),
            child: child,
          ),
        );
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _hoveredItems[index] = true),
        onExit: (_) => setState(() => _hoveredItems[index] = false),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(0),
            onTap: () {
              Navigator.pop(context);
              item['action']();
            },
            splashColor: Colors.grey.withOpacity(0.3),
            highlightColor: Colors.grey.withOpacity(0.2),
            child: Container(
              width: isFullWidth ? double.infinity : null,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              decoration: BoxDecoration(
                color: _hoveredItems[index] == true
                    ? Colors.grey[200] // Lighter color on hover
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(0),
                border: Border.all(
                  color: Colors.grey.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          item['color'].withOpacity(0.3),
                          item['color'].withOpacity(0.2),
                        ],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: item['color'].withOpacity(0.5),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      item['icon'],
                      color: item['color'],
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item['title'],
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  if (!isFullWidth)
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.grey[600],
                      size: 16,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppHeaderWrapper(
      titleWidget: Image.asset(
        'assets/images/efeedor_white_logo2.png',
        width: 100,
        height: 100,
        fit: BoxFit.contain,
      ),
      showBackButton: false,
      showLogo: false,
      showLanguageSelector: false,
      actions: [
        // Notification bell icon with badge
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.sync),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OfflineFeedbackSyncPage(),
                  ),
                ).then((_) {
                  // Refresh count when returning
                  _loadOfflineFeedbackCount();
                });
              },
            ),
            if (_offlineFeedbackCount > 0)
              Positioned(
                right: 11,
                top: 11,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 14,
                    minHeight: 14,
                  ),
                  child: Text(
                    '$_offlineFeedbackCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: efeedorBrandGreen,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        elevation: 0, // Remove shadow effect
        onTap: (i) {
          if (i == 3) {
            _openMenuBottomSheet(); // BOTTOM SHEET MENU
          } else if (i == 2) {
            _manageTickets(); // MANAGE TICKETS
          } else if (i == 1) {
            _accessWebDashboard(); // DASHBOARD
          } else {
            setState(() => _selectedIndex = i);
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(
              icon: Icon(Icons.confirmation_number), label: 'Tickets'),
          BottomNavigationBarItem(icon: Icon(Icons.menu), label: 'Menu'),
        ],
      ),
      child: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Hospital Logo - Rectangular container
                      const HospitalLogoWidget(
                        height: 80,
                        padding: EdgeInsets.all(16),
                        showRectangular: true,
                        showCircular: false,
                      ),
                      const SizedBox(height: 16),
                      // Search bar
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (v) => setState(() => _query = v),
                          decoration: InputDecoration(
                            hintText: 'Search', // Always English on Dashboard
                            hintStyle:
                                TextStyle(color: Colors.black.withOpacity(0.4)),
                            border: InputBorder.none,
                            prefixIcon:
                                const Icon(Icons.search, color: Colors.black45),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_isLoadingPermissions)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(efeedorBrandGreen),
                      ),
                    ),
                  ),
                )
              else if (_filteredModules.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No modules available',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'You don\'t have access to any modules',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final module = _filteredModules[index];
                      return GestureDetector(
                        onTap: () => _handleModuleTap(module),
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: (module['color'] as Color)
                                      .withOpacity(0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(module['icon'],
                                    color: module['color'], size: 24),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      module['title'],
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      module['desc'],
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right,
                                  color: Colors.black38)
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: _filteredModules.length,
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Center(
                    child: Image.asset(
                      'assets/images/Product_Branding_logo.png',
                      width: 150,
                      height: 150,
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Logout icon in bottom-right corner
          Positioned(
            bottom: 20,
            right: 20,
            child: Container(
              decoration: BoxDecoration(
                color: efeedorBrandGreen,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.logout, size: 28, color: Colors.white),
                onPressed: _logout,
                tooltip: 'Logout', // Always English on Dashboard
                padding: const EdgeInsets.all(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
