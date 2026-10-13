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

class CgitHit {
  final String caseNo;
  final String subject;
  final String caseType;
  final String appellant;
  final String respondent;
  final String nextDate;
  final String details;
  final List<String> fileUrls;
  const CgitHit({
    required this.caseNo,
    required this.subject,
    required this.caseType,
    required this.appellant,
    required this.respondent,
    required this.nextDate,
    required this.details,
    this.fileUrls = const [],
  });

  String get title => caseNo.isNotEmpty ? caseNo : subject;
  String get parties => [appellant, if (respondent.isNotEmpty) 'v. $respondent'].where((e) => e.trim().isNotEmpty).join(' ');
  String get subtitle => [if (caseType.isNotEmpty) caseType, if (nextDate.isNotEmpty) 'Next $nextDate', if (details.isNotEmpty) details].join('  ·  ');
}

class CgitClient {
  CgitClient._() {
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

  static final CgitClient instance = CgitClient._();
  static const host = 'https://apps.labour.gov.in/cgit';
  static const causeListUrl = '$host/cause-list';
  static const awardsUrl = '$host/awards-and-judgements-orders';

  static const benches = [
    MapEntry('All', 'Any bench'),
    MapEntry('6', 'Ahmedabad'),
    MapEntry('7', 'Asansol'),
    MapEntry('8', 'Bangalore'),
    MapEntry('9', 'Bhubaneswar'),
    MapEntry('10', 'Chandigarh-I'),
    MapEntry('11', 'Chandigarh-II'),
    MapEntry('12', 'Chennai'),
    MapEntry('26', 'Delhi-I'),
    MapEntry('27', 'Delhi-II'),
    MapEntry('13', 'Dhanbad-I'),
    MapEntry('14', 'Dhanbad-II'),
    MapEntry('17', 'Ernakulam'),
    MapEntry('15', 'Guwahati'),
    MapEntry('16', 'Hyderabad'),
    MapEntry('18', 'Jabalpur'),
    MapEntry('19', 'Jaipur'),
    MapEntry('20', 'Kanpur'),
    MapEntry('21', 'Kolkata'),
    MapEntry('22', 'Lucknow'),
    MapEntry('23', 'Mumbai-I'),
    MapEntry('24', 'Mumbai-II'),
    MapEntry('25', 'Nagpur'),
  ];

  static const caseTypes = [
    MapEntry('All', 'Any type'),
    MapEntry('29', 'ID'),
    MapEntry('30', 'EPF Appeal'),
  ];

  final Dio _dio = Dio();

  static String absUrl(String href) {
    var p = href.trim().replaceAll('&amp;', '&');
    if (p.toLowerCase().startsWith('http')) {
      p = p.replaceFirst(RegExp(r'^http://apps\.labour\.gov\.in'), 'https://apps.labour.gov.in');
    } else {
      if (!p.startsWith('/')) p = '/$p';
      p = 'https://apps.labour.gov.in$p';
    }
    final uri = Uri.parse(p);
    try {
      return uri.replace(path: Uri.decodeFull(uri.path)).toString();
    } catch (_) {
      return uri.toString();
    }
  }

  Future<Uint8List> downloadPdf(String url) async {
    final uri = Uri.parse(absUrl(url));
    final res = await _dio.getUri<List<int>>(
      uri,
      options: Options(
        responseType: ResponseType.bytes,
        headers: {
          'Accept': 'application/pdf,*/*',
          'Referer': awardsUrl,
        },
      ),
    );
    final bytes = Uint8List.fromList(res.data ?? const []);
    if (bytes.length >= 4 && bytes[0] == 0x25 && bytes[1] == 0x50 && bytes[2] == 0x44 && bytes[3] == 0x46) {
      return bytes;
    }
    throw Exception('CGIT did not return a PDF for this file.');
  }

  Future<String> _get(String url, [Map<String, dynamic>? query]) async {
    final res = await _dio.get<String>(
      url,
      queryParameters: query,
      options: Options(responseType: ResponseType.plain, headers: {'Accept': 'text/html,*/*', 'Referer': host}),
    );
    if ((res.statusCode ?? 0) >= 400) throw Exception('CGIT page is not available (${res.statusCode}).');
    return res.data ?? '';
  }

  Future<List<CgitHit>> causeList({
    DateTime? date,
    String caseNo = '',
    String caseType = 'All',
    String appellant = '',
    String respondent = '',
    String bench = 'All',
    String subject = '',
    int page = 0,
  }) async {
    final q = <String, dynamic>{
      'page': page,
      if (date != null) 'field_date_value[date]': DateFormat('yyyy-MM-dd').format(date),
      if (caseNo.trim().isNotEmpty) 'field_case_no__value': caseNo.trim(),
      if (caseType != 'All') 'field_case_type_target_id': caseType,
      if (appellant.trim().isNotEmpty) 'field_name_of_appellant_value': appellant.trim(),
      if (respondent.trim().isNotEmpty) 'field_respondent__value': respondent.trim(),
      if (bench != 'All') 'field_term_cgit_target_id_1': bench,
      if (subject.trim().isNotEmpty) 'title': subject.trim(),
    };
    return _parseCause(await _get(causeListUrl, q));
  }

  Future<List<CgitHit>> awards({String query = '', int page = 0}) async {
    final q = <String, dynamic>{'page': page, if (query.trim().isNotEmpty) 'title': query.trim()};
    return _parseAwards(await _get(awardsUrl, q));
  }

  List<CgitHit> _parseCause(String html) {
    final doc = html_parser.parse(html);
    final table = doc.querySelector('table.cols-10') ?? doc.querySelector('table');
    if (table == null) return const [];
    final out = <CgitHit>[];
    for (final tr in table.querySelectorAll('tbody tr')) {
      String cell(String cls) => _text(tr.querySelector(cls));
      final files = [
        for (final a in tr.querySelectorAll('.views-field-field-details a[href]')) absUrl(a.attributes['href'] ?? ''),
      ].where((u) => u.toLowerCase().contains('/files/') || u.toLowerCase().contains('.pdf')).toList();
      final hit = CgitHit(
        caseNo: cell('.views-field-field-case-no-'),
        subject: cell('.views-field-title'),
        caseType: cell('.views-field-field-case-type'),
        appellant: cell('.views-field-field-name-of-appellant'),
        respondent: cell('.views-field-field-respondent-'),
        nextDate: cell('.views-field-field-date'),
        details: cell('.views-field-field-cgit-details'),
        fileUrls: files,
      );
      if (hit.title.isEmpty && hit.parties.isEmpty) continue;
      out.add(hit);
    }
    return out;
  }

  List<CgitHit> _parseAwards(String html) {
    final doc = html_parser.parse(html);
    final table = doc.querySelector('table.cols-3') ?? doc.querySelector('table');
    if (table == null) return const [];
    final out = <CgitHit>[];
    for (final tr in table.querySelectorAll('tbody tr')) {
      final subject = _text(tr.querySelector('.views-field-title'));
      if (subject.isEmpty || subject.toLowerCase() == 'subject') continue;
      final files = [
        for (final a in tr.querySelectorAll('.views-field-field-upload-award-orde a[href]')) absUrl(a.attributes['href'] ?? ''),
      ].where((u) => u.toLowerCase().contains('/files/') || u.toLowerCase().contains('.pdf')).toList();
      out.add(CgitHit(
        caseNo: '',
        subject: subject,
        caseType: '',
        appellant: '',
        respondent: '',
        nextDate: '',
        details: '',
        fileUrls: files,
      ));
    }
    return out;
  }

  String _text(Element? el) => (el?.text ?? '').replaceAll(RegExp(r'\s+'), ' ').trim();
}
