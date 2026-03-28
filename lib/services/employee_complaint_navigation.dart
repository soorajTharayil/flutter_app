import 'package:flutter/material.dart';
import '../ui/incident_report_detail_page.dart';

/// Opens the native incident report screen (same content as PHP view when `dataset` is available).
///
/// **Note:** The PHP view loads rows by `tickets_incident.id` (form field `empid`). Use the
/// **incident ticket id** here, not a separate HR employee code, unless your API adds lookup by employee id.
Future<void> openIncidentReportDetailPage(
  BuildContext context, {
  required String ticketId,
}) async {
  final id = ticketId.trim();
  if (id.isEmpty) return;
  if (!context.mounted) return;
  await Navigator.push<void>(
    context,
    MaterialPageRoute<void>(
      builder: (_) => IncidentReportDetailPage(ticketId: id),
    ),
  );
}
