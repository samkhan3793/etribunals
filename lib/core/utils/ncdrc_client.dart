import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:etribunals/core/utils/official_http.dart';
import 'package:intl/intl.dart';

class NcdrcHit {
  final String caseNumber;
  final String complainant;
  final String respondent;
  final String stage;
  final String filingDate;
  final String orderDate;
  final String disposalDate;
  final String hearingDate;
  final String judgementDate;
  final String filingRef;
  final String? judgementHtml;
  final bool dailyOrder;
  final Map<String, String> fields;

  const NcdrcHit({
    required this.caseNumber,
    required this.complainant,
    required this.respondent,
    required this.stage,
    required this.filingDate,
    required this.orderDate,
    required this.disposalDate,
    required this.hearingDate,
    required this.judgementDate,
    required this.filingRef,
    this.judgementHtml,
    this.dailyOrder = false,
    this.fields = const {},
  });

  String get parties => [complainant, if (respondent.isNotEmpty) 'v. $respondent'].join(' ');
  String get subtitle => [if (stage.isNotEmpty) stage, if (filingDate.isNotEmpty) 'filed $filingDate'].join('  ·  ');
  bool get hasJudgement => (judgementHtml ?? '').trim().isNotEmpty;
}

class NcdrcBoardRow {
  final String bench;
  final String item;
  const NcdrcBoardRow({required this.bench, required this.item});
}

