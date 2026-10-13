import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:etribunals/core/utils/official_http.dart';
import 'package:intl/intl.dart';

class CatBench {
  final String id;
  final String name;

  const CatBench({required this.id, required this.name});
}

class CatSession {
  CatSession._();
  static final CatSession instance = CatSession._();
  CatBench? bench;
}

class CatClient {
  CatClient._() {
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

  static final CatClient instance = CatClient._();
  static const api = 'https://cgat.gov.in/catapi';
  static const site = 'https://cgat.gov.in/#/';

  final _dio = Dio();

  static const benches = [
    CatBench(id: '100', name: 'Principal Bench (Delhi)'),
    CatBench(id: '120', name: 'Ahmedabad'),
    CatBench(id: '330', name: 'Allahabad'),
    CatBench(id: '103', name: 'Bangalore'),
    CatBench(id: '60', name: 'Chandigarh'),
    CatBench(id: '310', name: 'Chennai'),
    CatBench(id: '260', name: 'Cuttack'),
    CatBench(id: '180', name: 'Ernakulam'),
    CatBench(id: '40', name: 'Guwahati'),
    CatBench(id: '21', name: 'Hyderabad'),
    CatBench(id: '200', name: 'Jabalpur'),
    CatBench(id: '291', name: 'Jaipur'),
    CatBench(id: '117', name: 'Jammu'),
    CatBench(id: '111', name: 'Jodhpur'),
    CatBench(id: '350', name: 'Kolkata'),
    CatBench(id: '332', name: 'Lucknow'),
    CatBench(id: '210', name: 'Mumbai'),
    CatBench(id: '116', name: 'Patna'),
    CatBench(id: '119', name: 'Srinagar'),
  ];

  static const caseTypes = [
    MapEntry('1', 'Original Application'),
    MapEntry('2', 'Transfer Application'),
    MapEntry('3', 'Misc Application'),
    MapEntry('4', 'Contempt Petition'),
    MapEntry('5', 'Petition for Transfer'),
    MapEntry('6', 'Review Application'),
    MapEntry('7', 'Criminal Contempt Petition'),
    MapEntry('8', 'OA Obj'),
  ];

  static const partyTypes = [
    MapEntry('1', 'Applicant'),
    MapEntry('2', 'Respondent'),
    MapEntry('3', 'Both'),
  ];

  static const courtNames = [
    MapEntry('6', 'Larger Bench'),
    MapEntry('3', 'Full Bench'),
    MapEntry('2', 'Division Bench'),
    MapEntry('1', 'Single Bench'),
    MapEntry('4', 'Registrar'),
    MapEntry('5', 'Chamber'),
    MapEntry('7', 'Notification Cause List'),
  ];

  String listingDate(DateTime date) => DateFormat('dd/MM/yyyy').format(date);

  Future<dynamic> post(String path, [Map<String, dynamic>? body]) async {
    final response = await _dio.post<dynamic>(
      '$api/$path',
      data: FormData.fromMap(body ?? const {}),
      options: Options(contentType: Headers.multipartFormDataContentType),
    );
    if (response.statusCode != null && response.statusCode! >= 400) {
      throw Exception('CAT request failed (${response.statusCode}).');
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
    throw Exception('Could not reach cgat.gov.in. Check the network and try again.');
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

  static String? documentUrl(Map<String, dynamic> row) {
    for (final key in ['dailyOrderPdf', 'finalOrderPdf', 'path', 'file', 'pdf', 'orderUrl']) {
      final v = '${row[key] ?? ''}'.trim();
      if (v.startsWith('http')) return v;
    }
    return null;
  }
}
