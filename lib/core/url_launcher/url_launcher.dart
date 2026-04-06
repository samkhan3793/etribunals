import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> launchUrlWithScheme(String url) async {
  final Uri uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } else {
    print("Error launching URL: $url");
  }
}
Future<void> launchFileUrl(String url) async {
  final uri = Uri.parse("https://efiling.nclat.gov.in/nclat/$url");
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

Future<void> showRedirectAlert(BuildContext context, String url) async {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text("External Link Warning"),
        content: const Text("You are about to leave the app and open an external website. Do you want to continue?"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close the dialog
            },
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close the dialog
              await openExternalUrl(url);
            },
            child: const Text("Proceed"),
          ),
        ],
      );
    },
  );
}

Future<void> openExternalUrl(String url) async {
  final Uri uri = Uri.parse(url);
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    throw 'Could not launch $url';
  }
}