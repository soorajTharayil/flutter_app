import 'dart:convert';

import 'incident_timeline_message.dart';

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
  /// Incident: reported person (replaces patient-oriented fields on web track view).
  final String? employeeId;
  final String? employeeName;
  /// Incident feedback row id (PHP `feedbackid`) for assign / close payloads when API provides it.
  final String? feedbackId;
  /// Decoded `bf_feedback_incident.dataset` JSON (`$param` in PHP incident view).
  final Map<String, dynamic>? incidentDataset;
  final String? incidentOccurredOn;
  final String? incidentSource;
  final String? assignedTeamLeader;
  final String? assignedProcessMonitor;
  /// When `1`, web hides severity edit (`verified_status` on `bf_feedback_incident`).
  final int? verifiedStatus;

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
    this.employeeId,
    this.employeeName,
    this.feedbackId,
    this.incidentDataset,
    this.incidentOccurredOn,
    this.incidentSource,
    this.assignedTeamLeader,
    this.assignedProcessMonitor,
    this.verifiedStatus,
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

    Map<String, dynamic>? incidentDataset;
    final rawDs = json['dataset'] ?? json['incident_dataset'] ?? json['param'];
    if (rawDs is String && rawDs.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(rawDs);
        if (decoded is Map<String, dynamic>) {
          incidentDataset = decoded;
        } else if (decoded is Map) {
          incidentDataset = Map<String, dynamic>.from(decoded);
        }
      } catch (_) {}
    } else if (rawDs is Map<String, dynamic>) {
      incidentDataset = rawDs;
    } else if (rawDs is Map) {
      incidentDataset = Map<String, dynamic>.from(rawDs);
    }

    String? feedbackId = json['feedbackId']?.toString() ??
        json['feedbackid']?.toString() ??
        json['feedback_id']?.toString() ??
        json['bf_feedback_incident_id']?.toString() ??
        json['incident_feedback_id']?.toString() ??
        json['bfFeedbackIncidentId']?.toString();
    if (json['bf_feedback_incident'] != null && json['bf_feedback_incident'] is Map) {
      final b = json['bf_feedback_incident'] as Map<String, dynamic>;
      feedbackId = feedbackId ??
          b['id']?.toString() ??
          b['feedback_id']?.toString();
    }
    if ((feedbackId == null || feedbackId.trim().isEmpty) && incidentDataset != null) {
      feedbackId = incidentDataset['feedback_incident_id']?.toString() ??
          incidentDataset['bf_feedback_id']?.toString() ??
          incidentDataset['feedback_id']?.toString();
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
      bedNo: bedNo,
      employeeId: employeeId,
      employeeName: employeeName,
      feedbackId: feedbackId,
      incidentDataset: incidentDataset,
      incidentOccurredOn: json['incident_occured_in']?.toString() ??
          json['incident_occurred_on']?.toString() ??
          json['incidentOccurredOn']?.toString(),
      incidentSource: json['source']?.toString(),
      assignedTeamLeader: json['assigned_team_leader']?.toString() ??
          json['assign_to_names']?.toString() ??
          json['assignedTeamLeader']?.toString(),
      assignedProcessMonitor: json['assigned_process_monitor']?.toString() ??
          json['assign_for_process_monitor_names']?.toString() ??
          json['assignedProcessMonitor']?.toString(),
      verifiedStatus: _parseInt(json['verified_status'] ?? json['verifiedStatus']),
    );
  }
}

int? _parseInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  return int.tryParse(v.toString());
}

/// Model for ticket detail API response wrapper
class TicketDetailResponse {
  final bool error;
  final TicketDetail ticketDetail;
  /// Incident: `replymessage` from same payload as web track view (optional).
  final List<IncidentTimelineMessage> replyMessages;

  TicketDetailResponse({
    required this.error,
    required this.ticketDetail,
    this.replyMessages = const [],
  });

  factory TicketDetailResponse.fromJson(Map<String, dynamic> json) {
    final td = Map<String, dynamic>.from(
      json['ticketDetail'] as Map<String, dynamic>? ?? {},
    );
    if (td['feedbackId'] == null &&
        td['feedbackid'] == null &&
        td['feedback_id'] == null) {
      final root = json['feedbackId'] ??
          json['feedbackid'] ??
          json['feedback_id'] ??
          json['bf_feedback_incident_id'] ??
          json['incident_feedback_id'];
      if (root != null) td['feedbackId'] = root;
    }
    final dynamic rm = json['replymessage'] ??
        json['replyMessage'] ??
        json['reply_messages'] ??
        td['replymessage'] ??
        td['replyMessage'];
    return TicketDetailResponse(
      error: json['error'] as bool? ?? true,
      ticketDetail: TicketDetail.fromJson(td),
      replyMessages: IncidentTimelineMessage.listFromJson(rm),
    );
  }
}

