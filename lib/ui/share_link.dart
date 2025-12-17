import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:devkitflutter/config/constant.dart';
import 'package:devkitflutter/ui/share_link_source.dart';

class ShareLinkPage extends StatelessWidget {
  const ShareLinkPage({Key? key}) : super(key: key);

  // Links for the forms - replace with actual links
  static const String ipFeedbackLink = 'https://example.com/ip-feedback';
  static const String opFeedbackLink = 'https://example.com/op-feedback';
  static const String ipConcernLink = 'https://example.com/ip-concern';

  void _shareLink(BuildContext context, String link, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ShareLinkSourcePage(link: link, title: title),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Share Links'),
        backgroundColor: efeedorBrandGreen,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Share specific form links',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            _buildLinkCard(
              context,
              'IP Feedback Form',
              Icons.feedback,
              Colors.blue,
              () => _shareLink(context, ipFeedbackLink, 'IP Feedback Form'),
            ),
            const SizedBox(height: 20),
            _buildLinkCard(
              context,
              'OP Feedback Form',
              Icons.people_alt,
              Colors.green,
              () => _shareLink(context, opFeedbackLink, 'OP Feedback Form'),
            ),
            const SizedBox(height: 20),
            _buildLinkCard(
              context,
              'IP Concern/Request',
              Icons.warning_amber_rounded,
              Colors.orange,
              () =>
                  _shareLink(context, ipConcernLink, 'IP Concern/Request Form'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkCard(BuildContext context, String title, IconData icon,
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
              const Icon(Icons.share, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
