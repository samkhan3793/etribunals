import 'dart:async';

import 'package:dio/dio.dart';

class OfficialHttp {
  static const userAgent =
      'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 Chrome/124.0.0.0 Mobile Safari/537.36';

  static void attachDio(Dio dio) {
    dio.options.connectTimeout = const Duration(seconds: 20);
    dio.options.receiveTimeout = const Duration(seconds: 45);
    dio.options.sendTimeout = const Duration(seconds: 20);
    dio.interceptors.insert(
      0,
      InterceptorsWrapper(
        onError: (err, handler) async {
          final retryable = err.type == DioExceptionType.connectionTimeout ||
              err.type == DioExceptionType.receiveTimeout ||
              err.type == DioExceptionType.sendTimeout ||
              err.type == DioExceptionType.connectionError;
          final retried = err.requestOptions.extra['officialRetry'] == true;
          if (retryable && !retried) {
            err.requestOptions.extra['officialRetry'] = true;
            try {
              return handler.resolve(await dio.fetch(err.requestOptions));
            } catch (e) {
              if (e is DioException) return handler.next(e);
            }
          }
          handler.next(err);
        },
      ),
    );
  }

  static String friendly(Object error, [String site = 'Official site']) {
    if (error is TimeoutException) {
      return '$site is slow. Try again.';
    }
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.sendTimeout:
          return '$site is slow. Try again.';
        case DioExceptionType.connectionError:
          return 'No connection to $site. Check internet and try again.';
        default:
          final code = error.response?.statusCode;
          if (code != null && code >= 500) {
            return '$site may have changed this page. Try again later.';
          }
          if (code == 404) {
            return '$site did not find this page. Try another search.';
          }
      }
    }
    final text = '$error'.toLowerCase();
    if (text.contains('timed out') || text.contains('timeout')) {
      return '$site is slow. Try again.';
    }
    if (text.contains('socket') || text.contains('network') || text.contains('failed host')) {
      return 'No connection to $site. Check internet and try again.';
    }
    return '$site could not load. Try again.';
  }
}
