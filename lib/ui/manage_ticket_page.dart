import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../widgets/app_header_wrapper.dart';
import '../config/constant.dart';
import '../services/ticket_api_service.dart';
import '../model/ticket_detail_model.dart';

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
  
  // Controllers for input fields
  final TextEditingController _addressMessageController = TextEditingController();
  final TextEditingController _rcaController = TextEditingController();
  final TextEditingController _capaController = TextEditingController();
  final TextEditingController _transferReasonController = TextEditingController();
  String? _selectedDepartmentId; // For transfer dropdown

  @override
  void initState() {
    super.initState();
    _fetchTicketDetail();
  }

  @override
  void dispose() {
    _addressMessageController.dispose();
    _rcaController.dispose();
    _capaController.dispose();
    _transferReasonController.dispose();
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
        final mergedDetail = TicketDetail(
          ticketId: apiDetail.ticketId,
          status: apiDetail.status,
          createdOn: apiDetail.createdOn,
          reasonText: apiDetail.reasonText,
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
        );
        
        setState(() {
          _ticketDetail = mergedDetail;
          final normalizedStatus = _normalizeStatus(mergedDetail.status);
          _selectedStatus = normalizedStatus;
          _originalStatus = normalizedStatus; // Store original status from backend
          _hasUserChangedStatus = false; // Reset on new ticket load
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
            status: 'Open',
          );
          setState(() {
            _ticketDetail = fallbackDetail;
            final normalizedStatus = _normalizeStatus(fallbackDetail.status);
            _selectedStatus = normalizedStatus;
            _originalStatus = normalizedStatus; // Store original status
            _hasUserChangedStatus = false; // Reset on new ticket load
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

  /// Get ticket details description
  String _getTicketDetailsText() {
    if (_ticketDetail == null) return '-';
    
    final rating = _ticketDetail!.rating;
    final departDesc = _ticketDetail!.departDesc ?? _ticketDetail!.departmentName ?? '';
    
    if (rating != null && rating.isNotEmpty && departDesc.isNotEmpty) {
      return 'Rated $rating for $departDesc';
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

  /// Get department/location info
  /// Returns formatted as "From DEPARTMENT_NAME" or null if not available
  String? _getDepartmentInfo() {
    if (_ticketDetail == null) return null;
    
    // Try departmentName first, then departDesc
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
    return statusUpper == 'CLOSE' || statusUpper == 'CLOSED';
  }

  /// Get available status options based on current ticket status
  List<String> _getAvailableStatusOptions() {
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
      
      // If Reopen is selected, transition to Open (active state)
      if (newStatus == 'Reopen') {
        _selectedStatus = 'Open';
      } else if (newStatus == 'Close') {
        // Normalize "Close" to "Closed" for consistency
        _selectedStatus = 'Closed';
      } else {
        // Keep the selected value as-is (Address/Transfer) for UI display
        // The normalization happens when loading from database
        _selectedStatus = newStatus;
      }
    });
  }

  /// Check if Address section should be visible
  bool _shouldShowAddressSection() {
    // Only show if user has changed status to Address/Addressed
    if (!_hasUserChangedStatus) return false;
    final statusUpper = _selectedStatus.toUpperCase();
    return statusUpper == 'ADDRESS' || statusUpper == 'ADDRESSED';
  }

  /// Check if RCA/CAPA section should be visible
  /// Only show when user explicitly changes status TO Closed (not if already closed)
  bool _shouldShowRcaCapaSection() {
    final statusUpper = _selectedStatus.toUpperCase();
    // Only show if:
    // 1. Current status is Closed
    // 2. User has changed the status (not default)
    // 3. Original status was NOT Closed (user is transitioning TO closed)
    if (statusUpper == 'CLOSE' || statusUpper == 'CLOSED') {
      return _hasUserChangedStatus && 
             _originalStatus != null && 
             !_isClosedStatus(_originalStatus!);
    }
    return false;
  }

  /// Check if Transfer section should be visible
  bool _shouldShowTransferSection() {
    // Only show if user has changed status to Transfer/Transfered
    if (!_hasUserChangedStatus) return false;
    final statusUpper = _selectedStatus.toUpperCase();
    return statusUpper == 'TRANSFER' || statusUpper == 'TRANSFERED';
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
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _handleAddressSubmit(),
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

  /// Build RCA/CAPA section
  Widget _buildRcaCapaSection() {
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
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                hintText: 'Select Department',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              items: const [
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
      rca: rca,
      capa: capa,
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
          _transferReasonController.clear();
          setState(() {
            _selectedDepartmentId = null;
          });
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
              // Determine the group value for radio button selection
              String groupValue;
              
              if (_isClosedStatus(_selectedStatus)) {
                // When closed, map to "Closed" for display
                groupValue = 'Closed';
              } else {
                // For active tickets, use the actual status
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
      title: 'Manage Ticket',
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
                                          // Patient details (row 0 - white)
                                          _buildTableRow(
                                            'Patient details',
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                // Patient Name (Patient ID)
                                                if (_getPatientNameWithId() != null) ...[
                                                  Text(
                                                    _getPatientNameWithId()!,
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                ],
                                                // Department/Location
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
                                                // Mobile Number with icon
                                                if (_getPatientMobile() != null) ...[
                                                  if (_getPatientNameWithId() != null || _getDepartmentInfo() != null)
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
                                          
                                          // Ticket Status (row 4 - white, clickable)
                                          _buildTableRow(
                                            'Ticket Status',
                                            Text(
                                              _selectedStatus,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: _selectedStatus.toUpperCase() == 'OPEN'
                                                    ? Colors.red
                                                    : _isClosedStatus(_selectedStatus)
                                                        ? Colors.green
                                                        : Colors.black87,
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
                                    
                                    if (_shouldShowRcaCapaSection())
                                      _buildRcaCapaSection(),
                                    
                                    if (_shouldShowTransferSection())
                                      _buildTransferSection(),
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

