// lib/models/feedback_data.dart

class FeedbackData {
  String name;
  String uhid;
  String department;
  String mobileNumber;

  Map<String, int> feedbackValues;
  Map<String, Map<String, bool>> selectedReasons;
  Map<String, String> comments;

  bool isTermsAccepted;

  FeedbackData({
    this.name = '',
    this.uhid = '',
    this.department = '',
    this.mobileNumber = '',
    this.feedbackValues = const {},
    this.selectedReasons = const {},
    this.comments = const {},
    this.isTermsAccepted = false,
  });
}
