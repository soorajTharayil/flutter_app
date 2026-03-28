import 'package:flutter/material.dart';

/// Same mapping as PHP `computeLevel` in the risk matrix modal.
String computeIncidentRiskLevel(String impact, String likelihood) {
  const map = <String, Map<String, String>>{
    'High': {
      'Low': 'Medium',
      'Medium': 'High',
      'High': 'High',
    },
    'Medium': {
      'Low': 'Low',
      'Medium': 'Medium',
      'High': 'High',
    },
    'Low': {
      'Low': 'Low',
      'Medium': 'Low',
      'High': 'Medium',
    },
  };
  return map[impact]?[likelihood] ?? '';
}

Color _cellBg(String label) {
  switch (label) {
    case 'Low':
      return const Color(0xFF28A745);
    case 'Medium':
      return const Color(0xFFFFC107);
    case 'High':
      return const Color(0xFFDC3545);
    default:
      return Colors.grey;
  }
}

Color _levelColor(String? level) {
  switch (level) {
    case 'High':
      return const Color(0xFFD9534F);
    case 'Medium':
      return const Color(0xFFF0AD4E);
    case 'Low':
      return const Color(0xFF137F35);
    default:
      return const Color(0xFF000000);
  }
}

/// 3×3 matrix: rows = Impact High→Low, cols = Likelihood Low→High (matches PHP table).
class RiskMatrixEditorDialog extends StatefulWidget {
  final String? initialImpact;
  final String? initialLikelihood;

  const RiskMatrixEditorDialog({
    Key? key,
    this.initialImpact,
    this.initialLikelihood,
  }) : super(key: key);

  @override
  State<RiskMatrixEditorDialog> createState() => _RiskMatrixEditorDialogState();
}

class _RiskMatrixEditorDialogState extends State<RiskMatrixEditorDialog> {
  static const _impacts = ['High', 'Medium', 'Low'];
  static const _likelihoods = ['Low', 'Medium', 'High'];

  /// Cell labels [impactIndex][likelihoodIndex]
  static const _labels = [
    ['Medium', 'High', 'High'],
    ['Low', 'Medium', 'High'],
    ['Low', 'Low', 'Medium'],
  ];

  late String _impact;
  late String _likelihood;

  @override
  void initState() {
    super.initState();
    _impact = widget.initialImpact != null &&
            _impacts.contains(widget.initialImpact)
        ? widget.initialImpact!
        : 'Medium';
    _likelihood = widget.initialLikelihood != null &&
            _likelihoods.contains(widget.initialLikelihood)
        ? widget.initialLikelihood!
        : 'Medium';
  }

  String get _level => computeIncidentRiskLevel(_impact, _likelihood);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Risk Matrix'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Table(
              border: TableBorder.all(color: Colors.grey.shade400),
              defaultColumnWidth: const IntrinsicColumnWidth(),
              children: [
                TableRow(
                  children: [
                    const SizedBox(width: 44, height: 8),
                    ..._likelihoods.map(
                      (l) => Padding(
                        padding: const EdgeInsets.all(6),
                        child: Text(
                          l,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                for (var i = 0; i < 3; i++)
                  TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(6),
                        child: RotatedBox(
                          quarterTurns: 0,
                          child: Text(
                            _impacts[i],
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      for (var j = 0; j < 3; j++)
                        _cell(i, j),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'IMPACT →',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: _level.isEmpty ? '—' : _level,
                    style: TextStyle(
                      color: _levelColor(_level.isEmpty ? null : _level),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  TextSpan(
                    text:
                        ' ($_impact Impact × $_likelihood Likelihood)',
                    style: const TextStyle(color: Colors.black87, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF28A745),
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            Navigator.pop(context, {
              'impact': _impact,
              'likelihood': _likelihood,
              'level': _level,
            });
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  Widget _cell(int impactIndex, int likelihoodIndex) {
    final label = _labels[impactIndex][likelihoodIndex];
    final selected = _impacts[impactIndex] == _impact &&
        _likelihoods[likelihoodIndex] == _likelihood;
    return GestureDetector(
      onTap: () {
        setState(() {
          _impact = _impacts[impactIndex];
          _likelihood = _likelihoods[likelihoodIndex];
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: _cellBg(label),
          border: Border.all(
            color: selected ? Colors.black : Colors.transparent,
            width: selected ? 3 : 0,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: label == 'Medium' && _cellBg(label) == const Color(0xFFFFC107)
                ? Colors.black
                : Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
