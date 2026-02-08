import 'package:flutter/material.dart';
import '../model/op_question_model.dart';
import '../model/ip_feedback_data_model.dart';
import '../config/constant.dart';
import '../widgets/app_header_wrapper.dart';
import '../services/op_localization_service.dart';
import '../services/ip_data_loader.dart';
import '../services/op_app_localizations.dart';
import 'ip_discharge_nps_page.dart';

class IPDischargeEmojiPage extends StatefulWidget {
  final IPFeedbackData feedbackData;
  final String language;

  IPDischargeEmojiPage({
    Key? key,
    required this.feedbackData,
    this.language = 'lang1',
  }) : super(key: key);

  @override
  _IPDischargeEmojiPageState createState() => _IPDischargeEmojiPageState();
}

class _IPDischargeEmojiPageState extends State<IPDischargeEmojiPage> {
  Map<String, int> feedbackValues = {};
  Map<String, Map<String, bool>> selectedReasons = {};
  Map<String, String> comments = {};
  List<QuestionSet> _questionSets = [];
  bool _isReloading = false;
  bool _isLoading = true;
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _questionKeys = {};

  @override
  void initState() {
    super.initState();
    _loadQuestionSets();
    // Listen to language changes
    OPLocalizationService.instance.addListener(_onLanguageChanged);
  }

