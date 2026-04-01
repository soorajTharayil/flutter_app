import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/app_header_wrapper.dart';
import '../config/constant.dart';
import '../services/ticket_api_service.dart';
import '../services/incident_workflow_api.dart';
import '../services/employee_complaint_navigation.dart';
import '../model/ticket_detail_model.dart';
import '../services/ip_question_service.dart';
import '../services/department_service.dart';
import '../model/op_question_model.dart';
import '../model/department_model.dart';

/// Page for managing individual ticket details
class ManageTicketPage extends StatefulWidget {
  final String ticketId;
  final String module;
  final String? uid;
  final String? patientName;
  final String? patientId;
  final String? patientMobile;

  const ManageTicketPage({
    Key? key,
    required this.ticketId,
    required this.module,
    this.uid,
    this.patientName,
    this.patientId,
    this.patientMobile,
  }) : super(key: key);

  @override
  State<ManageTicketPage> createState() => _ManageTicketPageState();
}

class _ManageTicketPageState extends State<ManageTicketPage> {
  TicketDetail? _ticketDetail;
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedStatus = '';
  String? _originalStatus; // Track original status from backend
  bool _hasUserChangedStatus = false; // Track if user has changed status
  bool _showReopenSection = false; // Track if reopen section should be shown
  
  // Controllers for input fields
  final TextEditingController _addressMessageController = TextEditingController();
  final TextEditingController _rcaController = TextEditingController();
  final TextEditingController _capaController = TextEditingController();
  final TextEditingController _closeCommentController = TextEditingController();
  final TextEditingController _transferReasonController = TextEditingController();
  final TextEditingController _reopenReasonController = TextEditingController();
  final TextEditingController _rejectReasonController = TextEditingController();
  String? _selectedDepartmentId; // For transfer dropdown
  List<dynamic> _transferDepartments = []; // For transfer dropdown - QuestionSet for IP, Department for OP
  bool _isLoadingDepartments = false;

  // Incident: Accept & Assign / Re-assign
  List<IncidentUser> _incidentUsers = [];
  bool _loadingIncidentUsers = false;
  final TextEditingController _assignTlSearchController = TextEditingController();
  final TextEditingController _assignPmSearchController = TextEditingController();
  final TextEditingController _assignNotesController = TextEditingController();
  final TextEditingController _tlManualIdsController = TextEditingController();
  final TextEditingController _pmManualIdsController = TextEditingController();
  DateTime? _assignTatDue;
  final Set<String> _selectedTeamLeaderIds = {};
  final Set<String> _selectedProcessMonitorIds = {};
  bool _savingIncidentAssign = false;

  // Incident: Verify & Close (RCA tool + remarks)
  String _incidentRcaTool = 'DEFAULT';
  final TextEditingController _incRootCauseController = TextEditingController();
  late final List<TextEditingController> _incWhyControllers;
  late final List<TextEditingController> _inc2hControllers;
  final TextEditingController _incCorrectiveController = TextEditingController();
  final TextEditingController _incPreventiveController = TextEditingController();
  final TextEditingController _incVerificationController = TextEditingController();
  bool _savingIncidentVerifyClose = false;

  /// 5W2H labels — same as web `ticket_track` / RCA form.
  static const List<String> _incident5w2hQuestionLabels = [
    'What happened?',
    'Why did it happen?',
    'Where did it happen?',
    'When did it happen?',
    'Who was involved?',
    'How did it happen?',
    'How much/How many (impact/cost)?',
  ];

  @override
  void initState() {
    super.initState();
    _incWhyControllers = List.generate(5, (_) => TextEditingController());
    _inc2hControllers = List.generate(7, (_) => TextEditingController());
    _fetchTicketDetail();
  }

  @override
  void dispose() {
    _addressMessageController.dispose();
    _rcaController.dispose();
    _capaController.dispose();
    _closeCommentController.dispose();
    _transferReasonController.dispose();
    _reopenReasonController.dispose();
    _rejectReasonController.dispose();
    _assignTlSearchController.dispose();
    _assignPmSearchController.dispose();
    _assignNotesController.dispose();
    _tlManualIdsController.dispose();
    _pmManualIdsController.dispose();
    _incRootCauseController.dispose();
    for (final c in _incWhyControllers) {
      c.dispose();
    }
    for (final c in _inc2hControllers) {
      c.dispose();
    }
    _incCorrectiveController.dispose();
    _incPreventiveController.dispose();
    _incVerificationController.dispose();
    super.dispose();
  }

  /// Fetch ticket detail from API
  Future<void> _fetchTicketDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get domain
      final prefs = await SharedPreferences.getInstance();
      final domain = prefs.getString('domain') ?? '';

      if (domain.isEmpty) {
        throw Exception('Domain not found. Please login again.');
      }

      // Fetch ticket detail
      final response = await TicketApiService.fetchTicketDetail(
        domain: domain,
        module: widget.module,
        ticketId: widget.ticketId,
      );

      if (mounted) {
        // Merge API data with passed navigation arguments
        // API data takes precedence, but use passed data as fallback
        final apiDetail = response.ticketDetail;
        String? pickNonEmpty(String? a, String? b, String? c) {
          for (final x in [a, b, c]) {
            if (x != null && x.trim().isNotEmpty) return x.trim();
          }
          return null;
        }

        final mergedEmployeeId =
            pickNonEmpty(apiDetail.employeeId, apiDetail.patientId, widget.patientId);
        final mergedEmployeeName =
            pickNonEmpty(apiDetail.employeeName, apiDetail.patientName, widget.patientName);

        final mergedDetail = TicketDetail(
          ticketId: apiDetail.ticketId,
          status: apiDetail.status,
          createdOn: apiDetail.createdOn,
          reasonText: apiDetail.reasonText,
          submissionComment: apiDetail.submissionComment,
          departmentName: apiDetail.departmentName,
          departDesc: apiDetail.departDesc,
          ward: apiDetail.ward,
          rating: apiDetail.rating,
          // Patient data: Use API data if available, otherwise use passed navigation data
          patientName: (apiDetail.patientName?.trim().isNotEmpty == true) 
              ? apiDetail.patientName?.trim()
              : (widget.patientName?.trim().isNotEmpty == true ? widget.patientName?.trim() : null),
          patientId: (apiDetail.patientId?.trim().isNotEmpty == true) 
              ? apiDetail.patientId?.trim()
              : (widget.patientId?.trim().isNotEmpty == true ? widget.patientId?.trim() : null),
          patientMobile: (apiDetail.patientMobile?.trim().isNotEmpty == true) 
              ? apiDetail.patientMobile?.trim()
              : (widget.patientMobile?.trim().isNotEmpty == true ? widget.patientMobile?.trim() : null),
          floor: apiDetail.floor,
          bedNo: apiDetail.bedNo,
          employeeId: mergedEmployeeId,
          employeeName: mergedEmployeeName,
          feedbackId: apiDetail.feedbackId,
          incidentDataset: apiDetail.incidentDataset,
          incidentOccurredOn: apiDetail.incidentOccurredOn,
          incidentSource: apiDetail.incidentSource,
          assignedTeamLeader: apiDetail.assignedTeamLeader,
          assignedProcessMonitor: apiDetail.assignedProcessMonitor,
          verifiedStatus: apiDetail.verifiedStatus,
        );
        
        setState(() {
          _ticketDetail = mergedDetail;
          final normalizedStatus = _normalizeStatus(mergedDetail.status);
          _selectedStatus = normalizedStatus;
          _originalStatus = normalizedStatus; // Store original status from backend
          _hasUserChangedStatus = false; // Reset on new ticket load
          _showReopenSection = false; // Reset reopen section on new ticket load
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        // On API failure, use passed data if available to show patient details
        if (widget.patientName != null || widget.patientId != null || widget.patientMobile != null) {
          final fallbackDetail = TicketDetail(
            ticketId: widget.ticketId,
            patientName: widget.patientName,
            patientId: widget.patientId,
            patientMobile: widget.patientMobile,
            employeeId: widget.patientId,
            employeeName: widget.patientName,
            status: 'Open',
          );
          setState(() {
            _ticketDetail = fallbackDetail;
            final normalizedStatus = _normalizeStatus(fallbackDetail.status);
            _selectedStatus = normalizedStatus;
            _originalStatus = normalizedStatus; // Store original status
            _hasUserChangedStatus = false; // Reset on new ticket load
            _showReopenSection = false; // Reset reopen section on new ticket load
            _isLoading = false;
            _errorMessage = e.toString().replaceAll('Exception: ', '');
          });
        } else {
          setState(() {
            _errorMessage = e.toString().replaceAll('Exception: ', '');
            _isLoading = false;
          });
        }
      }
    }
  }

