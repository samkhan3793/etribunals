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

class AftHit {
  final String title;
  final String subtitle;
  final String? detailUrl;
  final String? fileUrl;
  final List<String> files;
  final Map<String, String> fields;
  const AftHit({
    required this.title,
    required this.subtitle,
    this.detailUrl,
    this.fileUrl,
    this.files = const [],
    this.fields = const {},
  });
}

class AftBlock {
  final String title;
  final List<MapEntry<String, String>> fields;
  final List<String> headers;
  final List<List<String>> rows;
  final List<String?> links;
  const AftBlock({
    required this.title,
    this.fields = const [],
    this.headers = const [],
    this.rows = const [],
    this.links = const [],
  });
}

class AftDossier {
  final String title;
  final String subtitle;
  final Map<String, String> fields;
  final List<AftHit> documents;
  const AftDossier({required this.title, this.subtitle = '', this.fields = const {}, this.documents = const []});
}

class AftCourt {
  final String id;
  final String name;
  const AftCourt(this.id, this.name);
}

class AftClient {
  AftClient._() {
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

  static final AftClient instance = AftClient._();
  static const host = 'https://aft.gov.in';
  static const caseNumberUrl = '$host/casestatus/casenumber';
  static const diaryUrl = '$host/casestatus/diarynumber';
  static const partyUrl = '$host/casestatus/partyname';
  static const ordersUrl = '$host/casestatus/daterange';
  static const judgementsUrl = '$host/judgements/daterange';
  static const causeListUrl = '$host/cause-list';
  static const captchaUrl = '$host/admin/captcha';

  static const caseTypes = [
    MapEntry('1', 'OA'),
    MapEntry('2', 'TA'),
    MapEntry('3', 'AT'),
    MapEntry('4', 'CA'),
    MapEntry('5', 'RA'),
    MapEntry('6', 'MA'),
    MapEntry('7', 'OA(A)'),
  ];

  final Dio _dio = Dio();

  String iso(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  Future<String> _get(String url, {Map<String, dynamic>? query, String? referer}) async {
    final res = await _dio.get<String>(
      url,
      queryParameters: query,
      options: Options(responseType: ResponseType.plain, headers: {'Accept': 'text/html,*/*', 'Referer': referer ?? host}),
    );
    return res.data ?? '';
  }

  Future<Uint8List> loadCaptcha(String pageUrl) async {
    await _get(pageUrl);
    final res = await _dio.get<List<int>>(
      '$captchaUrl?${DateTime.now().millisecondsSinceEpoch}',
      options: Options(responseType: ResponseType.bytes, headers: {'Accept': 'image/*,*/*', 'Referer': pageUrl}),
    );
    return Uint8List.fromList(res.data ?? const []);
  }

  String? lastSearchHtml;

  Future<List<AftHit>> search({
    required String pageUrl,
    required String searchPath,
    required Map<String, String> fields,
    required String captcha,
  }) async {
    final html = await _get('$host$searchPath', query: {...fields, 'captcha': captcha.trim()}, referer: pageUrl);
    lastSearchHtml = html;
    if (html.toLowerCase().contains('invalid captcha')) {
      throw Exception('Invalid captcha. Refresh the image and try again.');
    }
    final rows = _hits(html);
    if (rows.isEmpty && html.toLowerCase().contains('no record')) {
      return const [];
    }
    return rows;
  }

  Future<List<AftBlock>> caseDetails(String url) async {
    final html = await _get(url);
    return _blocks(html);
  }

  List<AftBlock> blocksFromHtml(String html) => _blocks(html);

  Future<Uint8List> fetchBytes(String url) async {
    var target = rewriteDocUrl(url);
    for (var hop = 0; hop < 3; hop++) {
      final res = await _dio.get<List<int>>(
        target,
        options: Options(
          responseType: ResponseType.bytes,
          headers: {'Accept': 'application/pdf,*/*', 'Referer': host},
        ),
      );
      final bytes = Uint8List.fromList(res.data ?? const []);
      if (bytes.length >= 5 && bytes[0] == 0x25 && bytes[1] == 0x50) return bytes;
      final html = utf8.decode(bytes, allowMalformed: true);
      final nested = RegExp(r'upload_document/(\d+\.pdf)', caseSensitive: false).firstMatch(html);
      final abs = RegExp(r'''https?://[^"'\s>]+\.pdf''', caseSensitive: false).firstMatch(html);
      if (nested != null) {
        target = rewriteDocUrl(nested.group(0)!);
        continue;
      }
      if (abs != null) {
        target = rewriteDocUrl(abs.group(0)!);
        continue;
      }
      break;
    }
    throw Exception('This AFT PDF is not available on the official file server.');
  }

  AftDossier dossierFor(AftHit hit) {
    bool actionField(String key, String value) {
      final k = key.toLowerCase();
      final v = value.trim().toLowerCase();
      return k.contains('view') ||
          k.contains('pdf') ||
          k.contains('order') && k.contains('file') ||
          v == 'view' ||
          v.contains('pdf') ||
          _looksLikeUrl(value);
    }

    final fields = <String, String>{
      for (final e in hit.fields.entries)
        if (!actionField(e.key, e.value)) e.key: e.value,
    };
    final docs = <AftHit>[];
    void addDoc(String? url, String label) {
      final text = (url ?? '').trim();
      if (text.isEmpty || text.toLowerCase() == 'view') return;
      final file = rewriteDocUrl(text);
      if (file.isEmpty || _isNav(file)) return;
      final path = Uri.tryParse(file)?.path.toLowerCase() ?? '';
      if (path == '/view' || path.endsWith('/view')) return;
      if (!_isFile(file) && !path.contains('upload') && !path.contains('pdf') && !path.contains('order') && !path.contains('judg')) return;
      if (docs.any((d) => d.fileUrl == file)) return;
      docs.add(AftHit(title: label.trim().isEmpty || label.trim().toLowerCase() == 'view' ? 'Order / judgement PDF' : label.trim(), subtitle: hit.title, fileUrl: file));
    }

    for (final f in hit.files) {
      addDoc(f, 'Order / judgement PDF');
    }
    addDoc(hit.fileUrl, 'Order / judgement PDF');
    for (final e in hit.fields.entries) {
      if (actionField(e.key, e.value)) addDoc(e.value, e.key);
    }
    final html = lastSearchHtml;
    if (html != null && html.isNotEmpty) {
      final document = html_parser.parse(html);
      final root = document.querySelector('#block-system-main') ?? document.querySelector('.region-content') ?? document.body;
      if (root != null) {
        final needle = hit.title.trim().toLowerCase();
        for (final row in root.querySelectorAll('tr')) {
          final blob = _plain(row).toLowerCase();
          if (needle.isNotEmpty && !blob.contains(needle)) continue;
          addDoc(_docFromRow(row), 'Order / judgement PDF');
          for (final a in row.querySelectorAll('a')) {
            addDoc(a.attributes['href'], _plain(a));
            addDoc(_urlFromOnclick(a.attributes['onclick'] ?? ''), 'Order / judgement PDF');
          }
        }
      }
    }
    return AftDossier(title: hit.title, subtitle: hit.subtitle, fields: fields, documents: docs);
  }

  Future<List<AftCourt>> courts(DateTime date) async {
    final res = await _dio.get<String>(
      '$host/get-courts/${iso(date)}',
      options: Options(responseType: ResponseType.plain, headers: {'Accept': 'application/json', 'Referer': causeListUrl}),
    );
    try {
      final map = jsonDecode(res.data ?? '{}');
      final list = map is Map ? map['courts'] : map;
      if (list is! List) return const [AftCourt('3', 'Court 1'), AftCourt('4', 'Court 2'), AftCourt('5', 'Court 3'), AftCourt('9', 'PR Court 4')];
      return [
        for (final c in list)
          if (c is Map) AftCourt('${c['id']}', 'Court ${c['court_name'] ?? c['id']}'),
      ];
    } catch (_) {
      return const [AftCourt('3', 'Court 1'), AftCourt('4', 'Court 2'), AftCourt('5', 'Court 3'), AftCourt('9', 'PR Court 4')];
    }
  }

  String causeListPdf(DateTime date, String courtId, [String benchId = '']) {
    return '$host/daily-cause-pdf/${iso(date)}/${Uri.encodeComponent(courtId)}/${Uri.encodeComponent(benchId)}';
  }

  List<AftHit> _hits(String html) {
    final document = html_parser.parse(html);
    final root = document.querySelector('#block-system-main') ??
        document.querySelector('.region-content') ??
        document.querySelector('main') ??
        document.body;
    final out = <AftHit>[];
    if (root == null) return out;
    for (final table in root.querySelectorAll('table')) {
      final rows = _directRows(table);
      var headers = <String>[];
      for (final row in rows) {
        final ths = row.querySelectorAll('th').map(_plain).where((e) => e.isNotEmpty).toList();
        if (ths.isNotEmpty) {
          headers = ths;
          continue;
        }
        final tds = row.querySelectorAll('td');
        if (tds.length < 2) continue;
        final cells = tds.map(_plain).toList();
        final fields = <String, String>{};
        for (var i = 0; i < cells.length; i++) {
          final key = i < headers.length ? headers[i] : 'Col ${i + 1}';
          final value = cells[i];
          if (value.isEmpty) continue;
          if (value.startsWith('http') || value.contains('upload_document')) continue;
          fields[key] = value;
        }
        final files = <String>[];
        void takeFile(String? raw) {
          final text = (raw ?? '').trim();
          if (text.isEmpty || text.toLowerCase() == 'view' || text == '#') return;
          final href = rewriteDocUrl(text);
          if (href.isEmpty || _isNav(href)) return;
          final path = Uri.tryParse(href)?.path.toLowerCase() ?? '';
          if (path == '/view' || path.endsWith('/view')) return;
          if (!files.contains(href)) files.add(href);
        }
        String? fileUrl = _docFromRow(row);
        takeFile(fileUrl);
        String? detailUrl;
        for (final a in row.querySelectorAll('a')) {
          final href = rewriteDocUrl(a.attributes['href'] ?? '');
          final click = _urlFromOnclick(a.attributes['onclick'] ?? '');
          takeFile(href);
          takeFile(click);
          if (_isFile(href)) fileUrl = href;
          else if (_isFile(click ?? '')) fileUrl = click;
          else if (href.contains('aft.gov.in') && !_isNav(href)) {
            detailUrl ??= href;
            fileUrl ??= href;
          }
        }
        for (final el in row.querySelectorAll('[data-url],[data-href],[data-file],[data-pdf]')) {
          final dataUrl = rewriteDocUrl(el.attributes['data-url'] ?? el.attributes['data-href'] ?? el.attributes['data-file'] ?? el.attributes['data-pdf'] ?? '');
          takeFile(dataUrl);
          if (_isFile(dataUrl)) fileUrl ??= dataUrl;
        }
        for (final td in tds) {
          takeFile(_docFromCell(td));
          takeFile(_plain(td));
          fileUrl ??= _docFromCell(td);
        }
        fileUrl ??= files.isEmpty ? null : files.first;
        final title = [
          fields['Case No'],
          fields['Case Number'],
          fields['Diary No'],
          fields['Diary Number'],
          fields['Registration Number'],
          ...cells.where((c) => c.isNotEmpty && !c.startsWith('http') && !c.toLowerCase().contains('upload_document') && c.toLowerCase() != 'view'),
        ].whereType<String>().firstWhere((e) => e.trim().isNotEmpty, orElse: () => '');
        if (title.trim().isEmpty) continue;
        out.add(AftHit(
          title: title.trim(),
          subtitle: [
            if ((fields['Petitioner'] ?? fields['Party'] ?? fields['Applicant'] ?? fields['Applicant Name'] ?? '').isNotEmpty)
              fields['Petitioner'] ?? fields['Party'] ?? fields['Applicant'] ?? fields['Applicant Name']!,
            if ((fields['Status'] ?? fields['Order Date'] ?? fields['Date'] ?? '').isNotEmpty)
              fields['Status'] ?? fields['Order Date'] ?? fields['Date']!,
          ].where((e) => e.trim().isNotEmpty).join('  ·  '),
          detailUrl: detailUrl,
          fileUrl: fileUrl,
          files: files,
          fields: fields,
        ));
      }
    }
    return out;
  }

  List<AftBlock> _blocks(String html) {
    final document = html_parser.parse(html);
    final root = document.querySelector('#block-system-main') ??
        document.querySelector('.region-content') ??
        document.querySelector('#printableArea') ??
        document.querySelector('main') ??
        document.body;
    if (root == null) return const [];
    final blocks = <AftBlock>[];
    for (final table in root.querySelectorAll('table')) {
      final rows = _directRows(table);
      var headers = <String>[];
      final data = <List<String>>[];
      final links = <String?>[];
      final fields = <MapEntry<String, String>>[];
      for (final row in rows) {
        final ths = row.querySelectorAll('th').map(_plain).where((e) => e.isNotEmpty).toList();
        if (ths.isNotEmpty) {
          headers = ths;
          continue;
        }
        String? link;
        final cells = <String>[];
        for (final td in row.querySelectorAll('td')) {
          final file = _docFromCell(td);
          if (file != null) {
            link ??= file;
            final label = _plain(td);
            cells.add(label.isEmpty || label.toLowerCase() == 'view' ? 'View' : ( _looksLikeUrl(label) ? 'View' : label));
          } else {
            cells.add(_plain(td));
          }
        }
        if (cells.isEmpty) continue;
        data.add(cells);
        links.add(link);
        if (cells.length >= 2 && headers.length <= 2 && !headers.any((h) => h.toLowerCase().contains('view'))) {
          fields.add(MapEntry(cells.first, cells.length > 1 ? cells[1] : ''));
        }
      }
      if (data.isEmpty && fields.isEmpty) continue;
      final heading = headers.isEmpty
          ? 'Details'
          : (headers.any((h) => h.toLowerCase().contains('history') || h.toLowerCase().contains('order') || h.toLowerCase().contains('hearing'))
              ? 'Case history'
              : (headers.length > 4 ? 'Case history' : headers.join(' / ')));
      blocks.add(AftBlock(
        title: heading,
        fields: links.any((e) => (e ?? '').isNotEmpty) ? const [] : (fields.length == data.length ? fields : const []),
        headers: headers,
        rows: data,
        links: links,
      ));
    }
    final pairs = <MapEntry<String, String>>[];
    for (final row in root.querySelectorAll('.row, tr')) {
      final labels = row.querySelectorAll('label, .label, b, strong, th');
      if (labels.length == 1) {
        final key = _plain(labels.first);
        final value = _plain(row).replaceFirst(key, '').trim();
        if (key.length > 1 && key.length < 48 && value.isNotEmpty && value != key) {
          pairs.add(MapEntry(key.replaceAll(':', ''), value));
        }
      }
    }
    if (pairs.length >= 3) {
      blocks.insert(0, AftBlock(title: 'Case details', fields: pairs));
    }
    return blocks;
  }

  static bool _looksLikeUrl(String value) {
    final u = value.toLowerCase();
    return u.startsWith('http') || u.contains('upload_document') || u.contains('.pdf');
  }

  static String? _docFromCell(Element td) {
    for (final a in td.querySelectorAll('a')) {
      final href = rewriteDocUrl(a.attributes['href'] ?? '');
      final click = _urlFromOnclick(a.attributes['onclick'] ?? '');
      for (final cand in [href, if (click != null) click]) {
        if (cand.isEmpty || _isNav(cand) || cand.contains('javascript')) continue;
        return cand;
      }
    }
    for (final el in td.querySelectorAll('[data-url],[data-href],[data-file],[data-pdf]')) {
      final data = rewriteDocUrl(el.attributes['data-url'] ?? el.attributes['data-href'] ?? el.attributes['data-file'] ?? el.attributes['data-pdf'] ?? '');
      if (data.isNotEmpty && !_isNav(data)) return data;
    }
    final raw = _plain(td);
    if (_looksLikeUrl(raw)) return rewriteDocUrl(raw);
    return null;
  }

  static String? _docFromRow(Element row) {
    String? any;
    for (final td in row.querySelectorAll('td')) {
      final found = _docFromCell(td);
      if (found == null) continue;
      if (_isFile(found)) return found;
      any ??= found;
    }
    return any;
  }

  static bool _isFile(String href) {
    final u = href.toLowerCase();
    return u.contains('.pdf') ||
        u.contains('upload_document') ||
        u.contains('daily-cause-pdf') ||
        u.contains('/public/upload') ||
        u.contains('103.154.') ||
        u.contains('/storage/') ||
        u.contains('/files/') ||
        u.contains('download');
  }

  static bool _isNav(String href) {
    return href == host ||
        href == '$host/' ||
        href.contains('/casestatus/casenumber') ||
        href.contains('/casestatus/daterange') ||
        href.contains('/judgements/daterange') ||
        href.contains('javascript:');
  }

  static String? _urlFromOnclick(String raw) {
    final m = RegExp(r'''['"](https?:[^'"]+|/[a-zA-Z][^'"]+)['"]''').firstMatch(raw);
    if (m == null) return null;
    return rewriteDocUrl(m.group(1)!);
  }

  static String rewriteDocUrl(String href) {
    final trimmed = href.trim();
    if (trimmed.isEmpty || trimmed == '#') return '';
    if (trimmed.startsWith('//')) return rewriteDocUrl('https:$trimmed');
    final bare = RegExp(r'^(\d+\.pdf)$', caseSensitive: false).firstMatch(trimmed);
    if (bare != null) return '$host/public/upload_document/${bare.group(1)}';
    final file = RegExp(r'upload_document/(\d+\.pdf)', caseSensitive: false).firstMatch(trimmed);
    if (file != null) return '$host/public/upload_document/${file.group(1)}';
    if (trimmed.toLowerCase().endsWith('.pdf') && !trimmed.contains('/') && !trimmed.contains(':')) {
      return '$host/public/upload_document/$trimmed';
    }
    if (file != null) return '$host/public/upload_document/${file.group(1)}';
    if (trimmed.startsWith('http')) return trimmed;
    return Uri.parse(host).resolve(trimmed).toString();
  }

  static String _plain(Element e) => e.text.replaceAll(RegExp(r'\s+'), ' ').trim();

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