  @override
  void dispose() {
    OPLocalizationService.instance.removeListener(_onLanguageChanged);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadQuestionSets() async {
    try {
      print(
          'Loading question sets for mobile: ${widget.feedbackData.mobileNumber}');

      // ONLY use cached data - never make API calls from this page
      // This ensures full offline support
      List<QuestionSet> cachedQuestionSets =
          await IPDataLoader.getCachedQuestionSets(
              widget.feedbackData.mobileNumber);

      print('Loaded ${cachedQuestionSets.length} question sets');

      if (mounted) {
        setState(() {
          _questionSets = cachedQuestionSets;
          _isLoading = false;
        });

        // If no cached data available, show helpful message
        if (cachedQuestionSets.isEmpty) {
          print(
              'No cached question sets found for mobile: ${widget.feedbackData.mobileNumber}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.opTranslate('failed_to_load')),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 4),
            ),
          );
        } else {
          // Log the categories found
          for (var set in cachedQuestionSets) {
            print(
                'Category: ${set.category} with ${set.questions.length} questions');
          }
        }
      }
    } catch (e) {
      print('Error loading question sets: $e');
      // Ensure loading state is cleared
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onLanguageChanged() async {
    if (mounted && !_isReloading) {
      setState(() {
        _isReloading = true;
      });

      try {
        // Reload from cache only (no API calls for offline support)
        final cachedQuestionSets = await IPDataLoader.getCachedQuestionSets(
          widget.feedbackData.mobileNumber,
        );

        if (mounted) {
          setState(() {
            _questionSets = cachedQuestionSets;
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
  /// Uses fields from ward.php output
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

  void _scrollToQuestion(String questionId) {
    final key = _questionKeys[questionId];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        alignment: 0.1, // Scroll to show question near top
      );
    }
  }

  Map<String, dynamic>? _validateFeedback() {
    final globalLang = OPLocalizationService.currentLanguage;

    // First check: At least one question must be answered
    if (feedbackValues.isEmpty) {
      return {'message': 'Please answer at least one question before proceeding', 'questionId': null};
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
            return {'message': 'Please select at least one issue for "$questionText"', 'questionId': q.id};
          }

        // Check if "Other" is selected - if so, comment is mandatory
        bool hasOtherSelected = false;
        for (final sub in q.negative) {
          if (reasons[sub.id] == true) {
            // Use the English source text so detection works in all languages
            final subText = sub.question.toLowerCase();
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
              return {'message': 'Please provide a comment for "Other" option in "$questionText"', 'questionId': q.id};
            }
          }
        }
      }
    }
    return null; // No validation errors
  }

  void _showAlert(String message, String? questionId) {
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
                      onPressed: () {
                        Navigator.pop(context);
                        // Scroll to the problematic question after alert is dismissed
                        if (questionId != null && _questionKeys.containsKey(questionId)) {
                          _scrollToQuestion(questionId);
                        }
                      },
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
      title: "",
      showLogo: false,
      showLanguageSelector: true,
      showHomeButton: true,
      showBackButton: false,
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _isReloading || _isLoading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : _questionSets.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Text(
                              context.opTranslate('failed_to_load'),
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                          itemCount: _questionSets.length +
                              2, // +2 for heading and welcome message
                          itemBuilder: (context, i) {
                            // Page Heading
                            if (i == 0) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Align(
                                  alignment: Alignment.center,
                                  child: Text(
                                    context.opTranslate(
                                        'ip_discharge_feedback_form'),
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.teal, // Teal-green
                                    ),
                                  ),
                                ),
                              );
                            }
                            // Added Welcome Message Block (DO NOT MODIFY ANY OTHER LOGIC)
                            if (i == 1) {
                              final patientName =
                                  widget.feedbackData.name.isNotEmpty
                                      ? widget.feedbackData.name
                                      : 'Guest';
                              return Container(
                                margin: const EdgeInsets.only(bottom: 0),
                                padding: const EdgeInsets.only(
                                    left: 16, right: 16, top: 12, bottom: 16),
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
                                    const SizedBox(height: 6),
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

                            // Original question set items (index adjusted for heading and welcome message)
                            final set = _questionSets[i - 2];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 20),
                              child: Card(
                                elevation: 4,
                                shadowColor: Colors.black.withOpacity(0.08),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20)),
                                child: Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(20, 20, 20, 20),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Center(
                                        child: Builder(
                                          builder: (context) {
                                            final globalLang =
                                                OPLocalizationService
                                                    .currentLanguage;
                                            final displayedCategory = apiText(
                                                set.category,
                                                set.categoryk,
                                                set.categorym,
                                                globalLang);
                                            return Text(
                                              displayedCategory,
                                              style: TextStyle(
                                                fontSize: 20,
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
                                        // Create GlobalKey for each question if not exists
                                        if (!_questionKeys.containsKey(q.id)) {
                                          _questionKeys[q.id] = GlobalKey();
                                        }
                                        final currentVal = feedbackValues[q.id];
                                        final globalLang = OPLocalizationService
                                            .currentLanguage;
                                        final displayedQuestion = apiText(
                                            q.question,
                                            q.questionk,
                                            q.questionm,
                                            globalLang);
                                        return Column(
                                          key: _questionKeys[q.id],
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              displayedQuestion,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                height: 1.4,
                                              ),
                                            ),
                                            const SizedBox(height: 20),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: buildEmojiWithLabel(
                                                      '😞',
                                                      1,
                                                      q.id,
                                                      context.opTranslate(
                                                          'worst')),
                                                ),
                                                Expanded(
                                                  child: buildEmojiWithLabel(
                                                      '😕',
                                                      2,
                                                      q.id,
                                                      context
                                                          .opTranslate('poor')),
                                                ),
                                                Expanded(
                                                  child: buildEmojiWithLabel(
                                                      '😐',
                                                      3,
                                                      q.id,
                                                      context.opTranslate(
                                                          'average')),
                                                ),
                                                Expanded(
                                                  child: buildEmojiWithLabel(
                                                      '🙂',
                                                      4,
                                                      q.id,
                                                      context
                                                          .opTranslate('good')),
                                                ),
                                                Expanded(
                                                  child: buildEmojiWithLabel(
                                                      '😊',
                                                      5,
                                                      q.id,
                                                      context.opTranslate(
                                                          'excellent')),
                                                ),
                                              ],
                                            ),
                                            if (currentVal == 1 ||
                                                currentVal == 2)
                                              Container(
                                                margin: const EdgeInsets.only(
                                                    top: 24),
                                                padding:
                                                    const EdgeInsets.all(16),
                                                decoration: BoxDecoration(
                                                  color: Colors.red
                                                      .withOpacity(0.06),
                                                  borderRadius:
                                                      BorderRadius.circular(14),
                                                  border: Border.all(
                                                    color: Colors.red
                                                        .withOpacity(0.2),
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
                                                          color: Colors
                                                              .red.shade700,
                                                          size: 18,
                                                        ),
                                                        const SizedBox(
                                                            width: 6),
                                                        Text(
                                                          "Tell us what went wrong:",
                                                          style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            fontSize: 15,
                                                            color: Colors
                                                                .red.shade700,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 16),
                                                    ...q.negative.map((sub) {
                                                      final globalLang =
                                                          OPLocalizationService
                                                              .currentLanguage;
                                                      final negQuestion =
                                                          apiText(
                                                              sub.question,
                                                              sub.questionk,
                                                              sub.questionm,
                                                              globalLang);
                                                      return Container(
                                                        margin: const EdgeInsets
                                                            .only(bottom: 12),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Colors.white,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(10),
                                                          border: Border.all(
                                                            color: Colors
                                                                .grey.shade300,
                                                          ),
                                                        ),
                                                        child: InkWell(
                                                          onTap: () {
                                                            setState(() {
                                                              selectedReasons[
                                                                  q.id] ??= {};
                                                              selectedReasons[
                                                                  q
                                                                      .id]![sub
                                                                  .id] = !(selectedReasons[
                                                                          q.id]![
                                                                      sub.id] ??
                                                                  false);
                                                            });
                                                          },
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(10),
                                                          child: Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                              horizontal: 12,
                                                              vertical: 12,
                                                            ),
                                                            child: Row(
                                                              children: [
                                                                Checkbox(
                                                                  value: selectedReasons[
                                                                              q.id]
                                                                          ?[
                                                                          sub.id] ??
                                                                      false,
                                                                  onChanged:
                                                                      (val) {
                                                                    setState(
                                                                        () {
                                                                      selectedReasons[
                                                                          q.id] ??= {};
                                                                      selectedReasons[
                                                                              q.id]![
                                                                          sub
                                                                              .id] = val ??
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
                                                                      fontSize:
                                                                          14,
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
                                                            selectedReasons[
                                                                    q.id] ??
                                                                {};
                                                        bool hasOtherSelected =
                                                            false;
                                                        for (final sub
                                                            in q.negative) {
                                                          if (reasons[sub.id] ==
                                                              true) {
                                                            // Use the English source text so detection works in all languages
                                                            final subText = sub
                                                                .question
                                                                .toLowerCase();
                                                            if (subText
                                                                .contains(
                                                                    'other')) {
                                                              hasOtherSelected =
                                                                  true;
                                                              break;
                                                            }
                                                          }
                                                        }

                                                        return TextField(
                                                          decoration:
                                                              InputDecoration(
                                                            hintText: hasOtherSelected
                                                                ? 'Comment required *'
                                                                : 'Please describe',
                                                            hintStyle:
                                                                TextStyle(
                                                              color: hasOtherSelected
                                                                  ? Colors
                                                                      .orange
                                                                      .shade700
                                                                  : Colors.black
                                                                      .withOpacity(
                                                                          0.35),
                                                            ),
                                                            filled: true,
                                                            fillColor:
                                                                Colors.white,
                                                            border:
                                                                OutlineInputBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          12),
                                                              borderSide:
                                                                  BorderSide(
                                                                color: hasOtherSelected &&
                                                                        (comments[q.id]?.trim().isEmpty ??
                                                                            true)
                                                                    ? Colors
                                                                        .orange
                                                                        .shade300
                                                                    : Colors
                                                                        .grey
                                                                        .shade300,
                                                              ),
                                                            ),
                                                            enabledBorder:
                                                                OutlineInputBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          12),
                                                              borderSide:
                                                                  BorderSide(
                                                                color: hasOtherSelected &&
                                                                        (comments[q.id]?.trim().isEmpty ??
                                                                            true)
                                                                    ? Colors
                                                                        .orange
                                                                        .shade300
                                                                    : Colors
                                                                        .grey
                                                                        .shade300,
                                                              ),
                                                            ),
                                                            focusedBorder:
                                                                OutlineInputBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          12),
                                                              borderSide:
                                                                  BorderSide(
                                                                color:
                                                                    efeedorBrandGreen,
                                                                width: 1.8,
                                                              ),
                                                            ),
                                                            contentPadding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                                    horizontal:
                                                                        16,
                                                                    vertical:
                                                                        14),
                                                          ),
                                                          onChanged: (val) {
                                                            setState(() {
                                                              comments[q.id] =
                                                                  val;
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
                        // Validate before proceeding
                        Map<String, dynamic>? validationResult = _validateFeedback();
                        if (validationResult != null) {
                          _showAlert(validationResult['message'], validationResult['questionId']);
                          return;
                        }

                        widget.feedbackData.feedbackValues = feedbackValues;
                        widget.feedbackData.selectedReasons = selectedReasons;
                        widget.feedbackData.comments = comments;
                        widget.feedbackData.questionSets = _questionSets;

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => IPDischargeNpsPage(
                              feedbackData: widget.feedbackData,
                            ),
                          ),
                        );
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
}
