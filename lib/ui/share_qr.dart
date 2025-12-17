import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:devkitflutter/config/constant.dart';

class ShareQrPage extends StatelessWidget {
  const ShareQrPage({Key? key}) : super(key: key);

  // Links for the forms - replace with actual links
  static const String ipFeedbackLink = 'https://example.com/ip-feedback';
  static const String opFeedbackLink = 'https://example.com/op-feedback';
  static const String ipConcernLink = 'https://example.com/ip-concern';

  void _showQrCode(BuildContext context, String link, String title) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('$title QR Code'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              QrImageView(
                data: link,
                version: QrVersions.auto,
                size: 200.0,
              ),
              const SizedBox(height: 16),
              Text('Scan this QR code to access the $title'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Share QR Codes'),
        backgroundColor: efeedorBrandGreen,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Share QR codes for specific forms',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            _buildQrCard(
              context,
              'IP Feedback QR Code',
              Icons.feedback,
              Colors.blue,
              () => _showQrCode(context, ipFeedbackLink, 'IP Feedback Form'),
            ),
            const SizedBox(height: 20),
            _buildQrCard(
              context,
              'OP Feedback QR Code',
              Icons.people_alt,
              Colors.green,
              () => _showQrCode(context, opFeedbackLink, 'OP Feedback Form'),
            ),
            const SizedBox(height: 20),
            _buildQrCard(
              context,
              'IP Complaint/Request',
              Icons.warning_amber_rounded,
              Colors.orange,
              () => _showQrCode(
                  context, ipConcernLink, 'IP Concern/Request Form'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQrCard(BuildContext context, String title, IconData icon,
      Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 30),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
              const Icon(Icons.qr_code, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
