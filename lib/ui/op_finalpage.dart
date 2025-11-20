// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../model/op_feedback_data_model.dart';
import 'op_thankyoupage.dart';
import '../config/constant.dart';

Future<String> getDomainFromPrefs() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('domain') ?? '';
}

class YourNextScreenFinal extends StatefulWidget {
  final FeedbackData feedbackData;

  const YourNextScreenFinal({Key? key, required this.feedbackData})
      : super(key: key);

  @override
  _YourNextScreenFinalState createState() => _YourNextScreenFinalState();
}

class _YourNextScreenFinalState extends State<YourNextScreenFinal> {
  int rating = 0;
  List<bool> selectedReasons = List.generate(8, (_) => false);
  TextEditingController suggestionController = TextEditingController();

  final List<String> generalReasons = [
    'Location/Proximity',
    'Specific services offered',
    'Referred by doctor',
    'Friend/Family recommendation',
    'Previous experience',
    'Insurance facilities',
    'Company recommendation',
    'Print/Online media',
  ];

  @override
  void dispose() {
    suggestionController.dispose();
    super.dispose();
  }

  Color getColor(int value) {
    if (value <= 6) return Colors.red.shade400;
    if (value <= 7) return Colors.orange.shade400;
    return Colors.green.shade400;
  }

  @override
  Widget build(BuildContext context) {
    final feedbackData = widget.feedbackData;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Feedback'),
        backgroundColor: efeedorBrandGreen,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // SECTION 1: NPS RATING
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
                              'Net Promoter Score (NPS)',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: efeedorBrandGreen,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'On a scale from 0-10, how likely are you to recommend this hospital to your friends or family?',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.black87,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 24),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: List.generate(11, (index) {
                                  final isSelected = rating == index;
                                  return Padding(
                                    padding: EdgeInsets.only(
                                      right: index < 10 ? 8 : 0,
                                    ),
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          rating = index;
                                        });
                                      },
                                      child: Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? getColor(index)
                                              : Colors.grey.shade300,
                                          borderRadius: BorderRadius.circular(12),
                                          border: isSelected
                                              ? Border.all(
                                                  color: getColor(index),
                                                  width: 2.5,
                                                )
                                              : Border.all(
                                                  color: Colors.grey.shade400,
                                                  width: 1,
                                                ),
                                          boxShadow: isSelected
                                              ? [
                                                  BoxShadow(
                                                    color: getColor(index)
                                                        .withOpacity(0.3),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 4),
                                                  )
                                                ]
                                              : null,
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          '$index',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 16,
                                            color: isSelected
                                                ? Colors.white
                                                : Colors.black87,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'NOT AT ALL LIKELY',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                Text(
                                  'EXTREMELY LIKELY',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: efeedorBrandGreen.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.star,
                                    color: efeedorBrandGreen,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Selected Rating: $rating',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: efeedorBrandGreen,
                                    ),
                                  ),
                                ],
                              ),
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
                              'Your reason for selecting our hospital',
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
                              children: List.generate(
                                  generalReasons.length, (index) {
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
                    // SECTION 3: COMMENT
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
                              'Suggestions or Concerns',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: efeedorBrandGreen,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Please describe reasons for low rating or share suggestions for improvement:',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: suggestionController,
                              decoration: InputDecoration(
                                hintText: 'Enter your suggestions here',
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
                    onPressed: () async {
                      if (rating < 0 || rating > 10) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  "Please select a rating between 0 and 10")),
                        );
                        return;
                      }

                      final List<String> selectedGeneralReasons = [];
                      for (int i = 0; i < selectedReasons.length; i++) {
                        if (selectedReasons[i]) {
                          selectedGeneralReasons.add(generalReasons[i]);
                        }
                      }

                      final feedbackPayload = {
                        'recommend1Score': rating / 2,
                        'source': 'WLink',
                        'name': feedbackData.name,
                        'patientid': feedbackData.uhid,
                        'ward': feedbackData.department,
                        'contactnumber': feedbackData.mobileNumber,
                        'patientType': 'Out-Patient',
                        'consultant_cat': 'General',
                        'administratorId': 'admin001',
                        'wardid': 'ward001',
                        'reasons': selectedGeneralReasons.join(', '),
                        'suggestions': suggestionController.text,
                        'feedback': feedbackData.feedbackValues,
                        'reasonsPerQuestion': feedbackData.selectedReasons,
                        'comments': feedbackData.comments,
                      };

                      final uri = Uri.parse(
                        'https://dev.efeedor.com/api/saveoutpatientfeedback.php?patient_id=${feedbackData.uhid}&administratorId=admin001',
                      );

                      try {
                        final response = await http.post(
                          uri,
                          headers: {'Content-Type': 'application/json'},
                          body: jsonEncode(feedbackPayload),
                        );

                        final responseData = jsonDecode(response.body);
                        if (responseData['status'] == 'success') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const ThankYouScreen()),
                          );
                        } else {
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text("Feedback Already Submitted"),
                              content: const Text(
                                  "Feedback has already been submitted."),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text("OK"),
                                ),
                              ],
                            ),
                          );
                        }
                      } catch (e) {
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text("Network Error"),
                            content: const Text(
                                "Please check your internet connection."),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text("OK"),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.send, color: Colors.white),
                    label: const Text(
                      'Submit',
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
