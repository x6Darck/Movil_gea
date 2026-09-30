import '../../domain/entities/announcement.dart';

class AnnouncementModel extends Announcement {
  const AnnouncementModel({
    required super.id,
    required super.title,
    required super.content,
    required super.date,
    super.author,
    super.imageUrl,
    super.category,
    super.correoContacto,
    super.responsableAnuncio,
    super.fechaInicioPublicacion,
    super.fechaFinPublicacion,
    super.horaInicio,
    super.horaFin,
    super.lugar,
    super.lugares,
  });

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    return AnnouncementModel(
      id: (json['id'] ?? '').toString(),
      title: json['tituloVisible'] ?? json['titulo'] ?? 'Sin título',
      content: json['descripcionVisible'] ?? json['contenido'] ?? 'Sin contenido',
      date: DateTime.tryParse(json['fechaPublicacion'] ?? json['fecha'] ?? '') ?? DateTime.now(),
      author: json['oficinaNombre'] ?? json['autor'],
      imageUrl: json['piezaGraficaUrl'],
      category: json['categoria'],
      correoContacto: json['correoContacto'],
      responsableAnuncio: json['responsableAnuncio'],
      fechaInicioPublicacion: DateTime.tryParse(json['fechaInicioPublicacion'] ?? ''),
      fechaFinPublicacion: DateTime.tryParse(json['fechaFinPublicacion'] ?? ''),
      horaInicio: json['horaInicio']?.toString(),
      horaFin: json['horaFin']?.toString(),
      lugar: json['lugar'],
      lugares: (json['lugares'] as List?)?.map((e) => e.toString()).toList(),
    );
  }
}