  /// Format date string for display
  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return '-';
    }
    try {
      DateTime? date;
      if (dateString.contains(' ')) {
        date = DateTime.tryParse(dateString);
      } else if (dateString.contains('-')) {
        date = DateTime.tryParse(dateString);
      }
      
      if (date != null) {
        if (dateString.contains(' ')) {
          return DateFormat('yyyy-MM-dd HH:mm:ss').format(date);
        } else {
          return DateFormat('yyyy-MM-dd').format(date);
        }
      }
      return dateString;
    } catch (e) {
      return dateString;
    }
  }

  /// Map numeric rating to text label
  /// 1 = Worst, 2 = Poor, 3 = Good, 4 = Very Good, 5 = Excellent
  String? _getRatingText(String? rating) {
    if (rating == null || rating.isEmpty) return null;
    
    // Try to parse as integer
    final ratingInt = int.tryParse(rating.trim());
    if (ratingInt != null) {
      switch (ratingInt) {
        case 1:
          return 'Worst';
        case 2:
          return 'Poor';
        case 3:
          return 'Good';
        case 4:
          return 'Very Good';
        case 5:
          return 'Excellent';
        default:
          return null;
      }
    }
    
    // If not numeric, check if it's already a text label
    final ratingLower = rating.trim().toLowerCase();
    if (ratingLower == 'worst' || ratingLower == 'poor' || ratingLower == 'good' || 
        ratingLower == 'very good' || ratingLower == 'excellent') {
      // Capitalize first letter of each word
      return rating.split(' ').map((word) {
        if (word.isEmpty) return word;
        return word[0].toUpperCase() + word.substring(1).toLowerCase();
      }).join(' ');
    }
    
    return null;
  }

  /// Get ticket details description
  String _getTicketDetailsText() {
    if (_ticketDetail == null) return '-';
    
    final rating = _ticketDetail!.rating;
    final ratingText = _getRatingText(rating);
    final departDesc = _ticketDetail!.departDesc ?? _ticketDetail!.departmentName ?? '';
    
    if (ratingText != null && departDesc.isNotEmpty) {
      return 'Rated $ratingText for $departDesc';
    } else if (departDesc.isNotEmpty) {
      return departDesc;
    } else if (_ticketDetail!.reasonText != null && _ticketDetail!.reasonText!.isNotEmpty) {
      return _ticketDetail!.reasonText!;
    }
    return '-';
  }

  /// Get patient name with ID text
  /// Returns formatted as "NAME (ID)" or just name/ID if one is missing
  String? _getPatientNameWithId() {
    if (_ticketDetail == null) return null;
    
    final name = _ticketDetail!.patientName?.trim() ?? '';
    final patientId = _ticketDetail!.patientId?.trim() ?? '';
    
    if (name.isEmpty && patientId.isEmpty) {
      return null; // Don't show if both are empty
    }
    
    if (name.isNotEmpty && patientId.isNotEmpty) {
      return '$name ($patientId)';
    }
    
    return name.isNotEmpty ? name : patientId;
  }

  /// Get patient mobile number
  /// Returns mobile number if available, null otherwise
  String? _getPatientMobile() {
    if (_ticketDetail == null) return null;
    final mobile = _ticketDetail!.patientMobile?.trim();
    return mobile?.isNotEmpty == true ? mobile : null;
  }

  /// Incident track: employee id (explicit field, else legacy patient id).
  String? _getIncidentEmployeeId() {
    if (_ticketDetail == null) return null;
    final e = _ticketDetail!.employeeId?.trim();
    if (e != null && e.isNotEmpty) return e;
    final p = _ticketDetail!.patientId?.trim();
    return p != null && p.isNotEmpty ? p : null;
  }

  /// Incident track: employee name (explicit field, else legacy patient name).
  String? _getIncidentEmployeeName() {
    if (_ticketDetail == null) return null;
    final e = _ticketDetail!.employeeName?.trim();
    if (e != null && e.isNotEmpty) return e;
    final p = _ticketDetail!.patientName?.trim();
    return p != null && p.isNotEmpty ? p : null;
  }

  Widget _buildIncidentEmployeeDetailsColumn() {
    final hasCore = _getIncidentEmployeeId() != null || _getIncidentEmployeeName() != null;
    final hasDept = _getDepartmentInfo() != null;
    final hasPhone = _getPatientMobile() != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_getIncidentEmployeeId() != null)
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              const Text(
                'Employee Id: ',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              InkWell(
                onTap: () => openIncidentReportDetailPage(
                  context,
                  ticketId: widget.ticketId,
                ),
                child: Text(
                  _getIncidentEmployeeId()!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: efeedorBrandGreen,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        if (_getIncidentEmployeeName() != null) ...[
          if (_getIncidentEmployeeId() != null) const SizedBox(height: 4),
          Text(
            'Employee Name: ${_getIncidentEmployeeName()}',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ],
        if (hasDept) ...[
          if (hasCore) const SizedBox(height: 4),
          Text(
            _getDepartmentInfo()!,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
            ),
          ),
        ],
        if (hasPhone) ...[
          if (hasCore || hasDept) const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.phone,
                size: 16,
                color: Colors.grey[700],
              ),
              const SizedBox(width: 4),
              Text(
                _getPatientMobile()!,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ],
        if (!hasCore && !hasDept && !hasPhone)
          const Text(
            '-',
            style: TextStyle(fontSize: 14, color: Colors.black87),
          ),
      ],
    );
  }

  /// Get department/location info
  /// Returns formatted as "From <bed_no> in <ward>" or "From <ward>" or null if not available
  String? _getDepartmentInfo() {
    if (_ticketDetail == null) return null;
    
    final bedNo = _ticketDetail!.bedNo?.trim();
    final ward = _ticketDetail!.ward?.trim() ?? _ticketDetail!.floor?.trim();
    
    // Build location string similar to Cordova: "From <bed_no> in <ward>"
    if (bedNo != null && bedNo.isNotEmpty && ward != null && ward.isNotEmpty) {
      return 'From $bedNo in $ward';
    } else if (bedNo != null && bedNo.isNotEmpty) {
      return 'From $bedNo';
    } else if (ward != null && ward.isNotEmpty) {
      return 'From $ward';
    }
    
    // Fallback to department name if location fields are not available
    final department = _ticketDetail!.departmentName?.trim() ?? 
                       _ticketDetail!.departDesc?.trim() ?? '';
    
    if (department.isEmpty) return null;
    
    return 'From $department';
  }

  /// Normalize status value (map UI values to canonical database values)
  String _normalizeStatus(String? status) {
    if (status == null || status.isEmpty) {
      return 'Open';
    }
    
    final statusUpper = status.toUpperCase().trim();
    
    // Normalize "Close" to "Closed" for consistency
    if (statusUpper == 'CLOSE') {
      return 'Closed';
    }
    
    // Normalize "Address" to "Addressed" (canonical database value)
    if (statusUpper == 'ADDRESS') {
      return 'Addressed';
    }
    
    // Normalize "Transfer" to "Transfered" (canonical database value)
    if (statusUpper == 'TRANSFER') {
      return 'Transfered';
    }
    
    // Return unchanged for all other values
    return status;
  }

  /// Check if ticket is currently in closed state
  bool _isClosedStatus(String status) {
    final statusUpper = status.toUpperCase();
    return statusUpper == 'CLOSE' ||
        statusUpper == 'CLOSED' ||
        statusUpper == 'VERIFIED';
  }

  /// Get color for status value text
  Color _getStatusColor(String status) {
    final statusUpper = status.toUpperCase();
    
    // Addressed status → Yellow
    if (statusUpper == 'ADDRESS' || statusUpper == 'ADDRESSED') {
      return Colors.yellow.shade700;
    }
    
    // Transferred status → Blue
    if (statusUpper == 'TRANSFER' || statusUpper == 'TRANSFERED' || statusUpper == 'TRANSFERRED') {
      return Colors.blue;
    }
    
    // Reopen status → Purple
    if (statusUpper == 'REOPEN') {
      return Colors.purple;
    }

    if (statusUpper == 'REJECT' || statusUpper == 'REJECTED') {
      return Colors.deepOrange;
    }

    if (status.contains('Verify & Close')) {
      return const Color(0xFFF09A22);
    }
    if (status.contains('Accept & Assign')) {
      return const Color(0xFF2A73E8);
    }
    if (status.contains('Re-assign') || status.contains('Explain with RCA')) {
      return const Color(0xFF3F1670);
    }
    
    // Keep existing colors for Open and Closed
    if (statusUpper == 'OPEN') {
      return Colors.red;
    }
    
    if (_isClosedStatus(status)) {
      return Colors.green;
    }
    
    // Default: black
    return Colors.black87;
  }

  /// Normalizes incident status for comparison (mirrors ticket_track.php branches).
  String _incidentWebStatusKey(String? raw) {
    if (raw == null || raw.trim().isEmpty) return 'open';
    var t = raw.trim().toLowerCase().replaceAll(' ', '');
    if (t == 're-assigned') return 're-assigned';
    if (t == 'transfered' || t == 'transferred') return 'transfered';
    return t;
  }

  /// Incident workflow: matches incidentmodules/ticket_track.php `<select>` option visibility.
  List<String> _getIncidentWorkflowActionOptions() {
    final raw = (_originalStatus ?? _selectedStatus ?? '').trim();
    final key = _incidentWebStatusKey(raw);

    if (key == 'closed' || key == 'verified') {
      return ['Closed', 'Reopen'];
    }
    if (key == 'rejected') {
      return ['Rejected', 'Reopen'];
    }
    if (key == 'deleted') {
      return [raw.isEmpty ? 'Deleted' : raw];
    }

    final actions = <String>[];

    // Accept & Assign — hidden for Assigned, Rejected, Described, Closed, Re-assigned
    if (!{'assigned', 'rejected', 'described', 'closed', 're-assigned'}.contains(key)) {
      actions.add('Accept & Assign');
    }

    // Re-assign — only when not Open and not Closed
    if (key != 'closed' && key != 'open') {
      actions.add('Re-assign');
    }

    // Reject — hidden for Rejected, Assigned, Described, Closed
    if (!{'rejected', 'assigned', 'described', 'closed'}.contains(key)) {
      actions.add('Reject');
    }

    // Explain with RCA & CAPA — only when not Open and not Closed
    if (key != 'closed' && key != 'open') {
      actions.add('Explain with RCA & CAPA');
    }

    // Verify & Close (capa) — when not Closed and not Rejected
    if (key != 'closed' && key != 'rejected') {
      actions.add('Verify & Close');
    }

    if (raw.isEmpty) return actions;
    final hasCurrent =
        actions.any((a) => a.toLowerCase() == raw.toLowerCase());
    if (hasCurrent) return actions;
    return [raw, ...actions];
  }

  /// Radio group value for incident status sheet (must match one of [options]).
  String _incidentSheetGroupValue(List<String> options) {
    final sel = _selectedStatus.trim();
    for (final o in options) {
      if (o.toLowerCase() == sel.toLowerCase()) return o;
    }
    if (_isClosedStatus(sel) && options.contains('Closed')) return 'Closed';
    if (options.isNotEmpty) return options.first;
    return sel;
  }

  /// Get available status options based on current ticket status
  List<String> _getAvailableStatusOptions() {
    if (widget.module == 'INCIDENT') {
      return _getIncidentWorkflowActionOptions();
    }

    // If ticket is closed, only show Closed and Reopen
    if (_isClosedStatus(_selectedStatus)) {
      return ['Closed', 'Reopen'];
    }

    // For active tickets, show full workflow options
    return ['Open', 'Address', 'Close', 'Transfer'];
  }

  /// Handle status change with proper state transitions
  void _handleStatusChange(String newStatus) {
    setState(() {
      // Mark that user has changed the status
      _hasUserChangedStatus = true;
      
      // If Reopen is selected, show reopen section and transition to Open (active state)
      if (newStatus == 'Reopen') {
        _selectedStatus = 'Open';
        _showReopenSection = true;
      } else {
        // Hide reopen section for other status changes
        _showReopenSection = false;
        if (newStatus == 'Close') {
          // Normalize "Close" to "Closed" for consistency (non-incident legacy label)
          _selectedStatus = 'Closed';
        } else if (widget.module == 'INCIDENT') {
          // Web incident track labels — keep exact strings for UI + section visibility
          _selectedStatus = newStatus;
        } else {
          // Keep the selected value as-is (Address/Transfer/Reject) for UI display
          _selectedStatus = newStatus;
        }
      }
    });
    if (widget.module == 'INCIDENT' &&
        (newStatus == 'Accept & Assign' || newStatus == 'Re-assign')) {
      _loadIncidentAssignableUsers();
    }
  }

  Future<void> _loadIncidentAssignableUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final domain = prefs.getString('domain') ?? '';
    final uid = prefs.getString('userid') ?? widget.uid ?? '';
    if (domain.isEmpty || uid.isEmpty) return;
    setState(() {
      _loadingIncidentUsers = true;
    });
    final list = await IncidentWorkflowApi.fetchAssignableUsers(domain: domain, uid: uid);
    if (!mounted) return;
    setState(() {
      _incidentUsers = list;
      _loadingIncidentUsers = false;
    });
  }

  /// Check if Address section should be visible
  bool _shouldShowAddressSection() {
    // Incident workflow uses web portal / track page for full forms; not the legacy Address picker.
    if (widget.module == 'INCIDENT') return false;
    // Only show if user has changed status to Address/Addressed
    if (!_hasUserChangedStatus) return false;
    final statusUpper = _selectedStatus.toUpperCase();
    return statusUpper == 'ADDRESS' || statusUpper == 'ADDRESSED';
  }

  /// Check if Reject section should be visible (INCIDENT only)
  bool _shouldShowRejectSection() {
    if (widget.module != 'INCIDENT') return false;
    if (!_hasUserChangedStatus) return false;
    return _selectedStatus.trim().toLowerCase() == 'reject';
  }

  /// Explain with RCA & CAPA still uses the full web Describe flow.
  bool _shouldShowIncidentPortalSection() {
    if (widget.module != 'INCIDENT') return false;
    if (!_hasUserChangedStatus) return false;
    return _selectedStatus.trim() == 'Explain with RCA & CAPA';
  }

  bool _shouldShowIncidentAssignSection() {
    if (widget.module != 'INCIDENT') return false;
    if (!_hasUserChangedStatus) return false;
    final s = _selectedStatus.trim();
    return s == 'Accept & Assign' || s == 'Re-assign';
  }

  Future<void> _openIncidentTrackUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final domain = prefs.getString('domain') ?? '';
    if (domain.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Domain not found. Please login again.')),
        );
      }
      return;
    }
    final uri = Uri.parse('https://$domain.efeedor.com/incident/track/${widget.ticketId}');
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open incident track page')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open link: $e')),
        );
      }
    }
  }

  Widget _buildIncidentPortalCard() {
    const title = 'Explain with RCA & CAPA';
    const body =
        'Full Describe flow (RCA tool, CAPA, attachments) is on the web incident track — same fields as ticket_track.php → Describe.';
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              style: TextStyle(fontSize: 14, color: Colors.grey[800], height: 1.35),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _openIncidentTrackUrl,
                icon: const Icon(Icons.open_in_browser, size: 20),
                label: const Text('Open incident track'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: efeedorBrandGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool get _isIncidentReassign =>
      widget.module == 'INCIDENT' && _selectedStatus.trim() == 'Re-assign';

  Widget _buildIncidentAssignCard() {
    final isReassign = _isIncidentReassign;
    final header = isReassign
        ? 'Re-assign incident to respective users'
        : 'Assign incident to respective users';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.grey[300],
            child: Text(
              header,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_loadingIncidentUsers)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                _buildIncidentUserRow(
                  label: 'Select Team Leader to input RCA/ CAPA',
                  searchController: _assignTlSearchController,
                  selected: _selectedTeamLeaderIds,
                  onToggle: (id, on) {
                    setState(() {
                      if (on) {
                        _selectedTeamLeaderIds.add(id);
                      } else {
                        _selectedTeamLeaderIds.remove(id);
                      }
                    });
                  },
                ),
                const SizedBox(height: 16),
                _buildIncidentUserRow(
                  label: 'Select Process monitors to monitor incident',
                  searchController: _assignPmSearchController,
                  selected: _selectedProcessMonitorIds,
                  onToggle: (id, on) {
                    setState(() {
                      if (on) {
                        _selectedProcessMonitorIds.add(id);
                      } else {
                        _selectedProcessMonitorIds.remove(id);
                      }
                    });
                  },
                ),
                if (_incidentUsers.isEmpty && !_loadingIncidentUsers) ...[
                  const SizedBox(height: 12),
                  Text(
                    'No user list from server (deploy api/incident_users.php) or enter user IDs below.',
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 8),
                  _buildIncidentManualIdsRow(
                    label: 'Team leader user IDs (comma-separated)',
                    controller: _tlManualIdsController,
                  ),
                  const SizedBox(height: 8),
                  _buildIncidentManualIdsRow(
                    label: 'Process monitor user IDs (comma-separated)',
                    controller: _pmManualIdsController,
                  ),
                ],
                const SizedBox(height: 16),
                _buildIncidentLabeledField(
                  label: 'Additional Notes',
                  child: TextField(
                    controller: _assignNotesController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Your inputs here',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildIncidentLabeledField(
                  label: 'TAT Due Date',
                  child: InkWell(
                    onTap: _pickAssignTatDue,
                    child: InputDecorator(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        filled: true,
                        fillColor: Colors.grey[50],
                        suffixIcon: const Icon(Icons.calendar_today, size: 20),
                      ),
                      child: Text(
                        _assignTatDue == null
                            ? 'Select date and time'
                            : DateFormat('dd-MM-yyyy HH:mm').format(_assignTatDue!),
                        style: TextStyle(
                          color: _assignTatDue == null ? Colors.grey[600] : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerLeft,
                  child: ElevatedButton(
                    onPressed: _savingIncidentAssign ? null : () => _submitIncidentAssign(isReassign),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: efeedorBrandGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: _savingIncidentAssign
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Submit', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncidentLabeledField({required String label, required Widget child}) {
    return LayoutBuilder(
      builder: (context, c) {
        final narrow = c.maxWidth < 560;
        if (narrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 8),
              child,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 280,
              child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            ),
            Expanded(child: child),
          ],
        );
      },
    );
  }

  Widget _buildIncidentUserRow({
    required String label,
    required TextEditingController searchController,
    required Set<String> selected,
    required void Function(String id, bool on) onToggle,
  }) {
    final q = searchController.text.trim().toLowerCase();
    final filtered = _incidentUsers.where((u) {
      if (q.isEmpty) return true;
      return u.displayName.toLowerCase().contains(q) || u.userId.toLowerCase().contains(q);
    }).toList();

    return _buildIncidentLabeledField(
      label: label,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search for names..',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    filled: true,
                    fillColor: Colors.grey[50],
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message: 'Select one or more users for this step.',
                child: Icon(Icons.info_outline, color: Colors.green[700], size: 22),
              ),
            ],
          ),
          if (_incidentUsers.isNotEmpty) ...[
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 180),
              child: Scrollbar(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final u = filtered[i];
                    final sel = selected.contains(u.userId);
                    return CheckboxListTile(
                      dense: true,
                      value: sel,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text(u.displayName, maxLines: 2, overflow: TextOverflow.ellipsis),
                      onChanged: (v) => onToggle(u.userId, v ?? false),
                    );
                  },
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIncidentManualIdsRow({
    required String label,
    required TextEditingController controller,
  }) {
    return _buildIncidentLabeledField(
      label: label,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: 'e.g. 12, 34',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
          fillColor: Colors.grey[50],
        ),
      ),
    );
  }

  Future<void> _pickAssignTatDue() async {
    final now = DateTime.now();
    final initial = _assignTatDue ?? now;
    final d = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (d == null || !mounted) return;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (t == null || !mounted) return;
    setState(() {
      _assignTatDue = DateTime(d.year, d.month, d.day, t.hour, t.minute);
    });
  }

  List<String> _parseCommaIds(String raw) {
    return raw
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  Future<void> _submitIncidentAssign(bool isReassign) async {
    final prefs = await SharedPreferences.getInstance();
    final domain = prefs.getString('domain') ?? '';
    final uid = prefs.getString('userid') ?? widget.uid ?? '';
    final name = prefs.getString('name') ?? '';
    if (domain.isEmpty || uid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login session incomplete.')),
      );
      return;
    }
    List<String> tlIds;
    List<String> pmIds;
    if (_incidentUsers.isNotEmpty) {
      tlIds = _selectedTeamLeaderIds.toList();
      pmIds = _selectedProcessMonitorIds.toList();
    } else {
      tlIds = _parseCommaIds(_tlManualIdsController.text);
      pmIds = _parseCommaIds(_pmManualIdsController.text);
    }
    if (tlIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one team leader (or enter IDs).')),
      );
      return;
    }
    final due = _assignTatDue;
    if (due == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select TAT due date')),
      );
      return;
    }
    final dueStr = DateFormat('yyyy-MM-dd HH:mm').format(due);
    final fid = _ticketDetail?.feedbackId;
    final extra = isReassign
        ? <String, dynamic>{
            'workflow': 'incident_reassign',
            if (fid != null && fid.isNotEmpty) 'feedbackId': fid,
            if (fid != null && fid.isNotEmpty) 'feedbackid': fid,
            'users_reassign': tlIds,
            'users_reassign_for_process_monitor': pmIds,
            'reassign_due_date': dueStr,
            'reply': _assignNotesController.text.trim(),
          }
        : <String, dynamic>{
            'workflow': 'incident_assign',
            if (fid != null && fid.isNotEmpty) 'feedbackId': fid,
            if (fid != null && fid.isNotEmpty) 'feedbackid': fid,
            'users': tlIds,
            'users_for_process_monitor': pmIds,
            'assign_due_date': dueStr,
            'reply': _assignNotesController.text.trim(),
          };

    setState(() => _savingIncidentAssign = true);
    try {
      final response = await TicketApiService.saveTicketDetails(
        domain: domain,
        module: 'INCIDENT',
        ticketId: widget.ticketId,
        status: isReassign ? 'Re-assigned' : 'Assigned',
        uid: uid,
        name: name,
        additionalPayload: extra,
      );
      if (!mounted) return;
      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message']?.toString() ?? 'Updated'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _assignNotesController.clear();
          _assignTlSearchController.clear();
          _assignPmSearchController.clear();
          _tlManualIdsController.clear();
          _pmManualIdsController.clear();
          _selectedTeamLeaderIds.clear();
          _selectedProcessMonitorIds.clear();
          _assignTatDue = null;
        });
        await _fetchTicketDetail();
      } else {
        final err = response['error'] ?? response['message'] ?? 'Failed';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$err')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _savingIncidentAssign = false);
    }
  }

  /// Check if RCA/CAPA section should be visible
  /// Only show when user explicitly changes status TO Closed (not if already closed)
  bool _shouldShowRcaCapaSection() {
    final trimmed = _selectedStatus.trim();
    final statusUpper = trimmed.toUpperCase();
    // Incident web label "Verify & Close" → same close + RCA/CAPA as PHP capa option
    final isClosingIntent = statusUpper == 'CLOSE' ||
        statusUpper == 'CLOSED' ||
        trimmed == 'Verify & Close';
    if (isClosingIntent) {
      return _hasUserChangedStatus &&
          _originalStatus != null &&
          !_isClosedStatus(_originalStatus!);
    }
    return false;
  }

  /// Check if Transfer section should be visible
  bool _shouldShowTransferSection() {
    // Category transfer is a separate panel on web (not in the status dropdown).
    if (widget.module == 'INCIDENT') return false;
    // Only show if user has changed status to Transfer/Transfered
    if (!_hasUserChangedStatus) return false;
    final statusUpper = _selectedStatus.toUpperCase();
    if (statusUpper == 'TRANSFER' || statusUpper == 'TRANSFERED') {
      // Load departments when transfer section becomes visible
      if (_transferDepartments.isEmpty && !_isLoadingDepartments) {
        _loadTransferDepartments();
      }
      return true;
    }
    return false;
  }

  /// Check if Reopen section should be visible
  bool _shouldShowReopenSection() {
    // Only show if user has selected Reopen and section should be visible
    return _showReopenSection && _isClosedStatus(_originalStatus ?? '');
  }

  /// Load transfer departments based on module
  Future<void> _loadTransferDepartments() async {
    setState(() {
      _isLoadingDepartments = true;
    });

    try {
      print('🔵 [DEBUG] ========================================');
      print('🔵 [DEBUG] Loading Transfer Departments');
      print('🔵 [DEBUG] Module: ${widget.module}');
      print('🔵 [DEBUG] Status selected: $_selectedStatus');
      print('🔵 [DEBUG] ========================================');

      if (widget.module == 'IP') {
        // For IP module, use ward.php question_set
        final patientMobile = widget.patientMobile ?? '';
        if (patientMobile.isNotEmpty) {
          print('🔵 [DEBUG] Calling ward.php for IP module');
          final questionSets = await fetchIPQuestionSets(patientMobile);
          
          print('🔵 [DEBUG] ward.php response question_set count: ${questionSets.length}');
          print('🔵 [DEBUG] Using question_set for department dropdown: ${questionSets.map((qs) => qs.category).toList()}');
          
          setState(() {
            _transferDepartments = questionSets;
            _isLoadingDepartments = false;
          });
        } else {
          print('🔴 [DEBUG] Patient mobile is empty for IP module');
          setState(() {
            _isLoadingDepartments = false;
          });
        }
      } else if (widget.module == 'OP') {
        // For OP module, use department.php
        final patientId = widget.patientId ?? '';
        if (patientId.isNotEmpty) {
          print('🔵 [DEBUG] Calling OP department API');
          print('🔵 [DEBUG] Calling department.php for OP module');
          final departments = await fetchDepartments(patientId);
          
          print('🔵 [DEBUG] department.php response count: ${departments.length}');
          print('🔵 [DEBUG] department.php response: ${departments.map((d) => d.title).toList()}');
          
          setState(() {
            _transferDepartments = departments;
            _isLoadingDepartments = false;
          });
        } else {
          print('🔴 [DEBUG] Patient ID is empty for OP module');
          setState(() {
            _isLoadingDepartments = false;
          });
        }
      } else if (widget.module == 'PCF') {
        // For IP Complaints/Requests (PCF), use ward2.php question_set
        final prefs = await SharedPreferences.getInstance();
        final uid = prefs.getString('userid') ?? widget.uid ?? '';
        if (uid.isNotEmpty) {
          print('🔵 [DEBUG] Calling ward2.php for PCF module');
          print('🔵 [DEBUG] Using question_set (not ward) for department dropdown');
          final questionSets = await fetchWard2QuestionSets(uid);
          
          print('🔵 [DEBUG] ward2.php question_set count: ${questionSets.length}');
          print('🔵 [DEBUG] ward2.php question_set categories: ${questionSets.map((qs) => qs.category).toList()}');
          
          setState(() {
            _transferDepartments = questionSets;
            _isLoadingDepartments = false;
          });
        } else {
          print('🔴 [DEBUG] User ID is empty for PCF module');
          setState(() {
            _isLoadingDepartments = false;
          });
        }
      } else if (widget.module == 'ISR') {
        // For Internal Service Requests (ISR), use esr_wards.php question_set
        final prefs = await SharedPreferences.getInstance();
        final uid = prefs.getString('userid') ?? widget.uid ?? '';
        if (uid.isNotEmpty) {
          print('🔵 [DEBUG] Calling esr_wards.php for ISR module');
          print('🔵 [DEBUG] Using question_set (not ward) for department dropdown');
          final questionSets = await fetchEsrWardsQuestionSets(uid);
          
          print('🔵 [DEBUG] esr_wards.php question_set count: ${questionSets.length}');
          print('🔵 [DEBUG] esr_wards.php question_set categories: ${questionSets.map((qs) => qs.category).toList()}');
          
          setState(() {
            _transferDepartments = questionSets;
            _isLoadingDepartments = false;
          });
        } else {
          print('🔴 [DEBUG] User ID is empty for ISR module');
          setState(() {
            _isLoadingDepartments = false;
          });
        }
      } else if (widget.module == 'INCIDENT') {
        // For Incidents, use incident_wards.php question_set
        final prefs = await SharedPreferences.getInstance();
        final uid = prefs.getString('userid') ?? widget.uid ?? '';
        if (uid.isNotEmpty) {
          print('🔵 [DEBUG] Calling incident_wards.php for INCIDENT module');
          print('🔵 [DEBUG] Using question_set (not ward) for department dropdown');
          final questionSets = await fetchIncidentWardsQuestionSets(uid);
          
          print('🔵 [DEBUG] incident_wards.php question_set count: ${questionSets.length}');
          print('🔵 [DEBUG] incident_wards.php question_set categories: ${questionSets.map((qs) => qs.category).toList()}');
          
          setState(() {
            _transferDepartments = questionSets;
            _isLoadingDepartments = false;
          });
        } else {
          print('🔴 [DEBUG] User ID is empty for INCIDENT module');
          setState(() {
            _isLoadingDepartments = false;
          });
        }
      } else {
        print('🔴 [DEBUG] Unknown module: ${widget.module}');
        setState(() {
          _isLoadingDepartments = false;
        });
      }
    } catch (e) {
      print('🔴 [DEBUG] Failed to load transfer departments: $e');
      setState(() {
        _isLoadingDepartments = false;
      });
    }
  }

  /// Build Reject section (incident workflow → ticketsincident create status Rejected)
  Widget _buildRejectSection() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Reject this incident',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _rejectReasonController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Enter the reason for rejecting this incident',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            Text(
              'Reason must be at least 25 characters',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _rejectReasonController.text.trim().length >= 25
                    ? () => _handleRejectSubmit()
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: efeedorBrandGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  disabledBackgroundColor: Colors.grey[300],
                  disabledForegroundColor: Colors.grey[600],
                ),
                child: const Text(
                  'Submit',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Handle Reject submit
  Future<void> _handleRejectSubmit() async {
    final message = _rejectReasonController.text.trim();
    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a reason')),
      );
      return;
    }
    await _submitTicketDetails(
      status: 'Rejected',
      message: message,
    );
  }

  /// Build Address section
  Widget _buildAddressSection() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Address this ticket',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _addressMessageController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Please enter your initial response message',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              onChanged: (_) => setState(() {}), // Trigger rebuild for button state
            ),
            const SizedBox(height: 8),
            Text(
              'Address must be at least 25 characters',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _addressMessageController.text.trim().length >= 25
                    ? () => _handleAddressSubmit()
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: efeedorBrandGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  disabledBackgroundColor: Colors.grey[300],
                  disabledForegroundColor: Colors.grey[600],
                ),
                child: const Text(
                  'Submit',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build RCA/CAPA section (IP/OP legacy) or incident Verify & Close form.
  Widget _buildRcaCapaSection() {
    if (widget.module == 'INCIDENT') {
      return _buildIncidentVerifyCloseSection();
    }
    return _buildStandardRcaCapaSection();
  }

  Widget _buildStandardRcaCapaSection() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Please submit an RCA and CAPA to close this ticket',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'RCA (Root Cause Analysis)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _rcaController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Enter an RCA (Root Cause Analysis)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'CAPA (Corrective Action and Preventive Action)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _capaController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Enter CAPA (Corrective Action and Preventive Action)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
            if (widget.module == 'PCF') ...[
              const SizedBox(height: 16),
              const Text(
                'Resolution comment',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _closeCommentController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Enter your resolution comment (visible to the patient who raised the issue)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _handleCloseSubmit(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: efeedorBrandGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Submit',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncidentVerifyCloseSection() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter Root Cause Analysis (RCA) to Close the Incident',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            _buildIncidentLabeledField(
              label: 'Choose RCA Tool :',
              child: InputDecorator(
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: Colors.grey[50],
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _incidentRcaTool,
                    isExpanded: true,
                    isDense: true,
                    items: const [
                      DropdownMenuItem(value: 'DEFAULT', child: Text('DEFAULT')),
                      DropdownMenuItem(value: '5WHY', child: Text('5WHY')),
                      DropdownMenuItem(value: '5W2H', child: Text('5W2H')),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _incidentRcaTool = v);
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_incidentRcaTool == 'DEFAULT')
              _buildIncidentLabeledField(
                label: 'Root cause',
                child: TextField(
                  controller: _incRootCauseController,
                  maxLines: 6,
                  decoration: InputDecoration(
                    hintText: 'Enter the Root Cause for incident closure.',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                ),
              ),
            if (_incidentRcaTool == '5WHY')
              ...List.generate(5, (i) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildIncidentLabeledField(
                      label: 'WHY ?',
                      child: TextField(
                        controller: _incWhyControllers[i],
                        minLines: 3,
                        maxLines: 8,
                        decoration: InputDecoration(
                          hintText: 'Your input here',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                      ),
                    ),
                    if (i < 4)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Center(
                          child: Icon(
                            Icons.arrow_downward,
                            color: Colors.blue.shade600,
                            size: 28,
                          ),
                        ),
                      ),
                  ],
                );
              }),
            if (_incidentRcaTool == '5W2H')
              ...List.generate(7, (i) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildIncidentLabeledField(
                    label: _incident5w2hQuestionLabels[i],
                    child: TextField(
                      controller: _inc2hControllers[i],
                      minLines: 3,
                      maxLines: 8,
                      decoration: InputDecoration(
                        hintText: 'Your input here',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                    ),
                  ),
                );
              }),
            const SizedBox(height: 20),
            const Text(
              'Verification and closure remarks',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            _buildIncidentLabeledField(
              label: 'Corrective action',
              child: TextField(
                controller: _incCorrectiveController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Enter the Corrective Action for incident closure:',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildIncidentLabeledField(
              label: 'Preventive action',
              child: TextField(
                controller: _incPreventiveController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Enter the Preventive Action for incident closure:',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildIncidentLabeledField(
              label: 'Verification comment (optional)',
              child: TextField(
                controller: _incVerificationController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Additional verification remarks',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _savingIncidentVerifyClose ? null : _handleIncidentVerifyCloseSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: efeedorBrandGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _savingIncidentVerifyClose
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        'Submit',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _incidentVerifyCloseRcaSummary() {
    switch (_incidentRcaTool) {
      case 'DEFAULT':
        return _incRootCauseController.text.trim();
      case '5WHY':
        return _incWhyControllers
            .asMap()
            .entries
            .map((e) => 'WHY ? ${e.key + 1}: ${e.value.text.trim()}')
            .join('\n');
      case '5W2H':
        return _inc2hControllers
            .asMap()
            .entries
            .map((e) =>
                '${_incident5w2hQuestionLabels[e.key]}: ${e.value.text.trim()}')
            .join('\n');
      default:
        return '';
    }
  }

  bool _validateIncidentVerifyCloseFields() {
    bool longEnough(String s, int min) => s.trim().length >= min;
    if (!longEnough(_incCorrectiveController.text, 10) ||
        !longEnough(_incPreventiveController.text, 10)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter at least 10 characters for corrective and preventive actions.'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
    switch (_incidentRcaTool) {
      case 'DEFAULT':
        if (_incRootCauseController.text.trim().length < 10) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Enter the root cause (at least 10 characters).'),
              backgroundColor: Colors.red,
            ),
          );
          return false;
        }
        break;
      case '5WHY':
        for (var i = 0; i < _incWhyControllers.length; i++) {
          if (_incWhyControllers[i].text.trim().length < 3) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Please fill in WHY ? (${i + 1} of 5).',
                ),
                backgroundColor: Colors.red,
              ),
            );
            return false;
          }
        }
        break;
      case '5W2H':
        for (var i = 0; i < _inc2hControllers.length; i++) {
          if (_inc2hControllers[i].text.trim().length < 3) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Please fill in: ${_incident5w2hQuestionLabels[i]}',
                ),
                backgroundColor: Colors.red,
              ),
            );
            return false;
          }
        }
        break;
    }
    return true;
  }

  Future<void> _handleIncidentVerifyCloseSubmit() async {
    if (!_validateIncidentVerifyCloseFields()) return;

    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final domain = prefs.getString('domain') ?? '';
    final uid = prefs.getString('userid') ?? widget.uid ?? '';
    final name = prefs.getString('name') ?? '';
    if (domain.isEmpty || uid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login session incomplete.')),
      );
      return;
    }

    final fid = _ticketDetail?.feedbackId;
    final extra = <String, dynamic>{
      'workflow': 'incident_verify_close',
      'rca_method': _incidentRcaTool,
      'rootcause':
          _incidentRcaTool == 'DEFAULT' ? _incRootCauseController.text.trim() : '',
      'corrective': _incCorrectiveController.text.trim(),
      'preventive': _incPreventiveController.text.trim(),
      'verification_comment': _incVerificationController.text.trim(),
      if (fid != null && fid.isNotEmpty) 'feedbackId': fid,
      if (fid != null && fid.isNotEmpty) 'feedbackid': fid,
    };
    for (var i = 0; i < 5; i++) {
      extra['fivewhy_${i + 1}'] = _incWhyControllers[i].text.trim();
    }
    for (var i = 0; i < 7; i++) {
      extra['fivewhy2h_${i + 1}'] = _inc2hControllers[i].text.trim();
    }

    final rcaSummary = _incidentVerifyCloseRcaSummary();
    final capaSummary =
        '${_incCorrectiveController.text.trim()}\n---\n${_incPreventiveController.text.trim()}';

    setState(() => _savingIncidentVerifyClose = true);
    try {
      final response = await TicketApiService.saveTicketDetails(
        domain: domain,
        module: 'INCIDENT',
        ticketId: widget.ticketId,
        status: 'Closed',
        uid: uid,
        name: name,
        rca: rcaSummary,
        capa: capaSummary,
        additionalPayload: extra,
      );
      if (!mounted) return;
      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message']?.toString() ?? 'Incident closed'),
            backgroundColor: Colors.green,
          ),
        );
        _incRootCauseController.clear();
        for (final c in _incWhyControllers) {
          c.clear();
        }
        for (final c in _inc2hControllers) {
          c.clear();
        }
        _incCorrectiveController.clear();
        _incPreventiveController.clear();
        _incVerificationController.clear();
        await _fetchTicketDetail();
      } else {
        final err = response['error'] ?? response['message'] ?? 'Failed';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$err')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _savingIncidentVerifyClose = false);
    }
  }

  /// Build Transfer section
  Widget _buildTransferSection() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Transfer ticket to other department',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Department',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            _isLoadingDepartments
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : DropdownButtonFormField<String>(
                    isExpanded: true,
                    decoration: InputDecoration(
                      hintText: 'Select Department',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    ),
                    items: _transferDepartments.isNotEmpty
                        ? _transferDepartments.map((dept) {
                            // Handle both QuestionSet (IP) and Department (OP) models
                            final title = dept is QuestionSet 
                                ? dept.category 
                                : (dept is Department ? dept.title : dept.toString());
                            final value = dept is QuestionSet 
                                ? dept.category 
                                : (dept is Department ? dept.title : title);
                            
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(
                                title,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            );
                          }).toList()
                        : const [
                            DropdownMenuItem(value: 'dept1', child: Text('Department 1')),
                            DropdownMenuItem(value: 'dept2', child: Text('Department 2')),
                            DropdownMenuItem(value: 'dept3', child: Text('Department 3')),
                          ],
                    value: _selectedDepartmentId,
                    onChanged: (value) {
                      setState(() {
                        _selectedDepartmentId = value;
                      });
                    },
                  ),
            const SizedBox(height: 16),
            const Text(
              'Reason for transfer',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _transferReasonController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Enter the reason for ticket transfer',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _handleTransferSubmit(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: efeedorBrandGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Submit',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Handle Address submit
  Future<void> _handleAddressSubmit() async {
    print('🟡 [DEBUG] ========================================');
    print('🟡 [DEBUG] ADDRESS SUBMIT CLICKED');
    print('🟡 [DEBUG] ========================================');
    
    final message = _addressMessageController.text.trim();
    if (message.isEmpty) {
      print('🔴 [DEBUG] Validation failed: Message is empty');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a message')),
      );
      return;
    }

    print('🟡 [DEBUG] Message: $message');
    print('🟡 [DEBUG] Status: Addressed');
    print('🟡 [DEBUG] Ticket ID: ${widget.ticketId}');
    print('🟡 [DEBUG] Module: ${widget.module}');

    await _submitTicketDetails(
      status: 'Addressed',
      message: message,
    );
  }

  /// Handle Close submit
  Future<void> _handleCloseSubmit() async {
    print('🟡 [DEBUG] ========================================');
    print('🟡 [DEBUG] CLOSE SUBMIT CLICKED');
    print('🟡 [DEBUG] ========================================');
    
    final rca = _rcaController.text.trim();
    final capa = _capaController.text.trim();

    if (rca.isEmpty) {
      print('🔴 [DEBUG] Validation failed: RCA is empty');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter RCA')),
      );
      return;
    }

    if (capa.isEmpty) {
      print('🔴 [DEBUG] Validation failed: CAPA is empty');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter CAPA')),
      );
      return;
    }

    // Validate minimum character length (25 characters)
    if (rca.length < 25 || capa.length < 25) {
      print('🔴 [DEBUG] Validation failed: RCA or CAPA has less than 25 characters');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter at least 25 characters for RCA and CAPA.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    print('🟡 [DEBUG] RCA: $rca');
    print('🟡 [DEBUG] CAPA: $capa');
    print('🟡 [DEBUG] Status: Closed');
    print('🟡 [DEBUG] Ticket ID: ${widget.ticketId}');
    print('🟡 [DEBUG] Module: ${widget.module}');

    await _submitTicketDetails(
      status: 'Closed',
      message: widget.module == 'PCF' ? _closeCommentController.text.trim() : null,
      rca: rca,
      capa: capa,
    );
  }

  /// Build Reopen section
  Widget _buildReopenSection() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Reopen ticket',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _reopenReasonController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Reason to reopen ticket',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              onChanged: (_) => setState(() {}), // Trigger rebuild for button state
            ),
            const SizedBox(height: 8),
            Text(
              'Reason must be at least 25 characters',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _reopenReasonController.text.trim().length >= 25
                    ? () => _handleReopenSubmit()
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: efeedorBrandGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  disabledBackgroundColor: Colors.grey[300],
                  disabledForegroundColor: Colors.grey[600],
                ),
                child: const Text(
                  'Submit',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Handle Reopen submit
  Future<void> _handleReopenSubmit() async {
    print('🟡 [DEBUG] ========================================');
    print('🟡 [DEBUG] REOPEN SUBMIT CLICKED');
    print('🟡 [DEBUG] ========================================');
    
    final reason = _reopenReasonController.text.trim();

    if (reason.isEmpty) {
      print('🔴 [DEBUG] Validation failed: Reopen reason is empty');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a reason to reopen the ticket'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate minimum character length (25 characters)
    if (reason.length < 25) {
      print('🔴 [DEBUG] Validation failed: Reopen reason has less than 25 characters');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter at least 25 characters for the reopen reason.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    print('🟡 [DEBUG] Reopen Reason: $reason');
    print('🟡 [DEBUG] Status: Reopen');
    print('🟡 [DEBUG] Ticket ID: ${widget.ticketId}');
    print('🟡 [DEBUG] Module: ${widget.module}');

    await _submitTicketDetails(
      status: 'Reopen',
      reason: reason,
    );
  }

  /// Handle Transfer submit
  Future<void> _handleTransferSubmit() async {
    print('🟡 [DEBUG] ========================================');
    print('🟡 [DEBUG] TRANSFER SUBMIT CLICKED');
    print('🟡 [DEBUG] ========================================');
    
    final reason = _transferReasonController.text.trim();
    
    if (_selectedDepartmentId == null || _selectedDepartmentId!.isEmpty) {
      print('🔴 [DEBUG] Validation failed: Department not selected');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a department')),
      );
      return;
    }

    if (reason.isEmpty) {
      print('🔴 [DEBUG] Validation failed: Transfer reason is empty');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter transfer reason')),
      );
      return;
    }

    print('🟡 [DEBUG] Department ID: $_selectedDepartmentId');
    print('🟡 [DEBUG] Reason: $reason');
    print('🟡 [DEBUG] Status: Transfered');
    print('🟡 [DEBUG] Ticket ID: ${widget.ticketId}');
    print('🟡 [DEBUG] Module: ${widget.module}');

    await _submitTicketDetails(
      status: 'Transfered',
      departmentId: _selectedDepartmentId,
      reason: reason,
    );
  }

  /// Submit ticket details to API
  Future<void> _submitTicketDetails({
    required String status,
    String? message,
    String? rca,
    String? capa,
    String? departmentId,
    String? reason,
  }) async {
    print('🟡 [DEBUG] ========================================');
    print('🟡 [DEBUG] SUBMITTING TICKET DETAILS');
    print('🟡 [DEBUG] ========================================');

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get domain and user ID
      final prefs = await SharedPreferences.getInstance();
      final domain = prefs.getString('domain') ?? '';
      final uid = prefs.getString('userid') ?? widget.uid ?? '';
      final name = prefs.getString('name') ?? '';

      if (domain.isEmpty) {
        throw Exception('Domain not found. Please login again.');
      }

      if (uid.isEmpty) {
        throw Exception('User ID not found. Please login again.');
      }

      print('🟡 [DEBUG] Domain: $domain');
      print('🟡 [DEBUG] User ID: $uid');
      print('🟡 [DEBUG] Calling API...');

      // Call API
      final response = await TicketApiService.saveTicketDetails(
        domain: domain,
        module: widget.module,
        ticketId: widget.ticketId,
        status: status,
        uid: uid,
        name: name,
        message: message,
        rca: rca,
        capa: capa,
        departmentId: departmentId,
        reason: reason,
      );

      print('🟢 [DEBUG] ========================================');
      print('🟢 [DEBUG] API CALL SUCCESSFUL');
      print('🟢 [DEBUG] ========================================');
      print('🟢 [DEBUG] Response: $response');
      print('🟢 [DEBUG] Success: ${response['success']}');

      if (mounted) {
        if (response['success'] == true) {
          print('🟢 [DEBUG] Showing success message');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Ticket details updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Refresh ticket details
          await _fetchTicketDetail();
          
          // Clear form fields
          _addressMessageController.clear();
          _rcaController.clear();
          _capaController.clear();
          _closeCommentController.clear();
          _transferReasonController.clear();
          _reopenReasonController.clear();
          _rejectReasonController.clear();
          setState(() {
            _selectedDepartmentId = null;
            _showReopenSection = false; // Hide reopen section after successful submit
          });
          
          // Return true to indicate ticket was updated (for list page refresh)
          // Don't pop immediately - let user see the updated status
          // The list will refresh when user navigates back
        } else {
          print('🔴 [DEBUG] API returned success=false');
          final errorMsg = response['error'] ?? response['message'] ?? 'Failed to update ticket';
          setState(() {
            _errorMessage = errorMsg;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMsg),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('🔴 [DEBUG] ========================================');
      print('🔴 [DEBUG] SUBMIT FAILED');
      print('🔴 [DEBUG] ========================================');
      print('🔴 [DEBUG] Error: $e');
      print('🔴 [DEBUG] Error Type: ${e.runtimeType}');
      
      if (mounted) {
        final errorMsg = e.toString().replaceAll('Exception: ', '');
        setState(() {
          _errorMessage = errorMsg;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      print('🟡 [DEBUG] Submit process completed');
    }
  }

  /// Show status selection bottom sheet
  void _showStatusSelector() {
    final statusOptions = _getAvailableStatusOptions();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white, // Light mode background
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
            // Status options
            ...statusOptions.map((status) {
              final String groupValue;
              if (widget.module == 'INCIDENT') {
                groupValue = _incidentSheetGroupValue(statusOptions);
              } else if (_isClosedStatus(_selectedStatus)) {
                groupValue = 'Closed';
              } else if (_selectedStatus.toUpperCase() == 'VERIFIED') {
                groupValue = 'Closed';
              } else {
                groupValue = _selectedStatus;
              }

              return RadioListTile<String>(
                title: Text(
                  status,
                  style: const TextStyle(color: Colors.black87), // Dark text for readability
                ),
                value: status,
                groupValue: groupValue,
                activeColor: efeedorBrandGreen,
                onChanged: (value) {
                  if (value != null) {
                    Navigator.pop(context);
                    _handleStatusChange(value);
                  }
                },
              );
            }),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  /// Build table row with alternating colors
  Widget _buildTableRow(
    String label,
    Widget value, {
    bool isClickable = false,
    bool isEven = false,
  }) {
    return InkWell(
      onTap: isClickable ? _showStatusSelector : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isEven ? Colors.purple.shade50 : Colors.white,
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            Expanded(
              child: value,
            ),
            if (isClickable)
              Icon(
                Icons.keyboard_arrow_down,
                color: Colors.grey[600],
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppHeaderWrapper(
      title: widget.module == 'INCIDENT' ? 'Manage incident' : 'Manage Ticket',
      child: Stack(
        children: [
          // Main content
          Column(
            children: [
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(efeedorBrandGreen),
                        ),
                      )
                    : _errorMessage != null
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
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
                                    onPressed: _fetchTicketDetail,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: efeedorBrandGreen,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : _ticketDetail == null
                            ? const Center(
                                child: Text(
                                  'No ticket details found',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              )
                            : SingleChildScrollView(
                                child: Column(
                                  children: [
                                    // Ticket details card
                                    Card(
                                      margin: const EdgeInsets.all(16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        children: [
                                          // Row 0: employee details (incident) or patient details (other modules)
                                          if (widget.module == 'INCIDENT')
                                            _buildTableRow(
                                              'Employee details',
                                              _buildIncidentEmployeeDetailsColumn(),
                                              isEven: false,
                                            )
                                          else
                                            _buildTableRow(
                                              'Patient details',
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  if (_getPatientNameWithId() != null) ...[
                                                    Text(
                                                      _getPatientNameWithId()!,
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.black87,
                                                      ),
                                                    ),
                                                  ],
                                                  if (_getDepartmentInfo() != null) ...[
                                                    if (_getPatientNameWithId() != null)
                                                      const SizedBox(height: 4),
                                                    Text(
                                                      _getDepartmentInfo()!,
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        color: Colors.grey[700],
                                                      ),
                                                    ),
                                                  ],
                                                  if (_getPatientMobile() != null) ...[
                                                    if (_getPatientNameWithId() != null ||
                                                        _getDepartmentInfo() != null)
                                                      const SizedBox(height: 4),
                                                    Row(
                                                      children: [
                                                        Icon(
                                                          Icons.phone,
                                                          size: 16,
                                                          color: Colors.grey[700],
                                                        ),
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          _getPatientMobile()!,
                                                          style: TextStyle(
                                                            fontSize: 13,
                                                            color: Colors.grey[700],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ],
                                              ),
                                              isEven: false,
                                            ),
                                          
                                          // Ticket details (row 1 - purple)
                                          _buildTableRow(
                                            'Ticket details',
                                            Text(
                                              _getTicketDetailsText(),
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            isEven: true,
                                          ),
                                          
                                          // Concern (row 2 - white)
                                          _buildTableRow(
                                            'Concern',
                                            Text(
                                              _ticketDetail!.reasonText ?? '-',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            isEven: false,
                                          ),
                                          if (_ticketDetail!.submissionComment != null &&
                                              _ticketDetail!.submissionComment!.trim().isNotEmpty)
                                            _buildTableRow(
                                              'comment',
                                              Text(
                                                _ticketDetail!.submissionComment!,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              isEven: true,
                                            ),
                                          
                                          // Created On (row 3 - purple)
                                          _buildTableRow(
                                            'Created On',
                                            Text(
                                              _formatDate(_ticketDetail!.createdOn),
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            isEven: true,
                                          ),
                                          
                                          // Ticket / Incident status (row 4 - white, clickable)
                                          _buildTableRow(
                                            widget.module == 'INCIDENT'
                                                ? 'Incident status'
                                                : 'Ticket Status',
                                            Text(
                                              _selectedStatus,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: _getStatusColor(_selectedStatus),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            isClickable: true,
                                            isEven: false,
                                          ),
                                        ],
                                      ),
                                    ),
                                    
                                    // Conditional sections based on status
                                    if (_shouldShowAddressSection())
                                      _buildAddressSection(),

                                    if (_shouldShowRejectSection())
                                      _buildRejectSection(),

                                    if (_shouldShowIncidentAssignSection())
                                      _buildIncidentAssignCard(),

                                    if (_shouldShowIncidentPortalSection())
                                      _buildIncidentPortalCard(),
                                    
                                    if (_shouldShowRcaCapaSection())
                                      _buildRcaCapaSection(),
                                    
                                    if (_shouldShowTransferSection())
                                      _buildTransferSection(),
                                    
                                    if (_shouldShowReopenSection())
                                      _buildReopenSection(),
                                  ],
                                ),
                              ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

