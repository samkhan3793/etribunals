import 'dart:convert';
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

class ItatDoc {
  final String title;
  final String date;
  final String url;
  final String extra;

  const ItatDoc({required this.title, this.date = '', required this.url, this.extra = ''});
}

class ItatCaseRecord {
  final Map<String, String> fields;
  final List<Map<String, String>> hearings;
  final List<ItatDoc> documents;

  const ItatCaseRecord({
    required this.fields,
    this.hearings = const [],
    this.documents = const [],
  });

  String get appealNo {
    for (final key in ['Appeal Number', 'Appeal No', 'Appeal No.', 'ITA No', 'Case No', 'Case Number']) {
      final v = fields[key]?.trim() ?? '';
      if (v.isNotEmpty) return v;
    }
    return fields.values.firstWhere((e) => e.trim().isNotEmpty, orElse: () => 'ITAT case');
  }

  String get assessee => _first(['Assessee Name', 'Assessee', 'Appellant', 'Applicant']);
  String get respondent => _first(['Respondent', 'Revenue', 'Opposite Party']);
  String get status => _first(['Status', 'Case Status', 'Present Status']);
  String get nextDate => _first(['Next Date of Hearing', 'Next Hearing', 'Next Date', 'NDOH']);
  String get title {
    if (assessee.isNotEmpty && respondent.isNotEmpty) return '$assessee vs $respondent';
    if (assessee.isNotEmpty) return assessee;
    return appealNo;
  }

  String _first(List<String> keys) {
    for (final key in keys) {
      final v = fields[key]?.trim() ?? '';
      if (v.isNotEmpty) return v;
    }
    for (final e in fields.entries) {
      for (final key in keys) {
        if (e.key.toLowerCase() == key.toLowerCase() && e.value.trim().isNotEmpty) return e.value.trim();
      }
    }
    return '';
  }

  Map<String, dynamic> toJson() => {
        'fields': fields,
        'hearings': hearings,
        'documents': documents.map((d) => {'title': d.title, 'date': d.date, 'url': d.url, 'extra': d.extra}).toList(),
      };

  factory ItatCaseRecord.fromJson(Map<String, dynamic> json) {
    final fields = <String, String>{};
    final raw = json['fields'];
    if (raw is Map) {
      raw.forEach((k, v) => fields['$k'] = '$v');
    }
    final hearings = <Map<String, String>>[];
    final h = json['hearings'];
    if (h is List) {
      for (final row in h) {
        if (row is Map) {
          hearings.add(row.map((k, v) => MapEntry('$k', '$v')));
        }
      }
    }
    final documents = <ItatDoc>[];
    final d = json['documents'];
    if (d is List) {
      for (final row in d) {
        if (row is Map) {
          documents.add(ItatDoc(
            title: '${row['title'] ?? ''}',
            date: '${row['date'] ?? ''}',
            url: '${row['url'] ?? ''}',
            extra: '${row['extra'] ?? ''}',
          ));
        }
      }
    }
    return ItatCaseRecord(fields: fields, hearings: hearings, documents: documents);
  }
}

class ItatClient {
  ItatClient._() {
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
    _dio.options.headers['User-Agent'] =
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36';
    _dio.options.headers['Accept-Language'] = 'en-US,en;q=0.9';
  }

  static final ItatClient instance = ItatClient._();
  static const site = 'https://itat.gov.in/';
  static const caseStatusUrl = 'https://itat.gov.in/judicial/casestatus';
  static const ordersUrl = 'https://itat.gov.in/judicial/tribunalorders';
  static const noticeUrl = 'https://itat.gov.in/judicial/notice_board';
  static const specialUrl = 'https://itat.gov.in/judicial/sborders';
  static const captchaUrl = 'https://itat.gov.in/captcha/show';
  static const checkCaptchaUrl = 'https://itat.gov.in/Ajax/checkCaptcha';

  final Dio _dio = Dio();
  final CookieJar _cookies = CookieJar();
  String _csrf = '';
  String _caseStatusAction = caseStatusUrl;
  String _ordersAction = ordersUrl;
  var _sessionReady = false;

