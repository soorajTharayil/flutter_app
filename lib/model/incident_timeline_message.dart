/// One row from `ticket_incident_message` / `$department->replymessage` (web closed dashboard).
class IncidentTimelineMessage {
  final String? ticketStatus;
  final String? createdOn;
  final String? action;
  final String? message;
  final String? reply;
  final String? processMonitorNote;
  final String? actionForProcessMonitor;
  final String? rcaToolDescribe;
  final String? rootcauseDescribe;
  final String? fivewhy1Describe;
  final String? fivewhy2Describe;
  final String? fivewhy3Describe;
  final String? fivewhy4Describe;
  final String? fivewhy5Describe;
  final String? fivewhy2h1Describe;
  final String? fivewhy2h2Describe;
  final String? fivewhy2h3Describe;
  final String? fivewhy2h4Describe;
  final String? fivewhy2h5Describe;
  final String? fivewhy2h6Describe;
  final String? fivewhy2h7Describe;
  final String? correctiveDescribe;
  final String? preventiveDescribe;
  final String? verificationCommentDescribe;
  final String? rcaTool;
  final String? rootcause;
  final String? fivewhy1;
  final String? fivewhy2;
  final String? fivewhy3;
  final String? fivewhy4;
  final String? fivewhy5;
  final String? fivewhy2h1;
  final String? fivewhy2h2;
  final String? fivewhy2h3;
  final String? fivewhy2h4;
  final String? fivewhy2h5;
  final String? fivewhy2h6;
  final String? fivewhy2h7;
  final String? corrective;
  final String? preventive;
  final String? verificationComment;
  final String? teamMemberNote;

  IncidentTimelineMessage({
    this.ticketStatus,
    this.createdOn,
    this.action,
    this.message,
    this.reply,
    this.processMonitorNote,
    this.actionForProcessMonitor,
    this.rcaToolDescribe,
    this.rootcauseDescribe,
    this.fivewhy1Describe,
    this.fivewhy2Describe,
    this.fivewhy3Describe,
    this.fivewhy4Describe,
    this.fivewhy5Describe,
    this.fivewhy2h1Describe,
    this.fivewhy2h2Describe,
    this.fivewhy2h3Describe,
    this.fivewhy2h4Describe,
    this.fivewhy2h5Describe,
    this.fivewhy2h6Describe,
    this.fivewhy2h7Describe,
    this.correctiveDescribe,
    this.preventiveDescribe,
    this.verificationCommentDescribe,
    this.rcaTool,
    this.rootcause,
    this.fivewhy1,
    this.fivewhy2,
    this.fivewhy3,
    this.fivewhy4,
    this.fivewhy5,
    this.fivewhy2h1,
    this.fivewhy2h2,
    this.fivewhy2h3,
    this.fivewhy2h4,
    this.fivewhy2h5,
    this.fivewhy2h6,
    this.fivewhy2h7,
    this.corrective,
    this.preventive,
    this.verificationComment,
    this.teamMemberNote,
  });

  static String? _s(Map<String, dynamic> j, List<String> keys) {
    for (final k in keys) {
      final v = j[k];
      if (v != null && v.toString().trim().isNotEmpty) {
        return v.toString();
      }
    }
    return null;
  }

  factory IncidentTimelineMessage.fromJson(Map<String, dynamic> json) {
    return IncidentTimelineMessage(
      ticketStatus: _s(json, ['ticket_status', 'ticketStatus']),
      createdOn: _s(json, ['created_on', 'createdOn']),
      action: _s(json, ['action']),
      message: _s(json, ['message']),
      reply: _s(json, ['reply']),
      processMonitorNote: _s(json, ['process_monitor_note', 'processMonitorNote']),
      actionForProcessMonitor:
          _s(json, ['action_for_process_monitor', 'actionForProcessMonitor']),
      rcaToolDescribe: _s(json, ['rca_tool_describe', 'rcaToolDescribe']),
      rootcauseDescribe: _s(json, ['rootcause_describe', 'rootcauseDescribe']),
      fivewhy1Describe: _s(json, ['fivewhy_1_describe', 'fivewhy1_describe']),
      fivewhy2Describe: _s(json, ['fivewhy_2_describe', 'fivewhy2_describe']),
      fivewhy3Describe: _s(json, ['fivewhy_3_describe', 'fivewhy3_describe']),
      fivewhy4Describe: _s(json, ['fivewhy_4_describe', 'fivewhy4_describe']),
      fivewhy5Describe: _s(json, ['fivewhy_5_describe', 'fivewhy5_describe']),
      fivewhy2h1Describe: _s(json, ['fivewhy2h_1_describe']),
      fivewhy2h2Describe: _s(json, ['fivewhy2h_2_describe']),
      fivewhy2h3Describe: _s(json, ['fivewhy2h_3_describe']),
      fivewhy2h4Describe: _s(json, ['fivewhy2h_4_describe']),
      fivewhy2h5Describe: _s(json, ['fivewhy2h_5_describe']),
      fivewhy2h6Describe: _s(json, ['fivewhy2h_6_describe']),
      fivewhy2h7Describe: _s(json, ['fivewhy2h_7_describe']),
      correctiveDescribe: _s(json, ['corrective_describe', 'correctiveDescribe']),
      preventiveDescribe: _s(json, ['preventive_describe', 'preventiveDescribe']),
      verificationCommentDescribe:
          _s(json, ['verification_comment_describe', 'verificationCommentDescribe']),
      rcaTool: _s(json, ['rca_tool', 'rcaTool']),
      rootcause: _s(json, ['rootcause']),
      fivewhy1: _s(json, ['fivewhy_1']),
      fivewhy2: _s(json, ['fivewhy_2']),
      fivewhy3: _s(json, ['fivewhy_3']),
      fivewhy4: _s(json, ['fivewhy_4']),
      fivewhy5: _s(json, ['fivewhy_5']),
      fivewhy2h1: _s(json, ['fivewhy2h_1']),
      fivewhy2h2: _s(json, ['fivewhy2h_2']),
      fivewhy2h3: _s(json, ['fivewhy2h_3']),
      fivewhy2h4: _s(json, ['fivewhy2h_4']),
      fivewhy2h5: _s(json, ['fivewhy2h_5']),
      fivewhy2h6: _s(json, ['fivewhy2h_6']),
      fivewhy2h7: _s(json, ['fivewhy2h_7']),
      corrective: _s(json, ['corrective']),
      preventive: _s(json, ['preventive']),
      verificationComment: _s(json, ['verification_comment', 'verificationComment']),
      teamMemberNote: _s(json, ['team_member_note', 'teamMemberNote']),
    );
  }

  static List<IncidentTimelineMessage> listFromJson(dynamic raw) {
    if (raw is! List) return [];
    final out = <IncidentTimelineMessage>[];
    for (final e in raw) {
      if (e is Map<String, dynamic>) {
        out.add(IncidentTimelineMessage.fromJson(e));
      } else if (e is Map) {
        out.add(IncidentTimelineMessage.fromJson(Map<String, dynamic>.from(e)));
      }
    }
    out.sort((a, b) {
      final ta = DateTime.tryParse(a.createdOn ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
      final tb = DateTime.tryParse(b.createdOn ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
      return ta.compareTo(tb);
    });
    return out;
  }
}
