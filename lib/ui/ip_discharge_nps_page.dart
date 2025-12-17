// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../model/ip_feedback_data_model.dart';
import 'op_thankyoupage.dart';
import '../config/constant.dart';
import '../widgets/app_header_wrapper.dart';
import '../services/op_localization_service.dart';
import '../services/op_app_localizations.dart';
import '../services/offline_storage_service.dart';
import '../services/connectivity_helper.dart';

Future<String> getDomainFromPrefs() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('domain') ?? '';
}

class IPDischargeNpsPage extends StatefulWidget {
  final IPFeedbackData feedbackData;

  const IPDischargeNpsPage({Key? key, required this.feedbackData})
      : super(key: key);

  @override
  _IPDischargeNpsPageState createState() => _IPDischargeNpsPageState();
}

class _IPDischargeNpsPageState extends State<IPDischargeNpsPage> {
  int? rating; // No default selection
  List<bool> selectedReasons = List.generate(8, (_) => false);
  TextEditingController suggestionController = TextEditingController();
  TextEditingController detractorCommentController = TextEditingController();
  TextEditingController staffNameController = TextEditingController();
  bool isSubmitting = false; // Prevent double submission

  List<String> get generalReasons => [
        context.opTranslate('location_proximity'),
        context.opTranslate('specific_services_offered'),
        context.opTranslate('referred_by_doctor'),
        context.opTranslate('friend_family_recommendation'),
        context.opTranslate('previous_experience'),
        context.opTranslate('insurance_facilities'),
        context.opTranslate('company_recommendation'),
        context.opTranslate('print_online_media'),
      ];

  @override
  void initState() {
    super.initState();
    // Listen to language changes
    OPLocalizationService.instance.addListener(_onLanguageChanged);
  }

  @override
  void dispose() {
    OPLocalizationService.instance.removeListener(_onLanguageChanged);
    suggestionController.dispose();
    detractorCommentController.dispose();
    staffNameController.dispose();
    super.dispose();
  }

  void _onLanguageChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  /// Returns the color for an NPS button based on its value
  /// 0-6: Red, 7-8: Orange, 9-10: Green
  Color getNpsColor(int index, int selected) {
    if (index <= 6) return const Color(0xFFE57373); // Red
    if (index <= 8) return const Color(0xFFFFB74D); // Orange
    return const Color(0xFF81C784); // Green
  }

