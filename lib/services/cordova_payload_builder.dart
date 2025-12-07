import '../model/op_feedback_data_model.dart';

/// Builds flat payload structure matching Cordova exactly
/// NO nested objects, NO reasonSet/commentSet
/// Flat structure with all required fields: patientid, name, ward, contactnumber, email, remarks, comments, bedno, op10, op20, etc.
class CordovaPayloadBuilder {
  /// Build flat payload matching Cordova structure
  static Map<String, dynamic> buildFlatPayload(
    FeedbackData feedbackData,
    int npsRating,
    String suggestions,
    Map<String, bool> generalReasonsMap,
    String detractorComment,
  ) {
    // Map question ID to shortkey for ratings
    Map<String, String> questionIdToShortkey = {};
    Map<String, Map<String, String>> subQuestionInfo = {};
    
    // Build mappings
    for (final questionSet in feedbackData.questionSets) {
      for (final question in questionSet.questions) {
        if (question.shortkey.isNotEmpty) {
          questionIdToShortkey[question.id] = question.shortkey;
        }
        
        for (final subQuestion in question.negative) {
          if (subQuestion.shortkey.isNotEmpty) {
            subQuestionInfo[subQuestion.id] = {
              'shortkey': subQuestion.shortkey,
              'type': subQuestion.type,
            };
          }
        }
      }
    }

    // Build flat rating values (op10, op20, op30, etc.)
    Map<String, dynamic> ratingValues = {};
    for (final entry in feedbackData.feedbackValues.entries) {
      final questionId = entry.key;
      final ratingValue = entry.value;
      final questionShortkey = questionIdToShortkey[questionId];
      if (questionShortkey != null && questionShortkey.isNotEmpty) {
        ratingValues[questionShortkey] = ratingValue;
      }
    }

    // Build flat reason map (shortkey -> true or "")
    Map<String, dynamic> reason = {};
    for (final entry in feedbackData.feedbackValues.entries) {
      final questionId = entry.key;
      final ratingValue = entry.value;
      
      if (ratingValue == 1 || ratingValue == 2) {
        final selectedReasonsForQuestion = feedbackData.selectedReasons[questionId] ?? {};
        
        // Get all shortkeys for this question
        for (final questionSet in feedbackData.questionSets) {
          for (final question in questionSet.questions) {
            if (question.id == questionId) {
              for (final subQuestion in question.negative) {
                final shortkey = subQuestion.shortkey;
                if (shortkey.isNotEmpty) {
                  // Check if this reason was selected
                  bool isSelected = selectedReasonsForQuestion[subQuestion.id] == true;
                  reason[shortkey] = isSelected ? true : "";
                }
              }
              break;
            }
          }
        }
      }
    }

    // Build flat comment string (combine all comments)
    String comments = '';
    for (final entry in feedbackData.comments.entries) {
      final comment = entry.value.trim();
      if (comment.isNotEmpty) {
        if (comments.isNotEmpty) {
          comments += ' | ';
        }
        comments += comment;
      }
    }

    // Calculate overallScore
    double overallScore = 0.0;
    if (ratingValues.isNotEmpty) {
      final ratingList = ratingValues.values.map((v) => v as int).toList();
      final sum = ratingList.reduce((a, b) => a + b);
      overallScore = sum / ratingList.length;
      overallScore = double.parse(overallScore.toStringAsFixed(2));
    }

    // Build FLAT payload matching Cordova exactly
    final payload = <String, dynamic>{
      // Required patient fields (matching Cordova)
      'patientid': feedbackData.uhid,
      'name': feedbackData.name,
      'ward': feedbackData.department,
      'contactnumber': feedbackData.mobileNumber,
      'email': '', // Required field, empty if not provided
      'remarks': suggestions.isNotEmpty ? suggestions : '', // Required field
      'comments': comments.isNotEmpty ? comments : '', // Required field
      'bedno': '', // Required field, empty for OP
      
      // Rating values (op10, op20, op30, etc.)
      ...ratingValues,
      
      // NPS rating
      'recommend1Score': npsRating / 2,
      
      // Additional fields
      'section': 'OP',
      'langsub': 'english',
      'datetime': DateTime.now().millisecondsSinceEpoch,
      'overallScore': overallScore,
      'source': 'WLink',
      'patientType': 'Out-Patient',
      'consultant_cat': 'General',
      'administratorId': 'admin001',
      'wardid': 'ward001',
      // General reasons as boolean map
      ...generalReasonsMap,
      'suggestions': suggestions,
      'detractorcomment': detractorComment,
      
      // Flat reason map (all shortkeys)
      ...reason,
    };

    return payload;
  }
}

