import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:devkitflutter/ui/op_feedback_page.dart'; // Adjust if needed
import 'package:devkitflutter/ui/webview_page.dart';
import 'package:devkitflutter/ui/signin.dart';
import 'package:devkitflutter/config/constant.dart';
import 'package:devkitflutter/widgets/app_header_wrapper.dart';
import 'package:devkitflutter/widgets/hospital_logo_widget.dart';
import 'package:devkitflutter/services/department_service.dart' as dept_service;
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

  @override
  void initState() {
    super.initState();
    _loadPermissions();
    // Dashboard always uses English - no language listener needed
  }

  // All available modules with their permission keys
  final List<Map<String, dynamic>> _allModules = [
    {
      'title': 'IP Discharge Feedback',
      'icon': Icons.exit_to_app,
      'color': Colors.blue,
      'desc': 'Submit feedback for in-patient discharge experience',
      'urlPath': '/ipfb', // Web URL path
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
      // Internal navigation for Outpatient Feedback
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => module['page']));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppHeaderWrapper(
      title: 'Dashboard', // Always English on Dashboard
      showBackButton: false,
      showLogo: false,
      showLanguageSelector: false,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(
              icon: Icon(Icons.menu), label: 'Menu'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings), label: 'Settings'),
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
                              color:
                                  (module['color'] as Color).withOpacity(0.12),
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
                                      fontSize: 13,
                                      color: Colors.black.withOpacity(0.6)),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: Colors.black38)
                        ],
                      ),
                    ),
                  );
                },
                childCount: _filteredModules.length,
              ),
            ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
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
