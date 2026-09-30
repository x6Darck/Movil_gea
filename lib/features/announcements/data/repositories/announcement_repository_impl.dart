import 'package:flutter/material.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:intl/intl.dart';
import '../../../../core/error/dio_error_mapper.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/services/offline_cache_service.dart';
import '../../domain/entities/announcement.dart';
import '../../domain/repositories/announcement_repository.dart';
import '../models/announcement_model.dart';
import '../models/announcement_request_model.dart';
import '../../domain/entities/announcement_request.dart';

class AnnouncementRepositoryImpl implements AnnouncementRepository {
  final Dio _dio;
  final OfflineCacheService _cache;

  AnnouncementRepositoryImpl(this._dio, this._cache);

  @override
  Future<Either<Failure, List<Announcement>>> getAnnouncements() async {
    try {
      final response = await _dio.get('/app/anuncios/publicados');
      final data = response.data['data'] as List? ?? [];
      await _cache.saveAnnouncements(data);
      final announcements = data
          .map((json) => AnnouncementModel.fromJson(json as Map<String, dynamic>))
          .toList();
      return Right(announcements);
    } on DioException catch (e) {
      if (e.response == null) {
        final cached = await _cache.loadAnnouncements();
        if (cached != null) {
          final announcements = cached
              .map((json) => AnnouncementModel.fromJson(json as Map<String, dynamic>))
              .toList();
          return Right(announcements);
        }
      }
      return Left(ServerFailure(friendlyDioMessage(
        e,
        fallback: 'No se pudieron cargar los anuncios. Intenta de nuevo.',
      )));
    } catch (e) {
      return const Left(ServerFailure('Ocurrió un error inesperado. Intenta de nuevo.'));
    }
  }

