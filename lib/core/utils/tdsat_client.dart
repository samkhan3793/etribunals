import 'dart:io';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:etribunals/core/utils/official_http.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:intl/intl.dart';

class TdsatBlock {
  final String title;
  final List<MapEntry<String, String>> fields;
  final List<String> headers;
  final List<List<String>> rows;

  const TdsatBlock({
    required this.title,
    this.fields = const [],
    this.headers = const [],
    this.rows = const [],
  });

  bool get isEmpty => fields.isEmpty && rows.isEmpty;
}

class TdsatCaseFile {
  final List<TdsatBlock> blocks;
  final List<TdsatHit> orders;
  const TdsatCaseFile({required this.blocks, this.orders = const []});
}

class TdsatHit {
  final String title;
  final String subtitle;
  final String? fileUrl;
  final Map<String, String> fields;

  const TdsatHit({
    required this.title,
    required this.subtitle,
    this.fileUrl,
    this.fields = const {},
  });
}

class TdsatClient {
  TdsatClient._() {
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

  static final TdsatClient instance = TdsatClient._();
  static const host = 'https://www.tdsat.gov.in';
  static const home = '$host/Delhi/Delhi.php';
  static const services = '$host/Delhi/services';
  static const caseStatusUrl = '$services/casestatus.php?chek=1234';
  static const caseStatusPost = '$services/checkhomedetail1.php';
  static const causeListUrl = '$services/causelistent.php?chek=1234';
  static const dailyOrdersUrl = '$services/dailyorderlist.php';
  static const judgmentsUrl = '$services/judgment.php';
  static const proceedingsUrl = '$services/record_of_proceeding.php';
  static const orderViewUrl = '$services/daily_order_view.php';

  static const caseTypes = [
    MapEntry('2', 'Telecom petition'),
    MapEntry('4', 'Telecom appeal'),
    MapEntry('1', 'Broadcasting petition'),
    MapEntry('3', 'Broadcasting appeal'),
    MapEntry('10', 'AERA appeal'),
    MapEntry('9', 'AERA petition'),
    MapEntry('11', 'Cyber appeal'),
    MapEntry('8', 'E A'),
    MapEntry('5', 'Misc application'),
    MapEntry('7', 'Review application'),
  ];

  final Dio _dio = Dio();

  String dateLabel(DateTime d) => DateFormat('dd/MM/yyyy').format(d);

  Future<String> _get(String url) async {
    final res = await _dio.get<String>(
      url,
      options: Options(responseType: ResponseType.plain, headers: {'Accept': 'text/html,*/*', 'Referer': home}),
    );
    return res.data ?? '';
  }

  Future<String> _post(String url, Map<String, String> body, {String? referer}) async {
    final res = await _dio.post<String>(
      url,
      data: body,
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
        responseType: ResponseType.plain,
        followRedirects: false,
        headers: {
          'Accept': 'text/html,*/*',
          'Origin': host,
          'Referer': referer ?? url,
        },
      ),
    );
    return res.data ?? '';
  }

  Future<TdsatCaseFile> searchCaseStatus({
    required bool diary,
    required String value,
    required String year,
    String caseType = '2',
  }) async {
    await _get(caseStatusUrl);
    final html = await _post(caseStatusPost, diary
        ? {
            'pet_type': '2',
            'dairyNo': value.trim(),
            'dairyyear': year.trim(),
            'submit1': 'Search',
          }
        : {
            'pet_type': '1',
            'casetype': caseType,
            'caseno': value.trim(),
            'caseyear': year.trim(),
            'submit1': 'Search',
          }, referer: caseStatusUrl);
    final orders = _resultRows(html);
    final blocks = parseBlocks(html).where((b) => !b.title.toUpperCase().contains('ORDER DETAIL')).toList();
    return TdsatCaseFile(blocks: blocks, orders: orders);
  }

  Future<List<TdsatHit>> causeList(DateTime date) async {
    final html = await _post('$services/causelistent.php', {
      'from_date1': dateLabel(date),
      'submit11': 'Go',
      'chek': '1234',
      'frm3': '',
    }, referer: causeListUrl);
    return _pdfRows(html);
  }

  Future<List<TdsatHit>> searchOrders({
    required String pageUrl,
    required String mode,
    String caseType = '2',
    String caseNo = '',
    String caseYear = '',
    String diaryNo = '',
    String diaryYear = '',
    DateTime? from,
    DateTime? to,
  }) async {
    await _get(pageUrl);
    late final Map<String, String> body;
    if (mode == 'diary') {
      body = {'dno': diaryNo.trim(), 'dyear': diaryYear.trim(), 'submit1': 'Go'};
    } else if (mode == 'dates') {
      body = {
        'from_date1': from == null ? '' : dateLabel(from),
        'to_date1': to == null ? '' : dateLabel(to),
        'submit11': 'Go',
        'frm3': '',
      };
    } else {
      body = {
        'casetype': caseType,
        'caseno': caseNo.trim(),
        'caseyear': caseYear.trim(),
        'submit1': 'Go',
      };
    }
    final html = await _post(pageUrl, body, referer: pageUrl);
    return _resultRows(html);
  }

