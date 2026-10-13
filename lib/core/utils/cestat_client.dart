import 'dart:io';
import 'dart:typed_data';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:etribunals/core/utils/official_http.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:intl/intl.dart';

class CestatRow {
  final Map<String, String> fields;
  const CestatRow(this.fields);

  String get title {
    for (final k in ['Case No', 'Case Number', 'Diary No', 'Diary Number', 'Appeal No', 'Applicant Name', 'Party Name', 'Bench type', 'Bench Type', 'Title']) {
      final v = fields[k]?.trim() ?? '';
      if (v.isNotEmpty) return v;
    }
    return fields.entries
        .where((e) => e.key != 'PDF' && e.key != 'DETAIL' && !e.key.startsWith('Sr') && e.value.trim().isNotEmpty)
        .map((e) => e.value.trim())
        .firstWhere((e) => e.isNotEmpty, orElse: () => 'CESTAT record');
  }

  String? get pdf {
    final v = fields['PDF'] ?? '';
    return v.startsWith('http') ? v : null;
  }

  String? get detail {
    final v = fields['DETAIL'] ?? '';
    return v.startsWith('http') ? v : null;
  }

  bool get isCaseStatusPage => (detail ?? '').toLowerCase().contains('casedetailreport');
}

class CestatDetailBlock {
  final String title;
  final List<MapEntry<String, String>> fields;
  final List<String> headers;
  final List<List<String>> rows;

  const CestatDetailBlock({
    required this.title,
    this.fields = const [],
    this.headers = const [],
    this.rows = const [],
  });

  bool get isEmpty => fields.isEmpty && rows.isEmpty;
}