  @override
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
  }) async {
    try {
      final String formattedHoraInicio = '${horaInicio.hour.toString().padLeft(2, '0')}:${horaInicio.minute.toString().padLeft(2, '0')}:00';
      final String formattedHoraFin = '${horaFin.hour.toString().padLeft(2, '0')}:${horaFin.minute.toString().padLeft(2, '0')}:00';
      final DateFormat dateFormat = DateFormat('yyyy-MM-dd');

      await _dio.post('/app/solicitudes-anuncio', data: {
        'titulo': title,
        'descripcion': description,
        'categoria': category,
        'correoContacto': correoContacto,
        'responsableAnuncio': responsableAnuncio,
        'fechaInicioPublicacion': dateFormat.format(fechaInicioPublicacion),
        'fechaFinPublicacion': dateFormat.format(fechaFinPublicacion),
        'horaInicio': formattedHoraInicio,
        'horaFin': formattedHoraFin,
        'requierePiezaGrafica': requierePiezaGrafica,
        'piezaGraficaUrl': piezaGraficaUrl,
        'idsLugaresFisicos': idsLugaresFisicos,
      });
      return const Right(null);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return const Left(ServerFailure('Sesión expirada o no autorizada. Debes iniciar sesión.'));
      }
      if (e.response?.statusCode == 400) {
        final data = e.response?.data;
        String msg = 'Solicitud inválida. Revisa los datos.';
        if (data != null && data is Map && data.containsKey('message')) {
          msg = data['message'];
        }
        return Left(ServerFailure(msg));
      }
      return Left(ServerFailure(friendlyDioMessage(
        e,
        fallback: 'No se pudo enviar la solicitud. Intenta de nuevo.',
      )));
    } catch (e) {
      return const Left(ServerFailure('Ocurrió un error inesperado. Intenta de nuevo.'));
    }
  }

  @override
  Future<Either<Failure, List<AnnouncementRequest>>> getMyRequests() async {
    try {
      final response = await _dio.get('/app/solicitudes-anuncio/mis-solicitudes');
      final data = response.data['data'] as List? ?? [];
      final requests = data
          .map((json) =>
              AnnouncementRequestModel.fromJson(json as Map<String, dynamic>))
          .toList();
      return Right(requests);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return const Left(ServerFailure('Sesión expirada. Inicia sesión de nuevo.'));
      }
      return Left(ServerFailure(friendlyDioMessage(
        e,
        fallback: 'No se pudieron cargar tus solicitudes. Intenta de nuevo.',
      )));
    } catch (e) {
      return const Left(ServerFailure('Ocurrió un error inesperado. Intenta de nuevo.'));
    }
  }

  @override
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
  }) async {
    try {
      final String formattedHoraInicio =
          '${horaInicio.hour.toString().padLeft(2, '0')}:${horaInicio.minute.toString().padLeft(2, '0')}:00';
      final String formattedHoraFin =
          '${horaFin.hour.toString().padLeft(2, '0')}:${horaFin.minute.toString().padLeft(2, '0')}:00';
      final DateFormat dateFormat = DateFormat('yyyy-MM-dd');

      await _dio.put('/app/solicitudes-anuncio/$id', data: {
        'titulo': title,
        'descripcion': description,
        'categoria': category,
        'correoContacto': correoContacto,
        'responsableAnuncio': responsableAnuncio,
        'fechaInicioPublicacion': dateFormat.format(fechaInicioPublicacion),
        'fechaFinPublicacion': dateFormat.format(fechaFinPublicacion),
        'horaInicio': formattedHoraInicio,
        'horaFin': formattedHoraFin,
        'requierePiezaGrafica': requierePiezaGrafica,
        'piezaGraficaUrl': piezaGraficaUrl,
        'idsLugaresFisicos': idsLugaresFisicos,
      });
      return const Right(null);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return const Left(ServerFailure('Sesión expirada. Inicia sesión de nuevo.'));
      }
      if (e.response?.statusCode == 403) {
        return const Left(ServerFailure('No tienes permiso para editar esta solicitud.'));
      }
      if (e.response?.statusCode == 400) {
        final data = e.response?.data;
        String msg = 'Solicitud inválida. Revisa los datos.';
        if (data != null && data is Map && data.containsKey('message')) {
          msg = data['message'];
        }
        return Left(ServerFailure(msg));
      }
      return Left(ServerFailure(friendlyDioMessage(
        e,
        fallback: 'No se pudo actualizar la solicitud. Intenta de nuevo.',
      )));
    } catch (e) {
      return const Left(ServerFailure('Ocurrió un error inesperado. Intenta de nuevo.'));
    }
  }

  @override
  Future<Either<Failure, String>> uploadImage(File file) async {
    try {
      String fileName = file.path.split('/').last;
      String extension = fileName.split('.').last.toLowerCase();
      
      // Determinar el media type para que el backend no lo rechace como octet-stream
      String mimeType = 'image';
      String mimeSubtype = 'jpeg';
      if (extension == 'png') {
        mimeSubtype = 'png';
      } else if (extension == 'pdf') {
        mimeType = 'application';
        mimeSubtype = 'pdf';
      }
      
      FormData formData = FormData.fromMap({
        "archivo": await MultipartFile.fromFile(
          file.path, 
          filename: fileName,
          contentType: DioMediaType(mimeType, mimeSubtype),
        ),
      });
      
      final response = await _dio.post('/comunicaciones/archivos/upload', data: formData);
      final data = response.data;
      if (data != null && data['success'] == true) {
        final url = data['data']['url'];
        return Right(url);
      }
      return const Left(ServerFailure('Error al subir imagen. Respuesta inválida.'));
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return const Left(ServerFailure('Sesión expirada o no autorizada. Debes iniciar sesión.'));
      }
      if (e.response?.statusCode == 400) {
        final data = e.response?.data;
        String msg = 'El archivo no cumple los requisitos.';
        if (data != null && data is Map && data.containsKey('message')) {
          msg = data['message'];
        }
        return Left(ServerFailure(msg));
      }
      return Left(ServerFailure(friendlyDioMessage(
        e,
        fallback: 'No se pudo subir la imagen. Intenta de nuevo.',
      )));
    } catch (e) {
      return const Left(ServerFailure('Ocurrió un error inesperado. Intenta de nuevo.'));
    }
  }
}
