import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../model/incident_timeline_message.dart';
import '../services/ticket_api_service.dart';

/// "Incident Timeline & History" — same fields as web `closedtickets` view (`$department->replymessage`).
class IncidentTimelineSection extends StatelessWidget {
  final List<IncidentTimelineMessage> messages;

  const IncidentTimelineSection({
    Key? key,
    required this.messages,
  }) : super(key: key);

  String _formatDt(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '-';
    final d = DateTime.tryParse(raw);
    if (d == null) return raw;
    return DateFormat('dd MMM, yyyy - h:mm a').format(d);
  }

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(
          'Incident Timeline & History',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        ...messages.map((r) => _MessageCard(
              r: r,
              formatDt: _formatDt,
            )),
      ],
    );
  }
}

class _MessageCard extends StatelessWidget {
  final IncidentTimelineMessage r;
  final String Function(String?) formatDt;

  const _MessageCard({
    required this.r,
    required this.formatDt,
  });

  Widget _line(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.45),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  Widget _subHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final st = r.ticketStatus ?? '';
    final isAssigned = st == 'Assigned';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            st,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          _line('Date & Time', formatDt(r.createdOn)),
          if (!isAssigned && (r.action?.isNotEmpty ?? false))
            _line('Action', r.action!),
          if (r.processMonitorNote?.isNotEmpty ?? false)
            _line('Notes', r.processMonitorNote!),
          if (st == 'Transfered') ...[
            if (r.action?.isNotEmpty ?? false)
              _line('Action', '${r.action!} (Team Leader)'),
            if (r.message?.isNotEmpty ?? false)
              _line('Transferred by', r.message!),
            if (r.reply?.isNotEmpty ?? false) _line('Comment', r.reply!),
          ],
          if (st == 'Assigned') ...[
            if (r.action?.isNotEmpty ?? false)
              _line('Action', '${r.action!} (Team Leader)'),
            if (r.actionForProcessMonitor?.isNotEmpty ?? false)
              _line('Process Monitor', r.actionForProcessMonitor!),
            if (r.message?.isNotEmpty ?? false)
              _line('Assigned by', r.message!),
          ],
          if (st == 'Re-assigned') ...[
            if (r.actionForProcessMonitor?.isNotEmpty ?? false)
              _line('Process Monitor', r.actionForProcessMonitor!),
            if (r.message?.isNotEmpty ?? false)
              _line('Re-assigned by', r.message!),
          ],
          if (st == 'Described') ...[
            if (r.rcaToolDescribe?.isNotEmpty ?? false) ...[
              _subHeader('Root Cause Analysis (RCA)'),
              _line('Tool Applied', r.rcaToolDescribe!),
            ],
            if (r.rcaToolDescribe == 'DEFAULT' &&
                (r.rootcauseDescribe?.isNotEmpty ?? false))
              _line('Closure RCA', r.rootcauseDescribe!),
            if (r.rcaToolDescribe == '5WHY') ...[
              if (r.fivewhy1Describe?.isNotEmpty ?? false)
                _line('WHY 1', r.fivewhy1Describe!),
              if (r.fivewhy2Describe?.isNotEmpty ?? false)
                _line('WHY 2', r.fivewhy2Describe!),
              if (r.fivewhy3Describe?.isNotEmpty ?? false)
                _line('WHY 3', r.fivewhy3Describe!),
              if (r.fivewhy4Describe?.isNotEmpty ?? false)
                _line('WHY 4', r.fivewhy4Describe!),
              if (r.fivewhy5Describe?.isNotEmpty ?? false)
                _line('WHY 5', r.fivewhy5Describe!),
            ],
            if (r.rcaToolDescribe == '5W2H') ...[
              if (r.fivewhy2h1Describe?.isNotEmpty ?? false)
                _line('What happened?', r.fivewhy2h1Describe!),
              if (r.fivewhy2h2Describe?.isNotEmpty ?? false)
                _line('Why did it happen?', r.fivewhy2h2Describe!),
              if (r.fivewhy2h3Describe?.isNotEmpty ?? false)
                _line('Where did it happen?', r.fivewhy2h3Describe!),
              if (r.fivewhy2h4Describe?.isNotEmpty ?? false)
                _line('When did it happen?', r.fivewhy2h4Describe!),
              if (r.fivewhy2h5Describe?.isNotEmpty ?? false)
                _line('Who was involved?', r.fivewhy2h5Describe!),
              if (r.fivewhy2h6Describe?.isNotEmpty ?? false)
                _line('How did it happen?', r.fivewhy2h6Describe!),
              if (r.fivewhy2h7Describe?.isNotEmpty ?? false)
                _line('How much/How many (impact/cost)?', r.fivewhy2h7Describe!),
            ],
            if (r.correctiveDescribe?.isNotEmpty ?? false)
              _line('Corrective Action', r.correctiveDescribe!),
            if (r.preventiveDescribe?.isNotEmpty ?? false)
              _line('Preventive Action', r.preventiveDescribe!),
            if (r.verificationCommentDescribe?.isNotEmpty ?? false)
              _line('Lesson Learned', r.verificationCommentDescribe!),
          ],
          if ((r.reply?.isNotEmpty ?? false) &&
              st != 'Described' &&
              st != 'Transfered')
            _line('Comment', r.reply!),
          if (r.rcaTool?.isNotEmpty ?? false) ...[
            _subHeader('Root Cause Analysis (RCA) for Incident Closure'),
            _line('Tool Applied', r.rcaTool!),
          ],
          if (r.rcaTool == 'DEFAULT' && (r.rootcause?.isNotEmpty ?? false))
            _line('Closure RCA', r.rootcause!),
          if (r.rcaTool == '5WHY') ...[
            if (r.fivewhy1?.isNotEmpty ?? false) _line('WHY 1', r.fivewhy1!),
            if (r.fivewhy2?.isNotEmpty ?? false) _line('WHY 2', r.fivewhy2!),
            if (r.fivewhy3?.isNotEmpty ?? false) _line('WHY 3', r.fivewhy3!),
            if (r.fivewhy4?.isNotEmpty ?? false) _line('WHY 4', r.fivewhy4!),
            if (r.fivewhy5?.isNotEmpty ?? false) _line('WHY 5', r.fivewhy5!),
          ],
          if (r.rcaTool == '5W2H') ...[
            if (r.fivewhy2h1?.isNotEmpty ?? false)
              _line('What happened?', r.fivewhy2h1!),
            if (r.fivewhy2h2?.isNotEmpty ?? false)
              _line('Why did it happen?', r.fivewhy2h2!),
            if (r.fivewhy2h3?.isNotEmpty ?? false)
              _line('Where did it happen?', r.fivewhy2h3!),
            if (r.fivewhy2h4?.isNotEmpty ?? false)
              _line('When did it happen?', r.fivewhy2h4!),
            if (r.fivewhy2h5?.isNotEmpty ?? false)
              _line('Who was involved?', r.fivewhy2h5!),
            if (r.fivewhy2h6?.isNotEmpty ?? false)
              _line('How did it happen?', r.fivewhy2h6!),
            if (r.fivewhy2h7?.isNotEmpty ?? false)
              _line('How much/How many (impact/cost)?', r.fivewhy2h7!),
          ],
          if (r.corrective?.isNotEmpty ?? false)
            _line('Closure Corrective Action', r.corrective!),
          if (r.preventive?.isNotEmpty ?? false)
            _line('Closure Preventive Action', r.preventive!),
          if (r.verificationComment?.isNotEmpty ?? false)
            _line('Closure Verification Remark', r.verificationComment!),
          if (r.teamMemberNote?.isNotEmpty ?? false)
            _line('Additional Notes', r.teamMemberNote!),
        ],
      ),
    );
  }
}

