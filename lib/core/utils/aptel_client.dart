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

class AptelBlock {
  final String title;
  final List<MapEntry<String, String>> fields;
  final List<String> headers;
  final List<List<String>> rows;

  const AptelBlock({
    required this.title,
    this.fields = const [],
    this.headers = const [],
    this.rows = const [],
  });
}

class AptelCaseFile {
  final List<AptelBlock> blocks;
  final List<AptelHit> files;
  const AptelCaseFile({required this.blocks, this.files = const []});
}

class AptelHit {
  final String title;
  final String subtitle;
  final String? fileUrl;
  final String? detailUrl;
  final Map<String, String> fields;

  const AptelHit({
    required this.title,
    required this.subtitle,
    this.fileUrl,
    this.detailUrl,
    this.fields = const {},
  });
}

class AptelClient {
  AptelClient._() {
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

  static final AptelClient instance = AptelClient._();
  static const host = 'http://aptel.gov.in';
  static const home = '$host/en';
  static const caseStatusUrl = '$host/en/casestatusapi';
  static const causeListUrl = '$host/en/causelist';
  static const dailyOrderUrl = '$host/en/dailyorder';
  static const judgementUrl = '$host/en/judgementorder';
  static const displayBoardUrl = '$host/en/display-board';
  static const cis = 'https://cis.aptel.gov.in';

  static const caseTypes = [
    MapEntry('1', 'APL'),
    MapEntry('4', 'OP'),
    MapEntry('5', 'EP'),
    MapEntry('6', 'RP'),
    MapEntry('7', 'CP'),
  ];

  static const partyTypes = [
    MapEntry('1', 'Appellant / petitioner'),
    MapEntry('2', 'Respondent'),
    MapEntry('3', 'Both'),
  ];

  final Dio _dio = Dio();

  String isoDate(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  Future<String> _get(String url) async {
    final res = await _dio.get<String>(
      url,
      options: Options(responseType: ResponseType.plain, headers: {'Accept': 'text/html,*/*', 'Referer': home}),
    );
    return res.data ?? '';
  }

  Future<List<AptelHit>> ajaxSearch({
    required String pageUrl,
    required String formId,
    required Map<String, String> fields,
  }) async {
    final html = await _get(pageUrl);
    final buildId = _formBuildId(html, formId);
    if (buildId == null) throw Exception('APTEL search form did not load.');
    final body = {
      'form_build_id': buildId,
      'form_id': formId,
      'op': 'Submit',
      '_triggering_element_name': 'op',
      '_triggering_element_value': 'Submit',
      ...fields,
    };
    final res = await _dio.post<String>(
      '$pageUrl?ajax_form=1&_wrapper_format=drupal_ajax',
      data: body,
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
        responseType: ResponseType.plain,
        headers: {
          'Accept': 'application/json, application/vnd.drupal-ajax, */*',
          'X-Requested-With': 'XMLHttpRequest',
          'Origin': host,
          'Referer': pageUrl,
        },
      ),
    );
    return _hitsFromAjax(res.data ?? '');
  }

  Future<List<AptelHit>> causeListToday() async {
    final html = await _get(causeListUrl);
    return _hitsFromHtml(html);
  }

  Future<List<AptelHit>> searchCase({
    required String mode,
    String diaryNo = '',
    String caseNo = '',
    String year = '',
    String caseType = '1',
    String partyName = '',
    String partyType = '1',
    String yearType = '2',
    DateTime? from,
    DateTime? to,
  }) {
    if (mode == 'dfr') {
      return ajaxSearch(
        pageUrl: caseStatusUrl,
        formId: 'Case_order_dfrnowise_form',
        fields: {'diary_no': diaryNo.trim(), 'diary_year': year.trim()},
      );
    }
    if (mode == 'party') {
      return ajaxSearch(
        pageUrl: '$caseStatusUrl/tab3',
        formId: 'case_order_partywise_form',
        fields: {
          'party_name': partyName.trim(),
          'party_type': partyType,
          'year_type': yearType,
          'diary_year': year.trim(),
        },
      );
    }
    if (mode == 'date') {
      return ajaxSearch(
        pageUrl: '$caseStatusUrl/tab4',
        formId: 'case_order_date_wise_form',
        fields: {'from_date': isoDate(from ?? DateTime.now()), 'to_date': isoDate(to ?? DateTime.now())},
      );
    }
    return ajaxSearch(
      pageUrl: '$caseStatusUrl/tab2',
      formId: 'case_order_casenowise_form',
      fields: {'case_type': caseType, 'case_no': caseNo.trim(), 'diary_year': year.trim()},
    );
  }

  Future<List<AptelHit>> searchOrders({
    required bool judgement,
    required String mode,
    String diaryNo = '',
    String caseNo = '',
    String year = '',
    String caseType = '1',
    String partyName = '',
    String partyType = '1',
    String yearType = '2',
    DateTime? from,
    DateTime? to,
  }) {
    final base = judgement ? judgementUrl : dailyOrderUrl;
    final prefix = judgement ? 'judgement_order' : 'daily_order';
    if (mode == 'dfr') {
      return ajaxSearch(
        pageUrl: base,
        formId: '${prefix}_dfrnowise_form',
        fields: {'diary_no': diaryNo.trim(), 'diary_year': year.trim()},
      );
    }
    if (mode == 'party') {
      return ajaxSearch(
        pageUrl: '$base/tab4',
        formId: '${prefix}_partywise_form',
        fields: {
          'party_name': partyName.trim(),
          'party_type': partyType,
          'year_type': yearType,
          'diary_year': year.trim(),
        },
      );
    }
    if (mode == 'date') {
      return ajaxSearch(
        pageUrl: judgement ? '$base/tab3' : '$base/tab3',
        formId: '${prefix}_date_wise_form',
        fields: {'from_date': isoDate(from ?? DateTime.now()), 'to_date': isoDate(to ?? DateTime.now())},
      );
    }
    return ajaxSearch(
      pageUrl: '$base/tab2',
      formId: '${prefix}_casenowise_form',
      fields: {'case_type': caseType, 'case_no': caseNo.trim(), 'diary_year': year.trim()},
    );
  }

  Future<List<AptelHit>> searchCauseList({
    required String mode,
    String diaryNo = '',
    String caseNo = '',
    String year = '',
    String caseType = '1',
    DateTime? from,
    DateTime? to,
  }) {
    if (mode == 'dfr') {
      return ajaxSearch(
        pageUrl: '$causeListUrl/tab2',
        formId: 'Dfrnowise_form',
        fields: {'diary_no': diaryNo.trim(), 'diary_year': year.trim()},
      );
    }
    if (mode == 'date') {
      return ajaxSearch(
        pageUrl: '$causeListUrl/tab4',
        formId: 'date_wise_form',
        fields: {'from_date': isoDate(from ?? DateTime.now()), 'to_date': isoDate(to ?? DateTime.now())},
      );
    }
    if (mode == 'case') {
      return ajaxSearch(
        pageUrl: '$causeListUrl/tab3',
        formId: 'casenowise_form',
        fields: {'case_type': caseType, 'case_no': caseNo.trim(), 'diary_year': year.trim()},
      );
    }
    return causeListToday();
  }

  Future<AptelCaseFile> caseDetails(String url) async {
    final html = await _get(url);
    return parseCaseFile(html);
  }

  Future<List<AptelHit>> displayBoard(int court) async {
    final html = await _get('$cis/display_board_court$court.php');
    final ajax = await _get('$cis/ajax/ajax_court$court.php');
    final fromAjax = _hitsFromHtml(ajax);
    if (fromAjax.isNotEmpty) return fromAjax;
    return _hitsFromHtml(html);
  }

  String? _formBuildId(String html, String formId) {
    final idx = html.indexOf('value="$formId"');
    if (idx < 0) return null;
    final chunk = html.substring(idx > 1200 ? idx - 1200 : 0, idx);
    return RegExp(r'name="form_build_id"[^>]*value="([^"]+)"').firstMatch(chunk)?.group(1) ??
        RegExp(r'value="(form-[^"]+)"').firstMatch(chunk)?.group(1);
  }

  List<AptelHit> _hitsFromAjax(String raw) {
    if (raw.trim().isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        final buf = StringBuffer();
        for (final cmd in decoded) {
          if (cmd is Map && cmd['command'] == 'insert') {
            buf.write(cmd['data'] ?? '');
          }
        }
        return _hitsFromHtml(buf.toString());
      }
    } catch (_) {}
    return _hitsFromHtml(raw);
  }

