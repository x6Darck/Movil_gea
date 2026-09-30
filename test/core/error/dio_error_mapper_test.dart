import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gea_app/core/error/dio_error_mapper.dart';

void main() {
  group('friendlyDioMessage', () {
    test('usa el mensaje del backend cuando el cuerpo lo trae (ej. 429)', () {
      final e = DioException(
        requestOptions: RequestOptions(path: '/x'),
        response: Response(
          requestOptions: RequestOptions(path: '/x'),
          statusCode: 429,
          data: {
            'success': false,
            'message': 'Has superado el limite de peticiones. Por favor espera un momento.',
          },
        ),
      );

      expect(
        friendlyDioMessage(e),
        'Has superado el limite de peticiones. Por favor espera un momento.',
      );
    });

    test('devuelve un mensaje de límite de peticiones en 429 sin cuerpo parseable', () {
      final e = DioException(
        requestOptions: RequestOptions(path: '/x'),
        response: Response(
          requestOptions: RequestOptions(path: '/x'),
          statusCode: 429,
          data: 'texto plano no json',
        ),
      );

      expect(friendlyDioMessage(e), contains('límite de peticiones'));
    });

    test('devuelve un mensaje de conectividad cuando no hay respuesta del servidor', () {
      final e = DioException(
        requestOptions: RequestOptions(path: '/x'),
        type: DioExceptionType.connectionTimeout,
      );

      expect(friendlyDioMessage(e), contains('conexión'));
    });

    test('usa el fallback provisto cuando no hay mensaje del backend ni caso especial', () {
      final e = DioException(
        requestOptions: RequestOptions(path: '/x'),
        response: Response(
          requestOptions: RequestOptions(path: '/x'),
          statusCode: 500,
          data: {'success': false},
        ),
      );

      expect(
        friendlyDioMessage(e, fallback: 'Mensaje de respaldo'),
        'Mensaje de respaldo',
      );
    });

    test('nunca devuelve el mensaje técnico crudo de Dio', () {
      final e = DioException(
        requestOptions: RequestOptions(path: '/x'),
        response: Response(
          requestOptions: RequestOptions(path: '/x'),
          statusCode: 500,
        ),
        message: 'Http status error [500]',
      );

      final result = friendlyDioMessage(e, fallback: 'Mensaje amigable');
      expect(result, isNot(contains('Http status error')));
      expect(result, 'Mensaje amigable');
    });
  });
}
