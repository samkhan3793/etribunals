import 'package:html/parser.dart' as html_parser;

String absoluteUrl(String href, {String host = 'https://nclt.gov.in'}) {
  final value = href.trim();
  if (value.isEmpty) return value;
  if (value.startsWith('http://') || value.startsWith('https://')) return value;
  if (value.startsWith('//')) return 'https:$value';
  if (value.startsWith('/')) return '$host$value';
  return '$host/$value';
}

List<Map<String, String>> parseDrupalListingTable(String html, {String host = 'https://nclt.gov.in'}) {
  final document = html_parser.parse(html);
  final table = document.querySelector('table');
  if (table == null) return [];

  var headers = table.querySelectorAll('thead tr th').map((e) => e.text.trim()).where((e) => e.isNotEmpty).toList();
  if (headers.isEmpty) {
    headers = table.querySelectorAll('tr').first.querySelectorAll('th,td').map((e) => e.text.trim()).toList();
  }
  final rows = table.querySelectorAll('tbody tr');
  final sourceRows = rows.isNotEmpty ? rows : table.querySelectorAll('tr').skip(headers.isEmpty ? 0 : 1);

  final data = <Map<String, String>>[];
  for (final row in sourceRows) {
    final cells = row.querySelectorAll('td');
    if (cells.isEmpty) continue;
    final rowData = <String, String>{};
    for (var i = 0; i < cells.length; i++) {
      final header = i < headers.length && headers[i].isNotEmpty ? headers[i] : 'Column ${i + 1}';
      final cell = cells[i];
      final anchor = cell.querySelector('a');
      if (anchor != null && (anchor.attributes['href'] ?? '').isNotEmpty) {
        rowData[header] = absoluteUrl(anchor.attributes['href']!, host: host);
        rowData['${header}_label'] = anchor.text.trim().isEmpty ? 'Open' : anchor.text.trim();
      } else {
        rowData[header] = cell.text.trim();
      }
    }
    if (rowData.values.any((v) => v.isNotEmpty)) data.add(rowData);
  }
  return data;
}

Map<String, String> parseSelectOptions(String html, String name) {
  final document = html_parser.parse(html);
  final options = document.querySelectorAll('select[name="$name"] option');
  final map = <String, String>{};
  for (final option in options) {
    final value = option.attributes['value'] ?? '';
    final label = option.text.trim();
    if (value.isEmpty || value.toLowerCase() == 'all') continue;
    map[value] = label;
  }
  return map;
}

List<Map<String, dynamic>> parseHtmlDataTable(
  String html, {
  String host = 'https://nclat.nic.in',
}) {
  final document = html_parser.parse(html);
  final table = document.querySelector('table');
  if (table == null) return [];

  var headers = table
      .querySelectorAll('thead tr th')
      .map((e) => e.text.trim())
      .where((e) => e.isNotEmpty)
      .toList();
  if (headers.isEmpty) {
    headers = table.querySelector('tr')?.querySelectorAll('th').map((e) => e.text.trim()).toList() ?? [];
  }
  final rows = table.querySelectorAll('tbody tr');
  final sourceRows = rows.isNotEmpty ? rows : table.querySelectorAll('tr').skip(1);

  final data = <Map<String, dynamic>>[];
  for (final row in sourceRows) {
    final cells = row.querySelectorAll('td');
    if (cells.isEmpty) continue;
    final rowData = <String, dynamic>{};
    for (var i = 0; i < cells.length; i++) {
      final header = i < headers.length && headers[i].isNotEmpty ? headers[i] : 'Column ${i + 1}';
      final cell = cells[i];
      final anchor = cell.querySelector('a');
      final href = anchor?.attributes['href'];
      if (href != null && href.isNotEmpty) {
        rowData[header] = {
          'label': anchor!.text.trim().isEmpty ? 'View' : anchor.text.trim(),
          'url': absoluteUrl(href, host: host),
        };
      } else {
        rowData[header] = cell.text.trim();
      }
    }
    data.add(rowData);
  }
  return data;
}
