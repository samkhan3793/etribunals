import 'dart:convert';

import 'package:etribunals/core/widgets/in_app_document_screen.dart';
import 'package:etribunals/data/model/bookmarked_case.dart';
import 'package:etribunals/presentation/screens/tribunals/nclat/case_tracker/case_details_screen.dart'
    as nclat;
import 'package:etribunals/presentation/screens/tribunals/nclt/case-status/nclt_case_details_screen.dart'
    as nclt;
import 'package:etribunals/core/utils/itat_client.dart';
import 'package:etribunals/core/utils/ngt_case_client.dart';
import 'package:etribunals/presentation/screens/tribunals/ngt/case-tracker/ngt_case_details_screen.dart';
import 'package:etribunals/presentation/screens/tribunals/cat/cat_case_details_screen.dart';
import 'package:etribunals/presentation/screens/tribunals/drt/drt_case_details_screen.dart';
import 'package:etribunals/presentation/screens/tribunals/rct/rct_case_details_screen.dart';
import 'package:etribunals/presentation/screens/tribunals/itat/itat_case_details_screen.dart';
import 'package:etribunals/presentation/screens/tribunals/cestat/cestat_screens.dart';
import 'package:etribunals/core/utils/cestat_client.dart';
import 'package:etribunals/presentation/screens/tribunals/tdsat/tdsat_screen.dart';
import 'package:etribunals/presentation/screens/tribunals/aptel/aptel_screen.dart';
import 'package:etribunals/presentation/screens/tribunals/sat/sat_screen.dart';
import 'package:etribunals/presentation/screens/tribunals/aft/aft_screen.dart';
import 'package:etribunals/core/utils/aft_client.dart';
import 'package:etribunals/presentation/screens/tribunals/ncdrc/ncdrc_screen.dart';
import 'package:etribunals/presentation/screens/tribunals/atfp/atfp_screen.dart';
import 'package:etribunals/presentation/screens/tribunals/cgit/cgit_screen.dart';
import 'package:etribunals/presentation/screens/tribunals/upreat/case-status/upreat_case_details_screen.dart';
import 'package:flutter/material.dart';