  static const benches = [
    MapEntry('203', 'Agra'),
    MapEntry('205', 'Ahmedabad'),
    MapEntry('207', 'Allahabad'),
    MapEntry('209', 'Amritsar'),
    MapEntry('211', 'Bangalore'),
    MapEntry('215', 'Chandigarh'),
    MapEntry('217', 'Chennai'),
    MapEntry('219', 'Cochin'),
    MapEntry('221', 'Cuttack'),
    MapEntry('260', 'Dehradun'),
    MapEntry('201', 'Delhi'),
    MapEntry('223', 'Guwahati'),
    MapEntry('225', 'Hyderabad'),
    MapEntry('227', 'Indore'),
    MapEntry('229', 'Jabalpur'),
    MapEntry('231', 'Jaipur'),
    MapEntry('233', 'Jodhpur'),
    MapEntry('235', 'Kolkata'),
    MapEntry('237', 'Lucknow'),
    MapEntry('199', 'Mumbai'),
    MapEntry('239', 'Nagpur'),
    MapEntry('241', 'Panaji'),
    MapEntry('243', 'Patna'),
    MapEntry('245', 'Pune'),
    MapEntry('247', 'Raipur'),
    MapEntry('249', 'Rajkot'),
    MapEntry('251', 'Ranchi'),
    MapEntry('256', 'Surat'),
    MapEntry('258', 'Varanasi'),
    MapEntry('253', 'Visakhapatnam'),
  ];

  static const appealTypes = [
    MapEntry('ITA', 'Income Tax Appeal'),
    MapEntry('CO', 'Cross Objection'),
    MapEntry('ITSSA', 'Income Tax (Search & Seizure) Appeal'),
    MapEntry('ITTPA', 'Income Tax (Transfer Pricing) Appeal'),
    MapEntry('ITITA', 'Income Tax (International Taxation) Appeal'),
    MapEntry('WTA', 'Wealth Tax Appeal'),
    MapEntry('BMA', 'Black Money Appeal'),
    MapEntry('GTA', 'Gift Tax Appeal'),
    MapEntry('SA', 'Stay Application'),
    MapEntry('MA', 'Miscellaneous Application'),
  ];

  String dateLabel(DateTime d) => DateFormat('dd-MM-yyyy').format(d);

  void _captureCsrf(String html) {
    final csrf = RegExp(r'id="csrftkn1"[^>]*value="([^"]+)"').firstMatch(html)?.group(1) ??
        RegExp(r'name="csrftkn"[^>]*value="([^"]+)"').firstMatch(html)?.group(1);
    if (csrf != null && csrf.isNotEmpty) _csrf = csrf;
  }

  Options _htmlGet({required String referer}) {
    return Options(
      followRedirects: true,
      maxRedirects: 5,
      responseType: ResponseType.plain,
      headers: {
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        'Origin': 'https://itat.gov.in',
        'Referer': referer,
      },
    );
  }

  Future<String> _get(String url) async {
    final res = await _dio.get<String>(url, options: _htmlGet(referer: site));
    final html = res.data ?? '';
    _captureCsrf(html);
    if (url.contains('casestatus')) _caseStatusAction = res.realUri.toString();
    if (url.contains('tribunalorders')) _ordersAction = res.realUri.toString();
    return html;
  }

  Future<String> _postForm(String url, Map<String, String> body, {bool ajax = false}) async {
    final res = await _dio.post<dynamic>(
      url,
      data: body,
      options: Options(
        followRedirects: false,
        contentType: Headers.formUrlEncodedContentType,
        responseType: ajax ? ResponseType.plain : ResponseType.plain,
        headers: {
          'Accept': ajax ? 'application/json, text/javascript, */*; q=0.01' : 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
          'Origin': 'https://itat.gov.in',
          'Referer': ajax ? caseStatusUrl : url,
          'X-CSRF-TOKEN': _csrf,
          if (ajax) 'X-Requested-With': 'XMLHttpRequest',
        },
      ),
    );
    final code = res.statusCode ?? 0;
    if (!ajax && code >= 300 && code < 400) {
      final loc = res.headers.value('location');
      if (loc != null && loc.isNotEmpty) {
        final next = res.realUri.resolve(loc);
        final getRes = await _dio.get<String>(next.toString(), options: _htmlGet(referer: url));
        final html = getRes.data ?? '';
        _captureCsrf(html);
        if (_hasResultMarkup(html)) return html;
        final retry = await _dio.post<dynamic>(
          next.toString(),
          data: body,
          options: Options(
            followRedirects: false,
            contentType: Headers.formUrlEncodedContentType,
            responseType: ResponseType.plain,
            headers: {
              'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
              'Origin': 'https://itat.gov.in',
              'Referer': url,
              'X-CSRF-TOKEN': _csrf,
            },
          ),
        );
        final retryHtml = '${retry.data ?? ''}';
        _captureCsrf(retryHtml);
        return retryHtml;
      }
    }
    final html = '${res.data ?? ''}';
    _captureCsrf(html);
    return html;
  }

