class Department {
  final String title;

  Department({required this.title});

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(title: json['title']);
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
    };
  }
}
