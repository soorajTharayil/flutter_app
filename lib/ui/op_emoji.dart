import 'package:flutter/material.dart';
import '../model/op_question_model.dart';
import '../model/op_feedback_data_model.dart';
import 'op_finalpage.dart';
import '../config/constant.dart';
import '../widgets/app_header_wrapper.dart';
import '../services/op_localization_service.dart';
import '../services/op_data_loader.dart';
import '../services/op_app_localizations.dart';

class FeedbackScreen extends StatefulWidget {
  final List<QuestionSet> questionSets;
  final FeedbackData feedbackData;
  final String language;

  FeedbackScreen({
    required this.questionSets,
    required this.feedbackData,
    this.language = 'lang1',
  });

  @override
  _FeedbackScreenState createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  Map<String, int> feedbackValues = {};
  Map<String, Map<String, bool>> selectedReasons = {};
  Map<String, String> comments = {};
  late List<QuestionSet> _questionSets;
  bool _isReloading = false;

  @override
  void initState() {
    super.initState();
    _questionSets = widget.questionSets;
    // Listen to language changes
    OPLocalizationService.instance.addListener(_onLanguageChanged);
  }

  @override
  void dispose() {
    OPLocalizationService.instance.removeListener(_onLanguageChanged);
    super.dispose();
  }

  void _onLanguageChanged() async {
    if (mounted && !_isReloading) {
      setState(() {
        _isReloading = true;
      });

      try {
        // Reload from cache only (no API calls for offline support)
        // Cached question sets already contain all multilingual fields
        // (categoryk, categorym, questionk, questionm, titlek, titlem)
        final cachedQuestionSets = await OPDataLoader.getCachedQuestionSets(
          widget.feedbackData.department,
        );

        if (mounted) {
          setState(() {
            // Update question sets from cache (multilingual fields already included)
            if (cachedQuestionSets.isNotEmpty) {
              _questionSets = cachedQuestionSets;
            }
            // If cache is empty, keep existing question sets
            // The apiText() function will still work with existing data
            _isReloading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isReloading = false;
          });
        }
      }
    }
  }

  /// Language helper function: returns the correct API text based on selected language
  /// Matches backend API structure: category/categoryk/categorym, question/questionk/questionm, title/titlek/titlem
  /// Uses fields from department.php → op_questionjson() output
  String apiText(String en, String kn, String ml, String lang) {
    if (lang == 'kn' && kn.isNotEmpty) {
      return kn;
    }
    if (lang == 'ml' && ml.isNotEmpty) {
      return ml;
    }
    return en;
  }

  void setFeedback(int value, String questionId) {
    setState(() {
      // Toggle: if clicking the same value, deselect it
      if (feedbackValues[questionId] == value) {
        feedbackValues.remove(questionId);
        selectedReasons.remove(questionId);
        comments.remove(questionId);
      } else {
        feedbackValues[questionId] = value;
        if (value == 1 || value == 2) {
          selectedReasons[questionId] = {};
          comments[questionId] = '';
        } else {
          selectedReasons.remove(questionId);
          comments.remove(questionId);
        }
      }
    });
  }

  String? _validateFeedback() {
    final globalLang = OPLocalizationService.currentLanguage;

    // First check: At least one question must be answered
    if (feedbackValues.isEmpty) {
      return 'Please answer at least one question before proceeding';
    }

    // Check all question sets
    for (final set in _questionSets) {
      for (final q in set.questions) {
        final currentVal = feedbackValues[q.id];

        // If poor (2) or worst (1) is selected, check if at least one sub-category is selected
        if (currentVal == 1 || currentVal == 2) {
          final reasons = selectedReasons[q.id] ?? {};
          final hasSelection = reasons.values.any((selected) => selected);

          if (!hasSelection) {
            final questionText =
                apiText(q.question, q.questionk, q.questionm, globalLang);
            return 'Please select at least one issue for "$questionText"';
          }

          // Check if "Other" is selected - if so, comment is mandatory
          bool hasOtherSelected = false;
          for (final sub in q.negative) {
            if (reasons[sub.id] == true) {
              // Check if this sub-question contains "other" (case-insensitive)
              final subText = apiText(
                      sub.question, sub.questionk, sub.questionm, globalLang)
                  .toLowerCase();
              if (subText.contains('other')) {
                hasOtherSelected = true;
                break;
              }
            }
          }

          if (hasOtherSelected) {
            final comment = comments[q.id] ?? '';
            if (comment.trim().isEmpty) {
              final questionText =
                  apiText(q.question, q.questionk, q.questionm, globalLang);
              return 'Please provide a comment for "Other" option in "$questionText"';
            }
          }
        }
      }
    }
    return null; // No validation errors
  }

