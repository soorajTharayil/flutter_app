import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/constant.dart';
import '../widgets/app_header_wrapper.dart';
import '../services/op_app_localizations.dart';
import '../services/op_localization_service.dart';
import '../services/ip_data_loader.dart';
import '../model/ip_feedback_data_model.dart';
import 'ip_discharge_patient_info_page.dart';
import 'ip_discharge_emoji_page.dart';
import '../widgets/hospital_logo_widget.dart';

class IPDischargeMobilePage extends StatefulWidget {
  const IPDischargeMobilePage({Key? key}) : super(key: key);

  @override
  State<IPDischargeMobilePage> createState() => _IPDischargeMobilePageState();
}

class _IPDischargeMobilePageState extends State<IPDischargeMobilePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _mobileController = TextEditingController();
  final _mobileFieldKey = GlobalKey<FormFieldState<String>>();
  bool _hasValidatedOnce = false;

  @override
  void initState() {
    super.initState();
    // Listen to language changes
    OPLocalizationService.instance.addListener(_onLanguageChanged);
  }

  @override
  void dispose() {
    OPLocalizationService.instance.removeListener(_onLanguageChanged);
    _mobileController.dispose();
    super.dispose();
  }

  void _onLanguageChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _navigateToNextPage() async {
    if (_formKey.currentState!.validate()) {
      final mobileNumber = _mobileController.text;

      // Check if cached IP data exists (from dashboard preload)
      final hasCachedData = await IPDataLoader.hasCachedIpData();

      if (!hasCachedData) {
        // No cached data available - show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Unable to load ward details. Please ensure internet is ON once at the dashboard and try again.',
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 5),
            ),
          );
        }
        return; // Don't navigate if no cached data
      }

      // ADDED: mobile_inpatient.php check (do not modify other logic)
      try {
        final domain = await getDomainFromPrefs();
        if (domain.isNotEmpty) {
          final response = await http
              .get(
            Uri.parse(
                'https://$domain.efeedor.com/api/mobile_inpatient.php?mobile=$mobileNumber'),
          )
              .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw Exception('Request timeout. Please check your connection.');
            },
          );

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            final pinfo = data['pinfo'];

            // CASE B: Patient exists in database
            if (pinfo != null && pinfo != 'NO' && pinfo is Map) {
              // Prefill feedback data from API response
              final feedbackData = IPFeedbackData(
                name: pinfo['name']?.toString() ?? '',
                uhid: pinfo['patient_id']?.toString() ?? '',
                mobileNumber: mobileNumber,
                ward: pinfo['ward']?.toString() ?? '',
                bed_no: pinfo['bed_no']?.toString() ?? '',
              );

              // Navigate directly to Emoji Page (skip Patient Info Page)
              if (mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => IPDischargeEmojiPage(
                      feedbackData: feedbackData,
                    ),
                  ),
                );
              }
              return; // Exit early - don't go to patient info page
            }
          }
        }
      } catch (e) {
        // API call failed - continue to patient info page (existing behavior)
        // Don't show error - allow user to proceed manually
      }

      // CASE A: pinfo == "NO" or API failed - go to Patient Information Page (existing behavior)
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => IPDischargePatientInfoPage(
            mobileNumber: mobileNumber,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppHeaderWrapper(
      titleWidget: Text(
        context.opTranslate(''),
        style: const TextStyle(
          fontSize: 16, // adjust to 14 or 15 if you want even smaller
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      showLogo: false,
      showLanguageSelector: true,
      showHomeButton: true,
      child: SafeArea(
        child: Column(
          children: [
            // -------------------- Hospital Logo (Same as Home Page) --------------------
            const HospitalLogoWidget(
              height: 80,
              padding: EdgeInsets.all(16),
              showRectangular: true,
              showCircular: false,
            ),
            const SizedBox(height: 2),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      autovalidateMode: AutovalidateMode.disabled,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          Text(
                            context.opTranslate('registered_mobile_number'),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Colors.teal, // Teal-green
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            context.opTranslate('ip_mobile_subtitle'),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            context.opTranslate('mobile_number'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            key: _mobileFieldKey,
                            controller: _mobileController,
                            keyboardType: TextInputType.phone,
                            maxLength: 10,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: inputDecoration(
                              context.opTranslate('enter_ip_mobile_number'),
                            ).copyWith(
                              prefixIcon: const Icon(Icons.phone),
                            ),
                            validator: (val) {
                              if (val == null || val.isEmpty) {
                                return context.opTranslate('mobile_required');
                              }
                              if (val.length != 10) {
                                return context.opTranslate('mobile_invalid');
                              }
                              return null;
                            },
                            onChanged: (value) {
                              // After first validation attempt, validate this field when it changes
                              if (_hasValidatedOnce &&
                                  _mobileFieldKey.currentState != null) {
                                _mobileFieldKey.currentState!.validate();
                              }
                            },
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _hasValidatedOnce = true;
                        });
                        _navigateToNextPage();
                      },
                      icon:
                          const Icon(Icons.arrow_forward, color: Colors.white),
                      label: Text(
                        context.opTranslate('next'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: efeedorBrandGreen,
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

  InputDecoration inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.black.withOpacity(0.35)),
      filled: true,
      fillColor: const Color(0xFFF1F3F6),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFCBD1DC)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: efeedorBrandGreen, width: 1.8),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}