class NcdrcClient {
  NcdrcClient._() {
    _dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient();
        client.badCertificateCallback = (cert, host, port) => true;
        return client;
      },
    );
    OfficialHttp.attachDio(_dio);
    _dio.options.validateStatus = (code) => code != null && code < 500;
    _dio.options.headers['User-Agent'] =
        'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 Chrome/124.0.0.0 Mobile Safari/537.36';
    _dio.options.headers['Accept'] = 'application/json';
    _dio.options.headers['Origin'] = 'https://e-jagriti.gov.in';
    _dio.options.headers['Referer'] = 'https://e-jagriti.gov.in/';
  }

  static final NcdrcClient instance = NcdrcClient._();
  static const host = 'https://e-jagriti.gov.in';
  static const services = '$host/services';
  static const searchUrl = '$host/advance-case-search';
  static const causeListUrl = '$host/cause-list';
  static const ncdrcId = 11000000;
  /// e-Jagriti: 1 = daily order listing, 2 = judgement listing.
  static const orderDaily = 1;
  static const orderJudgement = 2;
  /// e-Jagriti: 1 = case filing date, 2 = hearing / disposal / order date.
  static const byFilingDate = 1;
  static const byHearingDate = 2;

  final Dio _dio = Dio();
  String apiDate(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  Future<List<NcdrcHit>> searchByCaseNumber(String caseNumber) {
    return _search({
      'commissionId': ncdrcId,
      'page': 0,
      'size': 40,
      'dateRequestType': 0,
      'serchType': 1,
      'serchTypeValue': caseNumber.trim(),
      'judgeId': '',
      'orderType': 2,
    });
  }

  Future<List<NcdrcHit>> searchByParty(String party, DateTime from, DateTime to) {
    return _search({
      'commissionId': ncdrcId,
      'page': 0,
      'size': 40,
      'fromDate': apiDate(from),
      'toDate': apiDate(to),
      'dateRequestType': byHearingDate,
      'serchType': 3,
      'serchTypeValue': party.trim(),
      'judgeId': '',
      'orderType': 2,
    });
  }

  Future<List<NcdrcHit>> searchByDate(
    DateTime from,
    DateTime to, {
    int orderType = orderJudgement,
    int dateRequestType = byHearingDate,
  }) {
    return _search({
      'commissionId': ncdrcId,
      'page': 0,
      'size': 80,
      'fromDate': apiDate(from),
      'toDate': apiDate(to),
      'dateRequestType': dateRequestType,
      'serchType': 2,
      'serchTypeValue': '',
      'judgeId': '',
      'orderType': orderType,
    });
  }

  Future<List<NcdrcHit>> causeList(DateTime from, DateTime to) async {
    final a = await searchByDate(from, to, orderType: orderDaily);
    final b = await searchByDate(from, to, orderType: orderJudgement);
    final seen = <String>{};
    final out = <NcdrcHit>[];
    for (final row in [...a, ...b]) {
      final key = '${row.caseNumber}|${row.hearingDate}|${row.orderDate}|${row.judgementDate}';
      if (seen.add(key)) out.add(row);
    }
    return out;
  }

  Future<Uint8List> orderPdf({
    required String filingRef,
    required String hearingDate,
    int orderTypeId = orderDaily,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '$services/courtmaster/courtRoom/judgement/v1/getDailyOrderJudgementPdf',
      queryParameters: {
        'filingReferenceNumber': filingRef,
        'dateOfHearing': hearingDate,
        'orderTypeId': orderTypeId,
      },
    );
    final body = res.data ?? const {};
    final data = body['data'];
    final raw = data is Map ? data['dailyOrderPdf'] : null;
    if (raw is! String || raw.trim().isEmpty) {
      throw Exception('${body['message'] ?? 'NCDRC order PDF is not available.'}');
    }
    if (raw.contains('<html')) {
      throw Exception('html:$raw');
    }
    return base64Decode(raw.replaceAll(RegExp(r'\s'), ''));
  }

  Future<Map<String, dynamic>> caseStatus(String caseNumber) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '$services/case/caseFilingService/v2/getCaseStatus',
      queryParameters: {'caseNumber': caseNumber.trim()},
      options: Options(contentType: Headers.jsonContentType),
    );
    final body = res.data ?? const {};
    if (res.statusCode != 200 || body['error'] == 'true' || body['error'] == true) {
      throw Exception('${body['message'] ?? 'NCDRC case status is not available.'}');
    }
    final data = body['data'];
    if (data is Map<String, dynamic>) return data;
    throw Exception('NCDRC case status is not available.');
  }

  Future<List<NcdrcBoardRow>> displayBoard() async {
    final res = await _dio.get<Map<String, dynamic>>(
      '$services/case/caseFilingService/v2/getDisplayBoardByCommissionId',
      queryParameters: {'commissionId': ncdrcId},
    );
    final body = res.data ?? const {};
    final data = body['data'];
    final rows = <NcdrcBoardRow>[];
    void add(dynamic item) {
      if (item is! Map) return;
      rows.add(NcdrcBoardRow(bench: '${item['benchnumber'] ?? ''}', item: '${item['itemnumber'] ?? ''}'));
    }

    if (data is List) {
      for (final group in data) {
        if (group is List) {
          for (final item in group) {
            add(item);
          }
        } else {
          add(group);
        }
      }
    }
    return rows;
  }

  Future<List<NcdrcHit>> _search(Map<String, dynamic> payload) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '$services/case/caseFilingService/v2/getCaseDetailsBySearchType',
      data: payload,
      options: Options(contentType: Headers.jsonContentType),
    );
    final body = res.data ?? const {};
    if (res.statusCode != 200 || body['error'] == 'true' || body['error'] == true) {
      throw Exception('${body['message'] ?? 'NCDRC search failed.'}');
    }
    final data = body['data'];
    if (data is! List) return const [];
    return [for (final row in data) if (row is Map) _hit(row)];
  }

  NcdrcHit _hit(Map row) {
    String s(String k) {
      final v = row[k];
      if (v == null) return '';
      return '$v'.trim();
    }

    final extra = <String>[];
    final addR = row['additionalRespondantList'];
    if (addR is List) {
      for (final item in addR) {
        if (item is Map) {
          final n = '${item['additional_respondent_name'] ?? ''}'.trim();
          if (n.isNotEmpty) extra.add(n);
        }
      }
    }
    final respondent = [s('respondentName'), if (extra.isNotEmpty) extra.join(', ')].where((e) => e.isNotEmpty).join('; ');
    final html = s('judgmentOrderDocumentBase64');
    final altHtml = s('documentBase64');
    final body = html.isNotEmpty ? html : (altHtml.contains('<html') ? altHtml : '');
    final fields = <String, String>{
      'Case number': s('caseNumber'),
      'Complainant': s('complainantName'),
      'Complainant advocate': s('complainantAdvocateName'),
      'Respondent': respondent,
      'Respondent advocate': s('respondentAdvocateName'),
      'Stage': s('caseStageName'),
      'Filing date': s('caseFilingDate'),
      'Hearing date': s('dateOfHearing'),
      'Order date': s('orderDate'),
      'Disposal date': s('dateOfDisposal'),
      'Judgement date': s('judgemtmentDate'),
      'Filing reference': s('filingReferenceNumber'),
    }..removeWhere((_, v) => v.isEmpty);

    return NcdrcHit(
      caseNumber: s('caseNumber'),
      complainant: s('complainantName'),
      respondent: respondent,
      stage: s('caseStageName'),
      filingDate: s('caseFilingDate'),
      orderDate: s('orderDate'),
      disposalDate: s('dateOfDisposal'),
      hearingDate: s('dateOfHearing'),
      judgementDate: s('judgemtmentDate'),
      filingRef: s('filingReferenceNumber'),
      judgementHtml: body.isEmpty ? null : body,
      dailyOrder: row['dailyOrderStatus'] == true,
      fields: fields,
    );
  }
}