class CestatClient {
  CestatClient._() {
    _dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient();
        client.badCertificateCallback = (cert, host, port) => true;
        return client;
      },
    );
    _dio.interceptors.add(CookieManager(_cookies));
    OfficialHttp.attachDio(_dio);
    _dio.options.validateStatus = (code) => code != null && code < 500;
    _dio.options.followRedirects = false;
    _dio.options.maxRedirects = 0;
    _dio.options.headers['User-Agent'] =
        'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 Chrome/124.0.0.0 Mobile Safari/537.36';
  }

  static final CestatClient instance = CestatClient._();
  static const site = 'https://cestat.gov.in/';
  static const caseStatusUrl = 'https://cestat.gov.in/casestatus';
  static const causeListUrl = 'https://cestat.gov.in/viewcauselist';
  static const proceedingsUrl = 'https://cestat.gov.in/viewproceeding';
  static const dashboardUrl = 'https://cestat.gov.in/publicdashboard/charts';
  static const dailyOrdersUrl = 'https://cestat.gov.in/order-status';
  static const finalOrdersUrl = 'https://cestat.gov.in/final-order-status';
  static const finalSearchUrl = 'https://cestat.gov.in/final-order-status-all';
  static const dailyOrdersPost = 'https://cestat.gov.in/order-status-web';
  static const finalSearchPost = 'https://cestat.gov.in/order-status-web-all';
  static const displayUrl = 'https://cestat.gov.in/display';
  static const captchaUrl = 'https://cestat.gov.in/captcha';

  final Dio _dio = Dio();
  final CookieJar _cookies = CookieJar();
  String _csrf = '';

  static const slugBenches = [
    MapEntry('delhi', 'Delhi'),
    MapEntry('chandigarh', 'Chandigarh'),
    MapEntry('mumbai', 'Mumbai'),
    MapEntry('ahmedabad', 'Ahmedabad'),
    MapEntry('bangalore', 'Bangalore'),
    MapEntry('allahabad', 'Allahabad'),
    MapEntry('kolkata', 'Kolkata'),
    MapEntry('chennai', 'Chennai'),
    MapEntry('hyderabad', 'Hyderabad'),
  ];

  static const idBenches = [
    MapEntry('107079', 'Delhi'),
    MapEntry('127482', 'Mumbai'),
    MapEntry('104044', 'Chandigarh'),
    MapEntry('124438', 'Ahmedabad'),
    MapEntry('109120', 'Allahabad'),
    MapEntry('119315', 'Kolkata'),
    MapEntry('129525', 'Bangalore'),
    MapEntry('133568', 'Chennai'),
    MapEntry('136507', 'Hyderabad'),
  ];

  static const searchTypes = [
    MapEntry('dno', 'Diary no.'),
    MapEntry('cno', 'Case no.'),
    MapEntry('pno', 'Party name'),
    MapEntry('ino', 'O-I-A / O-I-O'),
  ];

  static const caseTypes = [
    MapEntry('1', 'Customs'),
    MapEntry('2', 'Excise'),
    MapEntry('3', 'Service tax'),
    MapEntry('4', 'Antidumping'),
    MapEntry('5', 'Central sales tax'),
  ];

  String dateLabel(DateTime d) => DateFormat('dd-MM-yyyy').format(d);

  Future<String> _get(String url) async {
    final res = await _dio.get<String>(
      url,
      options: Options(
        responseType: ResponseType.plain,
        followRedirects: true,
        headers: {'Accept': 'text/html,*/*', 'Referer': site},
      ),
    );
    final html = res.data ?? '';
    _csrfFrom(html);
    return html;
  }

  void _csrfFrom(String html) {
    final m = RegExp(r'name="csrf_token"[^>]*value="([^"]+)"').firstMatch(html) ??
        RegExp(r'value="([^"]+)"[^>]*name="csrf_token"').firstMatch(html);
    if (m != null) _csrf = m.group(1)!;
  }

  Future<String> _post(String url, Map<String, String> body, {required String referer}) async {
    final data = Map<String, String>.from(body);
    if (_csrf.isNotEmpty) data['csrf_token'] = _csrf;
    data.putIfAbsent('captcha_code', () => '111111');
    var res = await _dio.post<String>(
      url,
      data: data,
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
        responseType: ResponseType.plain,
        followRedirects: false,
        headers: {
          'Accept': 'text/html,*/*',
          'Origin': 'https://cestat.gov.in',
          'Referer': referer,
          'X-CSRF-TOKEN': _csrf,
        },
      ),
    );
    var html = res.data ?? '';
    final loc = res.headers.value('location');
    if ((res.statusCode == 301 || res.statusCode == 302 || res.statusCode == 303) && loc != null && loc.isNotEmpty) {
      res = await _dio.get<String>(
        Uri.parse(url).resolve(loc).toString(),
        options: Options(
          responseType: ResponseType.plain,
          followRedirects: false,
          headers: {'Accept': 'text/html,*/*', 'Referer': referer},
        ),
      );
      html = res.data ?? '';
    }
    _csrfFrom(html);
    return html;
  }

  Future<Uint8List> loadCaptcha() async {
    final res = await _dio.get<List<int>>(
      '$captchaUrl?rand=${DateTime.now().millisecondsSinceEpoch}',
      options: Options(responseType: ResponseType.bytes, headers: {'Accept': 'image/*', 'Referer': site}),
    );
    return Uint8List.fromList(res.data ?? const []);
  }

  Future<List<CestatRow>> searchCaseStatus({
    required String bench,
    required String type,
    required String value,
    required String year,
    String caseType = '1',
  }) async {
    await _get(caseStatusUrl);
    await _post(caseStatusUrl, {
      'schema_type': bench,
      'app_type': type,
      'captcha_code': '111111',
    }, referer: caseStatusUrl);
    final fields = <String, String>{
      'schema_type': bench,
      'app_type': type,
      'token_no': value.trim(),
      'captcha_code': '111111',
    };
    switch (type) {
      case 'cno':
        fields['case_type'] = caseType;
        fields['token_year'] = year;
        fields['button2'] = 'Search';
        break;
      case 'pno':
        fields['button3'] = 'SEARCH';
        break;
      case 'ino':
        fields['button4'] = 'SEARCH';
        break;
      default:
        fields['token_year'] = year;
        fields['button1'] = 'SEARCH';
    }
    final html = await _post(caseStatusUrl, fields, referer: caseStatusUrl);
    final err = _formError(html);
    if (err != null) throw Exception(err);
    return _rows(html);
  }

  String? _formError(String html) {
    final items = html_parser
        .parse(html)
        .querySelectorAll('.errors li')
        .map((e) => e.text.replaceAll(RegExp(r'\s+'), ' ').trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (items.isEmpty) return null;
    return items.join(' ');
  }

  Future<List<CestatRow>> searchCauseList({required String benchId, required String date}) async {
    await _get(causeListUrl);
    final html = await _post(causeListUrl, {
      'schemas': benchId,
      'from': date,
      'captcha_code': '111111',
    }, referer: causeListUrl);
    return _rows(html);
  }

  Future<List<CestatRow>> searchProceedings({required String benchId, required String date}) async {
    await _get(proceedingsUrl);
    final html = await _post(proceedingsUrl, {
      'schemas': benchId,
      'from': date,
      'captcha_code': '111111',
    }, referer: proceedingsUrl);
    return _rows(html);
  }

  Future<List<MapEntry<String, String>>> members() async {
    final html = await _get(dailyOrdersUrl);
    final block = RegExp(r'<select[^>]*name="member_name"[^>]*>([\s\S]*?)</select>', caseSensitive: false).firstMatch(html)?.group(1) ?? '';
    final out = <MapEntry<String, String>>[];
    for (final m in RegExp(r'<option[^>]*value="([^"]*)"[^>]*>([\s\S]*?)</option>', caseSensitive: false).allMatches(block)) {
      final id = m.group(1) ?? '';
      final name = m.group(2)!.replaceAll(RegExp(r'\s+'), ' ').trim();
      if (id.isEmpty) continue;
      out.add(MapEntry(id, name));
    }
    return out;
  }

  Future<List<CestatRow>> searchDailyOrders(Map<String, String> fields) async {
    await _get(dailyOrdersUrl);
    fields['s'] = 's';
    fields['captcha_code'] = '111111';
    final html = await _post(dailyOrdersPost, fields, referer: dailyOrdersUrl);
    return _rows(html);
  }

  Future<List<CestatRow>> searchFinalOrders(Map<String, String> fields) async {
    await _get(finalOrdersUrl);
    fields['s'] = 's';
    fields['order_type'] = 'F';
    fields['captcha_code'] = '111111';
    final html = await _post(dailyOrdersPost, fields, referer: finalOrdersUrl);
    return _rows(html);
  }

  Future<List<CestatRow>> searchFinalAll(Map<String, String> fields) async {
    await _get(finalSearchUrl);
    fields['s'] = 's';
    fields['order_type'] = 'F';
    fields['captcha_code'] = '111111';
    final html = await _post(finalSearchPost, fields, referer: finalSearchUrl);
    return _rows(html);
  }

  Future<List<CestatRow>> displayBoard(String benchId) async {
    final html = await _get('https://cestat.gov.in/displayboard/$benchId');
    return _rows(html);
  }

  List<CestatRow> _rows(String html) {
    final document = html_parser.parse(html);
    final preferred = document.querySelector('#example') ?? document.querySelector('#data_table');
    final tables = [
      if (preferred != null) preferred,
      ...document.querySelectorAll('table'),
    ];
    final seen = <Element>{};
    for (final table in tables) {
      if (!seen.add(table)) continue;
      if (_isChrome(table)) continue;
      final parsed = _parseGrid(table);
      if (parsed.isNotEmpty) return parsed;
    }
    return [];
  }

  bool _isChrome(Element table) {
    if (table.id == 'example' || table.id == 'data_table') return false;
    return table.querySelector('select, input[type="text"]') != null;
  }

  List<CestatRow> _parseGrid(Element table) {
    var headers = table.querySelectorAll('thead tr th').map((e) => e.text.replaceAll(RegExp(r'\s+'), ' ').trim()).where((e) => e.isNotEmpty).toList();
    final body = table.querySelectorAll('tbody tr');
    var rows = body.isNotEmpty ? body : table.querySelectorAll('tr').skip(headers.isEmpty ? 0 : 1);
    if (headers.isEmpty) {
      final withTh = table.querySelectorAll('tr').where((tr) => tr.querySelectorAll('th').isNotEmpty);
      if (withTh.isNotEmpty) {
        headers = withTh.first.querySelectorAll('th').map((e) => e.text.replaceAll(RegExp(r'\s+'), ' ').trim()).where((e) => e.isNotEmpty).toList();
      }
    }
    if (headers.isEmpty) {
      final sample = rows.map((r) => r.querySelectorAll('td').length).firstWhere((n) => n > 0, orElse: () => 0);
      if (sample == 3) headers = ['Sr. No.', 'Bench type', 'Action'];
      if (sample == 4) headers = ['Sr. No.', 'Bench type', 'Uploaded', 'Action'];
      if (sample == 5) headers = ['Applicant Name', 'Respondent Name', 'Diary No', 'Case No', 'Action'];
    }
    final out = <CestatRow>[];
    for (final row in rows) {
      final cells = row.querySelectorAll('td');
      if (cells.isEmpty) continue;
      final map = <String, String>{};
      for (var i = 0; i < cells.length; i++) {
        final key = i < headers.length && headers[i].isNotEmpty ? headers[i] : 'Column ${i + 1}';
        map[key] = cells[i].text.replaceAll(RegExp(r'\s+'), ' ').trim();
        for (final a in cells[i].querySelectorAll('a')) {
          final href = a.attributes['href'] ?? '';
          if (href.isEmpty || href.startsWith('#') || href.toLowerCase().startsWith('javascript')) continue;
          final abs = href.startsWith('http') ? href : Uri.parse(site).resolve(href).toString();
          final lower = abs.toLowerCase();
          if (lower.contains('.pdf') || lower.contains('/openfilec/')) {
            map['PDF'] = abs;
          } else {
            map['DETAIL'] = abs;
          }
        }
      }
      final joined = map.values.join(' ').toLowerCase();
      if (joined.contains('no data') || joined.contains('no record')) continue;
      if (map.values.any((v) => v.isNotEmpty)) out.add(CestatRow(map));
    }
    return out;
  }

  Future<List<CestatDetailBlock>> fetchCaseDetail(String url) async {
    final html = await _get(url);
    return parseCaseDetail(html);
  }

  static List<CestatDetailBlock> parseCaseDetail(String html) {
    final document = html_parser.parse(html);
    final root = document.querySelector('section.container') ?? document.body;
    if (root == null) return const [];
    final blocks = <CestatDetailBlock>[];
    for (final table in root.querySelectorAll('table')) {
      final block = _parseDetailTable(table);
      if (block != null && !block.isEmpty) blocks.add(block);
    }
    return blocks;
  }

  static String _clean(String raw) {
    return raw.replaceAll(RegExp(r'\s+'), ' ').replaceAll(RegExp(r'\.+$'), '').trim();
  }

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

  static CestatDetailBlock? _parseDetailTable(Element table) {
    final rows = _directRows(table);
    if (rows.isEmpty) return null;
    var title = '';
    final fields = <MapEntry<String, String>>[];
    var headers = <String>[];
    final data = <List<String>>[];
    for (final row in rows) {
      final cells = row.children.where((e) => e.localName == 'td' || e.localName == 'th').toList();
      if (cells.isEmpty) continue;
      final texts = cells.map((e) => _clean(e.text)).toList();
      if (texts.join(' ').toLowerCase().contains('print')) continue;
      final colspan = cells.first.attributes['colspan'];
      if (cells.length == 1 || (colspan != null && cells.length <= 2 && texts.where((t) => t.isNotEmpty).length == 1)) {
        final heading = texts.firstWhere((t) => t.isNotEmpty, orElse: () => '');
        if (heading.isNotEmpty && title.isEmpty) title = heading;
        continue;
      }
      if (cells.length == 2) {
        final key = texts[0];
        final value = texts[1];
        if (key.isEmpty && value.isEmpty) continue;
        fields.add(MapEntry(key.isEmpty ? 'Detail' : key, value));
        continue;
      }
      final boldLabels = cells.every((c) => c.querySelector('b') != null || c.localName == 'th');
      if (headers.isEmpty && boldLabels) {
        headers = texts;
        continue;
      }
      if (texts.any((t) => t.isNotEmpty)) data.add(texts);
    }
    if (fields.isEmpty && data.isEmpty) return null;
    return CestatDetailBlock(title: title.isEmpty ? 'Case record' : title, fields: fields, headers: headers, rows: data);
  }
}
