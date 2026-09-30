import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:gea_app/core/services/offline_cache_service.dart';
import 'package:gea_app/features/announcements/data/repositories/announcement_repository_impl.dart';
import 'package:gea_app/features/announcements/domain/entities/request_status.dart';
import 'announcement_request_repository_test.mocks.dart';

@GenerateMocks([Dio, OfflineCacheService])
void main() {
  late MockDio mockDio;
  late MockOfflineCacheService mockCache;
  late AnnouncementRepositoryImpl repo;

  setUp(() {
    mockDio = MockDio();
    mockCache = MockOfflineCacheService();
    repo = AnnouncementRepositoryImpl(mockDio, mockCache);
  });

  test('getMyRequests devuelve la lista mapeada en 200', () async {
    when(mockDio.get('/app/solicitudes-anuncio/mis-solicitudes')).thenAnswer(
      (_) async => Response(
        data: {
          'data': [
            {
              'id': 1,
              'titulo': 'A',
              'descripcion': 'X',
              'estado': 'EN_REVISION',
              'observacionesRevision': 'Corrige',
            }
          ]
        },
        statusCode: 200,
        requestOptions: RequestOptions(path: '/app/solicitudes-anuncio/mis-solicitudes'),
      ),
    );

    final result = await repo.getMyRequests();

    expect(result.isRight(), isTrue);
    final list = result.getOrElse((_) => []);
    expect(list, hasLength(1));
    expect(list.first.status, RequestStatus.enRevision);
    expect(list.first.reviewNotes, 'Corrige');
  });

  test('getMyRequests devuelve el mensaje amigable del backend en 429', () async {
    when(mockDio.get('/app/solicitudes-anuncio/mis-solicitudes')).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/app/solicitudes-anuncio/mis-solicitudes'),
        response: Response(
          requestOptions: RequestOptions(path: '/app/solicitudes-anuncio/mis-solicitudes'),
          statusCode: 429,
          data: {
            'success': false,
            'message': 'Has superado el limite de peticiones. Por favor espera un momento.',
          },
        ),
      ),
    );

    final result = await repo.getMyRequests();

    expect(result.isLeft(), isTrue);
    result.match(
      (failure) => expect(
        failure.message,
        'Has superado el limite de peticiones. Por favor espera un momento.',
      ),
      (_) => fail('esperaba Left'),
    );
  });

  test('updateRequest hace PUT al id correcto y devuelve Right(null)', () async {
    when(mockDio.put('/app/solicitudes-anuncio/9', data: anyNamed('data'))).thenAnswer(
      (_) async => Response(
        data: {'success': true},
        statusCode: 200,
        requestOptions: RequestOptions(path: '/app/solicitudes-anuncio/9'),
      ),
    );

    final result = await repo.updateRequest(
      id: 9,
      title: 'Editado',
      description: 'Nuevo',
      category: 'Cultural',
      correoContacto: 'a@b.co',
      responsableAnuncio: 'Ana',
      fechaInicioPublicacion: DateTime(2026, 7, 1),
      fechaFinPublicacion: DateTime(2026, 7, 10),
      horaInicio: const TimeOfDay(hour: 8, minute: 0),
      horaFin: const TimeOfDay(hour: 10, minute: 0),
      requierePiezaGrafica: false,
      piezaGraficaUrl: '/uploads/x.png',
      idsLugaresFisicos: const [3],
    );

    expect(result.isRight(), isTrue);
    verify(mockDio.put('/app/solicitudes-anuncio/9', data: anyNamed('data'))).called(1);
  });
}
