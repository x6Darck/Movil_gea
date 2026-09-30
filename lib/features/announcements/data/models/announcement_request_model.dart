import '../../domain/entities/announcement_request.dart';
import '../../domain/entities/request_status.dart';

class AnnouncementRequestModel extends AnnouncementRequest {
  const AnnouncementRequestModel({
    required super.id,
    required super.title,
    required super.description,
    super.category,
    required super.status,
    super.rejectionReason,
    super.reviewNotes,
    super.correoContacto,
    super.responsableAnuncio,
    super.fechaInicioPublicacion,
    super.fechaFinPublicacion,
    super.horaInicio,
    super.horaFin,
    super.piezaGraficaUrl,
    super.requierePiezaGrafica,
    super.idsLugaresFisicos,
    super.lugares,
    super.fechaCreacion,
  });

  factory AnnouncementRequestModel.fromJson(Map<String, dynamic> json) {
    return AnnouncementRequestModel(
      id: (json['id'] as num).toInt(),
      title: json['titulo']?.toString() ?? 'Sin título',
      description: json['descripcion']?.toString() ?? '',
      category: json['categoria']?.toString(),
      status: RequestStatus.fromBackend(json['estado']?.toString()),
      rejectionReason: json['motivoRechazo']?.toString(),
      reviewNotes: json['observacionesRevision']?.toString(),
      correoContacto: json['correoContacto']?.toString(),
      responsableAnuncio: json['responsableAnuncio']?.toString(),
      fechaInicioPublicacion: _parseDate(json['fechaInicioPublicacion']),
      fechaFinPublicacion: _parseDate(json['fechaFinPublicacion']),
      horaInicio: json['horaInicio']?.toString(),
      horaFin: json['horaFin']?.toString(),
      piezaGraficaUrl: json['piezaGraficaUrl']?.toString(),
      requierePiezaGrafica: json['requierePiezaGrafica'] == true,
      idsLugaresFisicos: (json['idsLugaresFisicos'] as List?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [],
      lugares:
          (json['lugares'] as List?)?.map((e) => e.toString()).toList() ??
              const [],
      fechaCreacion: _parseDate(json['fechaCreacion']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
