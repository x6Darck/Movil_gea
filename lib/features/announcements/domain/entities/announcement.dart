import 'package:equatable/equatable.dart';

class Announcement extends Equatable {
  final String id;
  final String title;
  final String content;
  final DateTime date;
  final String? author;
  final String? imageUrl;
  final String? category;
  final String? correoContacto;
  final String? responsableAnuncio;
  final DateTime? fechaInicioPublicacion;
  final DateTime? fechaFinPublicacion;
  final String? horaInicio;
  final String? horaFin;
  final String? lugar;
  final List<String>? lugares;

  const Announcement({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
    this.author,
    this.imageUrl,
    this.category,
    this.correoContacto,
    this.responsableAnuncio,
    this.fechaInicioPublicacion,
    this.fechaFinPublicacion,
    this.horaInicio,
    this.horaFin,
    this.lugar,
    this.lugares,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        content,
        date,
        author,
        imageUrl,
        category,
        correoContacto,
        responsableAnuncio,
        fechaInicioPublicacion,
        fechaFinPublicacion,
        horaInicio,
        horaFin,
        lugar,
        lugares,
      ];
}
