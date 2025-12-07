import 'package:flutter/material.dart';
import '../services/offline_storage_service.dart';
import '../services/sync_service.dart';
import '../model/offline_feedback_entry.dart';
import '../config/constant.dart';
import '../widgets/app_header_wrapper.dart';
import '../services/connectivity_helper.dart';

/// Page for syncing offline feedbacks to the server
/// Has separate sections for OP and IP feedback
class OfflineFeedbackSyncPage extends StatefulWidget {
  const OfflineFeedbackSyncPage({Key? key}) : super(key: key);

  @override
  State<OfflineFeedbackSyncPage> createState() => _OfflineFeedbackSyncPageState();
}

class _OfflineFeedbackSyncPageState extends State<OfflineFeedbackSyncPage> {
  List<OfflineFeedbackEntry> _opFeedbacks = [];
  List<OfflineFeedbackEntry> _ipFeedbacks = [];
  bool _isLoading = false;
  bool _isSyncingOP = false;
  bool _isSyncingIP = false;

  @override
  void initState() {
    super.initState();
    _loadOfflineFeedbacks();
  }

  /// Load all offline feedbacks from local storage (OP and IP separately)
  Future<void> _loadOfflineFeedbacks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final opFeedbacks = await OfflineStorageService.loadOfflineOPFeedback();
      final ipFeedbacks = await OfflineStorageService.loadOfflineIPFeedback();
      setState(() {
        _opFeedbacks = opFeedbacks;
        _ipFeedbacks = ipFeedbacks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Format timestamp for display
  String _formatTimestamp(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  /// Sync OP offline feedbacks to the server using sinkdata.php
  Future<void> _syncOPData() async {
    // Check internet connection
    final online = await isOnline();
    if (!online) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("No Internet"),
            content: const Text("Internet Error Try Again"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
        );
      }
      return;
    }

    setState(() {
      _isSyncingOP = true;
    });

    try {
      // Sync OP feedbacks only
      final result = await SyncService.syncOPFeedbacks();
      
      final successCount = result['success'] ?? 0;
      final failCount = result['failed'] ?? 0;

      setState(() {
        _isSyncingOP = false;
      });

      // Reload list
      await _loadOfflineFeedbacks();

      // Show dialog: "Sync Completed"
      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Sync Completed"),
            content: Text(
              'Outpatient Feedback\nSuccessfully synced: $successCount\nFailed: $failCount',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSyncingOP = false;
      });

      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Error"),
            content: Text("Internet Error Try Again\n\n$e"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
        );
      }
    }
  }

  /// Sync IP offline feedbacks to the server using sinkdataip.php
  Future<void> _syncIPData() async {
    // Check internet connection
    final online = await isOnline();
    if (!online) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("No Internet"),
            content: const Text("Internet Error Try Again"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
        );
      }
      return;
    }

    setState(() {
      _isSyncingIP = true;
    });

    try {
      // Sync IP feedbacks only
      final result = await SyncService.syncIPFeedbacks();
      
      final successCount = result['success'] ?? 0;
      final failCount = result['failed'] ?? 0;

      setState(() {
        _isSyncingIP = false;
      });

      // Reload list
      await _loadOfflineFeedbacks();

      // Show dialog: "Sync Completed"
      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Sync Completed"),
            content: Text(
              'Inpatient Discharge Feedback\nSuccessfully synced: $successCount\nFailed: $failCount',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSyncingIP = false;
      });

      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Error"),
            content: Text("Internet Error Try Again\n\n$e"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalCount = _opFeedbacks.length + _ipFeedbacks.length;

    return AppHeaderWrapper(
      title: 'Offline Feedback Sync',
      showLogo: false,
      showLanguageSelector: false,
      child: Column(
        children: [
          // Total count at top
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Icon(
                  Icons.cloud_off,
                  color: efeedorBrandGreen,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Offline Feedbacks',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$totalCount feedback${totalCount != 1 ? 's' : ''}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // List view with expandable sections
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : totalCount == 0
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No offline feedbacks',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            // SECTION 1: OUTPATIENT FEEDBACK (OP)
                            Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ExpansionTile(
                                initiallyExpanded: _opFeedbacks.isNotEmpty,
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.people_alt,
                                    color: Colors.green,
                                    size: 20,
                                  ),
                                ),
                                title: const Text(
                                  'Outpatient Feedback (OP)',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  '${_opFeedbacks.length} feedback${_opFeedbacks.length != 1 ? 's' : ''}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                children: [
                                  if (_opFeedbacks.isEmpty)
                                    Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Text(
                                        'No offline OP feedbacks',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    )
                                  else
                                    ..._opFeedbacks.map((entry) {
                                      return ListTile(
                                        dense: true,
                                        leading: Icon(
                                          Icons.feedback,
                                          size: 18,
                                          color: Colors.grey[600],
                                        ),
                                        title: Text(
                                          _formatTimestamp(entry.createdAt),
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      );
                                    }),
                                  if (_opFeedbacks.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          onPressed: _isSyncingOP ? null : _syncOPData,
                                          icon: _isSyncingOP
                                              ? const SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                  ),
                                                )
                                              : const Icon(Icons.sync, color: Colors.white),
                                          label: Text(
                                            _isSyncingOP ? 'Syncing...' : 'Sync Outpatient Feedback',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            elevation: 2,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // SECTION 2: INPATIENT DISCHARGE FEEDBACK (IP)
                            Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ExpansionTile(
                                initiallyExpanded: _ipFeedbacks.isNotEmpty,
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.exit_to_app,
                                    color: Colors.blue,
                                    size: 20,
                                  ),
                                ),
                                title: const Text(
                                  'Inpatient Discharge Feedback (IP)',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  '${_ipFeedbacks.length} feedback${_ipFeedbacks.length != 1 ? 's' : ''}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                children: [
                                  if (_ipFeedbacks.isEmpty)
                                    Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Text(
                                        'No offline IP feedbacks',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    )
                                  else
                                    ..._ipFeedbacks.map((entry) {
                                      return ListTile(
                                        dense: true,
                                        leading: Icon(
                                          Icons.feedback,
                                          size: 18,
                                          color: Colors.grey[600],
                                        ),
                                        title: Text(
                                          _formatTimestamp(entry.createdAt),
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      );
                                    }),
                                  if (_ipFeedbacks.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          onPressed: _isSyncingIP ? null : _syncIPData,
                                          icon: _isSyncingIP
                                              ? const SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                  ),
                                                )
                                              : const Icon(Icons.sync, color: Colors.white),
                                          label: Text(
                                            _isSyncingIP ? 'Syncing...' : 'Sync Inpatient Feedback',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.blue,
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            elevation: 2,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