  /// Builds the correct JSON payload structure for IP feedback API
  /// Uses the SAME structure as OP but with IP-specific fields
  Map<String, dynamic> buildFeedbackPayload(
      IPFeedbackData feedbackData,
      int npsRating,
      String suggestions,
      Map<String, bool> generalReasonsMap,
      String detractorComment,
      String staffName) {
    // Initialize structures
    Map<String, dynamic> reasonSet = {};
    Map<String, dynamic> reason = {};
    Map<String, dynamic> commentSet = {};
    Map<String, dynamic> comment = {};
    Map<String, dynamic> ratingValues = {};

    // Collect all set types from negative items' type field
    Set<String> allSetTypes = {};
    // Map: subQuestionId -> (shortkey, type)
    Map<String, Map<String, String>> subQuestionInfo = {};
    // Map: questionId -> list of (shortkey, type) tuples
    Map<String, List<Map<String, String>>> questionToShortkeysAndTypes = {};
    // Map: questionId -> question shortkey (for rating values)
    Map<String, String> questionIdToShortkey = {};

    // First pass: Collect all set types and build mappings from negative items
    for (final questionSet in feedbackData.questionSets) {
      for (final question in questionSet.questions) {
        List<Map<String, String>> shortkeysAndTypes = [];

        // Map question ID to its shortkey
        if (question.shortkey.isNotEmpty) {
          questionIdToShortkey[question.id] = question.shortkey;
        }

        for (final subQuestion in question.negative) {
          if (subQuestion.shortkey.isNotEmpty && subQuestion.type.isNotEmpty) {
            final type = subQuestion.type;
            final shortkey = subQuestion.shortkey;

            // Collect set type
            allSetTypes.add(type);

            // Store sub-question info
            subQuestionInfo[subQuestion.id] = {
              'shortkey': shortkey,
              'type': type,
            };

            // Store for question mapping
            shortkeysAndTypes.add({
              'shortkey': shortkey,
              'type': type,
            });
          }
        }

        questionToShortkeysAndTypes[question.id] = shortkeysAndTypes;
      }
    }

    // Initialize all sets (even empty ones) as empty maps
    for (final setType in allSetTypes) {
      reasonSet[setType] = <String, dynamic>{};
      commentSet[setType] = <String, dynamic>{};
    }

    // Process feedback values and build reasonSet, reason, commentSet, comment
    for (final entry in feedbackData.feedbackValues.entries) {
      final questionId = entry.key;
      final ratingValue = entry.value;

      // Convert question ID to shortkey (e.g., "11" -> "op10")
      final questionShortkey = questionIdToShortkey[questionId];
      if (questionShortkey != null && questionShortkey.isNotEmpty) {
        // Add rating value using shortkey (e.g., op10, op20, op30)
        ratingValues[questionShortkey] = ratingValue;
      }

      // Process reasons and comments only for poor/worst ratings (1 or 2)
      if (ratingValue == 1 || ratingValue == 2) {
        final selectedReasonsForQuestion =
            feedbackData.selectedReasons[questionId] ?? {};
        final commentForQuestion = feedbackData.comments[questionId] ?? '';

        // Get all shortkeys and their types for this question
        final shortkeysAndTypes = questionToShortkeysAndTypes[questionId] ?? [];

        // Process each shortkey with its type
        for (final item in shortkeysAndTypes) {
          final shortkey = item['shortkey']!;
          final type = item['type']!;

          // Check if this shortkey was selected
          bool isSelected = false;
          for (final reasonEntry in selectedReasonsForQuestion.entries) {
            final subQuestionId = reasonEntry.key;
            if (subQuestionInfo[subQuestionId]?['shortkey'] == shortkey &&
                reasonEntry.value == true) {
              isSelected = true;
              break;
            }
          }

          if (isSelected) {
            // Add to reasonSet[type][shortkey] = true
            if (!reasonSet.containsKey(type)) {
              reasonSet[type] = <String, dynamic>{};
            }
            (reasonSet[type] as Map<String, dynamic>)[shortkey] = true;

            // Add to flat reason map (always set to true if selected)
            reason[shortkey] = true;
          } else {
            // Unchecked shortkeys return "" in reason map (only if not already set to true)
            if (!reason.containsKey(shortkey)) {
              reason[shortkey] = "";
            }
            // If already exists and is true, don't overwrite it
          }
        }

        // Process comment - determine which type this comment belongs to
        if (commentForQuestion.trim().isNotEmpty) {
          // Find the type: prefer type from selected reasons, otherwise use first type
          String? commentType;

          // First, try to find type from selected reasons
          for (final reasonEntry in selectedReasonsForQuestion.entries) {
            if (reasonEntry.value == true) {
              final subQuestionId = reasonEntry.key;
              final type = subQuestionInfo[subQuestionId]?['type'];
              if (type != null && type.isNotEmpty) {
                commentType = type;
                break;
              }
            }
          }

          // If no type found from selected reasons, use first type from negative items
          if (commentType == null && shortkeysAndTypes.isNotEmpty) {
            commentType = shortkeysAndTypes.first['type'];
          }

          if (commentType != null && commentType.isNotEmpty) {
            // Add to commentSet[type] = { type: comment }
            if (!commentSet.containsKey(commentType)) {
              commentSet[commentType] = <String, dynamic>{};
            }
            (commentSet[commentType] as Map<String, dynamic>)[commentType] =
                commentForQuestion.trim();

            // Add to flat comment map
            comment[commentType] = commentForQuestion.trim();
          }
        }
      }
    }

    // Convert empty sets to empty arrays as per backend expectation
    for (final setType in allSetTypes) {
      if ((reasonSet[setType] as Map).isEmpty) {
        reasonSet[setType] = [];
      }
      if ((commentSet[setType] as Map).isEmpty) {
        commentSet[setType] = [];
      }
    }

    // Calculate overallScore: average of all rating values, rounded to 2 decimal places
    double overallScore = 0.0;
    if (ratingValues.isNotEmpty) {
      final ratingList = ratingValues.values.map((v) => v as int).toList();
      final sum = ratingList.reduce((a, b) => a + b);
      overallScore = sum / ratingList.length;
      // Round to 2 decimal places
      overallScore = double.parse(overallScore.toStringAsFixed(2));
    }

    // Build final payload - SAME structure as OP but with IP section and IP fields
    final payload = <String, dynamic>{
      'section': 'IP',
      'langsub': 'english',
      'datetime': DateTime.now().millisecondsSinceEpoch,
      'reasonSet': reasonSet,
      'reason': reason,
      'commentSet': commentSet,
      'comment': comment,
      'overallScore': overallScore,
      // Add all rating values (op10, op20, op30, etc.)
      ...ratingValues,
      // Keep existing required fields
      'recommend1Score': npsRating / 2,
      'source': 'WLink',
      'name': feedbackData.name,
      'patientid': feedbackData.uhid,
      'ward': feedbackData.ward,
      'roomBed': feedbackData.roomBed,
      'contactnumber': feedbackData.mobileNumber,
      'patientType': 'In-Patient',
      'consultant_cat': 'General',
      'administratorId': 'admin001',
      'wardid': 'ward001',
      // General reasons as boolean map
      ...generalReasonsMap,
      'suggestionText': suggestions,
      'detractorcomment': detractorComment,
      'staffname': staffName,
    };

    return payload;
  }

