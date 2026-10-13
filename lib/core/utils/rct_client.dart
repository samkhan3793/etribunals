import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:etribunals/core/utils/official_http.dart';
import 'package:intl/intl.dart';

class RctBench {
  final int id;
  final String code;
  final String name;

  const RctBench({required this.id, required this.code, required this.name});
}

class RctCourt {
  final int no;
  final String label;

  const RctCourt({required this.no, required this.label});
}

class RctCaseType {
  final String code;
  final String name;

  const RctCaseType({required this.code, required this.name});
}

class RctCaseQuery {
  final String serial;
  final String? year;
  final String? benchCode;
  final String? typeCode;

  const RctCaseQuery({required this.serial, this.year, this.benchCode, this.typeCode});

  /// Official number looks like OA(IIu)/DLI/689/2026(DT). Search uses only 689.
  static RctCaseQuery parse(String raw) {
    var text = raw.trim().toUpperCase().replaceAll('\\', '/');
    text = text.replaceAll(RegExp(r'\s+'), '');
    final full = RegExp(
      r'OA\(?I{1,3}U?\)?/([A-Z]{2,5})/(\d{1,6})/(\d{4})',
    ).firstMatch(text);
    if (full != null) {
      return RctCaseQuery(
        serial: full.group(2)!,
        year: full.group(3),
        benchCode: full.group(1),
        typeCode: _typeFromPrefix(text),
      );
    }
    final slash = RegExp(r'^(\d{1,6})/(\d{4})$').firstMatch(text);
    if (slash != null) {
      return RctCaseQuery(serial: slash.group(1)!, year: slash.group(2));
    }
    final digits = RegExp(r'(\d{1,6})').firstMatch(text.replaceAll(RegExp(r'\(DT\)'), ''));
    return RctCaseQuery(serial: digits?.group(1) ?? raw.trim());
  }

  static String? _typeFromPrefix(String text) {
    if (text.contains('OA(IIU)') || text.contains('OA(IIU') || text.contains('IIU')) return '301';
    if (text.contains('OA(II)') || text.contains('OA(II/')) return '201';
    if (text.contains('OA(III)')) return '401';
    if (text.contains('OA(I)')) return '101';
    return null;
  }
}