  Future<List<TdsatBlock>> orderView(String filingNo) async {
    final html = await _get('$orderViewUrl?filing_no=$filingNo');
    return parseBlocks(html);
  }

  static String orderViewLink(String filingNo) => '$orderViewUrl?filing_no=$filingNo';

  List<TdsatHit> _resultRows(String html) {
    final fromJs = _orderRows(html);
    if (fromJs.isNotEmpty) return fromJs;
    return _pdfRows(html);
  }

  List<TdsatHit> _pdfRows(String html) {
    final document = html_parser.parse(html);
    final out = <TdsatHit>[];
    for (final row in document.querySelectorAll('tr')) {
      final a = row.querySelector('a[href]');
      final href = a?.attributes['href'] ?? '';
      if (!href.toLowerCase().contains('.pdf')) continue;
      final cells = row.querySelectorAll('td').map((e) => _clean(e.text)).where((e) => e.isNotEmpty).toList();
      final abs = href.startsWith('http') ? href : Uri.parse(host).resolve(href).toString();
      out.add(TdsatHit(
        title: cells.length > 1 ? cells[1] : 'Cause list',
        subtitle: cells.length > 2 ? cells[2] : dateLabel(DateTime.now()),
        fileUrl: abs,
        fields: {'PDF': abs},
      ));
    }
    return out;
  }

  List<TdsatHit> _orderRows(String html) {
    final out = <TdsatHit>[];
    final seen = <String>{};
    for (final m in RegExp(r"popsurety_pet_adv_name\('([^']+)'\)").allMatches(html)) {
      final filing = m.group(1)!;
      if (!seen.add(filing)) continue;
      final start = html.lastIndexOf('<tr', m.start);
      final end = html.indexOf('</tr>', m.end);
      final chunk = start >= 0 && end > start ? html.substring(start, end) : '';
      final caseNo = _clean(RegExp(r'>([A-Z][A-Z /0-9]+)<').firstMatch(chunk)?.group(1) ?? '');
      final date = RegExp(r'(\d{2}-\d{2}-\d{4})').firstMatch(chunk)?.group(1) ?? '';
      final party = _clean(chunk.replaceAll(RegExp(r'<[^>]+>'), ' '));
      out.add(TdsatHit(
        title: caseNo.isEmpty ? 'TDSAT order' : caseNo,
        subtitle: [if (date.isNotEmpty) date, if (party.contains('VS')) party].join('  ·  '),
        fileUrl: orderViewLink(filing),
        fields: {'filing_no': filing, 'Order Date': date},
      ));
    }
    return out;
  }

  static String _clean(String raw) => raw.replaceAll(RegExp(r'\s+'), ' ').replaceAll(RegExp(r'\.+$'), '').trim();

  static String _cell(Element e) => _clean(e.text);

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

  static List<TdsatBlock> parseBlocks(String html) {
    final document = html_parser.parse(html);
    final root = document.body;
    if (root == null) return const [];
    final blocks = <TdsatBlock>[];
    for (final table in root.querySelectorAll('table')) {
      final block = _parseTable(table);
      if (block != null && !block.isEmpty) blocks.add(block);
    }
    return blocks;
  }

  static TdsatBlock? _parseTable(Element table) {
    final rows = _directRows(table);
    if (rows.isEmpty) return null;
    var title = '';
    final fields = <MapEntry<String, String>>[];
    var headers = <String>[];
    final data = <List<String>>[];
    for (final row in rows) {
      final cells = row.children.where((e) => e.localName == 'td' || e.localName == 'th').toList();
      if (cells.isEmpty) continue;
      final texts = cells.map(_cell).toList();
      if (texts.join(' ').toLowerCase().contains('print')) continue;
      final colspan = cells.first.attributes['colspan'];
      if (cells.length == 1 || (colspan != null && int.tryParse(colspan) != null && int.parse(colspan) >= 3 && texts.where((t) => t.isNotEmpty).length == 1)) {
        final heading = texts.firstWhere((t) => t.isNotEmpty, orElse: () => '');
        if (heading.isNotEmpty) title = heading;
        continue;
      }
      if (cells.length == 2) {
        if (texts[0].isEmpty && texts[1].isEmpty) continue;
        fields.add(MapEntry(texts[0].isEmpty ? 'Detail' : texts[0], texts[1]));
        continue;
      }
      final headingish = cells.every((c) => c.localName == 'th' || c.querySelector('b') != null);
      if (headers.isEmpty && headingish && texts.any((t) => t.isNotEmpty)) {
        headers = texts;
        continue;
      }
      if (texts.any((t) => t.isNotEmpty)) data.add(texts);
    }
    if (fields.isEmpty && data.isEmpty) return null;
    return TdsatBlock(title: title.isEmpty ? 'Record' : title, fields: fields, headers: headers, rows: data);
  }
}
