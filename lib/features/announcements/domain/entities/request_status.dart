/// Estados del ciclo de vida de una solicitud, espejo del enum
/// EstadoSolicitud del backend.
enum RequestStatus {
  pendiente,
  aprobada,
  rechazada,
  publicada,
  enRevision;

  static RequestStatus fromBackend(String? raw) {
    switch (raw) {
      case 'APROBADA':
        return RequestStatus.aprobada;
      case 'RECHAZADA':
        return RequestStatus.rechazada;
      case 'PUBLICADA':
        return RequestStatus.publicada;
      case 'EN_REVISION':
        return RequestStatus.enRevision;
      case 'PENDIENTE':
      default:
        return RequestStatus.pendiente;
    }
  }

  /// El dueño puede editar y reenviar solo cuando fue devuelta a revisión
  /// (EN_REVISION). Una solicitud RECHAZADA es definitiva y no se reenvía.
  bool get isEditable => this == RequestStatus.enRevision;
}
