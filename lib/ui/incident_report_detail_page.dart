import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/constant.dart';
import '../model/ticket_detail_model.dart';
import '../services/ticket_api_service.dart';
import '../services/incident_ticketsincident_api.dart';
import '../widgets/app_header_wrapper.dart';
import '../widgets/risk_matrix_editor_dialog.dart';

/// Full incident report (native), aligned with PHP `bf_feedback_incident` / `tickets_incident` view
/// when `ticketDetail` includes decoded `dataset` (`$param` in PHP).
class IncidentReportDetailPage extends StatefulWidget {
  final String ticketId;

  const IncidentReportDetailPage({
    Key? key,
    required this.ticketId,
  }) : super(key: key);

  @override
  State<IncidentReportDetailPage> createState() => _IncidentReportDetailPageState();
}

class _IncidentReportDetailPageState extends State<IncidentReportDetailPage> {
  TicketDetail? _detail;
  bool _loading = true;
  String? _error;

  String _priorityDraft = '';
  String _severityDraft = '';
  bool _savingRisk = false;
  bool _savingPriority = false;
  bool _savingSeverity = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final domain = prefs.getString('domain') ?? '';
      if (domain.isEmpty) throw Exception('Domain not found');
      final res = await TicketApiService.fetchTicketDetail(
        domain: domain,
        module: 'INCIDENT',
        ticketId: widget.ticketId,
      );
      if (!mounted) return;
      final td = res.ticketDetail;
      final ds = td.incidentDataset;
      setState(() {
        _detail = td;
        _loading = false;
        _priorityDraft = _priorityValueForDropdown(ds?['priority']?.toString());
        _severityDraft = _severityValueForDropdown(ds?['incident_type']?.toString());
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _loading = false;
      });
    }
  }

  Map<String, dynamic>? get _p => _detail?.incidentDataset;

  String? _str(String key) {
    final v = _p?[key];
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  String? _descriptionFromParam() {
    final c = _p?['comment'];
    if (c is Map) {
      for (final v in c.values) {
        if (v != null && v.toString().trim().isNotEmpty) return v.toString().trim();
      }
    }
    return null;
  }

  String _incidentTypesFromReason() {
    final r = _p?['reason'];
    if (r is! Map) return '';
    final parts = <String>[];
    r.forEach((k, v) {
      if (v == true) parts.add(k.toString());
    });
    return parts.join(', ');
  }

  Map<String, dynamic>? get _risk => _p?['risk_matrix'] is Map
      ? Map<String, dynamic>.from(_p!['risk_matrix'] as Map)
      : null;

  Color _riskLevelColor(String? level) {
    switch (level) {
      case 'High':
        return const Color(0xFFD9534F);
      case 'Medium':
        return const Color(0xFFF0AD4E);
      case 'Low':
        return const Color(0xFF0C7E36);
      default:
        return const Color(0xFF6C757D);
    }
  }

  Color _priorityColor(String? p) {
    switch (p) {
      case 'P1-Critical':
      case 'P1 - Critical':
        return const Color(0xFFFF4D4D);
      case 'P2-High':
      case 'P2 - High':
        return const Color(0xFFFF9800);
      case 'P3-Medium':
      case 'P3 - Medium':
        return const Color(0xFFFBC02D);
      case 'P4-Low':
      case 'P4 - Low':
        return const Color(0xFF19CA6E);
      default:
        return const Color(0xFF6C757D);
    }
  }

  Color _severityColor(String? s) {
    switch (s) {
      case 'Sentinel':
        return const Color(0xFFFF4D4D);
      case 'Adverse':
        return const Color(0xFFFF9800);
      case 'No-harm':
        return const Color(0xFF2196F3);
      case 'Near miss':
        return const Color(0xFF19CA6E);
      default:
        return const Color(0xFF6C757D);
    }
  }

  Future<void> _openUrl(String url) async {
    final u = Uri.tryParse(url);
    if (u == null) return;
    if (await canLaunchUrl(u)) {
      await launchUrl(u, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppHeaderWrapper(
      title: 'INC - ${widget.ticketId}',
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        TextButton(onPressed: _load, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_p == null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            'Extended incident fields will appear when ticketDetail.php returns a `dataset` JSON (same as PHP `bf_feedback_incident.dataset`).',
                            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                          ),
                        ),
                      _sectionCard(
                        title: 'Incident report',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _kv('Category', _detail?.departmentName ?? _detail?.departDesc ?? _str('category')),
                            const SizedBox(height: 8),
                            if (_incidentTypesFromReason().isNotEmpty)
                              _kv('Incident', _incidentTypesFromReason())
                            else if (_detail?.reasonText != null)
                              _kv('Incident', _detail!.reasonText),
                            if (_descriptionFromParam() != null) ...[
                              const SizedBox(height: 12),
                              const Text('Description',
                                  style: TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text(_descriptionFromParam()!, style: const TextStyle(height: 1.35)),
                            ],
                            if (_str('what_went_wrong') != null) ...[
                              const SizedBox(height: 12),
                              const Text('What went wrong',
                                  style: TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text(_str('what_went_wrong')!, style: const TextStyle(height: 1.35)),
                            ],
                            if (_str('action_taken') != null) ...[
                              const SizedBox(height: 12),
                              const Text('Immediate action taken',
                                  style: TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text(_str('action_taken')!, style: const TextStyle(height: 1.35)),
                            ],
                          ],
                        ),
                      ),
                      _sectionCard(
                        title: 'Reporting',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _kv(
                              'Incident reported by',
                              _str('name') != null
                                  ? '${_str('name')} (${_str('patientid') ?? '-'})'
                                  : _detail?.patientName,
                            ),
                            if (_str('contactnumber') != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.phone, size: 16, color: Colors.grey[700]),
                                  const SizedBox(width: 6),
                                  Text(_str('contactnumber')!),
                                ],
                              ),
                            ],
                            if (_str('email') != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.email_outlined, size: 16, color: Colors.grey[700]),
                                  const SizedBox(width: 6),
                                  Expanded(child: Text(_str('email')!)),
                                ],
                              ),
                            ],
                            if (_detail?.incidentOccurredOn != null ||
                                _str('incident_occured_in') != null) ...[
                              const SizedBox(height: 12),
                              _kv(
                                'Incident occurred on',
                                _detail?.incidentOccurredOn ?? _str('incident_occured_in'),
                              ),
                            ],
                            if (_detail?.createdOn != null) ...[
                              const SizedBox(height: 8),
                              _kv('Incident reported on', _detail!.createdOn),
                            ],
                            Builder(
                              builder: (context) {
                                final reportedIn = [
                                  if (_str('ward') != null) 'Floor/Ward: ${_str('ward')}',
                                  if (_str('bedno') != null) 'Site: ${_str('bedno')}',
                                ].where((e) => e.isNotEmpty).join('\n');
                                if (reportedIn.isEmpty) return const SizedBox.shrink();
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: _kv('Incident reported in', reportedIn),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      _buildManagementCard(context),
                      if (_str('tag_patientid') != null || _str('tag_name') != null)
                        _sectionCard(
                          title: 'Patient details',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_str('tag_patientid') != null)
                                _kv('Patient Id', _str('tag_patientid')),
                              if (_str('tag_name') != null)
                                _kv('Patient Name', _str('tag_name')),
                            ],
                          ),
                        ),
                      if (_str('employee_id') != null ||
                          _str('employee_name') != null ||
                          _detail?.employeeId != null ||
                          _detail?.employeeName != null)
                        _sectionCard(
                          title: 'Employee details',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_str('employee_id') != null || _detail?.employeeId != null)
                                _kv(
                                  'Employee Id',
                                  _str('employee_id') ?? _detail?.employeeId,
                                ),
                              if (_str('employee_name') != null || _detail?.employeeName != null)
                                _kv(
                                  'Employee Name',
                                  _str('employee_name') ?? _detail?.employeeName,
                                ),
                            ],
                          ),
                        ),
                      if (_str('asset_name') != null || _str('asset_code') != null)
                        _sectionCard(
                          title: 'Equipment details',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_str('asset_name') != null)
                                _kv('Asset name', _str('asset_name')),
                              if (_str('asset_code') != null)
                                _kv('Asset code', _str('asset_code')),
                            ],
                          ),
                        ),
                      if (_detail?.assignedTeamLeader != null &&
                          _detail!.assignedTeamLeader!.trim().isNotEmpty)
                        _sectionCard(
                          title: 'Assigned team leader',
                          child: Text(_detail!.assignedTeamLeader!),
                        ),
                      if (_detail?.assignedProcessMonitor != null &&
                          _detail!.assignedProcessMonitor!.trim().isNotEmpty)
                        _sectionCard(
                          title: 'Assigned process monitor',
                          child: Text(_detail!.assignedProcessMonitor!),
                        ),
                      if (_p?['images'] is List && (_p!['images'] as List).isNotEmpty)
                        _sectionCard(
                          title: 'Attached image',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (var i = 0; i < (_p!['images'] as List).length; i++)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: InkWell(
                                    onTap: () => _openUrl(
                                      (_p!['images'] as List)[i].toString(),
                                    ),
                                    child: Text(
                                      'Download Image ${i + 1}',
                                      style: const TextStyle(
                                        color: efeedorBrandGreen,
                                        fontWeight: FontWeight.w600,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      _sectionCard(
                        title: 'Attached documents',
                        child: _buildFilesList(),
                      ),
                      if (_detail?.incidentSource != null &&
                          _detail!.incidentSource!.trim().isNotEmpty)
                        _sectionCard(
                          title: 'Source',
                          child: Text(_sourceLabel(_detail!.incidentSource!)),
                        ),
                    ],
                  ),
                ),
    );
  }

  String _normalizePriority(String? p) {
    if (p == null || p.isEmpty) return 'Unassigned';
    return p.replaceAll('–', '-');
  }

  String _sourceLabel(String s) {
    switch (s) {
      case 'APP':
        return 'Mobile Application.';
      case 'Link':
        return 'Default Feedback Link.';
      default:
        return s;
    }
  }

  bool get _isClosed {
    final s = _detail?.status?.toLowerCase().trim() ?? '';
    return s == 'closed' || s == 'verified';
  }

  String? get _feedbackRowId {
    final f = _detail?.feedbackId?.trim();
    return f != null && f.isNotEmpty ? f : null;
  }

  /// PHP `id` hidden field = `bf_feedback_incident.id`. If API omits it, use ticket id for `pid`/`id` POST fields.
  String get _postIdForIncidentForms => _feedbackRowId ?? widget.ticketId;

  bool get _hasExplicitFeedbackId =>
      _detail?.feedbackId != null && _detail!.feedbackId!.trim().isNotEmpty;

  bool get _canEditRisk => !_isClosed;
  bool get _canEditPriority => !_isClosed;
  bool get _canEditSeverity =>
      !_isClosed && _detail?.verifiedStatus != 1;

  static String _priorityValueForDropdown(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '';
    final t = raw.replaceAll('–', '-').trim();
    if (t.toLowerCase() == 'unassigned') return '';
    if (t.contains('P1') || t.contains('P1-Critical')) return 'P1-Critical';
    if (t.contains('P2') || t.contains('P2-High')) return 'P2-High';
    if (t.contains('P3') || t.contains('P3-Medium')) return 'P3-Medium';
    if (t.contains('P4') || t.contains('P4-Low')) return 'P4-Low';
    return '';
  }

  static String _severityValueForDropdown(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '';
    final t = raw.trim();
    if (t.toLowerCase() == 'unassigned') return '';
    return t;
  }

  Future<void> _openRiskEditor(BuildContext context) async {
    final id = _postIdForIncidentForms;
    final prefs = await SharedPreferences.getInstance();
    final domain = prefs.getString('domain') ?? '';
    if (domain.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Domain not found')),
        );
      }
      return;
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => RiskMatrixEditorDialog(
        initialImpact: _risk?['impact']?.toString(),
        initialLikelihood: _risk?['likelihood']?.toString(),
      ),
    );
    if (result == null || !mounted) return;

    setState(() => _savingRisk = true);
    try {
      final ok = await IncidentTicketsincidentApi.updateRiskMatrix(
        domain: domain,
        id: id,
        pid: widget.ticketId,
        empid: _str('patientid') ?? '',
        impact: result['impact']! as String,
        likelihood: result['likelihood']! as String,
        level: result['level']! as String,
      );
      if (!mounted) return;
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Risk matrix saved'),
            backgroundColor: Colors.green,
          ),
        );
        await _load();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not save. Ensure you are logged in on the server or use the web app.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _savingRisk = false);
    }
  }

  Future<void> _savePriority() async {
    final id = _postIdForIncidentForms;
    final prefs = await SharedPreferences.getInstance();
    final domain = prefs.getString('domain') ?? '';
    if (domain.isEmpty) return;

    setState(() => _savingPriority = true);
    try {
      final ok = await IncidentTicketsincidentApi.editPriority(
        domain: domain,
        id: id,
        pid: widget.ticketId,
        empid: _str('patientid') ?? '',
        priority: _priorityDraft,
      );
      if (!mounted) return;
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Priority saved'),
            backgroundColor: Colors.green,
          ),
        );
        await _load();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save priority')),
        );
      }
    } finally {
      if (mounted) setState(() => _savingPriority = false);
    }
  }

  Future<void> _saveSeverity() async {
    final id = _postIdForIncidentForms;
    final prefs = await SharedPreferences.getInstance();
    final domain = prefs.getString('domain') ?? '';
    if (domain.isEmpty) return;

    setState(() => _savingSeverity = true);
    try {
      final ok = await IncidentTicketsincidentApi.editSeverity(
        domain: domain,
        id: id,
        pid: widget.ticketId,
        incidentType: _severityDraft,
      );
      if (!mounted) return;
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Severity saved'),
            backgroundColor: Colors.green,
          ),
        );
        await _load();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save severity')),
        );
      }
    } finally {
      if (mounted) setState(() => _savingSeverity = false);
    }
  }

  Widget _buildManagementCard(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Management',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                if (_canEditRisk || _canEditPriority || _canEditSeverity)
                  Icon(
                    Icons.edit_note,
                    size: 22,
                    color: Colors.grey[700],
                  ),
              ],
            ),
            const Divider(height: 20),
            if (!_hasExplicitFeedbackId)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  'Using ticket id for save actions until ticketDetail.php returns `feedbackId` (bf_feedback_incident row id).',
                  style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                ),
              ),
            const Text(
              'Assigned risk',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Builder(
              builder: (context) {
                final level = _risk?['level']?.toString();
                final impact = _risk?['impact']?.toString() ?? '';
                final likelihood = _risk?['likelihood']?.toString() ?? '';
                final has = (level != null && level.isNotEmpty) ||
                    impact.isNotEmpty ||
                    likelihood.isNotEmpty;
                if (!has) {
                  return const Text(
                    'Unassigned',
                    style: TextStyle(
                      color: Color(0xFF6C757D),
                      fontStyle: FontStyle.italic,
                    ),
                  );
                }
                final col = _riskLevelColor(level);
                return Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: level ?? 'Unassigned',
                        style: TextStyle(
                          color: col,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(
                        text: ' ($impact Impact × $likelihood Likelihood)',
                        style: const TextStyle(color: Colors.black87),
                      ),
                    ],
                  ),
                );
              },
            ),
            if (_canEditRisk) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _savingRisk ? null : () => _openRiskEditor(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF28A745),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: _savingRisk
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Edit'),
                ),
              ),
            ],
            const SizedBox(height: 16),
            const Text(
              'Assigned priority',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            if (_canEditPriority) ...[
              DropdownButtonFormField<String>(
                value: _priorityDraft.isEmpty ? '' : _priorityDraft,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: [
                  DropdownMenuItem(
                    value: '',
                    child: Text(
                      'Unassigned',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'P1-Critical',
                    child: Text(
                      'P1 - Critical',
                      style: const TextStyle(color: Color(0xFFFF4D4D)),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'P2-High',
                    child: Text(
                      'P2 - High',
                      style: const TextStyle(color: Color(0xFFFF9800)),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'P3-Medium',
                    child: Text(
                      'P3 - Medium',
                      style: const TextStyle(color: Color(0xFFFBC02D)),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'P4-Low',
                    child: Text(
                      'P4 - Low',
                      style: const TextStyle(color: Color(0xFF19CA6E)),
                    ),
                  ),
                ],
                onChanged: _savingPriority
                    ? null
                    : (v) => setState(() => _priorityDraft = v ?? ''),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _savingPriority ? null : _savePriority,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF28A745),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: _savingPriority
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save'),
                ),
              ),
            ] else
              Builder(
                builder: (context) {
                  final pr = _normalizePriority(_str('priority'));
                  return Text(
                    pr,
                    style: TextStyle(
                      color: _priorityColor(pr),
                      fontWeight: FontWeight.w600,
                    ),
                  );
                },
              ),
            const SizedBox(height: 16),
            const Text(
              'Assigned severity',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            if (_canEditSeverity) ...[
              DropdownButtonFormField<String>(
                value: _severityDraft.isEmpty ? '' : _severityDraft,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: [
                  DropdownMenuItem(
                    value: '',
                    child: Text(
                      'Unassigned',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'Near miss',
                    child: Text(
                      'Near miss',
                      style: const TextStyle(color: Color(0xFF19CA6E)),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'No-harm',
                    child: Text(
                      'No-harm',
                      style: const TextStyle(color: Color(0xFF2196F3)),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'Adverse',
                    child: Text(
                      'Adverse',
                      style: const TextStyle(color: Color(0xFFFF9800)),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'Sentinel',
                    child: Text(
                      'Sentinel',
                      style: const TextStyle(color: Color(0xFFFF4D4D)),
                    ),
                  ),
                ],
                onChanged: _savingSeverity
                    ? null
                    : (v) => setState(() => _severityDraft = v ?? ''),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _savingSeverity ? null : _saveSeverity,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF28A745),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: _savingSeverity
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save'),
                ),
              ),
            ] else
              Text(
                _str('incident_type') ?? 'Unassigned',
                style: TextStyle(
                  color: _severityColor(_str('incident_type')),
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilesList() {
    final files = _p?['files_name'];
    if (files is! List || files.isEmpty) {
      return const Text('No files available');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final f in files)
          if (f is Map && f['name'] != null && f['url'] != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: InkWell(
                onTap: () => _openUrl(f['url'].toString()),
                child: Text(
                  f['name'].toString(),
                  style: const TextStyle(
                    color: efeedorBrandGreen,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
      ],
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const Divider(height: 20),
            child,
          ],
        ),
      ),
    );
  }

  Widget _kv(String label, String? value) {
    if (value == null || value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}
