import 'package:flutter/material.dart';
import '../config/constant.dart';
import '../widgets/app_header_wrapper.dart';
import '../services/op_app_localizations.dart';
import '../services/op_localization_service.dart';

class IPDischargeNextPage extends StatefulWidget {
  final String mobileNumber;
  final String patientName;
  final String patientUhid;
  final String ward;
  final String bed_no;

  const IPDischargeNextPage({
    Key? key,
    required this.mobileNumber,
    required this.patientName,
    required this.patientUhid,
    required this.ward,
    required this.bed_no,
  }) : super(key: key);

  @override
  State<IPDischargeNextPage> createState() => _IPDischargeNextPageState();
}

class _IPDischargeNextPageState extends State<IPDischargeNextPage> {
  @override
  void initState() {
    super.initState();
    // Listen to language changes
    OPLocalizationService.instance.addListener(_onLanguageChanged);
  }

  @override
  void dispose() {
    OPLocalizationService.instance.removeListener(_onLanguageChanged);
    super.dispose();
  }

  void _onLanguageChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppHeaderWrapper(
      title: context.opTranslate('ip_discharge_feedback'),
      showLogo: false,
      showLanguageSelector: true,
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 64,
                            color: efeedorBrandGreen.withOpacity(0.7),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            context.opTranslate('ip_next_page_title'),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            context.opTranslate('ip_next_page_subtitle'),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          _buildInfoCard(
                            Icons.phone,
                            context.opTranslate('mobile_number'),
                            widget.mobileNumber,
                          ),
                          const SizedBox(height: 12),
                          _buildInfoCard(
                            Icons.person,
                            context.opTranslate('patient_name'),
                            widget.patientName,
                          ),
                          const SizedBox(height: 12),
                          _buildInfoCard(
                            Icons.badge,
                            context.opTranslate('patient_uhid'),
                            widget.patientUhid,
                          ),
                          const SizedBox(height: 12),
                          _buildInfoCard(
                            Icons.local_hospital,
                            context.opTranslate('select_floor_ward'),
                            widget.ward,
                          ),
                          const SizedBox(height: 12),
                          _buildInfoCard(
                            Icons.bed,
                            context.opTranslate('room_bed_number'),
                            widget.bed_no,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Bottom fixed button bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      label: Text(
                        context.opTranslate('back'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: efeedorBrandGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: efeedorBrandGreen,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: efeedorBrandGreen,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

