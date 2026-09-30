import 'package:flutter_test/flutter_test.dart';
import 'package:gea_app/features/announcements/domain/entities/request_status.dart';

void main() {
  group('RequestStatus.fromBackend', () {
    test('mapea cada string del backend a su enum', () {
      expect(RequestStatus.fromBackend('PENDIENTE'), RequestStatus.pendiente);
      expect(RequestStatus.fromBackend('APROBADA'), RequestStatus.aprobada);
      expect(RequestStatus.fromBackend('RECHAZADA'), RequestStatus.rechazada);
      expect(RequestStatus.fromBackend('PUBLICADA'), RequestStatus.publicada);
      expect(RequestStatus.fromBackend('EN_REVISION'), RequestStatus.enRevision);
    });

    test('valor desconocido o nulo cae a pendiente', () {
      expect(RequestStatus.fromBackend('OTRA_COSA'), RequestStatus.pendiente);
      expect(RequestStatus.fromBackend(null), RequestStatus.pendiente);
    });
  });

  group('RequestStatus.isEditable', () {
    test('solo EN_REVISION es editable', () {
      expect(RequestStatus.enRevision.isEditable, isTrue);
      expect(RequestStatus.rechazada.isEditable, isFalse);
      expect(RequestStatus.pendiente.isEditable, isFalse);
      expect(RequestStatus.aprobada.isEditable, isFalse);
      expect(RequestStatus.publicada.isEditable, isFalse);
    });
  });
}
