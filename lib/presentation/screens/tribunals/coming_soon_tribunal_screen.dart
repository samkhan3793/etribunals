import 'package:etribunals/core/constants/app_colors.dart';
import 'package:etribunals/core/widgets/court_band.dart';
import 'package:etribunals/core/widgets/in_app_document_screen.dart';
import 'package:flutter/material.dart';

class ComingSoonTribunalScreen extends StatelessWidget {
  final String name;
  final String fullName;
  final String officialUrl;

  const ComingSoonTribunalScreen({
    super.key,
    required this.name,
    required this.fullName,
    required this.officialUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CourtBand(
            title: name,
            subtitle: fullName,
            icon: Icons.hourglass_top_rounded,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.outline),
            ),
            child: const Text(
              'In-app case status, cause list and orders for this tribunal are not wired yet. Use the official website until then.',
              style: TextStyle(color: AppColors.textPrimary, height: 1.45, fontSize: 14.5),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => InAppDocumentScreen.open(
              context,
              officialUrl,
              title: '$name official site',
            ),
            icon: const Icon(Icons.public),
            label: const Text('Open official website'),
          ),
        ],
      ),
    );
  }
}
