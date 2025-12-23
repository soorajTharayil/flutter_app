/// Model for individual ticket
class Ticket {
  final String ticketId;
  final String? patientName;
  final String? patientId;
  final String? concern;
  final String? department;
  final String? createdOn;
  final String? updatedOn;
  final String? status;

  Ticket({
    required this.ticketId,
    this.patientName,
    this.patientId,
    this.concern,
    this.department,
    this.createdOn,
    this.updatedOn,
    this.status,
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
    if (json['patinet'] != null && json['patinet'] is Map) {
      final patinet = json['patinet'] as Map<String, dynamic>;
      patientName = patinet['name']?.toString();
      patientId = patinet['patient_id']?.toString();
    }

    // Extract concern
    String? concern;
    if (json['reasonText'] != null) {
      concern = json['reasonText'].toString();
    }

    // Extract department description
    String? department;
    if (json['departDesc'] != null) {
      department = json['departDesc'].toString();
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

    return Ticket(
      ticketId: ticketId,
      patientName: patientName,
      patientId: patientId,
      concern: concern,
      department: department,
      createdOn: createdOn,
      updatedOn: updatedOn,
      status: status,
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

