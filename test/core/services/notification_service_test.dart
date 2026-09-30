import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gea_app/core/services/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationService.computePollingDelay', () {
    test('siempre devuelve una duración entre 70 y 110 segundos', () {
      for (var i = 0; i < 200; i++) {
        final delay = NotificationService.computePollingDelay();
        expect(delay.inMilliseconds, greaterThanOrEqualTo(70000));
        expect(delay.inMilliseconds, lessThanOrEqualTo(110000));
      }
    });

    test('no siempre devuelve el mismo valor (hay jitter real)', () {
      final delays = {
        for (var i = 0; i < 20; i++) NotificationService.computePollingDelay().inMilliseconds,
      };
      expect(delays.length, greaterThan(1));
    });
  });

  group('NotificationService pausa/reanudación en segundo plano', () {
    late Dio dio;

    setUp(() {
      // Dio que rechaza toda petición sincrónicamente, sin tocar la red real:
      // el objetivo de este grupo es la lógica de programación del timer
      // (pausa/reanudación), no el resultado de la llamada HTTP en sí.
      dio = Dio(BaseOptions(baseUrl: 'http://gea.test'));
      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) => handler.reject(
          DioException(requestOptions: options, type: DioExceptionType.connectionError),
          true,
        ),
      ));
    });

    tearDown(() {
      NotificationService().dispose();
    });

    test('el sondeo está activo tras init()', () {
      NotificationService().init(dio);

      expect(NotificationService().isPolling, isTrue);
    });

    test('pausePolling() detiene el sondeo', () {
      NotificationService().init(dio);

      NotificationService().pausePolling();

      expect(NotificationService().isPolling, isFalse);
    });

    test('resumePolling() reactiva el sondeo tras una pausa', () {
      NotificationService().init(dio);
      NotificationService().pausePolling();

      NotificationService().resumePolling(dio);

      expect(NotificationService().isPolling, isTrue);
    });
  });
}
