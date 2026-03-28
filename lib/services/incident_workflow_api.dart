import 'dart:convert';
import 'package:http/http.dart' as http;

/// Assignable user row for incident Accept & Assign / Re-assign (matches typical PHP user lists).
class IncidentUser {
  final String userId;
  final String displayName;

  IncidentUser({required this.userId, required this.displayName});

  factory IncidentUser.fromJson(Map<String, dynamic> j) {
    final id = j['user_id']?.toString() ??
        j['userId']?.toString() ??
        j['id']?.toString() ??
        '';
    final fn = j['firstname']?.toString() ?? '';
    final ln = j['lastname']?.toString() ?? '';
    final des = j['designation']?.toString() ?? '';
    final name = ('$fn $ln').trim();
    final label = name.isEmpty
        ? (id.isEmpty ? 'Unknown' : id)
        : '$name${des.isNotEmpty ? ' ($des)' : ''}';
    return IncidentUser(userId: id, displayName: label);
  }
}

/// Loads optional user lists. Backend should expose `POST /api/incident_users.php` with `{ "uid": "..." }`
/// returning `{ "users": [ ... ] }` or a JSON array.
class IncidentWorkflowApi {
  static const _timeout = Duration(seconds: 25);

  static Future<List<IncidentUser>> fetchAssignableUsers({
    required String domain,
    required String uid,
  }) async {
    final uri = Uri.parse('https://$domain.efeedor.com/api/incident_users.php');
    try {
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'uid': uid}),
          )
          .timeout(_timeout);
      if (response.statusCode != 200) return [];
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic> && decoded['users'] is List) {
        return (decoded['users'] as List)
            .map((e) => IncidentUser.fromJson(Map<String, dynamic>.from(e as Map)))
            .where((u) => u.userId.isNotEmpty)
            .toList();
      }
      if (decoded is List) {
        return decoded
            .map((e) => IncidentUser.fromJson(Map<String, dynamic>.from(e as Map)))
            .where((u) => u.userId.isNotEmpty)
            .toList();
      }
    } catch (_) {}
    return [];
  }
}
