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
  final String? bedNo;

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
    this.bedNo,
  });

  factory TicketDetail.fromJson(Map<String, dynamic> json) {
    // Extract patient details - handle multiple possible field structures
    String? patientName;
    String? patientMobile;
    String? patientId;
    String? bedNo;
    
    // Check for nested patient object (with typo 'patinet')
    if (json['patinet'] != null && json['patinet'] is Map) {
      final patinet = json['patinet'] as Map<String, dynamic>;
      patientName = patinet['name']?.toString() ?? patinet['patient_name']?.toString();
      patientMobile = patinet['patient_mobile']?.toString() ?? 
                      patinet['mobile']?.toString() ?? 
                      patinet['patientMobile']?.toString();
      patientId = patinet['patient_id']?.toString() ?? patinet['patientId']?.toString();
      bedNo = patinet['bed_no']?.toString() ?? patinet['bedNo']?.toString() ?? patinet['bed_number']?.toString();
    } 
    // Check for nested patient object (correct spelling)
    else if (json['patient'] != null && json['patient'] is Map) {
      final patient = json['patient'] as Map<String, dynamic>;
      patientName = patient['name']?.toString() ?? patient['patient_name']?.toString();
      patientMobile = patient['patient_mobile']?.toString() ?? 
                      patient['mobile']?.toString() ?? 
                      patient['patientMobile']?.toString();
      patientId = patient['patient_id']?.toString() ?? patient['patientId']?.toString();
      bedNo = patient['bed_no']?.toString() ?? patient['bedNo']?.toString() ?? patient['bed_number']?.toString();
    }
    // Check for direct fields (snake_case and camelCase)
    else {
      patientName = json['patient_name']?.toString() ?? json['patientName']?.toString();
      patientMobile = json['patient_mobile']?.toString() ?? json['patientMobile']?.toString();
      patientId = json['patient_id']?.toString() ?? json['patientId']?.toString();
      bedNo = json['bed_no']?.toString() ?? json['bedNo']?.toString() ?? json['bed_number']?.toString();
    }
    
    // Also check for bed_no at root level (fallback if not found in nested objects)
    bedNo = bedNo ?? json['bed_no']?.toString() ?? json['bedNo']?.toString() ?? json['bed_number']?.toString();

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
      bedNo: bedNo,
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