  bool _hasResultMarkup(String html) {
    final lower = html.toLowerCase();
    return lower.contains('<table') ||
        lower.contains('id="results"') ||
        lower.contains('assessee') && lower.contains('appeal');
  }

  Future<void> _ensureSession() async {
    await _get(caseStatusUrl);
    _sessionReady = true;
  }

  Future<Uint8List> loadCaptcha() async {
    if (!_sessionReady || _csrf.isEmpty) {
      await _ensureSession();
    }
    final res = await _dio.get<List<int>>(
      captchaUrl,
      options: Options(
        followRedirects: true,
        responseType: ResponseType.bytes,
        headers: {
          'Accept': 'image/avif,image/webp,image/apng,image/*,*/*;q=0.8',
          'Referer': _caseStatusAction,
        },
      ),
    );
    final bytes = Uint8List.fromList(res.data ?? const []);
    if (bytes.length < 80 || _looksLikeHtml(bytes)) {
      _sessionReady = false;
      throw Exception('Could not load ITAT captcha. Tap the image to refresh.');
    }
    return bytes;
  }

  bool _looksLikeHtml(Uint8List bytes) {
    final head = utf8.decode(bytes.take(80).toList(), allowMalformed: true).trimLeft().toLowerCase();
    return head.startsWith('<!doctype') || head.startsWith('<html');
  }

  Future<void> _checkCaptcha(String captcha) async {
    final code = captcha.trim();
    if (!RegExp(r'^[a-zA-Z0-9]{6}$').hasMatch(code)) {
      throw Exception('Captcha must be 6 letters or numbers, same as the image.');
    }
    try {
      final raw = await _postForm(checkCaptchaUrl, {'captcha': code}, ajax: true);
      final json = jsonDecode(raw);
      if (json is Map && '${json['rslt']}'.toLowerCase() == 'true') return;
      throw Exception('Captcha did not match. Tap the image and search again.');
    } catch (e) {
      if ('$e'.contains('Captcha did not match') || '$e'.contains('Captcha must be')) rethrow;
    }
  }

  Map<String, String> _form({
    required String n,
    required String benchId,
    required String appealType,
    required String captcha,
  }) {
    return {
      'hp': '',
      'csrftkn': _csrf,
      'c$n': captcha.trim(),
      'bench_name_$n': benchId,
      'app_type_$n': appealType,
      'bt$n': 'true',
    };
  }

  Future<List<ItatCaseRecord>> searchCaseStatus({
    required String mode,
    required String benchId,
    required String appealType,
    required String captcha,
    String appealNo = '',
    String year = '',
    String filingDate = '',
    String assessee = '',
    String ack = '',
  }) async {
    final n = switch (mode) {
      'date' => '2',
      'assessee' => '3',
      'ack' => '4',
      _ => '1',
    };
    await _checkCaptcha(captcha);
    final body = _form(n: n, benchId: benchId, appealType: appealType, captcha: captcha);
    if (n == '1') {
      body['app_number'] = appealNo.trim();
      body['app_year_1'] = year;
    } else if (n == '2') {
      body['filed_on'] = filingDate;
    } else if (n == '3') {
      body['assessee_name'] = assessee.trim();
    } else {
      body['ack_number'] = ack.trim();
    }
    final html = await _postForm(_caseStatusAction, body);
    var records = await _recordsFromHtml(html);
    if (records.isEmpty) {
      throw Exception(_emptySearchMessage(html));
    }
    return records;
  }

