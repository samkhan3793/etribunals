import 'dart:convert';

import 'package:etribunals/core/constants/app_colors.dart';
import 'package:etribunals/core/utils/cat_client.dart';
import 'package:etribunals/core/widgets/bookmark_icon_button.dart';
import 'package:etribunals/core/widgets/court_band.dart';
import 'package:etribunals/core/widgets/in_app_document_screen.dart';
import 'package:etribunals/core/widgets/source_footer.dart';
import 'package:etribunals/data/model/bookmarked_case.dart';
import 'package:flutter/material.dart';

class CatCaseDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> record;
  final String benchName;

  const CatCaseDetailsScreen({super.key, required this.record, required this.benchName});

  String _s(String key) => '${record[key] ?? ''}'.trim();

  @override
  Widget build(BuildContext context) {
    final diary = _s('diaryno');
    final caseNo = _s('caseno').isEmpty ? _s('applicantno') : _s('caseno');
    final applicant = _s('applicant').isEmpty ? _s('applicantName') : _s('applicant');
    final respondent = _s('respondent').isEmpty ? _s('respondentName') : _s('respondent');
    final title = '$applicant vs $respondent'.trim();
    final pdf = CatClient.documentUrl(record);

    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(
        title: const Text('CAT case record'),
        actions: [
          BookmarkIconButton(
            caseItem: BookmarkedCase(
              id: BookmarkedCase.makeId('CAT', diary.isEmpty ? caseNo : diary),
              tribunal: 'CAT',
              filingNo: diary,
              caseNo: caseNo,
              title: title == 'vs' ? 'CAT $diary' : title,
              nextHearing: _s('nextlistingdate'),
              savedAt: DateTime.now().millisecondsSinceEpoch,
              payloadKind: 'cat_json',
              payload: jsonEncode({'record': record, 'location': benchName}),
              sourceUrl: CatClient.site,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CourtBand(
            title: benchName,
            subtitle: 'Official CAT public record',
            color: const Color(0xFF3D4A6B),
            icon: Icons.badge_rounded,
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
                        _s('casestatus').isEmpty ? 'CASE' : _s('casestatus').toUpperCase(),
                        style: const TextStyle(color: Color(0xFFC4A265), fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        caseNo.isEmpty ? 'Diary $diary' : caseNo,
                        style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800),
                      ),
                      if (title != 'vs')
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(title, style: TextStyle(color: Colors.white.withValues(alpha: 0.92), fontSize: 12.5, height: 1.35)),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                  child: Column(
                    children: [
                      _kv('Diary no.', diary),
                      _kv('Filed on', _s('dateoffiling')),
                      _kv('Disposed', _s('dateofdisposal')),
                      _kv('Nature', _s('disposalNature')),
                      _kv('Next listing', _s('nextlistingdate')),
                      _kv('Purpose', _s('nextListingPurpose')),
                      _kv('Last listing', _s('lastlistingdate')),
                      _kv('Applicant', applicant),
                      _kv('Respondent', respondent),
                      _kv('Location', _s('location')),
                      _kv('Court', '${_s('courtName')} ${_s('courtNo')}'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (pdf != null) ...[
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => InAppDocumentScreen.open(context, pdf, title: 'Order'),
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('Open order'),
            ),
          ],
          const SourceFooter(tribunal: 'CAT', officialUrl: CatClient.site),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) {
    if (v.isEmpty || v == '/') return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110, child: Text(k, style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5))),
          Expanded(child: Text(v, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
        ],
      ),
    );
  }
}