class RctClient {
  RctClient._() {
    _dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient();
        client.badCertificateCallback = (cert, host, port) => true;
        return client;
      },
    );
    OfficialHttp.attachDio(_dio);
    _dio.options.headers['Accept'] = 'application/json, text/plain, */*';
    _dio.options.headers['Content-Type'] = 'application/json';
    _dio.options.validateStatus = (code) => code != null && code < 500;
  }

  static final RctClient instance = RctClient._();

  static const host = 'https://cis.erct.gov.in';
  static const api = '$host/rctapi/public/api/auth';
  static const files = '$host/rctapi/public/';
  static const guestLogin = '1 | 2 | 3';

  final _dio = Dio();

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async {
    final response = await _dio.post<dynamic>(
      '$api/$path',
      data: body,
    );
    final raw = response.data;
    Map<String, dynamic> json;
    if (raw is Map) {
      json = Map<String, dynamic>.from(raw);
    } else if (raw is String && raw.trim().isNotEmpty) {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        throw Exception('RCT did not return case data. Try again.');
      }
      json = Map<String, dynamic>.from(decoded);
    } else {
      throw Exception('Could not reach eRCT. Check the network and try again.');
    }
    if (response.statusCode != null && response.statusCode! >= 400) {
      throw Exception(_error(json) ?? 'eRCT request failed (${response.statusCode}).');
    }
    return json;
  }

  List<dynamic> _rows(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is List) return data;
    if (data is Map) return [data];
    return const [];
  }

  String? _error(Map<String, dynamic> json) {
    final error = json['error'];
    if (error is List && error.isNotEmpty) return error.map((e) => '$e').join('\n');
    final asText = error?.toString().trim();
    if (asText != null && asText.isNotEmpty) return asText;
    final message = json['message']?.toString().trim();
    if (message != null && message.isNotEmpty) return message;
    return null;
  }

  Future<List<RctBench>> benches() async {
    final json = await _post('getBenchLocations', {'login_id': guestLogin});
    return _rows(json).whereType<Map>().map((row) {
      return RctBench(
        id: int.tryParse('${row['id']}') ?? 0,
        code: '${row['railway_bench_code'] ?? ''}'.trim(),
        name: '${row['railway_bench_name'] ?? ''}'.trim(),
      );
    }).where((b) => b.id > 0 && b.code.isNotEmpty).toList();
  }

  Future<List<RctCourt>> courts(int benchId) async {
    final json = await _post('getCourtNos', {
      'bench_location': '$benchId',
      'login_id': guestLogin,
    });
    return _rows(json).whereType<Map>().map((row) {
      return RctCourt(
        no: int.tryParse('${row['court_no']}') ?? 0,
        label: '${row['court_description'] ?? 'Court'}'.trim(),
      );
    }).where((c) => c.no > 0).toList();
  }

  Future<List<RctCaseType>> caseTypes() async {
    final json = await _post('getCaseType', {'login_id': guestLogin});
    return _rows(json).whereType<Map>().map((row) {
      return RctCaseType(
        code: '${row['case_type_code'] ?? ''}',
        name: '${row['case_type_name'] ?? ''}'.trim(),
      );
    }).where((t) => t.code.isNotEmpty).toList();
  }

  Future<List<Map<String, dynamic>>> displayBoard({
    required int benchId,
    required int courtNo,
  }) async {
    final json = await _post('getDisplayBoardData', {
      'bench_location': '$benchId',
      'court_no': '$courtNo',
      'login_id': guestLogin,
    });
    final error = _error(json);
    if (error != null && _rows(json).isEmpty) throw Exception(error);
    return _maps(json);
  }

  Future<Map<String, dynamic>> causeList({
    required DateTime date,
    required int benchId,
    required int courtNo,
  }) async {
    final json = await _post('public_causelist', {
      'listing_date': DateFormat('yyyy-MM-dd').format(date),
      'court_no': '$courtNo',
      'bench_id': '$benchId',
    });
    final error = _error(json);
    final rows = _maps(json);
    if (error != null && rows.isEmpty) throw Exception(error);
    return json;
  }

  Future<Map<String, dynamic>> caseByFiling({
    required String locationCode,
    required String filingNo,
  }) {
    final value = filingNo.trim();
    if (value.isEmpty) {
      return Future.error(Exception('Enter a filing / e-reference number.'));
    }
    return _searchCase({
      'filing_no': value,
      'search_type': 'filing_no_wise',
      'location': locationCode,
      'case_no': '',
      'case_type': '',
      'case_year': '',
      'appl_case_type': '',
    });
  }

  Future<Map<String, dynamic>> caseByNumber({
    required String locationCode,
    required String caseNo,
    required String caseType,
    required String year,
  }) {
    if (caseNo.trim().isEmpty) {
      return Future.error(Exception('Enter the case number.'));
    }
    if (caseType.trim().isEmpty) {
      return Future.error(Exception('Select a case type.'));
    }
    return _searchCase({
      'filing_no': '',
      'search_type': 'case_no_wise',
      'location': locationCode,
      'case_no': caseNo.trim(),
      'case_type': caseType,
      'case_year': year,
      'appl_case_type': '',
    });
  }

  Future<Map<String, dynamic>> _searchCase(Map<String, dynamic> fields) async {
    final charset = 'ABCDEFGHJKLMNOPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz0123456789';
    final rand = Random();
    final captcha = List.generate(6, (_) => charset[rand.nextInt(charset.length)]).join();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final hash = sha512.convert(utf8.encode('$captcha$today')).toString();
    final json = await _post('getCaseDetailsPublic', {
      ...fields,
      'login_id': guestLogin,
      'captcha': hash,
    });
    final error = _error(json);
    if (error != null) throw Exception(error);
    if (_rows(json).isEmpty) {
      if (fields['search_type'] == 'case_no_wise') {
        throw Exception(
          'No case found for serial ${fields['case_no']} / ${fields['case_year']} at ${fields['location']}. '
          'From OA(IIu)/DLI/689/2026 enter 689, bench DLI, year 2026 and the matching Form II type.',
        );
      }
      throw Exception('No RCT case found for this filing number.');
    }
    return json;
  }

  static String orderPdfUrl(String filingNo, String fileName) {
    final file = fileName.trim();
    if (file.startsWith('http')) return file;
    return '${files}displayOrder/${filingNo.trim()}/$file';
  }

  static String? hashPdf(dynamic hash) {
    final value = hash?.toString().trim() ?? '';
    if (value.isEmpty || value == 'null') return null;
    if (value.startsWith('http')) return value;
    return '$files$value';
  }

  List<Map<String, dynamic>> _maps(Map<String, dynamic> json) {
    return _rows(json).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }
}
