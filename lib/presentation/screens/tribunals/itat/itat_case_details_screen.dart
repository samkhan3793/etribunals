import 'dart:convert';

import 'package:etribunals/core/constants/app_colors.dart';
import 'package:etribunals/core/utils/itat_client.dart';
import 'package:etribunals/core/widgets/bookmark_icon_button.dart';
import 'package:etribunals/core/widgets/court_band.dart';
import 'package:etribunals/core/widgets/in_app_document_screen.dart';
import 'package:etribunals/core/widgets/source_footer.dart';
import 'package:etribunals/data/model/bookmarked_case.dart';
import 'package:flutter/material.dart';

class ItatCaseDetailsScreen extends StatelessWidget {
  final ItatCaseRecord record;

  const ItatCaseDetailsScreen({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    final fields = Map<String, String>.from(record.fields)..remove('_id')..remove('PDF');
    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(
        title: const Text('ITAT case record'),
        actions: [
          BookmarkIconButton(
            caseItem: BookmarkedCase(
              id: BookmarkedCase.makeId('ITAT', record.appealNo),
              tribunal: 'ITAT',
              filingNo: record.appealNo,
              caseNo: record.appealNo,
              title: record.title,
              nextHearing: record.nextDate,
              savedAt: DateTime.now().millisecondsSinceEpoch,
              payloadKind: 'itat_json',
              payload: jsonEncode(record.toJson()),
              sourceUrl: ItatClient.caseStatusUrl,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const CourtBand(
            title: 'Income Tax Appellate Tribunal',
            subtitle: 'Official public case record',
            color: Color(0xFF1A4A3A),
            icon: Icons.account_balance_outlined,
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: AppColors.paper,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0x3314384A)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  color: AppColors.primary,
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.status.isEmpty ? 'CASE' : record.status.toUpperCase(),
                        style: const TextStyle(color: Color(0xFFC4A265), fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1),
                      ),
                      const SizedBox(height: 4),
                      Text(record.appealNo, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
                      if (record.title != record.appealNo)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(record.title, style: TextStyle(color: Colors.white.withValues(alpha: 0.92), fontSize: 12.5, height: 1.35)),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                  child: Column(
                    children: [
                      for (final e in fields.entries)
                        if (e.value.trim().isNotEmpty) _kv(e.key, e.value),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (record.hearings.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('Hearings', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            const SizedBox(height: 8),
            ...record.hearings.map(
              (row) => Card(
                color: AppColors.paper,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final e in row.entries.where((e) => e.key != 'PDF' && e.value.trim().isNotEmpty))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text('${e.key}: ${e.value}', style: const TextStyle(height: 1.35)),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
          if (record.documents.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('Orders / documents', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            const SizedBox(height: 8),
            ...record.documents.map(
              (doc) => Card(
                color: AppColors.paper,
                child: ListTile(
                  leading: const Icon(Icons.picture_as_pdf_outlined, color: AppColors.accent),
                  title: Text(doc.title.isEmpty ? 'Open document' : doc.title),
                  subtitle: Text([if (doc.extra.isNotEmpty) doc.extra, doc.date].where((e) => e.isNotEmpty).join(' · ')),
                  onTap: () => InAppDocumentScreen.open(context, doc.url, title: doc.title.isEmpty ? 'ITAT document' : doc.title),
                ),
              ),
            ),
          ],
          const SourceFooter(tribunal: 'ITAT', officialUrl: ItatClient.caseStatusUrl, showOfficialLink: false),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 130, child: Text(k, style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5))),
          Expanded(child: Text(v, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
        ],
      ),
    );
  }
}
