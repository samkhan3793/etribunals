import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:etribunals/core/utils/official_http.dart';
import 'package:etribunals/core/utils/drupal_listing.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html_unescape/html_unescape.dart';

class NgtCaseHit {
  final String diaryNo;
  final String caseNo;
  final String party;
  final String status;
  final String detailsUrl;
  final Map<String, String> raw;

  const NgtCaseHit({
    required this.diaryNo,
    required this.caseNo,
    required this.party,
    required this.status,
    required this.detailsUrl,
    required this.raw,
  });
}

class NgtJudgementPage {
  final List<Map<String, String>> rows;
  final bool hasMore;

  const NgtJudgementPage({required this.rows, required this.hasMore});
}

class NgtOrderLink {
  final String label;
  final String url;

  const NgtOrderLink({required this.label, required this.url});
}

class NgtListingRow {
  final String listingDate;
  final String uploadDate;
  final String coram;
  final List<NgtOrderLink> pdfs;

  const NgtListingRow({
    required this.listingDate,
    this.uploadDate = '',
    this.coram = '',
    this.pdfs = const [],
  });
}

class NgtCaseClient {
  NgtCaseClient._() {
    _dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient();
        client.badCertificateCallback = (cert, host, port) => true;
        return client;
      },
    );
    _dio.interceptors.add(CookieManager(_cookies));
    OfficialHttp.attachDio(_dio);
    _dio.options.followRedirects = true;
    _dio.options.validateStatus = (code) => code != null && code >= 200 && code < 400;
    _dio.options.headers['User-Agent'] =
        'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 Chrome/124.0.0.0 Mobile Safari/537.36';
    _dio.options.headers['Accept'] =
        'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8';
  }

  static final NgtCaseClient instance = NgtCaseClient._();

  static const host = 'https://www.greentribunal.gov.in';
  static const captchaUrl = '$host/sites/all/modules/custom/case_status/captcha.php';
  static const diaryFormUrl = '$host/casestatus/diarynumber';
  static const caseFormUrl = '$host/casestatus/casenumber';
  static const diarySearchUrl = '$host/casestatus/dairyData';
  static const caseSearchUrl = '$host/casestatus/caseNumberData';
  static const judgementFormUrl = '$host/judgementOrder/zonalbenchwise';
  static const judgementSearchUrl = '$host/judgementOrder/zonalBenchData';

  final Dio _dio = Dio();
  final CookieJar _cookies = CookieJar();

  Future<Uint8List> loadCaptcha({required String sessionUrl}) async {
    await _dio.get(sessionUrl);
    final response = await _dio.get<List<int>>(
      captchaUrl,
      queryParameters: {'t': DateTime.now().millisecondsSinceEpoch},
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(response.data ?? const []);
  }

  Future<List<NgtCaseHit>> searchByDiary({
    required String zoneType,
    required String diaryNo,
    required String year,
    required String captcha,
  }) {
    return _search(
      url: diarySearchUrl,
      referer: diaryFormUrl,
      query: {
        'zone_type': zoneType,
        'diary_no': diaryNo.trim(),
        'case_year': year,
        'captcha_input': captcha.trim(),
      },
    );
  }

  Future<List<NgtCaseHit>> searchByCaseNumber({
    required String zoneType,
    required String caseType,
    required String caseNumber,
    required String year,
    required String captcha,
  }) {
    return _search(
      url: caseSearchUrl,
      referer: caseFormUrl,
      query: {
        'zone_type': zoneType,
        'case_type': caseType,
        'case_number': caseNumber.trim(),
        'case_year': year,
        'captcha_input': captcha.trim(),
      },
    );
  }

  Future<NgtJudgementPage> searchJudgements({
    required String zoneType,
    required String fromDate,
    required String toDate,
    required String orderBy,
    required String captcha,
    int page = 0,
  }) async {
    final query = <String, String>{
      'zone_type': zoneType,
      'from_date': fromDate,
      'to_date': toDate,
      'order_by': orderBy,
      'captcha_input': captcha.trim(),
    };
    if (page > 0) query['page'] = '$page';
    final response = await _dio.get<String>(
      judgementSearchUrl,
      queryParameters: query,
      options: Options(responseType: ResponseType.plain, headers: {'Referer': judgementFormUrl}),
    );
    final html = response.data ?? '';
    _throwIfBlocked(html);
    final hits = parseNgtSearchHits(html);
    if (page == 0 && hits.isEmpty) {
      throw Exception('No NGT orders/judgements found for these dates.');
    }
    return NgtJudgementPage(
      rows: hits
          .map(
            (hit) => {
              'Date of Listing': _pick(hit.raw, const ['Order Date', 'Date of Listing', 'Date of Upload']),
              'Party': hit.party,
              'Diary Number': hit.diaryNo,
              'Case Number': hit.caseNo,
              'Case Status': hit.status,
              'case': hit.detailsUrl,
            },
          )
          .toList(),
      hasMore: html.contains('page=${page + 1}') || html.contains('page=${page + 1}&'),
    );
  }

  Future<String> fetchCaseHtml(String detailsUrl) async {
    final response = await _dio.get<String>(
      detailsUrl,
      options: Options(responseType: ResponseType.plain, headers: {'Referer': diaryFormUrl}),
    );
    final html = response.data ?? '';
    _throwIfBlocked(html);
    if (!html.toLowerCase().contains('case details') && !html.contains('Filing Number')) {
      throw Exception('NGT did not return case details for this search.');
    }
    return html;
  }

  Future<List<NgtListingRow>> fetchListingRows(String detailsUrl, {String? caseHtml}) async {
    final rows = <NgtListingRow>[];
    if (caseHtml != null && caseHtml.isNotEmpty) {
      rows.addAll(parseNgtListingRows(caseHtml));
    }
    try {
      final uri = Uri.parse(detailsUrl);
      if (uri.host.isNotEmpty) {
        final query = Map<String, String>.from(uri.queryParameters);
        query['page'] = 'order';
        final response = await _dio.get<String>(
          uri.replace(queryParameters: query).toString(),
          options: Options(responseType: ResponseType.plain, headers: {'Referer': diaryFormUrl}),
        );
        final orderHtml = response.data ?? '';
        _throwIfBlocked(orderHtml);
        final orderRows = parseNgtListingRows(orderHtml);
        if (orderRows.length > rows.length) return orderRows;
        if (orderRows.isNotEmpty && rows.isEmpty) return orderRows;
      }
    } catch (_) {}
    return rows;
  }

  Future<List<NgtCaseHit>> _search({
    required String url,
    required String referer,
    required Map<String, String> query,
  }) async {
    final response = await _dio.get<String>(
      url,
      queryParameters: query,
      options: Options(responseType: ResponseType.plain, headers: {'Referer': referer}),
    );
    final html = response.data ?? '';
    _throwIfBlocked(html);
    final hits = parseNgtSearchHits(html);
    if (hits.isEmpty) {
      throw Exception('No NGT record found for these details.');
    }
    return hits;
  }

  void _throwIfBlocked(String html) {
    final text = html.toLowerCase();
    if (text.contains('captcha is incorrect') || text.contains('captcha is missing')) {
      throw Exception('Captcha is incorrect. Refresh and try again.');
    }
  }
}

