import 'package:equatable/equatable.dart';

class Event extends Equatable {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final DateTime? endDate;
  final String? location;
  final List<String>? locations;
  final String? category;
  final String? colorHex;
  final bool isImportant;
  final String? imageUrl;
  final String? office;
  final String? responsible;
  final String? responsibleEmail;
  final String? observations;
  final String? link;
  final String? externalLocation;

  const Event({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    this.endDate,
    this.location,
    this.locations,
    this.category,
    this.colorHex,
    this.isImportant = false,
    this.imageUrl,
    this.office,
    this.responsible,
    this.responsibleEmail,
    this.observations,
    this.link,
    this.externalLocation,
  });

  @override
  List<Object?> get props => [
    id, title, description, date, endDate, location, locations, category,
    colorHex, isImportant, imageUrl, office, responsible,
    responsibleEmail, observations, link, externalLocation
  ];
}
