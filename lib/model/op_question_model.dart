// lib/models/op_question_model.dart

class QuestionSet {
  final String category;
  final List<Question> questions;

  QuestionSet({required this.category, required this.questions});

  factory QuestionSet.fromJson(Map<String, dynamic> json) {
    return QuestionSet(
      category: json['category'] ?? '',
      questions: (json['question'] as List<dynamic>)
          .map((q) => Question.fromJson(q))
          .toList(),
    );
  }
}

class Question {
  final String id;
  final String title;
  final String question;
  final List<SubQuestion> negative;

  Question({
    required this.id,
    required this.title,
    required this.question,
    required this.negative,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      question: json['question'] ?? '',
      negative: (json['negative'] as List<dynamic>?)
              ?.map((neg) => SubQuestion.fromJson(neg))
              .toList() ??
          [],
    );
  }
}

class SubQuestion {
  final String id;
  final String question;

  SubQuestion({required this.id, required this.question});

  factory SubQuestion.fromJson(Map<String, dynamic> json) {
    return SubQuestion(
      id: json['id'] ?? '',
      question: json['question'] ?? json['title'] ?? '',
    );
  }
}