List<NgtCaseHit> parseNgtSearchHits(String html) {
  final tableRows = parseDrupalListingTable(html, host: NgtCaseClient.host);
  final hits = <NgtCaseHit>[];
  for (final row in tableRows) {
    final url = _firstCaseDetailsUrl(row.values);
    if (url == null) continue;
    hits.add(
      NgtCaseHit(
        diaryNo: _pick(row, const ['Diary Number', 'Diary No', 'Diary No.']),
        caseNo: _pick(row, const ['Case Number/Location Code', 'Case Number', 'Case No']),
        party: _pick(row, const ['Party Name', 'Party']),
        status: _pick(row, const ['Case Status', 'Status']),
        detailsUrl: url,
        raw: row,
      ),
    );
  }
  if (hits.isNotEmpty) return hits;

  final document = html_parser.parse(html);
  for (final anchor in document.querySelectorAll('a[href*="caseDetails"]')) {
    final href = absoluteUrl(anchor.attributes['href'] ?? '', host: NgtCaseClient.host);
    if (href.isEmpty) continue;
    final label = anchor.text.trim();
    hits.add(
      NgtCaseHit(
        diaryNo: label,
        caseNo: '',
        party: label,
        status: '',
        detailsUrl: href,
        raw: {'label': label},
      ),
    );
  }
  return hits;
}

Map<String, String> parseNgtCaseFields(String html) {
  final document = html_parser.parse(html);
  final fields = <String, String>{};
  for (final table in document.querySelectorAll('table')) {
    final head = (table.querySelector('thead')?.text ?? table.querySelector('tr')?.text ?? '').toLowerCase();
    if (head.contains('date of listing') ||
        head.contains('order/judgement') ||
        head.contains('connected matter') ||
        (head.contains('petitioner') && head.contains('respondent'))) {
      continue;
    }
    for (final row in table.querySelectorAll('tr')) {
      final cells = row.querySelectorAll('th,td');
      if (cells.length == 2) {
        final key = cells[0].text.trim();
        if (key.isNotEmpty) fields.putIfAbsent(key, () => cells[1].text.trim());
      } else if (cells.length >= 4) {
        for (var i = 0; i + 1 < cells.length; i += 2) {
          final key = cells[i].text.trim();
          if (key.isEmpty || key.toLowerCase().contains('s.no')) continue;
          fields.putIfAbsent(key, () => cells[i + 1].text.trim());
        }
      }
    }
  }
  return fields;
}