class FollowedCaseOpener {
  static Future<void> open(BuildContext context, BookmarkedCase item) async {
    final kind = item.payloadKind ?? '';
    if (kind == 'nclt_json' && item.hasSnapshot) {
      final map = jsonDecode(item.payload!) as Map<String, dynamic>;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => nclt.CaseDetailsScreen(map)),
      );
      return;
    }
    if (kind == 'upreat_json' && item.hasSnapshot) {
      final map = jsonDecode(item.payload!) as Map<String, dynamic>;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => UpreatCaseDetailsScreen(map)),
      );
      return;
    }
    if (kind == 'ngt_html' && item.hasSnapshot) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => NgtCaseDetailsScreen(
            hit: NgtCaseHit(
              diaryNo: item.filingNo,
              caseNo: item.caseNo,
              party: item.title,
              status: '',
              detailsUrl: item.sourceUrl ?? '',
              raw: const {},
            ),
            html: item.payload!,
          ),
        ),
      );
      return;
    }
    if (kind == 'rct_json' && item.hasSnapshot) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RctCaseDetailsScreen(
            json: jsonDecode(item.payload!) as Map<String, dynamic>,
            benchCode: '',
          ),
        ),
      );
      return;
    }
    if (kind == 'drt_json' && item.hasSnapshot) {
      final map = jsonDecode(item.payload!) as Map<String, dynamic>;
      final rec = map['record'];
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DrtCaseDetailsScreen(
            record: rec is Map ? Map<String, dynamic>.from(rec) : map,
            locationName: '${map['location'] ?? 'DRT'}',
          ),
        ),
      );
      return;
    }
    if (kind == 'cat_json' && item.hasSnapshot) {
      final map = jsonDecode(item.payload!) as Map<String, dynamic>;
      final rec = map['record'];
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CatCaseDetailsScreen(
            record: rec is Map ? Map<String, dynamic>.from(rec) : map,
            benchName: '${map['location'] ?? 'CAT'}',
          ),
        ),
      );
      return;
    }
    if (kind == 'itat_json' && item.hasSnapshot) {
      final map = jsonDecode(item.payload!) as Map<String, dynamic>;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ItatCaseDetailsScreen(record: ItatCaseRecord.fromJson(map))),
      );
      return;
    }
    if (kind == 'cestat_json' && item.hasSnapshot) {
      final map = jsonDecode(item.payload!) as Map<String, dynamic>;
      final fields = <String, String>{};
      final raw = map['fields'];
      if (raw is Map) raw.forEach((k, v) => fields['$k'] = '$v');
      final row = CestatRow(fields);
      final url = '${map['detailUrl'] ?? row.detail ?? item.sourceUrl ?? ''}';
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => url.toLowerCase().contains('casedetailreport')
              ? CestatFullRecordScreen(url: url, seed: row)
              : CestatRecordScreen(row: row, heading: '${map['heading'] ?? 'CESTAT record'}'),
        ),
      );
      return;
    }
    if (kind == 'tdsat_json' && item.hasSnapshot) {
      final map = jsonDecode(item.payload!) as Map<String, dynamic>;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TdsatRecordScreen(
            blocks: tdsatBlocksFromJson(map['blocks']),
            orders: tdsatHitsFromJson(map['orders']),
            heading: '${map['heading'] ?? 'TDSAT record'}',
            seedTitle: item.title,
          ),
        ),
      );
      return;
    }
    if (kind == 'aptel_json' && item.hasSnapshot) {
      final map = jsonDecode(item.payload!) as Map<String, dynamic>;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AptelRecordScreen(
            blocks: aptelBlocksFromJson(map['blocks']),
            files: aptelHitsFromJson(map['files']),
            heading: '${map['heading'] ?? 'APTEL record'}',
            seedTitle: item.title,
          ),
        ),
      );
      return;
    }
    if (kind == 'sat_json' && item.hasSnapshot) {
      final map = jsonDecode(item.payload!) as Map<String, dynamic>;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SatRecordScreen(
            blocks: satBlocksFromJson(map['blocks']),
            heading: '${map['heading'] ?? 'SAT record'}',
            seedTitle: item.title,
            filingNo: '${map['filingNo'] ?? item.filingNo}',
          ),
        ),
      );
      return;
    }
    if (kind == 'aft_json' && item.hasSnapshot) {
      final map = jsonDecode(item.payload!) as Map<String, dynamic>;
      final rawFields = map['fields'];
      final fields = <String, String>{
        if (rawFields is Map) for (final e in rawFields.entries) '${e.key}': '${e.value}',
      };
      final docs = <AftHit>[
        for (final d in (map['documents'] as List? ?? const []))
          if (d is Map) AftHit(title: '${d['title'] ?? 'Order'}', subtitle: '', fileUrl: d['fileUrl'] == null ? null : '${d['fileUrl']}'),
      ];
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AftRecordScreen(
            dossier: AftDossier(
              title: '${map['title'] ?? item.title}',
              subtitle: '${map['subtitle'] ?? ''}',
              fields: fields,
              documents: docs,
            ),
            blocks: aftBlocksFromJson(map['blocks']),
            heading: '${map['heading'] ?? 'AFT record'}',
            seedTitle: item.title,
          ),
        ),
      );
      return;
    }
    if (kind == 'ncdrc_json' && item.hasSnapshot) {
      final map = jsonDecode(item.payload!) as Map<String, dynamic>;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => NcdrcRecordScreen(hit: ncdrcHitFromJson(map))),
      );
      return;
    }
    if (kind == 'atfp_json' && item.hasSnapshot) {
      final map = jsonDecode(item.payload!) as Map<String, dynamic>;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AtfpRecordScreen(
            hit: atfpHitFromJson(map),
            heading: '${map['heading'] ?? 'ATFP record'}',
          ),
        ),
      );
      return;
    }
    if (kind == 'cgit_json' && item.hasSnapshot) {
      final map = jsonDecode(item.payload!) as Map<String, dynamic>;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CgitRecordScreen(hit: cgitHitFromJson(map), heading: '${map['heading'] ?? 'CGIT record'}'),
        ),
      );
      return;
    }
    if (kind == 'nclat_html' && item.hasSnapshot) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => nclat.CaseDetailsScreen(
            filingNo: item.filingNo,
            responseData: item.payload!,
            tribunal: item.tribunal,
            caseTitle: item.title,
            caseNo: item.caseNo,
          ),
        ),
      );
      return;
    }
    if (item.sourceUrl != null && item.sourceUrl!.isNotEmpty && !item.sourceUrl!.contains('itat.gov.in')) {
      await InAppDocumentScreen.open(context, item.sourceUrl!, title: item.title);
      return;
    }
    await Navigator.pushNamed(context, item.searchRoute);
  }
}
