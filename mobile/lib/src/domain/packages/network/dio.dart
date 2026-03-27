import 'package:dio/dio.dart';

class ApiClient {
  final Dio _dio;

  static const String baseUrl = "http://localhost:8080";

  ApiClient({Dio? dio}) : _dio = dio ?? Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      contentType: 'application/json',
    )) {
    _dio.interceptors.add(LogInterceptor(responseBody: true, requestBody: true));
  }

  Dio get dio => _dio;
}
