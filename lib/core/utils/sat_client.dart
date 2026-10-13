import 'dart:convert';
import 'dart:io';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:etribunals/core/utils/official_http.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:intl/intl.dart';

class SatBlock {
  final String title;
  final List<MapEntry<String, String>> fields;
  final List<String> headers;
  final List<List<String>> rows;
  final List<String?> links;
  const SatBlock({
    required this.title,
    this.fields = const [],
    this.headers = const [],
    this.rows = const [],
    this.links = const [],
  });
}

class SatHit {
  final String title;
  final String subtitle;
  final String? filingNo;
  final String? fileUrl;
  final Map<String, String> fields;
  const SatHit({required this.title, required this.subtitle, this.filingNo, this.fileUrl, this.fields = const {}});
}

class SatClient {
  SatClient._() {
    _dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient();
        client.badCertificateCallback = (cert, host, port) => true;
        return client;
      },
    );
    _dio.interceptors.add(CookieManager(CookieJar()));
    OfficialHttp.attachDio(_dio);
    _dio.options.validateStatus = (code) => code != null && code < 500;
    _dio.options.followRedirects = true;
    _dio.options.headers['User-Agent'] =
        'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 Chrome/124.0.0.0 Mobile Safari/537.36';
  }

  static final SatClient instance = SatClient._();
  static const host = 'https://satweb.sat.gov.in';
  static const caseStatusUrl = '$host/case-status';
  static const causeListUrl = '$host/causelist';
  static const ordersUrl = '$host/orders';

  static const appealTypes = [
    MapEntry('1', 'SEBI'),
    MapEntry('2', 'IRDAI'),
    MapEntry('3', 'PFRDA'),
  ];

  final Dio _dio = Dio();
  String? _token;

  String uiDate(DateTime d) => DateFormat('MM/dd/yyyy').format(d);

  Future<String> _get(String url) async {
    final res = await _dio.get<String>(
      url,
      options: Options(responseType: ResponseType.plain, headers: {'Accept': 'text/html,*/*', 'Referer': host}),
    );
    final html = res.data ?? '';
    _token = RegExp(r'id="security_token"[^>]*value="([^"]+)"').firstMatch(html)?.group(1) ?? _token;
    return html;
  }

  Future<String> _ajax(String path, Map<String, String> body, String referer) async {
    await _get(referer);
    final token = _token ?? '';
    final payload = {
      ...body,
      if (!body.containsKey('token') && !body.containsKey('security_token')) 'token': token,
    };
    if (payload.containsKey('token') && payload['token']!.isEmpty) payload['token'] = token;
    if (payload.containsKey('security_token') && payload['security_token']!.isEmpty) payload['security_token'] = token;
    final res = await _dio.post<String>(
      '$host/$path',
      data: payload,
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
        responseType: ResponseType.plain,
        headers: {
          'Accept': 'application/json, text/javascript, */*; q=0.01',
          'X-Requested-With': 'XMLHttpRequest',
          'Origin': host,
          'Referer': referer,
        },
      ),
    );
    final raw = res.data ?? '';
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      _token = '${map['token'] ?? _token}';
      return '${map['content'] ?? ''}';
    } catch (_) {
      return raw;
    }
  }

  Future<List<SatHit>> searchCase({
    required String mode,
    String caseType = '1',
    String caseNo = '',
    String year = '',
    String alNo = '',
    String party = '',
  }) async {
    if (mode == 'al') {
      return _hits(await _ajax('get-al-status', {
        'bench': '1',
        'al_number': alNo.trim(),
        'filing_year': year.trim(),
        'token': '',
      }, caseStatusUrl));
    }
    if (mode == 'party') {
      return _hits(await _ajax('get-partywise-status', {
        'bench': '1',
        'prty_name': party.trim(),
        'filing_year': year.trim(),
        'token': '',
      }, caseStatusUrl));
    }
    return _hits(await _ajax('get-case-status', {
      'bench': '1',
      'case_type': caseType,
      'case_no': caseNo.trim(),
      'filing_year': year.trim(),
      'token': '',
    }, caseStatusUrl));
  }

  Future<List<SatBlock>> caseHistory(String filingNo) async {
    final html = await _ajax('get-case-history', {'filing_no': filingNo, 'token': ''}, caseStatusUrl);
    return parseHistory(html);
  }

  Future<List<SatHit>> causeList(DateTime from, DateTime to) async {
    return _hits(await _ajax('get-causelist', {
      'startDate': uiDate(from),
      'endDate': uiDate(to),
      'token': '',
    }, causeListUrl));
  }

  Future<List<SatHit>> searchOrders({
    required String mode,
    String caseType = '1',
    String caseNo = '',
    String year = '',
    String alNo = '',
    String party = '',
    DateTime? from,
    DateTime? to,
  }) async {
    if (mode == 'al') {
      return _hits(await _ajax('get-orders-by-al', {
        'bench': '1',
        'al_number': alNo.trim(),
        'filing_year': year.trim(),
        'security_token': '',
      }, ordersUrl));
    }
    if (mode == 'party') {
      return _hits(await _ajax('get-orders-by-party', {
        'bench': '1',
        'prty_name': party.trim(),
        'filing_year': year.trim(),
        'security_token': '',
      }, ordersUrl));
    }
    if (mode == 'date') {
      return _hits(await _ajax('get-orders-by-date', {
        'apl_type': caseType,
        'startDate': uiDate(from ?? DateTime.now()),
        'endDate': uiDate(to ?? DateTime.now()),
        'security_token': '',
      }, ordersUrl));
    }
    return _hits(await _ajax('get-orders-by-case', {
      'bench': '1',
      'case_type': caseType,
      'case_no': caseNo.trim(),
      'filing_year': year.trim(),
      'security_token': '',
    }, ordersUrl));
  }

  Future<List<int>> orderPdf(String viewOrderUrl) async {
    final id = Uri.parse(viewOrderUrl).pathSegments.where((e) => e.isNotEmpty).last;
    final raw = await _ajax('view-order-document', {'order': id, 'security_token': ''}, ordersUrl);
    if (raw.trim().startsWith('<') || raw.toLowerCase().contains('not valid')) {
      throw Exception('SAT order PDF did not load.');
    }
    return base64Decode(raw.replaceAll(RegExp(r'\s'), ''));
  }

  Future<String> causeListHtml(String url) async {
    await _get(causeListUrl);
    return _get(url);
  }

  List<SatHit> _hits(String html) {
    if (html.toLowerCase().contains('no records found') && !html.contains('<tbody')) return const [];
    final document = html_parser.parse(html);
    final out = <SatHit>[];
    for (final table in document.querySelectorAll('table')) {
      final rows = _directRows(table);
      var headers = <String>[];
      for (final row in rows) {
        final ths = row.querySelectorAll('th').map(_cell).where((e) => e.isNotEmpty).toList();
        if (ths.isNotEmpty) {
          headers = ths;
          continue;
        }
        final tds = row.querySelectorAll('td');
        if (tds.isEmpty) continue;
        final cells = tds.map(_cell).toList();
        if (cells.every((e) => e.isEmpty)) continue;
        final fields = <String, String>{};
        for (var i = 0; i < cells.length; i++) {
          final key = i < headers.length ? headers[i] : 'Col ${i + 1}';
          if (cells[i].isNotEmpty) fields[key] = cells[i];
        }
        String? filing;
        String? fileUrl;
        for (final a in row.querySelectorAll('a[href], a[data-id], a[data-order]')) {
          filing ??= a.attributes['data-id'];
          final href = a.attributes['href'] ?? '';
          if (href.contains('/view-order/') || href.contains('/view-causelist/')) {
            fileUrl = href.startsWith('http') ? href : Uri.parse(host).resolve(href).toString();
          }
        }
        if (html.contains('No records found') && cells.length < 2) continue;
        var title = fields['Appeal No'] ??
            fields['Date'] ??
            fields['AL No.'] ??
            fields['ALNo.'] ??
            (cells.length > 1 ? cells[1] : cells.first);
        if (title.trim().toLowerCase() == 'view' || title.trim().toLowerCase() == 'view cause list') {
          title = [
            fields['Date'] ?? '',
            if ((fields['Court No.'] ?? '').isNotEmpty) 'Court ${fields['Court No.']}',
          ].where((e) => e.trim().isNotEmpty).join('  ·  ');
        }
        final subtitle = [
          if ((fields['Petitioner Vs. Respondent'] ?? fields['Appellate vs Respondent'] ?? '').isNotEmpty)
            fields['Petitioner Vs. Respondent'] ?? fields['Appellate vs Respondent']!,
          if ((fields['Status'] ?? '').isNotEmpty) fields['Status']!,
          if ((fields['Order Date'] ?? '').isNotEmpty) fields['Order Date']!,
          if ((fields['Court No.'] ?? '').isNotEmpty) 'Court ${fields['Court No.']}',
          if ((fields['Date'] ?? '').isNotEmpty && !(title.contains(fields['Date']!))) fields['Date']!,
        ].where((e) => e.trim().isNotEmpty).join('  ·  ');
        out.add(SatHit(
          title: title.trim().isEmpty ? 'SAT record' : title.trim(),
          subtitle: subtitle,
          filingNo: filing,
          fileUrl: fileUrl,
          fields: fields,
        ));
      }
    }
    return out;
  }

  static List<SatBlock> parseHistory(String html) {
    final document = html_parser.parse(html);
    final root = document.querySelector('#case-history') ?? document.body;
    if (root == null) return const [];
    final blocks = <SatBlock>[];
    String title = 'Case history';
    for (final node in root.children) {
      if (node.localName == 'h3') {
        title = _cell(node);
        continue;
      }
      if (node.localName == 'table') {
        final rows = _directRows(node);
        var headers = <String>[];
        final data = <List<String>>[];
        final fields = <MapEntry<String, String>>[];
        final rowLinks = <String?>[];
        for (final row in rows) {
          final ths = row.querySelectorAll('th').map(_cell).toList();
          if (ths.any((e) => e.isNotEmpty)) {
            headers = ths.where((e) => e.isNotEmpty).toList();
            continue;
          }
          final cells = row.querySelectorAll('td').map(_cell).toList();
          if (cells.isEmpty) continue;
          data.add(cells);
          String? href;
          for (final a in row.querySelectorAll('a[href]')) {
            final raw = a.attributes['href'] ?? '';
            if (raw.contains('/view-order/') || raw.contains('/view-causelist/')) {
              href = raw.startsWith('http') ? raw : Uri.parse(host).resolve(raw).toString();
            }
          }
          rowLinks.add(href);
          if (headers.length == 2 && cells.length >= 2 && href == null) {
            fields.add(MapEntry(headers[0], cells[0]));
            fields.add(MapEntry(headers[1], cells[1]));
          }
        }
        blocks.add(SatBlock(title: title, fields: fields, headers: headers, rows: data, links: rowLinks));
      }
    }
    return blocks;
  }

  static String _cell(Element e) => e.text.replaceAll(RegExp(r'\s+'), ' ').trim();

  static List<Element> _directRows(Element table) {
    final out = <Element>[];
    for (final child in table.children) {
      if (child.localName == 'tr') out.add(child);
      if (child.localName == 'tbody' || child.localName == 'thead') {
        out.addAll(child.children.where((e) => e.localName == 'tr'));
      }
    }
    return out;
  }
}
