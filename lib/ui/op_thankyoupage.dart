import 'package:flutter/material.dart';
import '../services/op_localization_service.dart';

class ThankYouScreen extends StatelessWidget {
  final bool isUnhappyFeedback;

  const ThankYouScreen({
    Key? key,
    this.isUnhappyFeedback = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                // Thank you message
                const Text(
                  'Thank you for taking time out to provide the feedback.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 30),
                
                // Conditional content based on rating (Poor/Worst = unhappy)
                if (isUnhappyFeedback) ...[
                  // VERSION B: Unhappy feedback (Rating = Poor or Worst)
                  Icon(
                    Icons.check_circle,
                    size: 80,
                    color: Colors.green.shade700,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'We sincerely apologize for not meeting your expectations.\nWe would like to regain your trust.\nOur executive will get in touch with you.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                ] else ...[
                  // VERSION A: Happy feedback (Rating = Good/Very Good/Excellent/etc.)
                  const Text(
                    '😊',
                    style: TextStyle(fontSize: 80),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Kindly rate us on Google by clicking the link sent to you via SMS',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                ],
                
                const SizedBox(height: 40),
                
                // Continue to homepage button
                ElevatedButton.icon(
                  onPressed: () async {
                    // Reset language to English before going back to home
                    await OPLocalizationService.resetToEnglish();
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  icon: const Icon(Icons.home),
                  label: const Text('Continue to homepage'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                    shadowColor: Colors.transparent,
                  ),
                ),
                
                const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
