import 'dart:io';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:etribunals/core/utils/official_http.dart';
import 'package:html/parser.dart' as html_parser;

class AtfpHit {
  final String title;
  final String subtitle;
  final String? fileUrl;
  final Map<String, String> fields;
  const AtfpHit({required this.title, required this.subtitle, this.fileUrl, this.fields = const {}});
}

class AtfpClient {
  AtfpClient._() {
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

  static final AtfpClient instance = AtfpClient._();
  static const host = 'https://atfp.gov.in';
  static const causeListUrl = '$host/cause-list.asp';
  static const ordersUrl = '$host/orders.asp';
  static const judgementsUrl = '$host/judgements.asp';

  static const actTypes = [
    MapEntry('PMLA/FPA-PMLA', 'PMLA / FPA-PMLA'),
    MapEntry('NDPS/FPA/ND', 'NDPS / FPA/ND'),
    MapEntry('SAFEMA/FPA–1', 'SAFEMA / FPA-1'),
    MapEntry('FPA/BP', 'FPA / BP'),
    MapEntry('FEMA/FERA/FPA-FE', 'FEMA / FERA / FPA-FE'),
  ];

  final Dio _dio = Dio();

  static String absUrl(String href) {
    var p = href.trim().replaceAll('\\', '/');
    if (p.toLowerCase().startsWith('http')) return p;
    p = p.replaceAll(RegExp(r'/+'), '/');
    if (!p.startsWith('/')) p = '/$p';
    return '$host$p';
  }

  Future<String> _get(String url) async {
    final res = await _dio.get<String>(
      url,
      options: Options(responseType: ResponseType.plain, headers: {'Accept': 'text/html,*/*', 'Referer': host}),
    );
    return res.data ?? '';
  }

  Future<String> _post(String url, Map<String, String> body, String referer) async {
    await _get(referer);
    final res = await _dio.post<String>(
      url,
      data: body,
      options: Options(
        responseType: ResponseType.plain,
        contentType: Headers.formUrlEncodedContentType,
        headers: {'Accept': 'text/html,*/*', 'Referer': referer},
      ),
    );
    return res.data ?? '';
  }

  Future<List<AtfpHit>> causeList({int page = 1}) async {
    final html = await _get('$causeListUrl?currentPage=$page');
    return _pdfRows(html, titleIndex: 0);
  }

  Future<List<AtfpHit>> searchOrders({
    required String mode,
    String query = '',
    String act = 'PMLA/FPA-PMLA',
    required DateTime date,
  }) {
    final mm = date.month.toString().padLeft(2, '0');
    final yyyy = '${date.year}';
    final dd = date.day.toString().padLeft(2, '0');
    final body = switch (mode) {
      'date' => {'DDDate': dd, 'DDMONTH': mm, 'DDYEAR': yyyy},
      'act' => {'ACTAPPEALTYPE': act, 'q': query.trim()},
      _ => {'q': query.trim(), 'DDMONTH': mm, 'DDYEAR': yyyy},
    };
    return _post('$host/Ordersdetails.asp', body, ordersUrl).then(_orderRows);
  }

  Future<List<AtfpHit>> searchJudgements({
    required String mode,
    String query = '',
    String act = 'PMLA/FPA-PMLA',
    required DateTime date,
  }) {
    final mm = date.month.toString().padLeft(2, '0');
    final yyyy = '${date.year}';
    final dd = date.day.toString().padLeft(2, '0');
    final body = switch (mode) {
      'date' => {'DDDate': dd, 'DDMONTH': mm, 'DDYEAR': yyyy},
      'act' => {'ACTAPPEALTYPE': act, 'z': query.trim()},
      _ => {'z': query.trim(), 'DDMONTH': mm, 'DDYEAR': yyyy},
    };
    return _post('$host/judgementsdetails.asp', body, judgementsUrl).then(_orderRows);
  }

  List<AtfpHit> _orderRows(String html) {
    final doc = html_parser.parse(html);
    final out = <AtfpHit>[];
    for (final table in doc.querySelectorAll('table')) {
      for (final tr in table.querySelectorAll('tr')) {
        final cells = tr.querySelectorAll('td');
        if (cells.length < 4) continue;
        final texts = [for (final c in cells) c.text.replaceAll(RegExp(r'\s+'), ' ').trim()];
        if (texts[0].toLowerCase().contains('s. no') || texts[0].toLowerCase().contains('s.no')) continue;
        if (tr.querySelector('th') != null) continue;
        if (tr.querySelector('[colspan]') != null) continue;
        final caseNo = texts.length > 1 ? texts[1] : texts[0];
        final orderDate = texts.length > 2 ? texts[2] : '';
        final parties = texts.length > 3 ? texts[3] : '';
        if (caseNo.isEmpty || caseNo.toLowerCase() == 'case no.') continue;
        final href = tr.querySelector('a[href]')?.attributes['href'];
        if (href == null || href.toLowerCase().contains('javascript') || href == '#') continue;
        if (!href.toLowerCase().contains('writeread') && !href.toLowerCase().contains('.pdf')) continue;
        out.add(AtfpHit(
          title: caseNo,
          subtitle: [if (orderDate.isNotEmpty) orderDate, parties].where((e) => e.isNotEmpty).join('  ·  '),
          fileUrl: absUrl(href),
          fields: {
            'Case no.': caseNo,
            if (orderDate.isNotEmpty) 'Date of order': orderDate,
            if (parties.isNotEmpty) 'Parties': parties,
          },
        ));
      }
    }
    return out;
  }

  List<AtfpHit> _pdfRows(String html, {int titleIndex = 0}) {
    final doc = html_parser.parse(html);
    final out = <AtfpHit>[];
    for (final table in doc.querySelectorAll('table')) {
      for (final tr in table.querySelectorAll('tr')) {
        if (tr.querySelector('[colspan]') != null) continue;
        final cells = tr.querySelectorAll('td');
        if (cells.isEmpty) continue;
        final title = cells[titleIndex].text.replaceAll(RegExp(r'\s+'), ' ').trim();
        if (title.isEmpty || title.toLowerCase() == 'cause list') continue;
        final href = tr.querySelector('a[href]')?.attributes['href'];
        if (href == null || href.toLowerCase().contains('javascript') || href.contains('archive') || href.contains('currentPage')) {
          continue;
        }
        if (!href.toLowerCase().contains('writeread') && !href.toLowerCase().contains('.pdf')) continue;
        out.add(AtfpHit(title: title, subtitle: 'Cause list PDF', fileUrl: absUrl(href), fields: {'Listing': title}));
      }
    }
    return out;
  }
}
