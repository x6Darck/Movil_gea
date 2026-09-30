import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../session_expired_notifier.dart';

class AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _storage;

  AuthInterceptor(this._storage);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    try {
      // Timeout de 5s: si el Keystore de Android tarda, no colgamos toda la petición
      final token = await _storage
          .read(key: 'jwt_token')
          .timeout(const Duration(seconds: 5), onTimeout: () => null);
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    } catch (e) {
      // Si falla la lectura del token (ej. Keystore bloqueado), continuar sin auth.
      // El servidor rechazará la petición si el endpoint requiere autenticación.
      assert(() { debugPrint('[AuthInterceptor] Error leyendo token del Keystore: ${e.runtimeType}'); return true; }());
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    try {
      if (err.response?.statusCode == 401) {
        await _storage
            .delete(key: 'jwt_token')
            .timeout(const Duration(seconds: 5), onTimeout: () {});
        SessionExpiredNotifier.instance.notify();
      }
    } catch (_) {
      // Si falla la limpieza del token, continuar propagando el error
    }
    handler.next(err);
  }
}
