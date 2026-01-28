// lib/models/ip_feedback_data.dart
import '../model/op_question_model.dart';

class IPFeedbackData {
  String name;
  String uhid;
  String mobileNumber;
  String ward;
  String bed_no;

  Map<String, int> feedbackValues;
  Map<String, Map<String, bool>> selectedReasons;
  Map<String, String> comments;
  List<QuestionSet> questionSets;

  bool isTermsAccepted;

  IPFeedbackData({
    this.name = '',
    this.uhid = '',
    this.mobileNumber = '',
    this.ward = '',
    this.bed_no = '',
    this.feedbackValues = const {},
    this.selectedReasons = const {},
    this.comments = const {},
    this.questionSets = const [],
    this.isTermsAccepted = false,
  });
}

