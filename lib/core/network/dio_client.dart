import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'interceptors/auth_interceptor.dart';
import '../config/app_config.dart';

class DioClient {
  // En web el proxy Node/nginx reenvía /api al backend local.
  // En móvil se usa la URL configurada vía --dart-define.
  static String get baseUrl => kIsWeb ? '/api' : AppConfig.apiBaseUrl;

  final Dio dio;

  DioClient(this.dio, FlutterSecureStorage storage) {
    dio
      ..options.baseUrl = baseUrl
      ..options.connectTimeout = const Duration(seconds: 15)
      ..options.receiveTimeout = const Duration(seconds: 15)
      ..options.headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      }
      ..interceptors.add(AuthInterceptor(storage));
    // LogInterceptor solo en debug para no exponer datos en prod
    assert(() {
      dio.interceptors.add(LogInterceptor(
        requestHeader: false,
        requestBody: true,
        responseHeader: false,
        responseBody: true,
        error: true,
      ));
      return true;
    }());
  }
}
