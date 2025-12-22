import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/department_service.dart';
import '../model/department_model.dart';
import 'op_emoji.dart';
import '../model/op_feedback_data_model.dart';
import '../config/constant.dart';
import '../widgets/app_header_wrapper.dart';
import '../services/op_app_localizations.dart';
import '../services/op_localization_service.dart';
import '../services/op_data_loader.dart';
import '../widgets/hospital_logo_widget.dart';

class OpFeedbackPage extends StatefulWidget {
  const OpFeedbackPage({Key? key}) : super(key: key);

  @override
  State<OpFeedbackPage> createState() => _OpFeedbackPageState();
}

class _OpFeedbackPageState extends State<OpFeedbackPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController uhidController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  final _nameFieldKey = GlobalKey<FormFieldState<String>>();
  final _uhidFieldKey = GlobalKey<FormFieldState<String>>();
  final _mobileFieldKey = GlobalKey<FormFieldState<String>>();
  final _departmentFieldKey = GlobalKey<FormFieldState<String>>();

  String? selectedDepartment;
  List<Department> departments = [];
  bool isLoadingDepartments = true;
  bool _hasValidatedOnce = false;

  @override
  void initState() {
    super.initState();
    _loadCachedDepartments();
    // Listen to OP language changes only
    OPLocalizationService.instance.addListener(_onLanguageChanged);
  }

  /// Load departments from cache, fallback to API if cache is empty (first launch)
  Future<void> _loadCachedDepartments() async {
    try {
      final cachedDepartments = await OPDataLoader.getCachedDepartments();

      // If cache is empty (first launch), load from API
      if (cachedDepartments.isEmpty) {
        // Fallback to API call for first launch
        await loadDepartments();
      } else {
        // Use cached data
        if (mounted) {
          setState(() {
            departments = cachedDepartments;
            isLoadingDepartments = false;
          });
        }
      }
    } catch (e) {
      // If cache load fails, try API as fallback
      if (mounted) {
        await loadDepartments();
      }
    }
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

  Future<void> loadDepartments() async {
    try {
      final fetchedDepartments = await fetchDepartments('123');
      if (mounted) {
        setState(() {
          departments = fetchedDepartments;
          isLoadingDepartments = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoadingDepartments = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().contains('timeout')
                  ? context.opTranslate('connection_timeout')
                  : context.opTranslate('failed_to_load'),
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
          ),
        );
      }
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
                        children: [
                          // -------------------- Page Heading --------------------
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              context.opTranslate('patient_information'),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.teal, // Teal-green
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          buildTextField(
                            label: '${context.opTranslate('patient_name')} *',
                            controller: nameController,
                            hint: context.opTranslate('enter_patient_name'),
                            icon: Icons.person,
                            maxLength: 25,
                            fieldKey: _nameFieldKey,
                            validator: (val) => val == null || val.isEmpty
                                ? context.opTranslate('patient_name_required')
                                : null,
                          ),
                          buildTextField(
                            label: '${context.opTranslate('uhid')} *',
                            controller: uhidController,
                            hint: context.opTranslate('enter_uhid'),
                            icon: Icons.badge,
                            maxLength: 20,
                            keyboardType: TextInputType.number,
                            fieldKey: _uhidFieldKey,
                            validator: (val) => val == null || val.isEmpty
                                ? context.opTranslate('uhid_required')
                                : null,
                          ),
                          buildDropdown(),
                          const SizedBox(height: 16),
                          buildTextField(
                            label: '${context.opTranslate('mobile_number')} *',
                            controller: mobileController,
                            hint: context.opTranslate('enter_mobile_number'),
                            icon: Icons.phone,
                            maxLength: 10,
                            keyboardType: TextInputType.phone,
                            fieldKey: _mobileFieldKey,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: (val) {
                              if (val == null || val.isEmpty) {
                                return context.opTranslate('mobile_required');
                              }
                              if (val.length != 10) {
                                return context.opTranslate('mobile_invalid');
                              }
                              return null;
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

                        if (_formKey.currentState!.validate()) {
                          // NO API CALL - Use cached data only
                          _navigateToEmojiPage();
                        }
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

  /// Navigate to emoji page using cached question sets (NO API CALL)
  void _navigateToEmojiPage() async {
    try {
      // Get cached question sets for selected department
      final cachedQuestionSets =
          await OPDataLoader.getCachedQuestionSets(selectedDepartment!);

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FeedbackScreen(
              questionSets: cachedQuestionSets,
              feedbackData: FeedbackData(
                name: nameController.text,
                uhid: uhidController.text,
                department: selectedDepartment!,
                mobileNumber: mobileController.text,
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.opTranslate('failed_to_load')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
        Text(label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
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

  Widget buildDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
            '${context.opTranslate('select_department').replaceAll('Select ', '')} *',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        isLoadingDepartments
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
                  return DropdownButtonFormField<String>(
                    key: _departmentFieldKey,
                    isExpanded: true,
                    value: selectedDepartment,
                    decoration: inputDecoration(
                            context.opTranslate('select_department'))
                        .copyWith(prefixIcon: const Icon(Icons.local_hospital)),
                    items: departments
                        .map((dept) => DropdownMenuItem(
                              value: dept.title,
                              child: Text(
                                dept.title,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedDepartment = value;
                      });
                      // After first validation attempt, validate this field when it changes
                      if (_hasValidatedOnce &&
                          _departmentFieldKey.currentState != null) {
                        _departmentFieldKey.currentState!.validate();
                      }
                    },
                    validator: (value) => value == null
                        ? context.opTranslate('department_required')
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
