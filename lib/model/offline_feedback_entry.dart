class OfflineFeedbackEntry {
  final String id;
  final Map<String, dynamic> payload;
  final int createdAt;

  OfflineFeedbackEntry({
    required this.id,
    required this.payload,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'payload': payload,
      'createdAt': createdAt,
    };
  }

  factory OfflineFeedbackEntry.fromJson(Map<String, dynamic> json) {
    return OfflineFeedbackEntry(
      id: json['id'] as String,
      payload: json['payload'] as Map<String, dynamic>,
      createdAt: json['createdAt'] as int,
    );
  }
}

