import 'dart:convert';

import 'package:etribunals/core/constants/app_colors.dart';
import 'package:etribunals/core/utils/drt_client.dart';
import 'package:etribunals/core/widgets/bookmark_icon_button.dart';
import 'package:etribunals/core/widgets/court_band.dart';
import 'package:etribunals/core/widgets/in_app_document_screen.dart';
import 'package:etribunals/core/widgets/source_footer.dart';
import 'package:etribunals/data/model/bookmarked_case.dart';
import 'package:flutter/material.dart';

class DrtCaseDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> record;
  final String locationName;

  const DrtCaseDetailsScreen({super.key, required this.record, required this.locationName});

  String _s(String key) => '${record[key] ?? ''}'.trim();

  @override
  Widget build(BuildContext context) {
    final diary = _s('diaryno');
    final caseNo = '${_s('casetype')} ${_s('caseno')}/${_s('caseyear')}'.trim();
    final title = '${_s('petitionerName')} vs ${_s('respondentName')}'.trim();
    final hearings = record['caseProceedingDetails'];
    final ias = record['iaDetails'];

    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(
        title: const Text('DRT case record'),
        actions: [
          BookmarkIconButton(
            caseItem: BookmarkedCase(
              id: BookmarkedCase.makeId('DRT', diary.isEmpty ? caseNo : diary),
              tribunal: 'DRT',
              filingNo: diary,
              caseNo: caseNo,
              title: title.isEmpty ? 'DRT $diary' : title,
              nextHearing: _s('nextlistingdate'),
              savedAt: DateTime.now().millisecondsSinceEpoch,
              payloadKind: 'drt_json',
              payload: jsonEncode({'record': record, 'location': locationName}),
              sourceUrl: DrtClient.site,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CourtBand(
            title: locationName,
            subtitle: 'Official DRT / DRAT public record',
            color: const Color(0xFF1A4A6B),
            icon: Icons.account_balance,
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
                        caseNo.trim().isEmpty ? 'Diary $diary' : caseNo,
                        style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800),
                      ),
                      if (title.isNotEmpty)
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
                      _kv('Diary no.', '$diary / ${_s('diaryyear')}'),
                      _kv('Filed on', _s('dateoffiling')),
                      _kv('Disposed', _s('dateofdisposal')),
                      _kv('Nature', _s('disposalNature')),
                      _kv('Next listing', _s('nextlistingdate')),
                      _kv('Purpose', _s('nextListingPurpose')),
                      _kv('Petitioner', _s('petitionerName')),
                      _kv('Respondent', _s('respondentName')),
                      _kv('Pet. advocate', _s('advocatePetName')),
                      _kv('Res. advocate', _s('advocateResName')),
                      _kv('Court', '${_s('courtName')} ${_s('courtNo')}'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (hearings is List && hearings.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text('Proceedings', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink)),
            const SizedBox(height: 8),
            ...hearings.whereType<Map>().map((row) {
              final map = Map<String, dynamic>.from(row);
              final url = '${map['orderUrl'] ?? ''}'.trim();
              return Card(
                color: AppColors.paper,
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(color: Color(0x3314384A)),
                ),
                child: ListTile(
                  title: Text('${map['causelistdate'] ?? ''}  ·  ${map['purpose'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  subtitle: Text('${map['courtName'] ?? ''} ${map['courtNo'] ?? ''}'),
                  trailing: url.isEmpty ? null : const Icon(Icons.picture_as_pdf_outlined),
                  onTap: url.isEmpty ? null : () => InAppDocumentScreen.open(context, url, title: 'Order'),
                ),
              );
            }),
          ],
          if (ias is List && ias.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text('IAs', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink)),
            ...ias.whereType<Map>().map((row) {
              final map = Map<String, dynamic>.from(row);
              return ListTile(
                dense: true,
                title: Text('IA ${map['iano'] ?? ''}'),
                subtitle: Text('Filed ${map['iadateoffiling'] ?? ''}'),
              );
            }),
          ],
          const SourceFooter(tribunal: 'DRT', officialUrl: DrtClient.site),
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
          SizedBox(width: 118, child: Text(k, style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5, fontWeight: FontWeight.w700))),
          Expanded(child: Text(v, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w600, height: 1.3))),
        ],
      ),
    );
  }
}