  void _showAlert(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: efeedorBrandGreen.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.info_outline,
                      color: Colors.orange, size: 34),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Feedback Required',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 14, color: Colors.black87, height: 1.3),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 10),
                        foregroundColor: Colors.white,
                        backgroundColor: efeedorBrandGreen,
                        shape: const StadiumBorder(),
                      ),
                      child: const Text('OK'),
                    )
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildEmojiWithLabel(
      String emoji, int value, String questionId, String label) {
    bool selected = feedbackValues[questionId] == value;

    return GestureDetector(
      onTap: () => setFeedback(value, questionId),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? efeedorBrandGreen.withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? efeedorBrandGreen : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: selected ? 1.0 : 0.5,
              child: AnimatedScale(
                scale: selected ? 1.15 : 1.0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutBack,
                child: Text(emoji, style: const TextStyle(fontSize: 32)),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? efeedorBrandGreen : Colors.black87,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppHeaderWrapper(
      title: "Feedback Form",
      showLogo: false,
      showLanguageSelector: true,
      child: Column(
        children: [
          Expanded(
            child: _isReloading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                    itemCount:
                        _questionSets.length + 1, // +1 for welcome message
                    itemBuilder: (context, i) {
                      // Added Welcome Message Block (DO NOT MODIFY ANY OTHER LOGIC)
                      if (i == 0) {
                        final patientName = widget.feedbackData.name.isNotEmpty
                            ? widget.feedbackData.name
                            : 'Guest';
                        return Container(
                          margin: const EdgeInsets.only(bottom: 24),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9F9F9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${context.opTranslate('dear_patient')} $patientName,',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                context.opTranslate('thank_you_message'),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.normal,
                                  color: Colors.black87,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      // Original question set items (index adjusted for welcome message)
                      final set = _questionSets[i - 1];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Card(
                          elevation: 4,
                          shadowColor: Colors.black.withOpacity(0.08),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Center(
                                  child: Builder(
                                    builder: (context) {
                                      final globalLang =
                                          OPLocalizationService.currentLanguage;
                                      final displayedCategory = apiText(
                                          set.category,
                                          set.categoryk,
                                          set.categorym,
                                          globalLang);
                                      return Text(
                                        displayedCategory,
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800,
                                          color: efeedorBrandGreen,
                                          letterSpacing: 0.5,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 24),
                                ...set.questions.map((q) {
                                  final currentVal = feedbackValues[q.id];
                                  final globalLang =
                                      OPLocalizationService.currentLanguage;
                                  final displayedQuestion = apiText(q.question,
                                      q.questionk, q.questionm, globalLang);
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        displayedQuestion,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.normal,
                                          color: Colors.black87,
                                          height: 1.4,
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: buildEmojiWithLabel(
                                                '😞',
                                                1,
                                                q.id,
                                                context.opTranslate('worst')),
                                          ),
                                          Expanded(
                                            child: buildEmojiWithLabel(
                                                '😕',
                                                2,
                                                q.id,
                                                context.opTranslate('poor')),
                                          ),
                                          Expanded(
                                            child: buildEmojiWithLabel(
                                                '😐',
                                                3,
                                                q.id,
                                                context.opTranslate('average')),
                                          ),
                                          Expanded(
                                            child: buildEmojiWithLabel(
                                                '🙂',
                                                4,
                                                q.id,
                                                context.opTranslate('good')),
                                          ),
                                          Expanded(
                                            child: buildEmojiWithLabel(
                                                '😊',
                                                5,
                                                q.id,
                                                context
                                                    .opTranslate('excellent')),
                                          ),
                                        ],
                                      ),
                                      if (currentVal == 1 || currentVal == 2)
                                        Container(
                                          margin:
                                              const EdgeInsets.only(top: 24),
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: Colors.red.withOpacity(0.06),
                                            borderRadius:
                                                BorderRadius.circular(14),
                                            border: Border.all(
                                              color:
                                                  Colors.red.withOpacity(0.2),
                                              width: 1,
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.info_outline,
                                                    color: Colors.red.shade700,
                                                    size: 18,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    "Tell us what went wrong:",
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      fontSize: 15,
                                                      color:
                                                          Colors.red.shade700,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 16),
                                              ...q.negative.map((sub) {
                                                final globalLang =
                                                    OPLocalizationService
                                                        .currentLanguage;
                                                final negQuestion = apiText(
                                                    sub.question,
                                                    sub.questionk,
                                                    sub.questionm,
                                                    globalLang);
                                                return Container(
                                                  margin: const EdgeInsets.only(
                                                      bottom: 12),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                    border: Border.all(
                                                      color:
                                                          Colors.grey.shade300,
                                                    ),
                                                  ),
                                                  child: InkWell(
                                                    onTap: () {
                                                      setState(() {
                                                        selectedReasons[
                                                            q.id] ??= {};
                                                        selectedReasons[q.id]![
                                                                sub.id] =
                                                            !(selectedReasons[
                                                                        q.id]![
                                                                    sub.id] ??
                                                                false);
                                                      });
                                                    },
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                    child: Padding(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                        horizontal: 12,
                                                        vertical: 12,
                                                      ),
                                                      child: Row(
                                                        children: [
                                                          Checkbox(
                                                            value: selectedReasons[
                                                                        q.id]
                                                                    ?[sub.id] ??
                                                                false,
                                                            onChanged: (val) {
                                                              setState(() {
                                                                selectedReasons[
                                                                    q.id] ??= {};
                                                                selectedReasons[
                                                                            q.id]![
                                                                        sub.id] =
                                                                    val ??
                                                                        false;
                                                              });
                                                            },
                                                            activeColor:
                                                                efeedorBrandGreen,
                                                            materialTapTargetSize:
                                                                MaterialTapTargetSize
                                                                    .shrinkWrap,
                                                          ),
                                                          const SizedBox(
                                                              width: 8),
                                                          Expanded(
                                                            child: Text(
                                                              negQuestion,
                                                              style:
                                                                  const TextStyle(
                                                                fontSize: 14,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                                color: Colors
                                                                    .black87,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              }),
                                              const SizedBox(height: 12),
                                              Builder(
                                                builder: (context) {
                                                  // Check if "Other" is selected
                                                  final reasons =
                                                      selectedReasons[q.id] ??
                                                          {};
                                                  bool hasOtherSelected = false;
                                                  for (final sub
                                                      in q.negative) {
                                                    if (reasons[sub.id] ==
                                                        true) {
                                                      final globalLang =
                                                          OPLocalizationService
                                                              .currentLanguage;
                                                      final subText = apiText(
                                                              sub.question,
                                                              sub.questionk,
                                                              sub.questionm,
                                                              globalLang)
                                                          .toLowerCase();
                                                      if (subText
                                                          .contains('other')) {
                                                        hasOtherSelected = true;
                                                        break;
                                                      }
                                                    }
                                                  }

                                                  return TextField(
                                                    decoration: InputDecoration(
                                                      hintText: hasOtherSelected
                                                          ? 'Comment required *'
                                                          : 'Optional Comment',
                                                      hintStyle: TextStyle(
                                                        color: hasOtherSelected
                                                            ? Colors
                                                                .orange.shade700
                                                            : Colors.black
                                                                .withOpacity(
                                                                    0.35),
                                                      ),
                                                      filled: true,
                                                      fillColor: Colors.white,
                                                      border:
                                                          OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12),
                                                        borderSide: BorderSide(
                                                          color: hasOtherSelected &&
                                                                  (comments[q.id]
                                                                          ?.trim()
                                                                          .isEmpty ??
                                                                      true)
                                                              ? Colors.orange
                                                                  .shade300
                                                              : Colors.grey
                                                                  .shade300,
                                                        ),
                                                      ),
                                                      enabledBorder:
                                                          OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12),
                                                        borderSide: BorderSide(
                                                          color: hasOtherSelected &&
                                                                  (comments[q.id]
                                                                          ?.trim()
                                                                          .isEmpty ??
                                                                      true)
                                                              ? Colors.orange
                                                                  .shade300
                                                              : Colors.grey
                                                                  .shade300,
                                                        ),
                                                      ),
                                                      focusedBorder:
                                                          OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12),
                                                        borderSide: BorderSide(
                                                          color:
                                                              efeedorBrandGreen,
                                                          width: 1.8,
                                                        ),
                                                      ),
                                                      contentPadding:
                                                          const EdgeInsets
                                                              .symmetric(
                                                              horizontal: 16,
                                                              vertical: 14),
                                                    ),
                                                    onChanged: (val) {
                                                      setState(() {
                                                        comments[q.id] = val;
                                                      });
                                                    },
                                                    maxLines: 3,
                                                  );
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      if (q != set.questions.last)
                                        const SizedBox(height: 24),
                                      if (q != set.questions.last)
                                        Divider(
                                          height: 1,
                                          thickness: 1,
                                          color: Colors.grey.shade200,
                                        ),
                                      if (q != set.questions.last)
                                        const SizedBox(height: 24),
                                    ],
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
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
                    onPressed: () {
                      // Validate before proceeding
                      String? validationError = _validateFeedback();
                      if (validationError != null) {
                        _showAlert(validationError);
                        return;
                      }

                      widget.feedbackData.feedbackValues = feedbackValues;
                      widget.feedbackData.selectedReasons = selectedReasons;
                      widget.feedbackData.comments = comments;
                      widget.feedbackData.questionSets = _questionSets;

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => YourNextScreenFinal(
                            feedbackData: widget.feedbackData,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.arrow_forward, color: Colors.white),
                    label: const Text(
                      'Next',
                      style: TextStyle(
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
