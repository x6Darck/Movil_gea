import 'package:flutter_test/flutter_test.dart';
import 'package:gea_app/features/announcements/data/models/announcement_request_model.dart';
import 'package:gea_app/features/announcements/domain/entities/request_status.dart';

void main() {
  group('AnnouncementRequestModel.fromJson', () {
    test('mapea una solicitud rechazada con motivo', () {
      final json = {
        'id': 42,
        'titulo': 'Mi anuncio',
        'descripcion': 'Contenido',
        'categoria': 'Cultural',
        'estado': 'RECHAZADA',
        'motivoRechazo': 'La imagen no cumple el formato',
        'observacionesRevision': null,
        'correoContacto': 'a@b.co',
        'responsableAnuncio': 'Ana',
        'fechaInicioPublicacion': '2026-07-01',
        'fechaFinPublicacion': '2026-07-10',
        'horaInicio': '08:00:00',
        'horaFin': '10:00:00',
        'piezaGraficaUrl': '/uploads/x.png',
        'requierePiezaGrafica': false,
        'idsLugaresFisicos': [3, 7],
        'lugares': ['Plaza', 'Auditorio'],
        'fechaCreacion': '2026-06-20T09:30:00',
      };

      final r = AnnouncementRequestModel.fromJson(json);

      expect(r.id, 42);
      expect(r.title, 'Mi anuncio');
      expect(r.status, RequestStatus.rechazada);
      expect(r.rejectionReason, 'La imagen no cumple el formato');
      expect(r.reviewNotes, isNull);
      expect(r.fechaInicioPublicacion, DateTime(2026, 7, 1));
      expect(r.horaInicio, '08:00:00');
      expect(r.idsLugaresFisicos, [3, 7]);
      expect(r.lugares, ['Plaza', 'Auditorio']);
    });

    test('mapea una en revisión con observaciones y tolera campos ausentes', () {
      final json = {
        'id': 5,
        'titulo': 'Otro',
        'descripcion': 'X',
        'estado': 'EN_REVISION',
        'observacionesRevision': 'Corrige las fechas',
      };

      final r = AnnouncementRequestModel.fromJson(json);

      expect(r.status, RequestStatus.enRevision);
      expect(r.reviewNotes, 'Corrige las fechas');
      expect(r.category, isNull);
      expect(r.idsLugaresFisicos, isEmpty);
      expect(r.lugares, isEmpty);
      expect(r.fechaInicioPublicacion, isNull);
    });
  });
}
