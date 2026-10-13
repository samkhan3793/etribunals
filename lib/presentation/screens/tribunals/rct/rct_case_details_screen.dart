import 'dart:convert';

import 'package:etribunals/core/constants/app_colors.dart';
import 'package:etribunals/core/widgets/bookmark_icon_button.dart';
import 'package:etribunals/core/widgets/court_band.dart';
import 'package:etribunals/core/widgets/source_footer.dart';
import 'package:etribunals/data/model/bookmarked_case.dart';
import 'package:flutter/material.dart';

class RctCaseDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> json;
  final String benchCode;

  const RctCaseDetailsScreen({super.key, required this.json, required this.benchCode});

  @override
  State<RctCaseDetailsScreen> createState() => _RctCaseDetailsScreenState();
}

class _RctCaseDetailsScreenState extends State<RctCaseDetailsScreen> {
  bool _more = false;

  Map<String, dynamic> get _hit {
    final data = widget.json['data'];
    if (data is List && data.isNotEmpty && data.first is Map) {
      return Map<String, dynamic>.from(data.first as Map);
    }
    return const {};
  }

  @override
  Widget build(BuildContext context) {
    final hit = _hit;
    final filing = '${hit['filing_no'] ?? ''}';
    final caseNo = '${hit['case_no'] ?? ''}';
    final title = '${hit['case_title'] ?? ''}';
    final status = '${hit['c_status'] ?? ''}';
    final more = widget.json['more_data'];
    final extra = <MapEntry<String, String>>[];
    if (more is Map) {
      final basic = more['basic_details_full'];
      if (basic is List && basic.isNotEmpty && basic.first is Map) {
        Map<String, dynamic>.from(basic.first as Map).forEach((k, v) {
          if (v == null || '$v'.trim().isEmpty) return;
          extra.add(MapEntry(k.replaceAll('_', ' '), '$v'));
        });
      }
    }

    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(
        title: const Text('RCT case record'),
        actions: [
          BookmarkIconButton(
            caseItem: BookmarkedCase(
              id: BookmarkedCase.makeId('RCT', filing),
              tribunal: 'RCT',
              filingNo: filing,
              caseNo: caseNo,
              title: title.isEmpty ? 'RCT $filing' : title,
              nextHearing: '${hit['date_of_filing'] ?? ''}',
              savedAt: DateTime.now().millisecondsSinceEpoch,
              payloadKind: 'rct_json',
              payload: jsonEncode(widget.json),
              sourceUrl: 'https://cis.erct.gov.in/#/',
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const CourtBand(
            title: 'Railway Claims Tribunal',
            subtitle: 'Official eRCT public record',
            color: Color(0xFF8B2E2E),
            icon: Icons.train_outlined,
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
                        status.isEmpty ? 'CASE NUMBER' : status.toUpperCase(),
                        style: const TextStyle(color: Color(0xFFC4A265), fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        caseNo.isEmpty ? filing : caseNo,
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
                      _kv('Filing no.', filing),
                      _kv('Filed on', '${hit['date_of_filing'] ?? ''}'),
                      _kv('Registered', '${hit['case_registered_date'] ?? ''}'),
                      _kv('Petitioner', '${hit['pet_names'] ?? ''}'),
                      _kv('Respondent', '${hit['res_names'] ?? ''}'),
                      _kv('Pet. advocate', '${hit['pet_adv_name'] ?? ''}'),
                    ],
                  ),
                ),
                if (extra.isNotEmpty)
                  Container(
                    color: const Color(0xFFF3EEE6),
                    child: Column(
                      children: [
                        InkWell(
                          onTap: () => setState(() => _more = !_more),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            child: Row(
                              children: [
                                Text(
                                  _more ? 'Hide remaining particulars' : 'Remaining particulars',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.stampBlue),
                                ),
                                const Spacer(),
                                Icon(_more ? Icons.expand_less : Icons.expand_more, color: AppColors.stampBlue),
                              ],
                            ),
                          ),
                        ),
                        if (_more)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                            child: Column(children: extra.take(24).map((e) => _kv(e.key, e.value)).toList()),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SourceFooter(tribunal: 'RCT', officialUrl: 'https://cis.erct.gov.in/#/'),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) {
    if (v.trim().isEmpty || v == 'null') return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(k, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
          ),
          Expanded(
            child: Text(v, style: const TextStyle(fontSize: 13, height: 1.3, fontWeight: FontWeight.w700, color: AppColors.ink)),
          ),
        ],
      ),
    );
  }
}
