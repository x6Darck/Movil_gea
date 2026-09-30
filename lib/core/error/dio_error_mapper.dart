import 'package:dio/dio.dart';

/// Convierte un [DioException] en un mensaje apto para mostrar al usuario.
///
/// Orden de prioridad:
/// 1. El mensaje que ya mandó el backend en el cuerpo de la respuesta
///    (siempre en español y pensado para el usuario final — el backend lo
///    manda incluso en 429, ver `RateLimiterFilter`).
/// 2. Si no hubo respuesta del servidor (timeout, sin internet): mensaje de
///    conectividad.
/// 3. Si es 429 sin cuerpo parseable: mensaje fijo de límite de peticiones.
/// 4. [fallback] provisto por el llamador.
///
/// Nunca devuelve `e.message`/`e.toString()` crudos — son técnicos, en
/// inglés, y no deben llegar a la UI (ej. "DioException [bad response]:
/// The request returned an invalid status code of 429").
String friendlyDioMessage(
  DioException e, {
  String fallback = 'Ocurrió un error inesperado. Intenta de nuevo.',
}) {
  final backendMessage = _extractBackendMessage(e);
  if (backendMessage != null) return backendMessage;

  if (e.response == null) {
    return 'No se pudo contactar el servidor. Revisa tu conexión e intenta de nuevo.';
  }

  if (e.response?.statusCode == 429) {
    return 'Has superado el límite de peticiones. Espera un momento e intenta de nuevo.';
  }

  return fallback;
}

String? _extractBackendMessage(DioException e) {
  final data = e.response?.data;
  if (data is Map && data['message'] is String) {
    final msg = data['message'] as String;
    return msg.isNotEmpty ? msg : null;
  }
  return null;
}
