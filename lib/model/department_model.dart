class Department {
  final String title;
  /// Consultant names from `department.php` → `ward[].bedno` (e.g. sagarjnrwc OP).
  final List<String> bedno;

  Department({required this.title, this.bedno = const []});

  factory Department.fromJson(Map<String, dynamic> json) {
    final List<String> beds = [];
    if (json['bedno'] is List) {
      for (final e in json['bedno'] as List) {
        final s = e.toString().trim();
        if (s.isNotEmpty) {
          beds.add(s);
        }
      }
    }
    return Department(
      title: json['title']?.toString() ?? '',
      bedno: beds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'bedno': bedno,
    };
  }
}
