import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:gea_app/features/calendar/data/datasources/pinned_event_remote_datasource.dart';
import 'pinned_event_repository_test.mocks.dart';

@GenerateMocks([Dio])
void main() {
  group('PinnedEventRemoteDatasource', () {
    late MockDio mockDio;
    late PinnedEventRemoteDatasource datasource;

    setUp(() {
      mockDio = MockDio();
      datasource = PinnedEventRemoteDatasource(mockDio);
    });

    test('getPinnedEvents returns list on 200', () async {
      when(mockDio.get('/app/eventos/fijados')).thenAnswer(
        (_) async => Response(
          data: {'data': []},
          statusCode: 200,
          requestOptions: RequestOptions(path: '/app/eventos/fijados'),
        ),
      );

      final result = await datasource.getPinnedEvents();
      expect(result, isEmpty);
    });

    test('pinEvent calls POST with correct path', () async {
      when(mockDio.post('/app/eventos/fijados/123')).thenAnswer(
        (_) async => Response(
          data: {},
          statusCode: 200,
          requestOptions: RequestOptions(path: '/app/eventos/fijados/123'),
        ),
      );

      await datasource.pinEvent('123');
      verify(mockDio.post('/app/eventos/fijados/123')).called(1);
    });

    test('unpinEvent calls DELETE with correct path', () async {
      when(mockDio.delete('/app/eventos/fijados/123')).thenAnswer(
        (_) async => Response(
          data: {},
          statusCode: 200,
          requestOptions: RequestOptions(path: '/app/eventos/fijados/123'),
        ),
      );

      await datasource.unpinEvent('123');
      verify(mockDio.delete('/app/eventos/fijados/123')).called(1);
    });
  });
}