/// Loads timeline from ticket detail API when list payload omits `replymessage`.
class IncidentTimelineLoader extends StatefulWidget {
  final String domain;
  final String ticketId;
  final String moduleCode;
  final List<IncidentTimelineMessage> initialMessages;

  const IncidentTimelineLoader({
    Key? key,
    required this.domain,
    required this.ticketId,
    required this.moduleCode,
    this.initialMessages = const [],
  }) : super(key: key);

  @override
  State<IncidentTimelineLoader> createState() => _IncidentTimelineLoaderState();
}

class _IncidentTimelineLoaderState extends State<IncidentTimelineLoader> {
  late Future<List<IncidentTimelineMessage>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<IncidentTimelineMessage>> _load() async {
    if (widget.initialMessages.isNotEmpty) {
      return widget.initialMessages;
    }
    final res = await TicketApiService.fetchTicketDetail(
      domain: widget.domain,
      module: widget.moduleCode,
      ticketId: widget.ticketId,
    );
    return res.replyMessages;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.initialMessages.isNotEmpty) {
      return IncidentTimelineSection(messages: widget.initialMessages);
    }
    return FutureBuilder<List<IncidentTimelineMessage>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Loading timeline…',
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
              ],
            ),
          );
        }
        if (snap.hasError || !snap.hasData || snap.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        return IncidentTimelineSection(messages: snap.data!);
      },
    );
  }
}
