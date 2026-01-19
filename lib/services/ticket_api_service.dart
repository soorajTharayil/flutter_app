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

    print('🔵 [DASHBOARD API] ========================================');
    print('🔵 [DASHBOARD API] URL: $uri');
    print('🔵 [DASHBOARD API] Module: $moduleCode');
    print('🔵 [DASHBOARD API] From Date: $fdate');
    print('🔵 [DASHBOARD API] To Date: $tdate');
    print('🔵 [DASHBOARD API] Body: $body');
    print('🔵 [DASHBOARD API] ========================================');

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

    print('🟢 [DASHBOARD API] Response Status: ${response.statusCode}');
    print('🟢 [DASHBOARD API] Response Body: ${response.body}');

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
    // Add timestamp to prevent caching
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final uri = Uri.parse(
      'https://$domain.efeedor.com/api/allTickets.php?fdate=$fdate&tdate=$tdate&_t=$timestamp',
    );

    // Prepare request body
    final body = jsonEncode({
      'uid': uid,
      'module': module,
      'section': status,
      'status': status,
    });

    print('🔵 [LIST API] ========================================');
    print('🔵 [LIST API] URL: $uri');
    print('🔵 [LIST API] Module: $module');
    print('🔵 [LIST API] Status Filter: $status');
    print('🔵 [LIST API] From Date: $fdate');
    print('🔵 [LIST API] To Date: $tdate');
    print('🔵 [LIST API] Body: $body');
    print('🔵 [LIST API] ========================================');

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

    print('🟢 [LIST API] Response Status: ${response.statusCode}');
    if (response.statusCode == 200) {
      try {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        print('🟢 [LIST API] Ticket Count: ${responseData['ticketCount'] ?? 'N/A'}');
        print('🟢 [LIST API] Section: ${responseData['section'] ?? 'N/A'}');
        final tickets = responseData['tickets'] as List?;
        print('🟢 [LIST API] Tickets Returned: ${tickets?.length ?? 0}');
        if (tickets != null && tickets.isNotEmpty) {
          print('🟢 [LIST API] Sample ticket statuses:');
          for (var i = 0; i < tickets.length && i < 3; i++) {
            final ticket = tickets[i] as Map<String, dynamic>;
            print('🟢 [LIST API]   Ticket ${ticket['ticketID'] ?? ticket['id']}: status="${ticket['status']}"');
          }
        }
      } catch (e) {
        print('🔴 [LIST API] Error parsing response: $e');
      }
    } else {
      print('🔴 [LIST API] Error Response: ${response.body}');
    }

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

  /// Save ticket details (Address, Close, Transfer)
  /// 
  /// [domain] - The domain subdomain (e.g., "hospital1")
  /// [module] - Module code (IP, OP, PCF, ISR, INCIDENT)
  /// [ticketId] - Ticket ID
  /// [status] - Status (Address, Closed, Transfer, Reopen)
  /// [uid] - User ID
  /// [message] - Message for Addressed status (optional)
  /// [rca] - RCA for Closed status (optional)
  /// [capa] - CAPA for Closed status (optional)
  /// [departmentId] - Department ID for Transfer status (optional)
  /// [reason] - Reason for Transfer status (optional)
  /// 
  /// Returns Map with success status and message
  static Future<Map<String, dynamic>> saveTicketDetails({
    required String domain,
    required String module,
    required String ticketId,
    required String status,
    required String uid,
    required String name,
    String? message,
    String? rca,
    String? capa,
    String? departmentId,
    String? reason,
  }) async {
    // Build URL
    final apiUrl = 'https://$domain.efeedor.com/api/save-ticket-details.php';
    final uri = Uri.parse(apiUrl);

    // Prepare request payload
    final payload = <String, dynamic>{
      'module': module,
      'ticketId': ticketId,
      'status': status,
      'uid': uid,
      'name': name,
    };

    // Add optional fields based on status
    if (message != null && message.isNotEmpty) {
      payload['message'] = message;
      payload['addressDetails'] = message; // Support both field names
    }
    if (rca != null && rca.isNotEmpty) {
      payload['rca'] = rca;
    }
    if (capa != null && capa.isNotEmpty) {
      payload['capa'] = capa;
    }
    if (departmentId != null && departmentId.isNotEmpty) {
      payload['departmentId'] = departmentId;
    }
    if (reason != null && reason.isNotEmpty) {
      payload['reason'] = reason;
    }

    final body = jsonEncode(payload);

    // DEBUG: Log API call details
    print('🔵 [DEBUG] ========================================');
    print('🔵 [DEBUG] SAVE TICKET DETAILS API CALL');
    print('🔵 [DEBUG] ========================================');
    print('🔵 [DEBUG] API URL: $apiUrl');
    print('🔵 [DEBUG] Method: POST');
    print('🔵 [DEBUG] Headers: Content-Type: application/json');
    print('🔵 [DEBUG] Payload: $body');
    print('🔵 [DEBUG] Payload (formatted):');
    try {
      final formattedPayload = jsonDecode(body);
      print('🔵 [DEBUG] ${jsonEncode(formattedPayload)}');
    } catch (e) {
      print('🔵 [DEBUG] Error formatting payload: $e');
    }
    print('🔵 [DEBUG] ========================================');

    try {
      // Make POST request
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: body,
      ).timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          print('🔴 [DEBUG] Request timeout after 20 seconds');
          throw Exception('Request timeout');
        },
      );

      // DEBUG: Log response details
      print('🟢 [DEBUG] ========================================');
      print('🟢 [DEBUG] API RESPONSE RECEIVED');
      print('🟢 [DEBUG] ========================================');
      print('🟢 [DEBUG] Status Code: ${response.statusCode}');
      print('🟢 [DEBUG] Response Headers: ${response.headers}');
      print('🟢 [DEBUG] Response Body (raw): ${response.body}');
      print('🟢 [DEBUG] Response Body Length: ${response.body.length}');
      print('🟢 [DEBUG] ========================================');

      // Check response status
      if (response.statusCode == 200) {
        try {
          final responseData = jsonDecode(response.body) as Map<String, dynamic>;
          print('🟢 [DEBUG] Parsed Response: $responseData');
          print('🟢 [DEBUG] Success: ${responseData['success']}');
          print('🟢 [DEBUG] Message: ${responseData['message'] ?? responseData['error']}');
          
          return responseData;
        } catch (e) {
          print('🔴 [DEBUG] Failed to parse JSON response: $e');
          print('🔴 [DEBUG] Response body was: ${response.body}');
          throw Exception('Failed to parse response: $e');
        }
      } else {
        print('🔴 [DEBUG] API returned non-200 status: ${response.statusCode}');
        print('🔴 [DEBUG] Response body: ${response.body}');
        throw Exception('API error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('🔴 [DEBUG] ========================================');
      print('🔴 [DEBUG] API CALL FAILED');
      print('🔴 [DEBUG] ========================================');
      print('🔴 [DEBUG] Error Type: ${e.runtimeType}');
      print('🔴 [DEBUG] Error Message: $e');
      if (e is Exception) {
        print('🔴 [DEBUG] Exception Details: ${e.toString()}');
      }
      print('🔴 [DEBUG] ========================================');
      rethrow;
    }
  }
}

