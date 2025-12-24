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
  final _scrollController = ScrollController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _uhidController = TextEditingController();
  final TextEditingController _roomBedController = TextEditingController();
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
  final TextEditingController _wardSearchController = TextEditingController();
  List<Ward> _filteredWards = [];

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
    _scrollController.dispose();
    _nameController.dispose();
    _uhidController.dispose();
    _roomBedController.dispose();
    _wardSearchController.dispose();
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
          _filteredWards = cachedWards;
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
        _roomBedController.clear();
      });
      return;
    }

    final bedList = getBedNumbersForWard(wards, wardTitle);
    setState(() {
      bedNumbers = bedList;
      selectedRoomBed = null; // Reset selection when ward changes
      _roomBedController.clear();
    });
  }

  /// Find the first invalid field key in order: Name -> UHID -> Ward -> Room/Bed
  /// Checks field values directly to identify which field is invalid
  GlobalKey<FormFieldState<String>>? _findFirstInvalidField() {
    // Check Patient Name field
    final nameValue = _nameController.text.trim();
    if (nameValue.isEmpty || nameValue.length < 2) {
      return _nameFieldKey;
    }
    
    // Check Patient UHID field
    final uhidValue = _uhidController.text.trim();
    if (uhidValue.isEmpty) {
      return _uhidFieldKey;
    }
    
    // Check Ward field
    if (selectedWard == null) {
      return _wardFieldKey;
    }
    
    // Check Room/Bed field
    final roomBedValue = _roomBedController.text.trim();
    if (roomBedValue.isEmpty) {
      return _roomBedFieldKey;
    }
    
    return null;
  }

  /// Scroll to the field associated with the given GlobalKey
  void _scrollToField(GlobalKey<FormFieldState<String>> fieldKey) {
    // Use a post-frame callback to ensure the widget tree is fully built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && fieldKey.currentContext != null) {
        Scrollable.ensureVisible(
          fieldKey.currentContext!,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: 0.1, // Position the field near the top of the visible area
        );
      }
    });
  }

  void _navigateToEmojiPage() async {
    // Set validation flag
    setState(() {
      _hasValidatedOnce = true;
    });

    // Validate all fields
    if (_formKey.currentState!.validate()) {
      final feedbackData = IPFeedbackData(
        name: _nameController.text,
        uhid: _uhidController.text,
        mobileNumber: widget.mobileNumber,
        ward: selectedWard!,
        bedno: selectedRoomBed!,
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => IPDischargeEmojiPage(
            feedbackData: feedbackData,
          ),
        ),
      );
    } else {
      // Find the first invalid field
      final firstInvalidField = _findFirstInvalidField();
      
      if (firstInvalidField != null) {
        // Show alert dialog
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text(context.opTranslate('error')),
              content: const Text('Please fill all required fields.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    // Scroll to the first invalid field after dialog is dismissed
                    // Use a small delay to ensure dialog animation completes
                    Future.delayed(const Duration(milliseconds: 100), () {
                      if (mounted) {
                        _scrollToField(firstInvalidField);
                      }
                    });
                  },
                  child: Text(context.opTranslate('ok')),
                ),
              ],
            );
          },
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
                controller: _scrollController,
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
                            keyboardType: TextInputType.text,
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
                  String? displayText;
                  if (selectedWard != null) {
                    final ward = wards.firstWhere((w) => w.title == selectedWard);
                    displayText = apiText(
                      ward.title,
                      ward.titlek,
                      ward.titlem,
                      globalLang,
                    );
                  }
                  return GestureDetector(
                    onTap: () => _showWardSearchModal(context, globalLang),
                    child: AbsorbPointer(
                      child: TextFormField(
                        key: _wardFieldKey,
                        controller: TextEditingController(text: displayText ?? ''),
                        decoration: inputDecoration(
                                context.opTranslate('select_floor_ward'))
                            .copyWith(
                          prefixIcon: const Icon(Icons.local_hospital),
                          suffixIcon: const Icon(Icons.arrow_drop_down),
                        ),
                        validator: (value) => selectedWard == null
                            ? context.opTranslate('floor_ward_required')
                            : null,
                        readOnly: true,
                      ),
                    ),
                  );
                },
              ),
        const SizedBox(height: 16),
      ],
    );
  }

  void _showWardSearchModal(BuildContext context, String globalLang) {
    _wardSearchController.clear();
    _filteredWards = List.from(wards);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.7,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search field at the top
                TextField(
                  controller: _wardSearchController,
                  decoration: InputDecoration(
                    hintText: 'Search floor/ward...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _wardSearchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _wardSearchController.clear();
                              setModalState(() {
                                _filteredWards = List.from(wards);
                              });
                            },
                          )
                        : const SizedBox.shrink(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF1F3F6),
                  ),
                  onChanged: (value) {
                    setModalState(() {
                      if (value.isEmpty) {
                        _filteredWards = List.from(wards);
                      } else {
                        _filteredWards = wards.where((ward) {
                          final displayTitle = apiText(
                            ward.title,
                            ward.titlek,
                            ward.titlem,
                            globalLang,
                          );
                          return displayTitle.toLowerCase().contains(value.toLowerCase());
                        }).toList();
                      }
                    });
                  },
                ),
                const SizedBox(height: 16),
                // Filtered list
                Expanded(
                  child: _filteredWards.isEmpty
                      ? Center(
                          child: Text(
                            'No results found',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredWards.length,
                          itemBuilder: (context, index) {
                            final ward = _filteredWards[index];
                            final displayTitle = apiText(
                              ward.title,
                              ward.titlek,
                              ward.titlem,
                              globalLang,
                            );
                            final isSelected = selectedWard == ward.title;
                            return ListTile(
                              leading: const Icon(Icons.local_hospital),
                              title: Text(displayTitle),
                              selected: isSelected,
                              selectedTileColor: efeedorBrandGreen.withOpacity(0.1),
                              onTap: () {
                                setState(() {
                                  selectedWard = ward.title;
                                });
                                _loadBedNumbers(ward.title);
                                if (_hasValidatedOnce &&
                                    _wardFieldKey.currentState != null) {
                                  _wardFieldKey.currentState!.validate();
                                }
                                Navigator.pop(context);
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
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
                : TextFormField(
                    key: _roomBedFieldKey,
                    controller: _roomBedController,
                    onChanged: (value) {
                      // Update selectedRoomBed without calling setState
                      // This prevents focus loss during continuous typing
                      selectedRoomBed = value;
                      
                      // Only validate if validation has been attempted
                      // Use SchedulerBinding to defer validation to avoid rebuild during typing
                      if (_hasValidatedOnce &&
                          _roomBedFieldKey.currentState != null) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted && _roomBedFieldKey.currentState != null) {
                            _roomBedFieldKey.currentState!.validate();
                          }
                        });
                      }
                    },
                    decoration: inputDecoration(
                      context.opTranslate('enter_room_bed_number'),
                    ).copyWith(
                      prefixIcon: const Icon(Icons.bed),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly
                    ],
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                            ? context.opTranslate('room_bed_required')
                            : null,
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
