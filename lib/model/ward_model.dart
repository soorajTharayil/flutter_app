class Ward {
  final String title;
  final String titlek;
  final String titlem;
  final String id;
  final List<String> bedno;

  Ward({
    required this.title,
    required this.id,
    this.titlek = '',
    this.titlem = '',
    this.bedno = const [],
  });

  factory Ward.fromJson(Map<String, dynamic> json) {
    // Handle bedno as array of strings or array of objects
    List<String> bedList = [];
    if (json['bedno'] != null) {
      if (json['bedno'] is List) {
        bedList = (json['bedno'] as List).map((e) {
          if (e is Map) {
            return e['title']?.toString() ?? e['bedno']?.toString() ?? e.toString();
          }
          return e.toString();
        }).toList();
      }
    }

    return Ward(
      title: json['title'] ?? json['name'] ?? '',
      titlek: json['titlek'] ?? '',
      titlem: json['titlem'] ?? '',
      id: json['id']?.toString() ?? json['title'] ?? '',
      bedno: bedList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'titlek': titlek,
      'titlem': titlem,
      'id': id,
      'bedno': bedno,
    };
  }
}

class bed_no {
  final String title;
  final String id;
  final String? wardId;

  bed_no({required this.title, required this.id, this.wardId});

  factory bed_no.fromJson(Map<String, dynamic> json) {
    return bed_no(
      title: json['title'] ?? json['name'] ?? json['bedno'] ?? '',
      id: json['id']?.toString() ?? json['title'] ?? '',
      wardId: json['wardid']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'id': id,
      'wardid': wardId,
    };
  }
}

