import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../widgets/app_header_wrapper.dart';
import '../config/constant.dart';
import '../services/ticket_api_service.dart';
import '../model/ticket_model.dart';
import 'manage_ticket_page.dart';

/// Page for displaying list of tickets
class TicketListPage extends StatefulWidget {
  final String moduleCode;
  final String moduleName;
  final DateTime fromDate;
  final DateTime toDate;
  final String filterType; // "TOTAL", "OPEN", or "CLOSED"

  const TicketListPage({
    Key? key,
    required this.moduleCode,
    required this.moduleName,
    required this.fromDate,
    required this.toDate,
    required this.filterType,
  }) : super(key: key);

  @override
  State<TicketListPage> createState() => _TicketListPageState();
}

class _TicketListPageState extends State<TicketListPage> {
  TicketListResponse? _ticketListResponse;
  bool _isLoading = false;
  String? _errorMessage;
  String? _uid;

  @override
  void initState() {
    super.initState();
    _loadUserDataAndFetchTickets();
  }

  /// Load user ID and fetch tickets
  Future<void> _loadUserDataAndFetchTickets() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('userid') ?? '';

    if (uid.isEmpty) {
      setState(() {
        _errorMessage = 'User ID not found. Please login again.';
      });
      return;
    }

    setState(() {
      _uid = uid;
    });

    await _fetchTickets();
  }

  /// Convert filterType to API status
  String _getStatusFromFilterType() {
    switch (widget.filterType.toUpperCase()) {
      case 'OPEN':
        return 'OPEN';
      case 'CLOSED':
        return 'CLOSED';
      case 'TOTAL':
      default:
        return 'ALL';
    }
  }

  /// Fetch tickets from API
  Future<void> _fetchTickets() async {
    if (_uid == null || _uid!.isEmpty) {
      return;
    }

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

      // Get status from filter type
      final status = _getStatusFromFilterType();

      // Fetch tickets
      final response = await TicketApiService.fetchAllTickets(
        domain: domain,
        uid: _uid!,
        module: widget.moduleCode,
        status: status,
        fromDate: widget.fromDate,
        toDate: widget.toDate,
      );

      if (mounted) {
        setState(() {
          _ticketListResponse = response;
          _isLoading = false;
        });
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

  /// Format date string for display (YYYY-MM-DD HH:mm:ss format)
  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return '-';
    }
    try {
      // Handle YYYY-MM-DD HH:mm:ss format
      DateTime? date;
      if (dateString.contains(' ')) {
        // Has time component
        date = DateTime.tryParse(dateString);
      } else if (dateString.contains('-')) {
        // Date only
        date = DateTime.tryParse(dateString);
      }

      if (date != null) {
        // Format as readable date with time if available
        if (dateString.contains(' ')) {
          return DateFormat('MMM dd, yyyy HH:mm:ss').format(date);
        } else {
          return DateFormat('MMM dd, yyyy').format(date);
        }
      }
      // Return as-is if parsing fails
      return dateString;
    } catch (e) {
      return dateString;
    }
  }

  /// Get status display text
  String _getStatusText(String? status) {
    if (status == null || status.isEmpty) {
      return 'Unknown';
    }
    // Capitalize first letter, rest lowercase
    final statusLower = status.toLowerCase();
    if (statusLower.isEmpty) return 'Unknown';
    return statusLower[0].toUpperCase() + statusLower.substring(1);
  }

  /// Get status color
  Color _getStatusColor(String? status) {
    if (status == null) return Colors.grey;
    final statusUpper = status.toUpperCase();
    if (statusUpper == 'OPEN') {
      return Colors.red;
    } else if (statusUpper == 'CLOSED') {
      return Colors.green;
    }
    return Colors.grey;
  }

  /// Get patient details display text
  String _getPatientDetailsText(String? patientName, String? patientId) {
    if (patientName == null && patientId == null) {
      return '-';
    }
    if (patientName != null && patientId != null) {
      return '$patientName ($patientId)';
    }
    return patientName ?? patientId ?? '-';
  }

  /// Navigate to manage ticket page
  void _navigateToAction(Ticket ticket) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ManageTicketPage(
          ticketId: ticket.ticketId,
          module: widget.moduleCode,
          uid: _uid,
          patientName: ticket.patientName,
          patientId: ticket.patientId,
          patientMobile: ticket.patientMobile,
        ),
      ),
    );
  }

  /// Build ticket card
  Widget _buildTicketCard(Ticket ticket) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ticket ID
            _buildInfoRow(
              Icons.confirmation_number,
              'Ticket ID',
              ticket.ticketId.isNotEmpty ? ticket.ticketId : '-',
            ),
            const SizedBox(height: 10),

            // Patient Details
            _buildInfoRow(
              Icons.person,
              'Patient Details',
              _getPatientDetailsText(ticket.patientName, ticket.patientId),
            ),
            const SizedBox(height: 10),

            // Concern
            _buildInfoRow(
              Icons.message,
              'Concern',
              ticket.concern ?? '-',
            ),
            const SizedBox(height: 10),

            // Department
            _buildInfoRow(
              Icons.business,
              'Department',
              ticket.department ?? '-',
            ),
            const SizedBox(height: 10),

            // Created On
            _buildInfoRow(
              Icons.calendar_today,
              'Created on',
              _formatDate(ticket.createdOn),
            ),
            const SizedBox(height: 10),

            // Updated On
            _buildInfoRow(
              Icons.update,
              'Updated on',
              _formatDate(ticket.updatedOn),
            ),
            const SizedBox(height: 10),

            // Status - Clickable
            InkWell(
              onTap: () => _navigateToAction(ticket),
              child: _buildInfoRow(
                Icons.info,
                'Status',
                _getStatusText(ticket.status),
                valueColor: _getStatusColor(ticket.status),
              ),
            ),
            const SizedBox(height: 10),

            // Take action here - Clickable
            InkWell(
              onTap: () => _navigateToAction(ticket),
              child: Row(
                children: [
                  Icon(
                    Icons.touch_app,
                    size: 16,
                    color: efeedorBrandGreen,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Take action here',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: efeedorBrandGreen,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build info row with icon, label, and value
  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
              ),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
                TextSpan(
                  text: value,
                  style: TextStyle(
                    color: valueColor ?? Colors.black87,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get status display text
    final statusText = _getStatusFromFilterType();
    final statusDisplay = statusText == 'ALL' ? 'All' : statusText;

    return AppHeaderWrapper(
      title: '',
      child: Column(
        children: [
          // Heading - Module Name
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                widget.moduleName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
          ),

          // Subtitle
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.grey[50],
            child: Text(
              'Showing $statusDisplay tickets',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(efeedorBrandGreen),
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
                                onPressed: _fetchTickets,
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
                    : _ticketListResponse == null ||
                            _ticketListResponse!.ticketCount == 0
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.inbox,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No tickets found for this period',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: _ticketListResponse!.tickets.length,
                            itemBuilder: (context, index) {
                              return _buildTicketCard(
                                _ticketListResponse!.tickets[index],
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
