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

  @override
  void initState() {
    super.initState();
    _fetchTicketDetail();
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
          patientName: apiDetail.patientName?.isNotEmpty == true 
              ? apiDetail.patientName 
              : widget.patientName,
          patientId: apiDetail.patientId?.isNotEmpty == true 
              ? apiDetail.patientId 
              : widget.patientId,
          patientMobile: apiDetail.patientMobile?.isNotEmpty == true 
              ? apiDetail.patientMobile 
              : widget.patientMobile,
          floor: apiDetail.floor,
        );
        
        setState(() {
          _ticketDetail = mergedDetail;
          _selectedStatus = mergedDetail.status ?? 'Open';
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
            _selectedStatus = 'Open';
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
  String _getPatientNameWithId() {
    if (_ticketDetail == null) return '--';
    
    final name = _ticketDetail!.patientName ?? '';
    final patientId = _ticketDetail!.patientId ?? '';
    
    if (name.isEmpty && patientId.isEmpty) {
      return '--';
    }
    
    if (name.isNotEmpty && patientId.isNotEmpty) {
      return '$name ($patientId)';
    }
    
    return name.isNotEmpty ? name : patientId;
  }

  /// Get patient mobile text
  String _getPatientMobile() {
    if (_ticketDetail == null) return '--';
    return _ticketDetail!.patientMobile?.isNotEmpty == true 
        ? _ticketDetail!.patientMobile! 
        : '--';
  }

  /// Get ward/floor info
  String _getWardFloorInfo() {
    if (_ticketDetail == null) return '';
    
    final ward = _ticketDetail!.ward ?? '';
    final floor = _ticketDetail!.floor ?? '';
    
    if (ward.isEmpty && floor.isEmpty) return '';
    
    if (ward.isNotEmpty && floor.isNotEmpty) {
      return 'From $ward in $floor';
    } else if (ward.isNotEmpty) {
      return 'From $ward';
    } else if (floor.isNotEmpty) {
      return 'From $floor';
    }
    return '';
  }

  /// Show status selection bottom sheet
  void _showStatusSelector() {
    final statusOptions = ['Open', 'Address', 'Close', 'Transfer'];
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
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
            ...statusOptions.map((status) => RadioListTile<String>(
              title: Text(
                status,
                style: const TextStyle(color: Colors.white),
              ),
              value: status,
              groupValue: _selectedStatus,
              activeColor: efeedorBrandGreen,
              onChanged: (value) {
                if (value != null) {
                  Navigator.pop(context);
                  setState(() {
                    _selectedStatus = value;
                  });
                }
              },
            )),
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
                                child: Card(
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
                                            Text(
                                              _getPatientNameWithId(),
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Mobile: ${_getPatientMobile()}',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey[700],
                                              ),
                                            ),
                                            if (_getWardFloorInfo().isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                _getWardFloorInfo(),
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.grey[700],
                                                ),
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
                                                : _selectedStatus.toUpperCase() == 'CLOSE'
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
                              ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

