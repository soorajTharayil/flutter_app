import 'incident_timeline_message.dart';

/// Model for individual ticket
class Ticket {
  final String ticketId;
  final String? patientName;
  final String? patientId;
  final String? patientMobile;
  /// Incident list: prefer over patient* when API sends employee fields.
  final String? employeeId;
  final String? employeeName;
  final String? concern;
  final String? department;
  final String? category;
  final String? createdOn;
  final String? updatedOn;
  final String? status;
  /// When `allTickets.php` includes `replymessage` for incidents (optional).
  final List<IncidentTimelineMessage> replyMessages;

  Ticket({
    required this.ticketId,
    this.patientName,
    this.patientId,
    this.patientMobile,
    this.employeeId,
    this.employeeName,
    this.concern,
    this.department,
    this.category,
    this.createdOn,
    this.updatedOn,
    this.status,
    this.replyMessages = const [],
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    // Extract ticket ID
    String ticketId = '';
    if (json['ticketID'] != null) {
      ticketId = json['ticketID'].toString();
    } else if (json['id'] != null) {
      ticketId = json['id'].toString();
    } else if (json['ticketId'] != null) {
      ticketId = json['ticketId'].toString();
    } else if (json['ticket_id'] != null) {
      ticketId = json['ticket_id'].toString();
    }

    // Extract patient details from patinet object (note: backend typo)
    String? patientName;
    String? patientId;
    String? patientMobile;
    if (json['patinet'] != null && json['patinet'] is Map) {
      final patinet = json['patinet'] as Map<String, dynamic>;
      patientName = patinet['name']?.toString();
      patientId = patinet['patient_id']?.toString();
      patientMobile = patinet['patient_mobile']?.toString() ?? 
                      patinet['mobile']?.toString() ?? 
                      patinet['patientMobile']?.toString();
    }
    // Also check for direct patientMobile field in JSON
    if (patientMobile == null && json['patientMobile'] != null) {
      patientMobile = json['patientMobile']?.toString();
    }
    if (patientMobile == null && json['patient_mobile'] != null) {
      patientMobile = json['patient_mobile']?.toString();
    }

    String? employeeId;
    String? employeeName;
    if (json['employee'] != null && json['employee'] is Map) {
      final em = json['employee'] as Map<String, dynamic>;
      employeeId = em['employee_id']?.toString() ??
          em['employeeId']?.toString() ??
          em['id']?.toString();
      employeeName = em['employee_name']?.toString() ??
          em['employeeName']?.toString() ??
          em['name']?.toString();
    }
    employeeId = employeeId ??
        json['employee_id']?.toString() ??
        json['employeeId']?.toString();
    employeeName = employeeName ??
        json['employee_name']?.toString() ??
        json['employeeName']?.toString();

    // Extract concern
    String? concern;
    if (json['reasonText'] != null) {
      concern = json['reasonText'].toString();
    }

    // Extract department/service-request text
    String? department;
    if (json['departDesc'] != null) {
      department = json['departDesc'].toString();
    }

    // Extract category (ISR/web style: department.description)
    String? category;
    if (json['department'] != null && json['department'] is Map) {
      final dept = json['department'] as Map<String, dynamic>;
      final description = dept['description']?.toString().trim();
      if (description != null && description.isNotEmpty) {
        category = description;
      }
      // If departDesc duplicates reasonText, use department.name as service request text.
      final serviceRequest = dept['name']?.toString().trim();
      if ((department == null || department.trim().isEmpty) &&
          serviceRequest != null &&
          serviceRequest.isNotEmpty) {
        department = serviceRequest;
      }
    }
    if ((category == null || category.isEmpty) && json['category'] != null) {
      final c = json['category'].toString().trim();
      if (c.isNotEmpty) category = c;
    }

    // Extract created date
    String? createdOn;
    if (json['created_on'] != null) {
      createdOn = json['created_on'].toString();
    }

    // Extract updated date
    String? updatedOn;
    if (json['last_modified'] != null) {
      updatedOn = json['last_modified'].toString();
    } else if (json['updated_on'] != null) {
      updatedOn = json['updated_on'].toString();
    }

    // Extract status
    String? status;
    if (json['status'] != null) {
      status = json['status'].toString();
    }

    final dynamic rm = json['replymessage'] ?? json['replyMessage'] ?? json['reply_messages'];

    return Ticket(
      ticketId: ticketId,
      patientName: patientName,
      patientId: patientId,
      patientMobile: patientMobile,
      employeeId: employeeId,
      employeeName: employeeName,
      concern: concern,
      department: department,
      category: category,
      createdOn: createdOn,
      updatedOn: updatedOn,
      status: status,
      replyMessages: IncidentTimelineMessage.listFromJson(rm),
    );
  }
}

/// Model for ticket list API response
class TicketListResponse {
  final bool error;
  final String module;
  final String section;
  final int ticketCount;
  final List<Ticket> tickets;

  TicketListResponse({
    required this.error,
    required this.module,
    required this.section,
    required this.ticketCount,
    required this.tickets,
  });

  factory TicketListResponse.fromJson(Map<String, dynamic> json) {
    final ticketsList = json['tickets'] as List<dynamic>? ?? [];
    return TicketListResponse(
      error: json['error'] as bool? ?? true,
      module: json['module']?.toString() ?? '',
      section: json['section']?.toString() ?? '',
      ticketCount: json['ticketCount'] as int? ?? json['ticket_count'] as int? ?? 0,
      tickets: ticketsList.map((t) => Ticket.fromJson(t as Map<String, dynamic>)).toList(),
    );
  }
}

