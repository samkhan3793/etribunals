import 'package:etribunals/data/model/bookmarked_case.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

String caseShareText(BookmarkedCase item) {
  final caseNo = item.caseNo.trim().isNotEmpty ? item.caseNo.trim() : item.filingNo.trim();
  final lines = <String>[
    '${item.tribunal} matter',
    if (caseNo.isNotEmpty) 'Case: $caseNo',
    if (item.title.trim().isNotEmpty) 'Parties: ${item.title.trim()}',
    if ((item.nextHearing ?? '').trim().isNotEmpty) 'Next listing: ${item.nextHearing!.trim()}',
    'Shared from eTribunals',
  ];
  return lines.join('\n');
}

Future<void> shareBookmarkedCase(BookmarkedCase item) {
  return Share.share(caseShareText(item));
}

Future<void> copyBookmarkedCase(BookmarkedCase item) {
  return Clipboard.setData(ClipboardData(text: caseShareText(item)));
}
