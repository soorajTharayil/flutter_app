import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../widgets/app_header_wrapper.dart';
import '../config/constant.dart';
import '../services/ticket_api_service.dart';
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
  final TextEditingController _transferReasonController = TextEditingController();
  final TextEditingController _reopenReasonController = TextEditingController();
  String? _selectedDepartmentId; // For transfer dropdown
  List<dynamic> _transferDepartments = []; // For transfer dropdown - QuestionSet for IP, Department for OP
  bool _isLoadingDepartments = false;

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
    _reopenReasonController.dispose();
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
          bedNo: apiDetail.bedNo,
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
      
      // If Reopen is selected, show reopen section and transition to Open (active state)
      if (newStatus == 'Reopen') {
        _selectedStatus = 'Open';
        _showReopenSection = true;
      } else {
        // Hide reopen section for other status changes
        _showReopenSection = false;
        if (newStatus == 'Close') {
          // Normalize "Close" to "Closed" for consistency
          _selectedStatus = 'Closed';
        } else {
          // Keep the selected value as-is (Address/Transfer) for UI display
          // The normalization happens when loading from database
          _selectedStatus = newStatus;
        }
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
          _transferReasonController.clear();
          _reopenReasonController.clear();
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

