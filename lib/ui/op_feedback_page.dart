import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/department_service.dart';
import '../model/department_model.dart';
import 'op_emoji.dart';
import '../services/op_question_service.dart';
import '../model/op_feedback_data_model.dart';
import '../config/constant.dart';

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
  bool _isLoadingQuestions = false;
  bool _hasValidatedOnce = false;

  @override
  void initState() {
    super.initState();
    loadDepartments();
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
                  ? 'Connection timeout. Please check your internet connection.'
                  : 'Failed to load departments. Using cached data if available.',
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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Patient Details'),
        centerTitle: true,
        backgroundColor: efeedorBrandGreen,
      ),
      body: SafeArea(
        child: Column(
          children: [
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
                          buildTextField(
                            label: 'Patient Name *',
                            controller: nameController,
                            hint: 'Enter patient name',
                            icon: Icons.person,
                            maxLength: 25,
                            fieldKey: _nameFieldKey,
                            validator: (val) => val == null || val.isEmpty
                                ? 'Name is required'
                                : null,
                          ),
                          buildTextField(
                            label: 'UHID *',
                            controller: uhidController,
                            hint: 'Enter UHID',
                            icon: Icons.badge,
                            maxLength: 20,
                            keyboardType: TextInputType.number,
                            fieldKey: _uhidFieldKey,
                            validator: (val) => val == null || val.isEmpty
                                ? 'UHID is required'
                                : null,
                          ),
                          buildDropdown(),
                          const SizedBox(height: 16),
                          buildTextField(
                            label: 'Mobile Number *',
                            controller: mobileController,
                            hint: 'Enter mobile number',
                            icon: Icons.phone,
                            maxLength: 10,
                            keyboardType: TextInputType.phone,
                            fieldKey: _mobileFieldKey,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: (val) {
                              if (val == null || val.isEmpty) {
                                return 'Mobile is required';
                              }
                              if (val.length != 10) {
                                return 'Mobile number must be 10 digits';
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
                      label: const Text(
                        'Back',
                        style: TextStyle(
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
                      onPressed: _isLoadingQuestions ? null : () async {
                        setState(() {
                          _hasValidatedOnce = true;
                        });
                        
                        if (_formKey.currentState!.validate()) {
                          setState(() {
                            _isLoadingQuestions = true;
                          });
                          
                          try {
                            final sets = await fetchQuestionSets(
                                '123', selectedDepartment!);
                            
                            if (mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => FeedbackScreen(
                                    questionSets: sets,
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
                                  content: Text(e.toString().contains('timeout') 
                                      ? 'Connection timeout. Please try again.' 
                                      : 'Failed to load questions. Please try again.'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } finally {
                            if (mounted) {
                              setState(() {
                                _isLoadingQuestions = false;
                              });
                            }
                          }
                        }
                      },
                      icon: _isLoadingQuestions
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.arrow_forward, color: Colors.white),
                      label: Text(
                        _isLoadingQuestions ? 'Loading...' : 'Next',
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
        const Text('Department *',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
                        valueColor: AlwaysStoppedAnimation<Color>(efeedorBrandGreen),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Loading departments...',
                      style: TextStyle(
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
                    decoration: inputDecoration('Select Department')
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
                      if (_hasValidatedOnce && _departmentFieldKey.currentState != null) {
                        _departmentFieldKey.currentState!.validate();
                      }
                    },
                    validator: (value) =>
                        value == null ? 'Please select a department' : null,
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
