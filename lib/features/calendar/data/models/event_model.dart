import '../../domain/entities/event.dart';

class EventModel extends Event {
  const EventModel({
    required super.id,
    required super.title,
    required super.description,
    required super.date,
    super.endDate,
    super.location,
    super.locations,
    super.category,
    super.colorHex,
    super.isImportant,
    super.imageUrl,
    super.office,
    super.responsible,
    super.responsibleEmail,
    super.observations,
    super.link,
    super.externalLocation,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    DateTime eventDate = DateTime.tryParse(json['fechaEvento'] ?? json['fecha'] ?? '') ?? DateTime.now();
    
    // Combine with horaInicio if available
    final horaInicio = json['horaInicio'] as String?;
    if (horaInicio != null && horaInicio.isNotEmpty) {
      try {
        final timeParts = horaInicio.split(':');
        if (timeParts.length >= 2) {
          eventDate = DateTime(
            eventDate.year,
            eventDate.month,
            eventDate.day,
            int.parse(timeParts[0]),
            int.parse(timeParts[1]),
          );
        }
      } catch (e) {
        // Fallback to original date if time parsing fails
      }
    }

    DateTime? eventEndDate;
    final horaFin = json['horaFin'] as String?;
    if (horaFin != null && horaFin.isNotEmpty) {
      try {
        final timeParts = horaFin.split(':');
        if (timeParts.length >= 2) {
          eventEndDate = DateTime(
            eventDate.year,
            eventDate.month,
            eventDate.day,
            int.parse(timeParts[0]),
            int.parse(timeParts[1]),
          );
        }
      } catch (e) {
        // Ignore end time if parsing fails
      }
    }

    return EventModel(
      id: (json['id'] ?? '').toString(),
      title: json['tituloVisible'] ?? json['titulo'] ?? 'Sin título',
      description: json['descripcionVisible'] ?? json['descripcion'] ?? 'Sin descripción',
      date: eventDate,
      endDate: eventEndDate,
      location: json['lugar'],
      locations: (json['lugares'] as List?)?.map((e) => e.toString()).toList(),
      category: json['tipoEvento'] ?? json['categoria'],
      colorHex: json['tipoEventoColorHex'],
      isImportant: json['esImportante'] ?? false,
      imageUrl: json['piezaGraficaUrl'],
      office: json['oficinaNombre'],
      responsible: json['responsableEvento'],
      responsibleEmail: json['usuarioSolicitanteCorreo'],
      observations: json['observaciones'],
      link: json['linkConexion'],
      externalLocation: json['ubicacionExterna'] as String?,
    );
  }
}