  Future<List<ItatCaseRecord>> searchTribunalOrders({
    required String mode,
    required String benchId,
    required String appealType,
    required String captcha,
    String appealNo = '',
    String year = '',
    String orderDate = '',
    String member = '',
  }) async {
    await _checkCaptcha(captcha);
    final body = _form(n: '1', benchId: benchId, appealType: appealType, captcha: captcha);
    if (mode == 'appeal') {
      body['app_number'] = appealNo.trim();
      body['app_year_1'] = year;
    } else if (mode == 'date') {
      body['order_date'] = orderDate;
      body['filed_on'] = orderDate;
    } else {
      body['member_name'] = member.trim();
    }
    final html = await _postForm(_ordersAction, body);
    if (html.toLowerCase().contains('page or resoucre not found') || html.toLowerCase().contains('does not exist')) {
      throw Exception('ITAT Tribunal Orders page is not available on itat.gov.in right now.');
    }
    var records = await _recordsFromHtml(html);
    if (records.isEmpty) {
      final docs = parsePdfListing(html);
      if (docs.isNotEmpty) {
        return docs
            .map(
              (d) => ItatCaseRecord(
                fields: {'Title': d.title, 'Date': d.date, if (d.extra.isNotEmpty) 'Detail': d.extra},
                documents: [d],
              ),
            )
            .toList();
      }
      throw Exception('No tribunal orders found.');
    }
    return records;
  }

  Future<List<ItatDoc>> noticeBoard() async {
    final html = await _get(noticeUrl);
    final docs = parsePdfListing(html);
    if (docs.isEmpty) throw Exception('Could not load ITAT notice board.');
    return docs;
  }

  Future<List<ItatDoc>> specialBenchOrders() async {
    final html = await _get(specialUrl);
    final docs = parsePdfListing(html);
    if (docs.isEmpty) throw Exception('Could not load special bench orders.');
    return docs;
  }

  Future<List<ItatCaseRecord>> _recordsFromHtml(String html) async {
    var records = _parseCaseRecords(html);
    if (records.length == 1) {
      records = [await _enrichRecord(records.first)];
    }
    return records;
  }

  Future<ItatCaseRecord> _enrichRecord(ItatCaseRecord record) async {
    final id = record.fields['_id'] ?? '';
    if (id.isEmpty) return record;
    const endpoints = [
      'https://itat.gov.in/Ajax/getcasedetails',
      'https://itat.gov.in/Ajax/getCaseDetails',
      'https://itat.gov.in/Ajax/casedetails',
      'https://itat.gov.in/judicial/getcasedetails',
    ];
    for (final url in endpoints) {
      try {
        final html = await _postForm(url, {
          'id': id,
          'case_id': id,
          'cn': id,
          'csrftkn': _csrf,
        }, ajax: true);
        if (html.length < 80 || html.toLowerCase().contains('select bench')) continue;
        final extra = _parseCaseRecords(html);
        if (extra.isEmpty) continue;
        final merged = Map<String, String>.from(record.fields)..addAll(extra.first.fields)..remove('_id');
        return ItatCaseRecord(
          fields: merged,
          hearings: extra.first.hearings.isNotEmpty ? extra.first.hearings : record.hearings,
          documents: [...record.documents, ...extra.first.documents],
        );
      } catch (_) {}
    }
    record.fields.remove('_id');
    return record;
  }

  String _emptySearchMessage(String html) {
    final stripped = html.replaceAll(RegExp(r'<script[^>]*>[\s\S]*?</script>', caseSensitive: false), '').toLowerCase();
    if (stripped.contains('please enter valid captcha') || stripped.contains('invalid captcha')) {
      return 'Captcha did not match. Tap the image and search again.';
    }
    if (RegExp(r'no\s+(record|result|case)\s+(found|available)').hasMatch(stripped)) {
      return 'No ITAT case found. Check bench, appeal number and filing year.';
    }
    if (html.contains('id="f1"') && !RegExp(r'<tbody', caseSensitive: false).hasMatch(html) && !RegExp(r'<table', caseSensitive: false).hasMatch(html)) {
      return 'ITAT returned the search form instead of records. Refresh captcha and confirm filing year, then search.';
    }
    return 'No ITAT case found. Check bench, appeal number and filing year.';
  }

