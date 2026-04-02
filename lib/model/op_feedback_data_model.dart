// lib/models/feedback_data.dart
import '../model/op_question_model.dart';

class FeedbackData {
  String name;
  String uhid;
  String department;
  String mobileNumber;
  /// sagarjnrwc OP: Primary Consultant from `department.php` → `ward[].bedno`.
  String primaryConsultant;

  Map<String, int> feedbackValues;
  Map<String, Map<String, bool>> selectedReasons;
  Map<String, String> comments;
  List<QuestionSet> questionSets;

  bool isTermsAccepted;

  FeedbackData({
    this.name = '',
    this.uhid = '',
    this.department = '',
    this.mobileNumber = '',
    this.primaryConsultant = '',
    this.feedbackValues = const {},
    this.selectedReasons = const {},
    this.comments = const {},
    this.questionSets = const [],
    this.isTermsAccepted = false,
  });
}
