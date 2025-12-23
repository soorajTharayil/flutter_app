/// Model for ticket detail API response
class TicketDetail {
  final String ticketId;
  final String? status;
  final String? createdOn;
  final String? reasonText;
  final String? departmentName;
  final String? departDesc;
  final String? ward;
  final String? rating;
  final String? patientName;
  final String? patientMobile;
  final String? patientId;
  final String? floor;

  TicketDetail({
    required this.ticketId,
    this.status,
    this.createdOn,
    this.reasonText,
    this.departmentName,
    this.departDesc,
    this.rating,
    this.ward,
    this.patientName,
    this.patientMobile,
    this.patientId,
    this.floor,
  });

  factory TicketDetail.fromJson(Map<String, dynamic> json) {
    // Extract patient details
    String? patientName;
    String? patientMobile;
    String? patientId;
    if (json['patinet'] != null && json['patinet'] is Map) {
      final patinet = json['patinet'] as Map<String, dynamic>;
      patientName = patinet['name']?.toString();
      patientMobile = patinet['patient_mobile']?.toString() ?? patinet['mobile']?.toString();
      patientId = patinet['patient_id']?.toString();
    } else {
      patientName = json['patient_name']?.toString();
      patientMobile = json['patient_mobile']?.toString();
      patientId = json['patient_id']?.toString();
    }

    return TicketDetail(
      ticketId: json['ticketId']?.toString() ?? json['ticket_id']?.toString() ?? json['ticketID']?.toString() ?? '',
      status: json['status']?.toString(),
      createdOn: json['created_on']?.toString(),
      reasonText: json['reasonText']?.toString(),
      departmentName: json['departmentName']?.toString(),
      departDesc: json['departDesc']?.toString(),
      ward: json['ward']?.toString(),
      rating: json['rating']?.toString(),
      patientName: patientName,
      patientMobile: patientMobile,
      patientId: patientId,
      floor: json['floor']?.toString(),
    );
  }
}

/// Model for ticket detail API response wrapper
class TicketDetailResponse {
  final bool error;
  final TicketDetail ticketDetail;

  TicketDetailResponse({
    required this.error,
    required this.ticketDetail,
  });

  factory TicketDetailResponse.fromJson(Map<String, dynamic> json) {
    return TicketDetailResponse(
      error: json['error'] as bool? ?? true,
      ticketDetail: TicketDetail.fromJson(
        json['ticketDetail'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}

