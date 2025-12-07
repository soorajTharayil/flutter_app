// lib/models/op_question_model.dart

class QuestionSet {
  final String category;
  final String categoryk;
  final String categorym;
  final String type;
  final List<Question> questions;

  QuestionSet({
    required this.category,
    required this.type,
    required this.questions,
    this.categoryk = '',
    this.categorym = '',
  });

  factory QuestionSet.fromJson(Map<String, dynamic> json) {
    final category = json['category'] ?? '';
    final categoryk = json['categoryk'] ?? '';
    final categorym = json['categorym'] ?? '';

    print("═══════════════════════════════════════════════════════════");
    print("API → QuestionSet Parsing");
    print("API → category: $category");
    print("API → categoryk: $categoryk");
    print("API → categorym: $categorym");
    print("═══════════════════════════════════════════════════════════");

    return QuestionSet(
      category: category,
      categoryk: categoryk,
      categorym: categorym,
      type: json['type'] ?? json['category'] ?? '',
      questions: (json['question'] as List<dynamic>)
          .map((q) => Question.fromJson(q))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'categoryk': categoryk,
      'categorym': categorym,
      'type': type,
      'question': questions.map((q) => q.toJson()).toList(),
    };
  }
}

class Question {
  final String id;
  final String title;
  final String titlek;
  final String titlem;
  final String question;
  final String questionk;
  final String questionm;
  final String shortkey;
  final List<SubQuestion> negative;

  Question({
    required this.id,
    required this.title,
    required this.question,
    required this.shortkey,
    required this.negative,
    this.titlek = '',
    this.titlem = '',
    this.questionk = '',
    this.questionm = '',
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    final id = json['id'] ?? '';
    final title = json['title'] ?? '';
    final titlek = json['titlek'] ?? '';
    final titlem = json['titlem'] ?? '';
    final question = json['question'] ?? '';
    final questionk = json['questionk'] ?? '';
    final questionm = json['questionm'] ?? '';

    print("───────────────────────────────────────────────────────────");
    print("API → Question Parsing (id: $id)");
    print("API → title: $title");
    print("API → titlek: $titlek");
    print("API → titlem: $titlem");
    print("API → question: $question");
    print("API → questionk: $questionk");
    print("API → questionm: $questionm");

    final negativeList = (json['negative'] as List<dynamic>?)
            ?.map((neg) => SubQuestion.fromJson(neg))
            .toList() ??
        [];

    print("API → negative[] count: ${negativeList.length}");
    print("───────────────────────────────────────────────────────────");

    return Question(
      id: id,
      title: title,
      titlek: titlek,
      titlem: titlem,
      question: question,
      questionk: questionk,
      questionm: questionm,
      shortkey: json['shortkey'] ?? json['short_key'] ?? '',
      negative: negativeList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'titlek': titlek,
      'titlem': titlem,
      'question': question,
      'questionk': questionk,
      'questionm': questionm,
      'shortkey': shortkey,
      'negative': negative.map((neg) => neg.toJson()).toList(),
    };
  }
}

class SubQuestion {
  final String id;
  final String title;
  final String titlek;
  final String titlem;
  final String question;
  final String questionk;
  final String questionm;
  final String shortkey;
  final String type;

  SubQuestion({
    required this.id,
    required this.question,
    required this.shortkey,
    required this.type,
    this.title = '',
    this.titlek = '',
    this.titlem = '',
    this.questionk = '',
    this.questionm = '',
  });

  factory SubQuestion.fromJson(Map<String, dynamic> json) {
    final id = json['id'] ?? '';
    final title = json['title'] ?? '';
    final titlek = json['titlek'] ?? '';
    final titlem = json['titlem'] ?? '';
    final question = json['question'] ?? json['title'] ?? '';
    final questionk = json['questionk'] ?? '';
    final questionm = json['questionm'] ?? '';

    print("  └─ API → SubQuestion (id: $id)");
    print("  └─ API → title: $title");
    print("  └─ API → titlek: $titlek");
    print("  └─ API → titlem: $titlem");
    print("  └─ API → question: $question");
    print("  └─ API → questionk: $questionk");
    print("  └─ API → questionm: $questionm");

    return SubQuestion(
      id: id,
      title: title,
      titlek: titlek,
      titlem: titlem,
      question: question,
      questionk: questionk,
      questionm: questionm,
      shortkey: json['shortkey'] ?? json['short_key'] ?? '',
      type: json['type'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'titlek': titlek,
      'titlem': titlem,
      'question': question,
      'questionk': questionk,
      'questionm': questionm,
      'shortkey': shortkey,
      'type': type,
    };
  }
}
