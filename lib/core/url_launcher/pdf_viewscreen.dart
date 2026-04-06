import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PdfViewScreen extends StatelessWidget {
  final String pdfUrl = 'https://efiling.nclat.gov.in/nclat/order_view.php?path=L05DTEFUX0RvY3VtZW50cy9DSVNfRG9jdW1lbnRzL2Nhc2Vkb2Mvb3JkZXJzL0RFTEhJLzIwMjUtMDEtMjIvY291cnRzLzIvZGFpbHkvMTczNzcxMDAyMDIzMTA2Mjk2NDY3OTM1OWM0YzFjMjcucGRm';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Open PDF'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            final Uri url = Uri.parse(pdfUrl);
            if (await canLaunch(url.toString())) {
              await launch(url.toString(), forceSafariVC: false, forceWebView: false);
            } else {
              print('Could not launch $url');
            }
          },
          child: Text('Open PDF'),
        ),
      ),
    );
  }
}