  List<ItatCaseRecord> _parseCaseRecords(String html) {
    final document = html_parser.parse(html);
    final candidates = <Element>[
      if (document.querySelector('#results') != null) document.querySelector('#results')!,
      if (document.querySelector('#result') != null) document.querySelector('#result')!,
      if (document.querySelector('#example') != null) document.querySelector('#example')!,
      if (document.body != null) document.body!,
    ];
    for (final scope in candidates) {
      final records = _parseScope(scope);
      if (records.isNotEmpty) return records;
    }
    return _parseLabeledHtml(html);
  }

  List<ItatCaseRecord> _parseLabeledHtml(String html) {
    final text = html_parser.parse(html).body?.text.replaceAll(RegExp(r'\s+'), ' ') ?? '';
    final map = <String, String>{};
    final re = RegExp(
      r'(Appeal Number|Appeal No\.?|Diary No\.?|Assessee Name|Assessee|Respondent|Date of Filing|Filed On|Status|Case Status|Next Date of Hearing|Next Date|Last Date of Hearing|PAN)\s*[:\-]\s*([A-Za-z0-9][^:]{1,80}?)(?=\s+(?:Appeal Number|Appeal No|Diary No|Assessee|Respondent|Date of Filing|Status|Next Date|Last Date|PAN)\b|$)',
      caseSensitive: false,
    );
    for (final m in re.allMatches(text)) {
      map[m.group(1)!.trim()] = m.group(2)!.trim();
    }
    if (map.length >= 2) return [ItatCaseRecord(fields: map)];
    return [];
  }

  List<ItatCaseRecord> _parseScope(Element scope) {
    final documents = parsePdfListing(scope.outerHtml);
    final tables = scope.querySelectorAll('table').where((t) => !_isSearchChrome(t)).toList();
    if (tables.isEmpty && scope.localName == 'table' && !_isSearchChrome(scope)) {
      tables.add(scope);
    }
    if (tables.isEmpty) return [];

    final kvMaps = <Map<String, String>>[];
    final gridMaps = <Map<String, String>>[];
    final hearingTables = <List<Map<String, String>>>[];

    for (final table in tables) {
      if (_isKeyValueTable(table)) {
        final kv = _parseKeyValue(table);
        if (kv.isNotEmpty) kvMaps.add(kv);
      } else {
        final rows = _parseGrid(table);
        if (rows.isEmpty) continue;
        if (_looksLikeHearings(rows.first)) {
          hearingTables.add(rows);
        } else {
          gridMaps.addAll(rows);
        }
      }
    }

    if (kvMaps.isNotEmpty) {
      final fields = <String, String>{};
      for (final kv in kvMaps) {
        fields.addAll(kv);
      }
      return [
        ItatCaseRecord(
          fields: fields..removeWhere((k, v) => v.trim().isEmpty || k == '_id' && v.isEmpty),
          hearings: hearingTables.expand((e) => e).toList(),
          documents: documents,
        ),
      ];
    }

    return gridMaps
        .map(
          (fields) => ItatCaseRecord(
            fields: fields,
            documents: [
              ...documents.where((d) => fields.values.any((v) => v.contains(d.title) || d.url == fields['PDF'])),
              if ((fields['PDF'] ?? '').isNotEmpty)
                ItatDoc(title: fields['Title'] ?? 'Order', date: fields['Date'] ?? '', url: fields['PDF']!),
            ],
          ),
        )
        .toList();
  }

  bool _isSearchChrome(Element table) {
    return table.querySelector('select[name^="bench_name"], input[name="app_number"], input[name="captcha"], form#f1') != null;
  }

  bool _looksLikeHearings(Map<String, String> row) {
    final keys = row.keys.map((e) => e.toLowerCase()).join(' ');
    return keys.contains('hearing') || keys.contains('ndoh') || keys.contains('purpose') || keys.contains('bench sitting');
  }

  bool _isKeyValueTable(Element table) {
    final rows = table.querySelectorAll('tr');
    if (rows.length < 3) return false;
    var kv = 0;
    for (final row in rows) {
      final cells = row.querySelectorAll('th,td');
      if (cells.length == 2) kv++;
    }
    return kv >= 3 && kv * 2 >= rows.length;
  }