  @override
  Widget build(BuildContext context) {
    final feedbackData = widget.feedbackData;

    return AppHeaderWrapper(
      title: context.opTranslate('feedback'),
      showLogo: false,
      showLanguageSelector: true,
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 3, 16, 16),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // SECTION 1: NPS RATING
                    Card(
                      elevation: 4,
                      shadowColor: Colors.black.withOpacity(0.08),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      margin: const EdgeInsets.only(bottom: 20),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.opTranslate(''),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: efeedorBrandGreen,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              context.opTranslate('nps_question'),
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // ===== NPS SCALE (FIXED) =====
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final spacing = 3.0;
                                final totalSpacing = spacing * 10;
                                final boxWidth =
                                    (constraints.maxWidth - totalSpacing) / 11;

                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: List.generate(11, (index) {
                                    final isHighlighted =
                                        rating != null && index <= rating!;
                                    final buttonColor = rating != null
                                        ? getNpsColor(index, rating!)
                                        : const Color(0xFFE0E0E0);
                                    final defaultGrey = const Color(0xFFE0E0E0);

                                    return Padding(
                                      padding: EdgeInsets.only(
                                        right: index < 10 ? spacing : 0,
                                      ),
                                      child: SizedBox(
                                        width: boxWidth,
                                        height: 32,
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              rating = index;
                                            });
                                          },
                                          child: AnimatedContainer(
                                            duration: const Duration(
                                                milliseconds: 200),
                                            curve: Curves.easeOut,
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              color: isHighlighted
                                                  ? buttonColor
                                                  : defaultGrey,
                                              borderRadius: BorderRadius.only(
                                                topLeft: index == 0
                                                    ? const Radius.circular(4)
                                                    : Radius.zero,
                                                bottomLeft: index == 0
                                                    ? const Radius.circular(4)
                                                    : Radius.zero,
                                                topRight: index == 10
                                                    ? const Radius.circular(4)
                                                    : Radius.zero,
                                                bottomRight: index == 10
                                                    ? const Radius.circular(4)
                                                    : Radius.zero,
                                              ),
                                              border: Border.all(
                                                color: isHighlighted
                                                    ? buttonColor
                                                    : Colors.grey.shade300,
                                                width: 1.5,
                                              ),
                                            ),
                                            child: Text(
                                              '$index',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 14,
                                                color: isHighlighted
                                                    ? Colors.white
                                                    : Colors.black87,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                );
                              },
                            ),

                            const SizedBox(height: 20),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  context.opTranslate('not_at_all_likely'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                Text(
                                  context.opTranslate('extremely_likely'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            if (rating != null)
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: efeedorBrandGreen.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${context.opTranslate('selected_rating')}: $rating',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: efeedorBrandGreen,
                                  ),
                                ),
                              ),

                            AnimatedSize(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeOut,
                              child: rating != null && rating! <= 6
                                  ? Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 16),
                                        TextField(
                                          controller:
                                              detractorCommentController,
                                          maxLines: 4,
                                          decoration: InputDecoration(
                                            hintText: context.opTranslate(
                                              'please_tell_us_why_rating',
                                            ),
                                            filled: true,
                                            fillColor: Colors.white,
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                color: efeedorBrandGreen,
                                                width: 1.8,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // SECTION 2: REASONS
                    Card(
                      elevation: 4,
                      shadowColor: Colors.black.withOpacity(0.08),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      margin: const EdgeInsets.only(bottom: 20),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context
                                  .opTranslate('reason_for_selecting_hospital'),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: efeedorBrandGreen,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Wrap(
                              spacing: 10,
                              runSpacing: 12,
                              children:
                                  List.generate(generalReasons.length, (index) {
                                final isSelected = selectedReasons[index];
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selectedReasons[index] =
                                          !selectedReasons[index];
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 18, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? efeedorBrandGreen
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(
                                        color: isSelected
                                            ? efeedorBrandGreen
                                            : Colors.grey.shade300,
                                        width: 1.5,
                                      ),
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: efeedorBrandGreen
                                                    .withOpacity(0.2),
                                                blurRadius: 8,
                                                offset: const Offset(0, 4),
                                              )
                                            ]
                                          : [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(0.05),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              )
                                            ],
                                    ),
                                    child: Text(
                                      generalReasons[index],
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.w500,
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // SECTION 3: STAFF RECOGNITION
                    Card(
                      elevation: 4,
                      shadowColor: Colors.black.withOpacity(0.08),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      margin: const EdgeInsets.only(bottom: 20),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.opTranslate('staff_recognition'),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: efeedorBrandGreen,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              context
                                  .opTranslate('staff_recognition_description'),
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: staffNameController,
                              decoration: InputDecoration(
                                hintText: context.opTranslate('staff_name'),
                                hintStyle: TextStyle(
                                  color: Colors.black.withOpacity(0.35),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: efeedorBrandGreen,
                                    width: 1.8,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                              ),
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // SECTION 4: COMMENT
                    Card(
                      elevation: 4,
                      shadowColor: Colors.black.withOpacity(0.08),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      margin: const EdgeInsets.only(bottom: 20),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.opTranslate('suggestions_or_concerns'),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: efeedorBrandGreen,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              context.opTranslate(
                                  'describe_reasons_or_suggestions'),
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: suggestionController,
                              decoration: InputDecoration(
                                hintText:
                                    context.opTranslate('enter_suggestions'),
                                hintStyle: TextStyle(
                                  color: Colors.black.withOpacity(0.35),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: efeedorBrandGreen,
                                    width: 1.8,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                              ),
                              maxLines: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Buttons
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
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
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            // Prevent double submission
                            if (isSubmitting) return;

                            // Set submitting state immediately
                            setState(() {
                              isSubmitting = true;
                            });

                            // Validation 1: NPS rating must be mandatory
                            if (rating == null) {
                              setState(() {
                                isSubmitting = false;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(context
                                      .opTranslate('please_select_nps_rating')),
                                  backgroundColor: Colors.red,
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                              return;
                            }

                            // Convert selectedReasons to boolean map format
                            final Map<String, bool> generalReasonsMap = {
                              'location': selectedReasons[0],
                              'specificservice': selectedReasons[1],
                              'referred': selectedReasons[2],
                              'friend': selectedReasons[3],
                              'previous': selectedReasons[4],
                              'docAvailability': selectedReasons[5],
                              'companyRecommend': selectedReasons[6],
                              'otherReason': selectedReasons[7],
                            };

                            // Determine detractor comment based on rating
                            final String detractorComment = rating! <= 6
                                ? detractorCommentController.text.trim()
                                : '';

                            // Validation 2: Detractor comment must be mandatory for ratings 0-6
                            if (rating! <= 6 && detractorComment.isEmpty) {
                              setState(() {
                                isSubmitting = false;
                              });
                              showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: Text(
                                      context.opTranslate('comment_required')),
                                  content: Text(context.opTranslate(
                                      'please_tell_us_why_rating_dialog')),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text(context.opTranslate('ok')),
                                    ),
                                  ],
                                ),
                              );
                              return;
                            }

                            // Build the correct JSON payload structure
                            final feedbackPayload = buildFeedbackPayload(
                              feedbackData,
                              rating!,
                              suggestionController.text,
                              generalReasonsMap,
                              detractorComment,
                              staffNameController.text.trim(),
                            );

                            // Get domain from SharedPreferences
                            final domain = await getDomainFromPrefs();
                            if (domain.isEmpty) {
                              setState(() {
                                isSubmitting = false;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(context
                                        .opTranslate('domain_not_found'))),
                              );
                              return;
                            }

                            // Check if online
                            final online = await isOnline();

                            // If offline, save to local storage
                            if (!online) {
                              try {
                                // Save IP feedback offline
                                await OfflineStorageService
                                    .saveOfflineIPFeedback(feedbackPayload);

                                // Show success message and navigate to thank you page
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(context.opTranslate(
                                          'feedback_stored_offline')),
                                      backgroundColor: Colors.orange,
                                      duration: const Duration(seconds: 3),
                                    ),
                                  );

                                  // Navigate to thank you page even when offline
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const ThankYouScreen()),
                                  );
                                }
                              } catch (e) {
                                // MUST NOT crash UI - show error but don't throw
                                if (mounted) {
                                  setState(() {
                                    isSubmitting = false;
                                  });
                                  showDialog(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: Text(context.opTranslate('error')),
                                      content: Text(context.opTranslate(
                                          'failed_to_save_offline')),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child:
                                              Text(context.opTranslate('ok')),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                              }
                              return; // Exit early when offline
                            }

                            // If online, proceed with normal API call
                            final uri = Uri.parse(
                              'https://$domain.efeedor.com/api/savepatientfeedback.php?patient_id=${feedbackData.uhid}&administratorId=admin001',
                            );

                            try {
                              final response = await http
                                  .post(
                                uri,
                                headers: {'Content-Type': 'application/json'},
                                body: jsonEncode(feedbackPayload),
                              )
                                  .timeout(
                                const Duration(seconds: 30),
                                onTimeout: () {
                                  throw Exception('Request timeout');
                                },
                              );

                              final responseData = jsonDecode(response.body);
                              if (responseData['status'] == 'success') {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const ThankYouScreen()),
                                );
                              } else {
                                setState(() {
                                  isSubmitting = false;
                                });
                                showDialog(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: Text(context.opTranslate(
                                        'feedback_already_submitted')),
                                    content: Text(context.opTranslate(
                                        'feedback_already_submitted_message')),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: Text(context.opTranslate('ok')),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            } catch (e) {
                              // If online but API call fails, treat as offline and save locally
                              try {
                                await OfflineStorageService
                                    .saveOfflineIPFeedback(feedbackPayload);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(context.opTranslate(
                                          'network_error_offline')),
                                      backgroundColor: Colors.orange,
                                      duration: const Duration(seconds: 3),
                                    ),
                                  );
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const ThankYouScreen()),
                                  );
                                }
                              } catch (offlineError) {
                                // If offline save also fails, show error (MUST NOT crash)
                                if (mounted) {
                                  setState(() {
                                    isSubmitting = false;
                                  });
                                  showDialog(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: Text(
                                          context.opTranslate('network_error')),
                                      content: Text(context.opTranslate(
                                          'check_internet_connection')),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child:
                                              Text(context.opTranslate('ok')),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                              }
                            }
                          },
                    icon: isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.send, color: Colors.white),
                    label: Text(
                      isSubmitting
                          ? context.opTranslate('loading')
                          : context.opTranslate('submit'),
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
    );
  }
}
