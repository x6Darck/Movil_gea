import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gea_app/core/network/network_providers.dart';
import 'package:gea_app/core/providers/connectivity_providers.dart';
import '../../data/repositories/announcement_repository_impl.dart';
import '../../domain/repositories/announcement_repository.dart';
import '../../domain/entities/announcement.dart';
import '../../domain/entities/announcement_request.dart';

final announcementRepositoryProvider = Provider<AnnouncementRepository>((ref) {
  final dio = ref.watch(dioClientProvider).dio;
  final cache = ref.watch(offlineCacheServiceProvider);
  return AnnouncementRepositoryImpl(dio, cache);
});

final announcementsProvider = FutureProvider<List<Announcement>>((ref) async {
  final repository = ref.watch(announcementRepositoryProvider);
  final result = await repository.getAnnouncements();
  return result.fold(
    (failure) => throw failure.message,
    (announcements) => announcements,
  );
});

/// Historial de solicitudes de anuncio del usuario logueado. Se invalida tras
/// crear o editar una solicitud para reflejar el nuevo estado.
final myRequestsProvider = FutureProvider<List<AnnouncementRequest>>((ref) async {
  final repository = ref.watch(announcementRepositoryProvider);
  final result = await repository.getMyRequests();
  return result.fold(
    (failure) => throw failure.message,
    (requests) => requests,
  );
});

class RequestFormState {
  final bool isLoading;
  final bool isSuccess;
  final String? errorMessage;

  RequestFormState({this.isLoading = false, this.isSuccess = false, this.errorMessage});

  RequestFormState copyWith({bool? isLoading, bool? isSuccess, String? errorMessage}) {
    return RequestFormState(
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class RequestFormNotifier extends StateNotifier<RequestFormState> {
  final AnnouncementRepository _repository;

  RequestFormNotifier(this._repository) : super(RequestFormState());

  Future<void> submitRequest({
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
    List<int> idsLugaresFisicos = const [],
    File? imageFile,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null, isSuccess: false);
    
    String? piezaUrl;
    if (!requierePiezaGrafica && imageFile != null) {
      final uploadResult = await _repository.uploadImage(imageFile);
      bool errorEnSubida = false;
      uploadResult.fold(
        (l) {
          state = state.copyWith(isLoading: false, errorMessage: 'Error subiendo imagen: ${l.message}');
          errorEnSubida = true;
        },
        (url) => piezaUrl = url,
      );
      if (errorEnSubida) return;
    }

    final result = await _repository.requestAnnouncement(
      title: title,
      description: description,
      category: category,
      correoContacto: correoContacto,
      responsableAnuncio: responsableAnuncio,
      fechaInicioPublicacion: fechaInicioPublicacion,
      fechaFinPublicacion: fechaFinPublicacion,
      horaInicio: horaInicio,
      horaFin: horaFin,
      requierePiezaGrafica: requierePiezaGrafica,
      piezaGraficaUrl: piezaUrl,
      idsLugaresFisicos: idsLugaresFisicos,
    );
    
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, errorMessage: failure.message),
      (_) => state = state.copyWith(isLoading: false, isSuccess: true),
    );
  }

  Future<void> submitEdit({
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
    List<int> idsLugaresFisicos = const [],
    String? existingPiezaGraficaUrl,
    File? imageFile,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null, isSuccess: false);

    // Si el usuario eligió una imagen nueva, súbela; si no, conserva la que ya tenía.
    String? piezaUrl = existingPiezaGraficaUrl;
    if (!requierePiezaGrafica && imageFile != null) {
      final uploadResult = await _repository.uploadImage(imageFile);
      bool errorEnSubida = false;
      uploadResult.fold(
        (l) {
          state = state.copyWith(isLoading: false, errorMessage: 'Error subiendo imagen: ${l.message}');
          errorEnSubida = true;
        },
        (url) => piezaUrl = url,
      );
      if (errorEnSubida) return;
    }

    final result = await _repository.updateRequest(
      id: id,
      title: title,
      description: description,
      category: category,
      correoContacto: correoContacto,
      responsableAnuncio: responsableAnuncio,
      fechaInicioPublicacion: fechaInicioPublicacion,
      fechaFinPublicacion: fechaFinPublicacion,
      horaInicio: horaInicio,
      horaFin: horaFin,
      requierePiezaGrafica: requierePiezaGrafica,
      piezaGraficaUrl: piezaUrl,
      idsLugaresFisicos: idsLugaresFisicos,
    );

    result.fold(
      (failure) => state = state.copyWith(isLoading: false, errorMessage: failure.message),
      (_) => state = state.copyWith(isLoading: false, isSuccess: true),
    );
  }
}

final requestFormProvider = StateNotifierProvider<RequestFormNotifier, RequestFormState>((ref) {
  final repository = ref.watch(announcementRepositoryProvider);
  return RequestFormNotifier(repository);
});
