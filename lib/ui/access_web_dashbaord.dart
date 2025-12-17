import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:devkitflutter/config/constant.dart';
import 'package:devkitflutter/ui/webview_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:devkitflutter/services/department_service.dart' as dept_service;

class AccessWebDashboardPage extends StatelessWidget {
  const AccessWebDashboardPage({Key? key}) : super(key: key);

  Future<void> _goToWebDashboard(BuildContext context) async {
    final domain = await dept_service.getDomainFromPrefs();
    if (domain.isEmpty) {
      Fluttertoast.showToast(msg: "Domain not found. Please login again.");
      return;
    }
    final url = 'https://$domain.efeedor.com/dashboard';
    final title = 'Web Dashboard';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WebViewPage(url: url, title: title),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: efeedorBrandGreen,
        title: const Text(
          'Access Web Dashboard',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.web,
                size: 100,
                color: Colors.blue,
              ),
              const SizedBox(height: 20),
              const Text(
                'Web Dashboard',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Access the web dashboard to manage your data and settings.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () => _goToWebDashboard(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: efeedorBrandGreen,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Go to Web Dashboard',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
