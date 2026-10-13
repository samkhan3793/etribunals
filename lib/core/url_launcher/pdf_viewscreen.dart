import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PdfViewScreen extends StatelessWidget {
  final String pdfUrl = 'https://efiling.nclat.gov.in/nclat/order_view.php?path=L05DTEFUX0RvY3VtZW50cy9DSVNfRG9jdW1lbnRzL2Nhc2Vkb2Mvb3JkZXJzL0RFTEhJLzIwMjUtMDEtMjIvY291cnRzLzIvZGFpbHkvMTczNzcxMDAyMDIzMTA2Mjk2NDY3OTM1OWM0YzFjMjcucGRm';

  const PdfViewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Open PDF'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            final Uri url = Uri.parse(pdfUrl);
            try {
              final bool launched = await launchUrl(url, mode: LaunchMode.platformDefault);
              if (!launched) throw 'Could not launch.';
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: Could not launch PDF viewer.')),
              );
            }
          },
          child: const Text('Open PDF'),
        ),
      ),
    );
  }
}
