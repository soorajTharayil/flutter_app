import 'package:http/http.dart' as http;

/// POSTs to CodeIgniter `ticketsincident/*` (same field names as web `form_open` views).
/// Server must list these URIs in `$config['csrf_exclude_uris']` so POSTs work without a browser session cookie.
class IncidentTicketsincidentApi {
  static const _timeout = Duration(seconds: 30);

  static Future<bool> updateRiskMatrix({
    required String domain,
    required String id,
    required String pid,
    required String empid,
    required String impact,
    required String likelihood,
    required String level,
  }) {
    return _post(
      domain,
      'ticketsincident/update_risk_matrix',
      {
        'id': id,
        'pid': pid,
        'empid': empid,
        'status': 'EditAssignedRisk',
        'impact': impact,
        'likelihood': likelihood,
        'level': level,
      },
    );
  }

  static Future<bool> editPriority({
    required String domain,
    required String id,
    required String pid,
    required String empid,
    required String priority,
  }) {
    return _post(
      domain,
      'ticketsincident/edit_priority_type',
      {
        'id': id,
        'pid': pid,
        'empid': empid,
        'status': 'EditPriority',
        'priority': priority,
      },
    );
  }

  /// PHP controller name uses typo `edit_priority_serverity`.
  static Future<bool> editSeverity({
    required String domain,
    required String id,
    required String pid,
    required String incidentType,
  }) {
    return _post(
      domain,
      'ticketsincident/edit_priority_serverity',
      {
        'id': id,
        'pid': pid,
        'status': 'EditSeverity',
        'incident_type': incidentType,
      },
    );
  }

  static Future<bool> _post(
    String domain,
    String path,
    Map<String, String> fields,
  ) async {
    final uri = Uri.parse('https://$domain.efeedor.com/$path');
    final response = await http
        .post(
          uri,
          body: fields,
          headers: const {
            'Content-Type': 'application/x-www-form-urlencoded',
          },
        )
        .timeout(_timeout);
    return response.statusCode >= 200 && response.statusCode < 400;
  }
}
