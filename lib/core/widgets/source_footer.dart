import 'package:etribunals/core/constants/app_colors.dart';
import 'package:etribunals/core/widgets/in_app_document_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SourceFooter extends StatelessWidget {
  final String tribunal;
  final String officialUrl;
  final DateTime? fetchedAt;
  final bool showOfficialLink;

  const SourceFooter({
    super.key,
    required this.tribunal,
    required this.officialUrl,
    this.fetchedAt,
    this.showOfficialLink = true,
  });

  @override
  Widget build(BuildContext context) {
    final when = DateFormat('dd MMM yyyy, h:mm a').format(fetchedAt ?? DateTime.now());
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Public data from $tribunal  •  as of $when',
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          if (showOfficialLink)
            TextButton.icon(
              onPressed: () => InAppDocumentScreen.open(
                context,
                officialUrl,
                title: '$tribunal official site',
              ),
              icon: const Icon(Icons.public, size: 18),
              label: const Text('View on official website'),
            ),
        ],
      ),
    );
  }
}
