import 'package:flutter/material.dart'; // For TimeOfDay
import 'dart:io';
import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/announcement.dart';
import '../entities/announcement_request.dart';

abstract class AnnouncementRepository {
  Future<Either<Failure, List<Announcement>>> getAnnouncements();

  Future<Either<Failure, void>> requestAnnouncement({
    required String title,
    required String description,
    String? category,
    required String correoContacto,
    required String responsableAnuncio,
    required DateTime fechaInicioPublicacion,
    required DateTime fechaFinPublicacion,
    required TimeOfDay horaInicio,
    required TimeOfDay horaFin,
    required bool requierePiezaGrafica,
    String? piezaGraficaUrl,
    List<int> idsLugaresFisicos = const [],
  });

  Future<Either<Failure, String>> uploadImage(File file);

  Future<Either<Failure, List<AnnouncementRequest>>> getMyRequests();

  Future<Either<Failure, void>> updateRequest({
    required int id,
    required String title,
    required String description,
    String? category,
    required String correoContacto,
    required String responsableAnuncio,
    required DateTime fechaInicioPublicacion,
    required DateTime fechaFinPublicacion,
    required TimeOfDay horaInicio,
    required TimeOfDay horaFin,
    required bool requierePiezaGrafica,
    String? piezaGraficaUrl,
    List<int> idsLugaresFisicos = const [],
  });
}