  Map<String, String> _parseKeyValue(Element table) {
    final map = <String, String>{};
    for (final row in table.querySelectorAll('tr')) {
      final cells = row.querySelectorAll('th,td');
      if (cells.length < 2) continue;
      final key = cells.first.text.replaceAll(RegExp(r'\s+'), ' ').trim();
      final value = cells[1].text.replaceAll(RegExp(r'\s+'), ' ').trim();
      if (key.isEmpty || value.isEmpty) continue;
      if (key.toLowerCase().contains('s.no') && key.length < 8) continue;
      map[key] = value;
      _absorbLinkMeta(cells[1], map);
    }
    return map;
  }

  List<Map<String, String>> _parseGrid(Element table) {
    var headers = table.querySelectorAll('thead tr th').map((e) => e.text.replaceAll(RegExp(r'\s+'), ' ').trim()).where((e) => e.isNotEmpty).toList();
    final bodyRows = table.querySelectorAll('tbody tr');
    final rows = bodyRows.isNotEmpty ? bodyRows : table.querySelectorAll('tr').skip(headers.isEmpty ? 0 : 1);
    if (headers.isEmpty) {
      final first = table.querySelector('tr');
      headers = first?.querySelectorAll('th').map((e) => e.text.replaceAll(RegExp(r'\s+'), ' ').trim()).toList() ?? [];
    }
    final out = <Map<String, String>>[];
    for (final row in rows) {
      final cells = row.querySelectorAll('td');
      if (cells.isEmpty) continue;
      final map = <String, String>{};
      for (var i = 0; i < cells.length; i++) {
        final key = i < headers.length && headers[i].isNotEmpty ? headers[i] : 'Column ${i + 1}';
        map[key] = cells[i].text.replaceAll(RegExp(r'\s+'), ' ').trim();
        _absorbLinkMeta(cells[i], map);
      }
      _absorbLinkMeta(row, map);
      final joined = map.values.join(' ').toLowerCase();
      if (joined.contains('no data') || joined.contains('no record') || joined.contains('select bench')) continue;
      if (map.values.any((v) => v.isNotEmpty)) out.add(map);
    }
    return out;
  }

  void _absorbLinkMeta(Element node, Map<String, String> map) {
    for (final a in node.querySelectorAll('a')) {
      final href = a.attributes['href'] ?? '';
      final abs = href.isEmpty || href.startsWith('#') || href.toLowerCase().startsWith('javascript')
          ? ''
          : (href.startsWith('http') ? href : Uri.parse(site).resolve(href).toString());
      if (_isPdfUrl(abs)) map['PDF'] = abs;
      for (final attr in ['data-id', 'data-cn', 'data-case', 'data-caseid']) {
        final v = a.attributes[attr] ?? '';
        if (v.isNotEmpty) map['_id'] = v;
      }
      final onclick = a.attributes['onclick'] ?? '';
      final id = RegExp(r'''['"]?(\d{3,})['"]?''').firstMatch(onclick)?.group(1);
      if (id != null) map['_id'] = id;
      final pathId = RegExp(r'/(?:view|details|casedetails)/(\d+)', caseSensitive: false).firstMatch(href)?.group(1);
      if (pathId != null) map['_id'] = pathId;
    }
  }

  bool _isPdfUrl(String url) {
    final lower = url.toLowerCase();
    return lower.contains('.pdf') || lower.contains('files/upload') || lower.contains('secure-pdf') || lower.contains('qrpdfview');
  }

  static List<ItatDoc> parsePdfListing(String html) {
    final document = html_parser.parse(html);
    final rows = document.querySelectorAll('table tr');
    final docs = <ItatDoc>[];
    for (final row in rows) {
      final cells = row.querySelectorAll('td');
      if (cells.isEmpty) continue;
      final link = row.querySelector('a[href*="files/upload"], a[href*=".pdf"]');
      if (link == null) continue;
      final href = link.attributes['href'] ?? '';
      if (href.isEmpty) continue;
      final url = href.startsWith('http') ? href : Uri.parse(site).resolve(href).toString();
      final title = cells.first.text.replaceAll(RegExp(r'\s+'), ' ').trim();
      final date = cells.length > 1 ? cells.last.text.trim() : '';
      final extra = cells.length > 2 ? cells[1].text.trim() : '';
      if (title.toLowerCase().contains('s.no') || title.toLowerCase() == 'title') continue;
      docs.add(ItatDoc(title: title.isEmpty ? link.text.trim() : title, date: date, url: url, extra: extra));
    }
    return docs;
  }
}