String ngtOrderPdfUrl(String token) {
  var value = token.trim().replaceAll('&quot;', '').replaceAll('&#39;', '');
  if (value.startsWith('/ngt_documents') || value.startsWith('ngt_documents')) {
    if (!value.startsWith('/')) value = '/$value';
    value = base64Encode(utf8.encode(value));
  }
  try {
    if (value.contains('%')) value = Uri.decodeComponent(value);
  } catch (_) {}
  return '${NgtCaseClient.host}/gen_pdf_test.php?filepath=${Uri.encodeQueryComponent(value)}';
}

List<String> _ngtPdfTokens(String html) {
  final tokens = <String>[];
  for (final match in RegExp(r"myFunctionTest\s*\(\s*'([^']+)'\s*\)").allMatches(html)) {
    tokens.add(match.group(1)!);
  }
  for (final match in RegExp(r'myFunctionTest\s*\(\s*"([^"]+)"\s*\)').allMatches(html)) {
    tokens.add(match.group(1)!);
  }
  for (final match in RegExp(r'gen_pdf_test\.php\?filepath=([^"''&\s]+)').allMatches(html)) {
    tokens.add(match.group(1)!);
  }
  return tokens;
}

String _pdfLabel(String token) {
  try {
    var raw = token;
    if (raw.contains('%')) raw = Uri.decodeComponent(raw);
    final pad = raw.length % 4 == 0 ? raw : raw.padRight(raw.length + (4 - raw.length % 4), '=');
    final decoded = utf8.decode(base64Decode(pad), allowMalformed: true).toLowerCase();
    if (decoded.contains('judgement') || decoded.contains('judgment')) return 'View judgement PDF';
    if (decoded.contains('order')) return 'View order PDF';
  } catch (_) {}
  return 'View PDF';
}

List<NgtListingRow> parseNgtListingRows(String html) {
  html = HtmlUnescape().convert(html);
  final document = html_parser.parse(html);
  final rows = <NgtListingRow>[];
  for (final row in document.querySelectorAll('tr')) {
    final cells = row.querySelectorAll('td');
    if (cells.length < 2) continue;
    final tokens = _ngtPdfTokens(row.innerHtml).toSet().toList();
    if (tokens.isEmpty) continue;
    final dates = cells
        .map((c) => c.text.replaceAll(RegExp(r'\s+'), ' ').trim())
        .where((t) => RegExp(r'^\d{1,2}[-/]\d{1,2}[-/]\d{2,4}$').hasMatch(t))
        .toList();
    rows.add(
      NgtListingRow(
        listingDate: dates.isNotEmpty ? dates.first : '',
        uploadDate: dates.length > 1 ? dates[1] : '',
        coram: cells.length >= 4 ? cells[3].text.replaceAll(RegExp(r'\s+'), ' ').trim() : '',
        pdfs: [
          for (var i = 0; i < tokens.length; i++)
            NgtOrderLink(label: _pdfLabel(tokens[i]), url: ngtOrderPdfUrl(tokens[i])),
        ],
      ),
    );
  }
  return rows;
}

List<NgtOrderLink> parseNgtOrderLinks(String html) {
  return parseNgtListingRows(html).expand((row) => row.pdfs).toList();
}

String? _firstCaseDetailsUrl(Iterable<String> values) {
  for (final value in values) {
    if (value.contains('/caseDetails/')) return value;
  }
  return null;
}

String _pick(Map<String, String> row, List<String> keys) {
  for (final key in keys) {
    final direct = row[key]?.trim();
    if (direct != null && direct.isNotEmpty && !direct.contains('/caseDetails/')) return direct;
    final label = row['${key}_label']?.trim();
    if (label != null && label.isNotEmpty) return label;
  }
  return '';
}

String? ngtRowHref(Map<String, String> row, {required bool preferPdf}) {
  if (preferPdf) {
    final pdf = row['pdf'] ?? row['pdf2'];
    if (pdf != null && pdf.contains('gen_pdf_test.php')) return pdf;
  }
  final caseUrl = row['case'];
  if (!preferPdf && caseUrl != null && caseUrl.contains('/caseDetails/')) return caseUrl;
  for (final entry in row.entries) {
    if (entry.key.endsWith('_label')) continue;
    final value = entry.value;
    if (!preferPdf && value.contains('/caseDetails/')) return value;
  }
  return null;
}
