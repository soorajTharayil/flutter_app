import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/constant.dart';
import '../widgets/app_header_wrapper.dart';
import '../services/op_app_localizations.dart';
import '../services/op_localization_service.dart';
import '../services/ward_service.dart';
import '../services/ip_data_loader.dart';
import '../model/ward_model.dart';
import '../model/ip_feedback_data_model.dart';
import 'ip_discharge_emoji_page.dart';
import '../widgets/hospital_logo_widget.dart';

/// Language helper function: returns the correct API text based on selected language
String apiText(String en, String kn, String ml, String lang) {
  if (lang == 'kn' && kn.isNotEmpty) {
    return kn;
  }
  if (lang == 'ml' && ml.isNotEmpty) {
    return ml;
  }
  return en;
}

class IPDischargePatientInfoPage extends StatefulWidget {
  final String mobileNumber;

  const IPDischargePatientInfoPage({
    Key? key,
    required this.mobileNumber,
  }) : super(key: key);

  @override
  State<IPDischargePatientInfoPage> createState() =>
      _IPDischargePatientInfoPageState();
}

class _IPDischargePatientInfoPageState
    extends State<IPDischargePatientInfoPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _uhidController = TextEditingController();
  final _nameFieldKey = GlobalKey<FormFieldState<String>>();
  final _uhidFieldKey = GlobalKey<FormFieldState<String>>();
  final _wardFieldKey = GlobalKey<FormFieldState<String>>();
  final _roomBedFieldKey = GlobalKey<FormFieldState<String>>();

  String? selectedWard;
  String? selectedRoomBed;
  List<Ward> wards = [];
  List<String> bedNumbers = [];
  bool isLoadingWards = true;
  bool _hasValidatedOnce = false;

  @override
  void initState() {
    super.initState();
    _loadWards();
    // Listen to language changes
    OPLocalizationService.instance.addListener(_onLanguageChanged);
  }

  @override
  void dispose() {
    OPLocalizationService.instance.removeListener(_onLanguageChanged);
    _nameController.dispose();
    _uhidController.dispose();
    super.dispose();
  }

  void _onLanguageChanged() {
    if (mounted) {
      setState(() {});
      // Dismiss the keyboard when language changes
      FocusScope.of(context).unfocus();
    }
  }

  Future<void> _loadWards() async {
    try {
      // ONLY use cached data - never make API calls from this page
      // This ensures full offline support
      List<Ward> cachedWards =
          await IPDataLoader.getCachedWards(widget.mobileNumber);

      if (mounted) {
        setState(() {
          wards = cachedWards;
          isLoadingWards = false;
        });

        // If no cached data available, show helpful message
        if (cachedWards.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.opTranslate('failed_to_load'),
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      // Ensure loading state is cleared
      if (mounted) {
        setState(() {
          isLoadingWards = false;
        });
      }
    }
  }

  void _loadBedNumbers(String? wardTitle) {
    if (wardTitle == null || wardTitle.isEmpty) {
      setState(() {
        bedNumbers = [];
        selectedRoomBed = null;
      });
      return;
    }

    final bedList = getBedNumbersForWard(wards, wardTitle);
    setState(() {
      bedNumbers = bedList;
      selectedRoomBed = null; // Reset selection when ward changes
    });
  }

  void _navigateToEmojiPage() async {
    if (_formKey.currentState!.validate()) {
      final feedbackData = IPFeedbackData(
        name: _nameController.text,
        uhid: _uhidController.text,
        mobileNumber: widget.mobileNumber,
        ward: selectedWard!,
        roomBed: selectedRoomBed!,
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => IPDischargeEmojiPage(
            feedbackData: feedbackData,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppHeaderWrapper(
      titleWidget: Text(
        context.opTranslate('Patient Details'),
        style: const TextStyle(
          fontSize: 16, // adjust to 14 or 15 if you want even smaller
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      showLogo: false,
      showLanguageSelector: true,
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
// ---------------------------------------------------------------------------

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
                        children: [
                          // -------------------- Page Heading --------------------
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              context.opTranslate('ip_discharge_feedback_form'),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.teal, // Teal-green
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
// -------------------------------------------------------

                          buildTextField(
                            label: '${context.opTranslate('patient_name')} *',
                            controller: _nameController,
                            hint: context.opTranslate('enter_ip_patient_name'),
                            icon: Icons.person,
                            maxLength: 50,
                            fieldKey: _nameFieldKey,
                            validator: (val) {
                              if (val == null || val.isEmpty) {
                                return context
                                    .opTranslate('patient_name_required');
                              }
                              if (val.length < 2) {
                                return context
                                    .opTranslate('patient_name_min_length');
                              }
                              return null;
                            },
                          ),
                          buildTextField(
                            label: '${context.opTranslate('patient_uhid')} *',
                            controller: _uhidController,
                            hint: context.opTranslate('enter_ip_uhid'),
                            icon: Icons.badge,
                            maxLength: 20,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            fieldKey: _uhidFieldKey,
                            validator: (val) => val == null || val.isEmpty
                                ? context.opTranslate('uhid_required')
                                : null,
                          ),
                          buildWardDropdown(),
                          const SizedBox(height: 20),
                          buildRoomBedDropdown(),
                          // <-- SAME GAP AS NAME–UHID
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
                        _navigateToEmojiPage();
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

  Widget buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int? maxLength,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
    GlobalKey<FormFieldState<String>>? fieldKey,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700, // ← BOLD
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          key: fieldKey,
          controller: controller,
          decoration: inputDecoration(hint).copyWith(prefixIcon: Icon(icon)),
          keyboardType: keyboardType,
          maxLength: maxLength,
          validator: validator,
          inputFormatters: inputFormatters,
          onChanged: (value) {
            // After first validation attempt, validate this field when it changes
            if (_hasValidatedOnce && fieldKey?.currentState != null) {
              fieldKey!.currentState!.validate();
            }
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget buildWardDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${context.opTranslate('select_floor_ward')} *',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        isLoadingWards
            ? Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F3F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(efeedorBrandGreen),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      context.opTranslate('loading'),
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              )
            : LayoutBuilder(
                builder: (context, constraints) {
                  final globalLang = OPLocalizationService.currentLanguage;
                  return DropdownButtonFormField<String>(
                    key: _wardFieldKey,
                    isExpanded: true,
                    value: selectedWard,
                    decoration: inputDecoration(
                            context.opTranslate('select_floor_ward'))
                        .copyWith(prefixIcon: const Icon(Icons.local_hospital)),
                    items: wards.map((ward) {
                      final displayTitle = apiText(
                        ward.title,
                        ward.titlek,
                        ward.titlem,
                        globalLang,
                      );
                      return DropdownMenuItem(
                        value: ward.title, // Store English title as value
                        child: Text(
                          displayTitle,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedWard = value;
                      });
                      // Load bed numbers from selected ward's bedno array
                      _loadBedNumbers(value);
                      // After first validation attempt, validate this field when it changes
                      if (_hasValidatedOnce &&
                          _wardFieldKey.currentState != null) {
                        _wardFieldKey.currentState!.validate();
                      }
                    },
                    validator: (value) => value == null
                        ? context.opTranslate('floor_ward_required')
                        : null,
                  );
                },
              ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget buildRoomBedDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${context.opTranslate('room_bed_number')} *',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        selectedWard == null
            ? Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F3F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    context.opTranslate('select_ward_first'),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ),
              )
            : bedNumbers.isEmpty
                ? Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F3F6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        context.opTranslate('no_beds_available'),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      return TextFormField(
                        key: _roomBedFieldKey,
                        controller:
                            TextEditingController(text: selectedRoomBed),
                        onChanged: (value) {
                          setState(() {
                            selectedRoomBed = value;
                          });

                          if (_hasValidatedOnce &&
                              _roomBedFieldKey.currentState != null) {
                            _roomBedFieldKey.currentState!.validate();
                          }
                        },
                        decoration: inputDecoration(
                          context.opTranslate('enter_room_bed_number'),
                        ).copyWith(
                          prefixIcon: const Icon(Icons.bed),
                        ),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                                ? context.opTranslate('room_bed_required')
                                : null,
                      );
                    },
                  ),
        const SizedBox(height: 16),
      ],
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
