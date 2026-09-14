import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'api_exceptions.dart';
import 'config.dart';

Dio buildDio({String? Function()? tokenProvider}) {
  final dio = Dio(BaseOptions(
    baseUrl: apiBaseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
    headers: {'Content-Type':'application/json'},
    validateStatus: (s) => s != null && s < 500,
  ));
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (o,h) {
      final token=tokenProvider?.call(); if(token!=null) o.headers['Authorization']='Bearer $token';
      if(kDebugMode) debugPrint('[API] --> ${o.method} ${o.uri}');
      h.next(o);
    },
    onResponse: (r,h) {
      if(kDebugMode) debugPrint('[API] <-- ${r.statusCode} ${r.requestOptions.method} ${r.requestOptions.uri}');
      final s=r.statusCode??0;
      if(s>=400) return h.reject(DioException(requestOptions:r.requestOptions,response:r,type:DioExceptionType.badResponse,error:mapHttpError(s,r.data)),true);
      h.next(r);
    },
    onError: (e,h) { if(kDebugMode) debugPrint('[API] XX ${e.requestOptions.method} ${e.requestOptions.uri}: ${e.response?.statusCode ?? e.type}'); h.next(e); },
  ));
  return dio;
}
