import 'package:flutter/material.dart';
import '../widgets/app_header_wrapper.dart';

/// Placeholder page for ticket action
/// Details will be added later
class TicketActionPage extends StatelessWidget {
  final String ticketId;
  final String module;
  final String status;

  const TicketActionPage({
    Key? key,
    required this.ticketId,
    required this.module,
    required this.status,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppHeaderWrapper(
      title: 'Ticket Action',
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.info_outline,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 20),
              const Text(
                'Ticket action page – details will be added later',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Ticket ID', ticketId),
                    const SizedBox(height: 8),
                    _buildInfoRow('Module', module),
                    const SizedBox(height: 8),
                    _buildInfoRow('Status', status),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            '$label:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}

