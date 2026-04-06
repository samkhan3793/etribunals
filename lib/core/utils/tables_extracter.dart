// lib/core/utils/case_details_utils.dart
import 'package:html/dom.dart' as dom;

Map<String, String> extractKeyValuePairsForCaseDetails(dom.Element card) {
  final data = <String, String>{};
  final lines = card.text
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();

  for (int i = 1; i < lines.length - 1; i += 2) {
    final key = lines[i];
    final value = lines[i + 1];
    if (key.isNotEmpty && value.isNotEmpty) {
      data[key] = value;
    }
  }

  return data;
}

Map<String, String> extractKeyValuePairs(dom.Element card) {
  final data = <String, String>{};
  final lines = card.text
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();

  for (int i = 1; i < lines.length - 1; i += 2) {
    final key = lines[i];
    final value = lines[i + 1];
    if (key.isNotEmpty && value.isNotEmpty) {
      data[key] = value;
    }
  }

  return data;
}
Map<String, List<Map<String, String>>> extractKeyValuePairsForPartyDetails(dom.Element card) {
  final data = <String, List<Map<String, String>>>{
    'applicant': [],
    'respondent': [],
  };

  final lines = card.text
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();

  final respondentStartIndex = lines.indexWhere((line) => RegExp(r'(respondent\s*name|respodent\s*name)', caseSensitive: false).hasMatch(line));

  if (respondentStartIndex != -1) {
    final applicantLines = lines.sublist(1, respondentStartIndex - 1);
    final respondentLines = lines.sublist(respondentStartIndex);

    data['applicant'] = extractParties(applicantLines, 'applicant');
    data['respondent'] = extractParties(respondentLines, 'respondent');
  } else {
    data['applicant'] = extractParties(lines, 'applicant');
  }

  return data;
}

Map<String, List<Map<String, String>>> extractKeyValuePairsForLegalRepresentativeDetails(dom.Element card) {
  final data = <String, List<Map<String, String>>>{
    'applicant': [],
    'respondent': [],
  };

  final lines = card.text
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();

  print('Extracting parties from lines: $lines');
  final respondentStartIndex = lines.indexWhere((line) => RegExp(r'(respondent\s*|respodent\s*)', caseSensitive: false).hasMatch(line));

  if (respondentStartIndex != -1) {
    final applicantLines = lines.sublist(1, respondentStartIndex - 1);
    final respondentLines = lines.sublist(respondentStartIndex);

    data['applicant'] = extractParties(applicantLines, 'applicant');
    data['respondent'] = extractParties(respondentLines, 'respondent');
  } else {
    data['applicant'] = extractParties(lines, 'applicant');
  }

  return data;
}

List<Map<String, String>> extractParties(List<String> sectionLines, String type) {
  final result = <Map<String, String>>[];

  for (int i = 0; i < sectionLines.length - 1; i++) {
    final srNo = sectionLines[i];
    final name = sectionLines[i + 1];

    if (RegExp(r'^\d+$').hasMatch(srNo)) {
      result.add({'srNo': srNo, 'name': name});
      i++;
    }
  }
  return result;
}
List<Map<String, dynamic>> extractTableList(dom.Element card) {
  final data = <Map<String, dynamic>>[];
  final rows = card.querySelectorAll('table tr');
  if (rows.isEmpty) return data;

  final headers = rows.first.querySelectorAll('th').map((e) => e.text.trim()).toList();

  for (int i = 1; i < rows.length; i++) {
    final cols = rows[i].querySelectorAll('td');
    if (cols.isEmpty) continue;

    final rowData = <String, dynamic>{};

    for (int j = 0; j < cols.length && j < headers.length; j++) {
      final cell = cols[j];
      final anchor = cell.querySelector('a');

      if (anchor != null && anchor.attributes.containsKey('href')) {
        final href = anchor.attributes['href']!.trim();
        final linkText = anchor.text.trim().isNotEmpty ? anchor.text.trim() : 'Download';
        rowData[headers[j]] = {'text': linkText, 'url': href};
      } else {
        rowData[headers[j]] = cell.text.trim();
      }
    }

    if (rowData.isNotEmpty) {
      data.add(rowData);
    }
  }

  return data;
}