  List<AptelHit> _hitsFromHtml(String html) {
    final document = html_parser.parse(html);
    final out = <AptelHit>[];
    for (final table in document.querySelectorAll('table')) {
      final rows = _directRows(table);
      if (rows.isEmpty) continue;
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
        if (cells.every((e) => e.isEmpty) && row.querySelector('a[href]') == null) continue;
        final fields = <String, String>{};
        for (var i = 0; i < cells.length; i++) {
          final key = i < headers.length ? headers[i] : 'Col ${i + 1}';
          if (cells[i].isNotEmpty) fields[key] = cells[i];
        }
        String? fileUrl;
        String? detailUrl;
        for (final a in row.querySelectorAll('a[href]')) {
          final href = _abs(a.attributes['href'] ?? '');
          if (href.contains('gen_pdf') || href.toLowerCase().contains('.pdf')) {
            fileUrl = href;
          } else if (href.contains('caseapidetails')) {
            detailUrl = href;
          }
        }
        final title = fields['Case No'] ??
            fields['CASE No.'] ??
            fields['Case No.'] ??
            fields['DFR No'] ??
            fields['DFR No.'] ??
            fields['Listing Date'] ??
            fields['Item No'] ??
            (cells.length > 1 ? cells[1] : cells.first);
        final subtitle = [
          if ((fields['Party Detail'] ?? fields['PARTY DETAIL'] ?? '').isNotEmpty) fields['Party Detail'] ?? fields['PARTY DETAIL']!,
          if ((fields['Status'] ?? '').isNotEmpty) fields['Status']!,
          if ((fields['Court'] ?? fields['Court '] ?? '').isNotEmpty) fields['Court'] ?? fields['Court ']!,
          if ((fields['Listing Date'] ?? fields['Listing Date '] ?? '').isNotEmpty) fields['Listing Date'] ?? fields['Listing Date ']!,
        ].where((e) => e.trim().isNotEmpty).join('  ·  ');
        if (title.trim().isEmpty && fileUrl == null && detailUrl == null) continue;
        out.add(AptelHit(
          title: title.trim().isEmpty ? 'APTEL record' : title.trim(),
          subtitle: subtitle,
          fileUrl: fileUrl,
          detailUrl: detailUrl,
          fields: fields,
        ));
      }
    }
    return out;
  }

  static AptelCaseFile parseCaseFile(String html) {
    final document = html_parser.parse(html);
    final table = document.querySelector('.region-content table') ?? document.querySelector('table');
    final blocks = <AptelBlock>[];
    var title = 'Case status';
    var fields = <MapEntry<String, String>>[];
    void flush() {
      if (fields.isNotEmpty) {
        blocks.add(AptelBlock(title: title, fields: List.of(fields)));
        fields = [];
      }
    }

    if (table != null) {
      for (final row in _directRows(table)) {
        final tds = row.querySelectorAll('td');
        if (tds.isEmpty) continue;
        if (tds.length == 1 || (tds.first.attributes['colspan'] == '5')) {
          flush();
          title = _cell(tds.first);
          continue;
        }
        if (tds.length >= 2) {
          final key = _cell(tds.first);
          final value = tds.length > 2 ? _cell(tds[2]) : _cell(tds.last);
          if (key.isNotEmpty) fields.add(MapEntry(key, value));
        }
      }
      flush();
    }

    final files = <AptelHit>[];
    final seen = <String>{};
    for (final a in document.querySelectorAll('a[href]')) {
      final href = a.attributes['href'] ?? '';
      if (!(href.contains('gen_pdf') || href.toLowerCase().contains('.pdf'))) continue;
      final abs = _abs(href);
      if (!seen.add(abs)) continue;
      files.add(AptelHit(title: _cell(a).isEmpty ? 'Order / judgement PDF' : _cell(a), subtitle: 'cis.aptel.gov.in', fileUrl: abs));
    }
    return AptelCaseFile(blocks: blocks, files: files);
  }

  static String _abs(String href) {
    if (href.isEmpty || href.startsWith('javascript:')) return '';
    if (href.startsWith('http')) return href;
    return Uri.parse(host).resolve(href).toString();
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
