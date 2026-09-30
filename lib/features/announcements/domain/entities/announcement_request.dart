import 'package:equatable/equatable.dart';
import 'request_status.dart';

/// Una solicitud de anuncio del usuario, con su estado de moderación.
/// Espejo de SolicitudAnuncioResponse del backend.
class AnnouncementRequest extends Equatable {
  final int id;
  final String title;
  final String description;
  final String? category;
  final RequestStatus status;
  final String? rejectionReason; // motivoRechazo
  final String? reviewNotes; // observacionesRevision
  final String? correoContacto;
  final String? responsableAnuncio;
  final DateTime? fechaInicioPublicacion;
  final DateTime? fechaFinPublicacion;
  final String? horaInicio; // "HH:mm:ss"
  final String? horaFin; // "HH:mm:ss"
  final String? piezaGraficaUrl;
  final bool requierePiezaGrafica;
  final List<int> idsLugaresFisicos;
  final List<String> lugares;
  final DateTime? fechaCreacion;

  const AnnouncementRequest({
    required this.id,
    required this.title,
    required this.description,
    this.category,
    required this.status,
    this.rejectionReason,
    this.reviewNotes,
    this.correoContacto,
    this.responsableAnuncio,
    this.fechaInicioPublicacion,
    this.fechaFinPublicacion,
    this.horaInicio,
    this.horaFin,
    this.piezaGraficaUrl,
    this.requierePiezaGrafica = false,
    this.idsLugaresFisicos = const [],
    this.lugares = const [],
    this.fechaCreacion,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        category,
        status,
        rejectionReason,
        reviewNotes,
        correoContacto,
        responsableAnuncio,
        fechaInicioPublicacion,
        fechaFinPublicacion,
        horaInicio,
        horaFin,
        piezaGraficaUrl,
        requierePiezaGrafica,
        idsLugaresFisicos,
        lugares,
        fechaCreacion,
      ];
}
