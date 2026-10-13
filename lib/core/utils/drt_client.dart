import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:etribunals/core/utils/official_http.dart';
import 'package:intl/intl.dart';

class DrtLocation {
  final String id;
  final String name;
  final bool isDrat;

  const DrtLocation({required this.id, required this.name, required this.isDrat});
}

class DrtCaseType {
  final String id;
  final String name;

  const DrtCaseType({required this.id, required this.name});
}

class DrtClient {
  DrtClient._() {
    _dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient();
        client.badCertificateCallback = (cert, host, port) => true;
        return client;
      },
    );
    OfficialHttp.attachDio(_dio);
    _dio.options.headers['Accept'] = 'application/json, text/plain, */*';
    _dio.options.validateStatus = (code) => code != null && code < 500;
  }

  static final DrtClient instance = DrtClient._();
  static const api = 'https://drt.gov.in/drtapi';
  static const site = 'https://drt.gov.in/#/';

  final _dio = Dio();

  String listingDate(DateTime date) => DateFormat('dd/MM/yyyy').format(date);

  Future<dynamic> _post(String path, [Map<String, dynamic>? body]) async {
    final response = await _dio.post<dynamic>(
      '$api/$path',
      data: FormData.fromMap(body ?? const {}),
      options: Options(contentType: Headers.multipartFormDataContentType),
    );
    if (response.statusCode != null && response.statusCode! >= 400) {
      throw Exception('DRT request failed (${response.statusCode}).');
    }
    return _decode(response.data);
  }

  dynamic _decode(dynamic raw) {
    if (raw is Map || raw is List) return raw;
    if (raw is String && raw.trim().isNotEmpty) {
      try {
        return jsonDecode(raw);
      } catch (_) {
        throw Exception(raw.trim());
      }
    }
    throw Exception('Could not reach drt.gov.in. Check the network and try again.');
  }

  Never _fail(dynamic data, String fallback) {
    if (data is Map) {
      final status = data['status']?.toString().trim();
      if (status != null && status.isNotEmpty && status.toLowerCase() != 'false') {
        throw Exception(status);
      }
      final message = data['message']?.toString().trim();
      if (message != null && message.isNotEmpty) throw Exception(message);
    }
    throw Exception(fallback);
  }

  List<Map<String, dynamic>> asRows(dynamic data, {String empty = 'No record found.'}) {
    if (data is List) {
      final rows = data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      if (rows.isEmpty) throw Exception(empty);
      return rows;
    }
    if (data is Map) {
      if (data['status'] != null && data.length <= 2 && data['caseno'] == null && data['diaryno'] == null) {
        _fail(data, empty);
      }
      return [Map<String, dynamic>.from(data)];
    }
    throw Exception(empty);
  }

  Future<List<DrtLocation>> locations() async {
    final data = await _post('getDrtDratScheamName');
    if (data is! List) _fail(data, 'Could not load DRT / DRAT list.');
    return data.whereType<Map>().map((row) {
      final id = '${row['schemeNameDrtId'] ?? ''}'.trim();
      final n = int.tryParse(id) ?? 0;
      return DrtLocation(
        id: id,
        name: '${row['SchemaName'] ?? ''}'.replaceAll('\r\n', ' ').trim(),
        isDrat: n >= 100,
      );
    }).where((e) => e.id.isNotEmpty && e.name.isNotEmpty).toList();
  }

  Future<List<DrtCaseType>> caseTypes(String schemeId) async {
    final data = await _post('getDrtDratCaseTyepName', {'schemeNameDrtId': schemeId});
    if (data is! List) return const [];
    return data.whereType<Map>().map((row) {
      return DrtCaseType(
        id: '${row['caseType'] ?? row['caseTypeId'] ?? ''}'.trim(),
        name: '${row['caseTypeName'] ?? ''}'.trim(),
      );
    }).where((e) => e.id.isNotEmpty).toList();
  }

  Future<Map<String, dynamic>> diaryWise({required String schemeId, required String diaryNo, required String year, required bool drat}) async {
    final data = await _post(drat ? 'getDratCaseDetailDiaryNoWise' : 'getCaseDetailDiaryNoWise', {
      'schemeNameDrtId': schemeId,
      'diaryNo': diaryNo.trim(),
      'diaryYear': year,
    });
    return asRows(data, empty: 'No DRT case for this diary number.').first;
  }

  Future<Map<String, dynamic>> caseNoWise({
    required String schemeId,
    required String caseType,
    required String caseNo,
    required String year,
    required bool drat,
  }) async {
    final data = await _post(drat ? 'getDratCaseDetailCaseNoWise' : 'getCaseDetailCaseNoWise', {
      'schemeNameDrtId': schemeId,
      'casetypeId': caseType,
      'caseNo': caseNo.trim(),
      'caseYear': year,
    });
    return asRows(data, empty: 'No DRT case for this case number.').first;
  }

  Future<List<Map<String, dynamic>>> partyWise({required String schemeId, required String party, required bool drat}) async {
    final data = await _post(drat ? 'drat_party_name_wise' : 'casedetail_party_name_wise', {
      'schemeNameDratDrtId': schemeId,
      'partyName': party.trim().toUpperCase(),
    });
    return asRows(data, empty: 'No cases for this party name.');
  }

  Future<Map<String, dynamic>?> moreParty({required String schemeId, required String filingNo}) async {
    if (filingNo.trim().isEmpty) return null;
    final data = await _post('getCaseDetailPartyWise', {
      'schemeNameDrtId': schemeId,
      'filingNo': filingNo.trim(),
    });
    if (data is Map) return Map<String, dynamic>.from(data);
    return null;
  }

  Future<List<Map<String, dynamic>>> courtNames({required String schemeId, required DateTime date}) async {
    final data = await _post('getCourtName', {
      'schemeNameDrtId': schemeId,
      'listingDate': listingDate(date),
    });
    return asRows(data, empty: 'No court sitting on this date.');
  }

  Future<List<Map<String, dynamic>>> courtNos({
    required String schemeId,
    required DateTime date,
    required String courtNameId,
  }) async {
    final data = await _post('getDrtDratCourtNo', {
      'schemeNameDrtId': schemeId,
      'listingDate': listingDate(date),
      'courtNameId': courtNameId,
    });
    if (data is List) {
      return data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }
    if (data is Map) return [Map<String, dynamic>.from(data)];
    return const [];
  }

  Future<Map<String, dynamic>> causeList({
    required String schemeId,
    required DateTime date,
    required String courtNameId,
    required String courtNo,
    required String kind,
  }) async {
    final path = kind == 'drat'
        ? 'getDratCauselistReport'
        : kind == 'rc'
            ? 'getRcCauselistReport'
            : 'getDrtCauselistReport';
    final data = await _post(path, {
      'schemeNameDrtId': schemeId,
      'causeListDate': listingDate(date),
      'courtNameId': courtNameId,
      'courtNo': courtNo,
    });
    if (data is Map) return Map<String, dynamic>.from(data);
    _fail(data, 'No cause list for this sitting.');
  }

  Future<List<Map<String, dynamic>>> report(String path, Map<String, dynamic> body, {String empty = 'No orders found.'}) async {
    final data = await _post(path, body);
    return asRows(data, empty: empty);
  }
}
