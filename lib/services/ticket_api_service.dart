import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/ticket_dashboard_summary.dart';
import '../model/ticket_model.dart';
import '../model/ticket_detail_model.dart';
import 'package:intl/intl.dart';

/// Service for ticket dashboard API calls
class TicketApiService {
  /// Fetch ticket dashboard summary
  /// 
  /// [domain] - The domain subdomain (e.g., "hospital1")
  /// [uid] - User ID
  /// [moduleCode] - Module code (IP, OP, PCF, ISR, INCIDENT)
  /// [fromDate] - Start date for filtering
  /// [toDate] - End date for filtering
  /// 
  /// Returns [TicketDashboardSummary] with ticket counts
  static Future<TicketDashboardSummary> fetchTicketDashboard({
    required String domain,
    required String uid,
    required String moduleCode,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    // Format dates as YYYY-MM-DD
    final dateFormat = DateFormat('yyyy-MM-dd');
    final fdate = dateFormat.format(fromDate);
    final tdate = dateFormat.format(toDate);

    // Build URL with query parameters
    final uri = Uri.parse(
      'https://$domain.efeedor.com/api/ticketDashboard.php?fdate=$fdate&tdate=$tdate',
    );

    // Prepare request body
    final body = jsonEncode({
      'uid': uid,
      'module': moduleCode,
    });

    // Make POST request
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    ).timeout(
      const Duration(seconds: 20),
      onTimeout: () {
        throw Exception('Request timeout');
      },
    );

    // Check response status
    if (response.statusCode == 200) {
      try {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        return TicketDashboardSummary.fromJson(responseData);
      } catch (e) {
        throw Exception('Failed to parse response: $e');
      }
    } else {
      throw Exception('API error: ${response.statusCode} - ${response.body}');
    }
  }

  /// Fetch all tickets for a module and status
  /// 
  /// [domain] - The domain subdomain (e.g., "hospital1")
  /// [uid] - User ID
  /// [module] - Module code (IP, OP, PCF, ISR, INCIDENT)
  /// [status] - Status filter ("ALL", "OPEN", "CLOSED")
  /// [fromDate] - Start date for filtering
  /// [toDate] - End date for filtering
  /// 
  /// Returns [TicketListResponse] with list of tickets
  static Future<TicketListResponse> fetchAllTickets({
    required String domain,
    required String uid,
    required String module,
    required String status,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    // Format dates as YYYY-MM-DD
    final dateFormat = DateFormat('yyyy-MM-dd');
    final fdate = dateFormat.format(fromDate);
    final tdate = dateFormat.format(toDate);

    // Build URL with query parameters
    final uri = Uri.parse(
      'https://$domain.efeedor.com/api/allTickets.php?fdate=$fdate&tdate=$tdate',
    );

    // Prepare request body
    final body = jsonEncode({
      'uid': uid,
      'module': module,
      'section': status,
      'status': status,
    });

    // Make POST request
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    ).timeout(
      const Duration(seconds: 20),
      onTimeout: () {
        throw Exception('Request timeout');
      },
    );

    // Check response status
    if (response.statusCode == 200) {
      try {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        return TicketListResponse.fromJson(responseData);
      } catch (e) {
        throw Exception('Failed to parse response: $e');
      }
    } else {
      throw Exception('API error: ${response.statusCode} - ${response.body}');
    }
  }

  /// Fetch ticket detail
  /// 
  /// [domain] - The domain subdomain (e.g., "hospital1")
  /// [module] - Module code (IP, OP, PCF, ISR, INCIDENT)
  /// [ticketId] - Ticket ID
  /// 
  /// Returns [TicketDetailResponse] with ticket details
  static Future<TicketDetailResponse> fetchTicketDetail({
    required String domain,
    required String module,
    required String ticketId,
  }) async {
    // Build URL
    final uri = Uri.parse(
      'https://$domain.efeedor.com/api/ticketDetail.php',
    );

    // Prepare request body
    final body = jsonEncode({
      'module': module,
      'ticketId': ticketId,
    });

    // Make POST request
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    ).timeout(
      const Duration(seconds: 20),
      onTimeout: () {
        throw Exception('Request timeout');
      },
    );

    // Check response status
    if (response.statusCode == 200) {
      try {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        return TicketDetailResponse.fromJson(responseData);
      } catch (e) {
        throw Exception('Failed to parse response: $e');
      }
    } else {
      throw Exception('API error: ${response.statusCode} - ${response.body}');
    }
  }
}

