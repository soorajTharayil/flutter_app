import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:devkitflutter/config/constant.dart';

class ShareLinkSourcePage extends StatelessWidget {
  final String link;
  final String title;

  const ShareLinkSourcePage({Key? key, required this.link, required this.title})
      : super(key: key);

  void _shareViaWhatsApp(BuildContext context) async {
    final url = Uri.parse('whatsapp://send?text=$title: $link');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('WhatsApp not installed')),
      );
    }
  }

  void _shareViaGmail(BuildContext context) async {
    final url = Uri.parse('mailto:?subject=$title&body=$link');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gmail not available')),
      );
    }
  }

  void _shareViaSMS(BuildContext context) async {
    final url = Uri.parse('sms:?body=$title: $link');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('SMS not available')),
      );
    }
  }

  void _shareViaOther(BuildContext context) async {
    final url = Uri.parse('mailto:?subject=$title&body=$link');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No sharing app available')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Share Via'),
        backgroundColor: efeedorBrandGreen,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Share $title',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            _buildShareOption(
              context,
              'WhatsApp',
              Icons.message,
              Colors.green,
              () => _shareViaWhatsApp(context),
            ),
            const SizedBox(height: 20),
            _buildShareOption(
              context,
              'Gmail',
              Icons.email,
              Colors.red,
              () => _shareViaGmail(context),
            ),
            const SizedBox(height: 20),
            _buildShareOption(
              context,
              'Text Message',
              Icons.sms,
              Colors.blue,
              () => _shareViaSMS(context),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildShareOption(BuildContext context, String name, IconData icon,
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
                  name,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
