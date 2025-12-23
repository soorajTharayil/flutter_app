/// Model for ticket dashboard summary response
class TicketDashboardSummary {
  final int totalTicket;
  final int openTicket;
  final int closedTicket;

  TicketDashboardSummary({
    required this.totalTicket,
    required this.openTicket,
    required this.closedTicket,
  });

  /// Create from JSON response
  factory TicketDashboardSummary.fromJson(Map<String, dynamic> json) {
    return TicketDashboardSummary(
      totalTicket: json['totalTicket'] as int? ?? 0,
      openTicket: json['openTicket'] as int? ?? 0,
      closedTicket: json['closedTicket'] as int? ?? 0,
    );
  }

  /// Convert to JSON (if needed)
  Map<String, dynamic> toJson() {
    return {
      'totalTicket': totalTicket,
      'openTicket': openTicket,
      'closedTicket': closedTicket,
    };
  }
}

