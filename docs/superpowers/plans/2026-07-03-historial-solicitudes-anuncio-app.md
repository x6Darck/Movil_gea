# Historial de Solicitudes de Anuncio en la App — Plan de Implementación

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Que un usuario logueado vea, desde la sección Perfil, el historial de sus propias solicitudes de anuncio con su estado (pendiente / en revisión / rechazada / aprobada / publicada) y el motivo cuando aplica, y pueda editar y reenviar las que estén EN_REVISION o RECHAZADA.

**Architecture:** El feature es casi 100% Flutter. El backend **ya** expone todo lo necesario: `GET /app/solicitudes-anuncio/mis-solicitudes` (filtra por usuario propio cuando no tiene oficina — el caso de un estudiante), `PUT /app/solicitudes-anuncio/{id}` (que al editar una solicitud EN_REVISION/RECHAZADA la regresa a PENDIENTE y limpia motivo/observaciones — la lógica de "reenviar"), y un DTO de respuesta con `estado`, `motivoRechazo` y `observacionesRevision`. Se añade una capa dominio/datos/presentación en la feature `announcements`, se reutiliza el formulario existente `RequestAnnouncementScreen` en modo edición, y se agrega un botón en Perfil. Se añade **un** test de caracterización en el backend para blindar los dos invariantes de seguridad de los que depende la app (un estudiante solo ve sus solicitudes; un estudiante no puede editar la de otro → 403).

**Tech Stack:** Flutter, Riverpod, Dio, fpdart (Either), go_router, mockito + build_runner (tests). Backend: Spring Boot, JUnit 5 (un solo test nuevo).

**Alcance:** Solo **solicitudes de anuncio** (no eventos). Solo **ver + editar/reenviar** (sin cancelar/eliminar en esta versión).

---

## Verificación previa (leer antes de empezar)

Confirmaciones ya hechas sobre el backend (no requieren cambios de código, salvo el test de la Tarea 1):
- `SolicitudAnuncioController.listarPropias` → `@PreAuthorize` incluye `USUARIO_AUTENTICADO_APP`. ✅
- `SolicitudAnuncioServiceImpl.listarPropias`: si `usuario.getOficina() == null` (estudiante), filtra por `usuarioSolicitante.id == user.id`. ✅
- `SolicitudAnuncioServiceImpl.actualizar`: valida propiedad (owner o admin, si no → 403) y, si el dueño edita una EN_REVISION/RECHAZADA, la regresa a PENDIENTE y limpia `motivoRechazo`/`observacionesRevision`. ✅
- `SolicitudAnuncioResponse` incluye `estado`, `motivoRechazo`, `observacionesRevision`, `idsLugaresFisicos`, `lugares`, fechas y horas. ✅

---

## Task 1: Test de caracterización del backend (blindar invariantes de seguridad)

Confirma, con el escenario real de la app (estudiante sin oficina), que solo ve sus solicitudes y que no puede editar las de otro. Si el test pasa a la primera, confirma la base; si falla, revela un hueco real que debe corregirse antes de construir la app encima.

**Files:**
- Test: `GEA_BACKEND/src/test/java/com/calendario/callapp/callapp_backend/smoke/MisSolicitudesAnuncioTest.java`

- [ ] **Step 1: Escribir el test**

```java
package com.calendario.callapp.callapp_backend.smoke;

import com.calendario.callapp.callapp_backend.dto.request.SolicitudAnuncioRequest;
import com.calendario.callapp.callapp_backend.dto.response.SolicitudAnuncioResponse;
import com.calendario.callapp.callapp_backend.entity.*;
import com.calendario.callapp.callapp_backend.repository.*;
import com.calendario.callapp.callapp_backend.service.impl.SolicitudAnuncioServiceImpl;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDate;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * Invariantes de seguridad de los que depende el historial de solicitudes en
 * la app móvil: un estudiante (rol USUARIO_AUTENTICADO_APP, sin oficina) solo
 * ve las SUYAS, y no puede editar la de otro usuario.
 */
@SpringBootTest
@ActiveProfiles("test")
@Transactional
class MisSolicitudesAnuncioTest {

    @Autowired private SolicitudAnuncioServiceImpl service;
    @Autowired private SolicitudAnuncioRepository solicitudAnuncioRepository;
    @Autowired private UsuarioRepository usuarioRepository;
    @Autowired private RolRepository rolRepository;

    private Usuario estudianteA;
    private Usuario estudianteB;

    @BeforeEach
    void setUp() {
        RolEntity rol = rolRepository.findByNombre("Usuario Autenticado")
                .orElseGet(() -> {
                    RolEntity r = new RolEntity();
                    r.setNombre("Usuario Autenticado");
                    return rolRepository.save(r);
                });
        estudianteA = nuevoEstudiante(rol, "a");
        estudianteB = nuevoEstudiante(rol, "b");
    }

    private Usuario nuevoEstudiante(RolEntity rol, String suf) {
        Usuario u = new Usuario();
        u.setNombre("Estudiante " + suf);
        u.setCorreo("est." + suf + "." + System.currentTimeMillis() + "@unilibre.edu.co");
        u.setPassword("dummy");
        u.setRolEntity(rol);
        u.setOficina(null); // estudiante: sin oficina
        u.setEstado("ACTIVO");
        u.setAuthProvider(AuthProvider.LOCAL);
        return usuarioRepository.save(u);
    }

    private Authentication authDe(Usuario u) {
        return new UsernamePasswordAuthenticationToken(u.getCorreo(), null, List.of());
    }

    private SolicitudAnuncioRequest requestBasico(String titulo) {
        SolicitudAnuncioRequest req = new SolicitudAnuncioRequest();
        req.setTitulo(titulo);
        req.setDescripcion("Contenido " + titulo);
        req.setCategoria("Informativo");
        req.setFechaInicioPublicacion(LocalDate.now());
        req.setFechaFinPublicacion(LocalDate.now().plusDays(5));
        return req;
    }

    @Test
    void un_estudiante_solo_ve_sus_propias_solicitudes() {
        service.crear(requestBasico("De A - 1"), authDe(estudianteA));
        service.crear(requestBasico("De A - 2"), authDe(estudianteA));
        service.crear(requestBasico("De B - 1"), authDe(estudianteB));

        List<SolicitudAnuncioResponse> deA =
                service.listarPropias(authDe(estudianteA), null, null, null, null);

        assertThat(deA).hasSize(2);
        assertThat(deA).allMatch(r -> r.getUsuarioSolicitanteId().equals(estudianteA.getId()));
    }

    @Test
    void un_estudiante_no_puede_editar_la_solicitud_de_otro() {
        SolicitudAnuncioResponse deB = service.crear(requestBasico("De B"), authDe(estudianteB));

        SolicitudAnuncioRequest edit = requestBasico("Intento de secuestro");

        assertThatThrownBy(() -> service.actualizar(deB.getId(), edit, authDe(estudianteA)))
                .isInstanceOf(ResponseStatusException.class)
                .hasMessageContaining("No tienes permiso");
    }
}
```

- [ ] **Step 2: Correr el test**

Run: `cd GEA_BACKEND && ./mvnw.cmd test -Dtest=MisSolicitudesAnuncioTest`
Expected: PASS (confirma la base). Si FALLA, detente y reporta — hay un hueco real en el backend que corregir antes de seguir.

- [ ] **Step 3: Commit**

```bash
cd GEA_BACKEND
git add src/test/java/com/calendario/callapp/callapp_backend/smoke/MisSolicitudesAnuncioTest.java
git commit -m "test(anuncios): blindar propiedad y 403 cross-user en solicitudes de estudiante"
```

---

## Task 2: Enum `RequestStatus` (dominio Flutter)

**Files:**
- Create: `gea_app/lib/features/announcements/domain/entities/request_status.dart`
- Test: `gea_app/test/features/announcements/request_status_test.dart`

- [ ] **Step 1: Escribir el test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:gea_app/features/announcements/domain/entities/request_status.dart';

void main() {
  group('RequestStatus.fromBackend', () {
    test('mapea cada string del backend a su enum', () {
      expect(RequestStatus.fromBackend('PENDIENTE'), RequestStatus.pendiente);
      expect(RequestStatus.fromBackend('APROBADA'), RequestStatus.aprobada);
      expect(RequestStatus.fromBackend('RECHAZADA'), RequestStatus.rechazada);
      expect(RequestStatus.fromBackend('PUBLICADA'), RequestStatus.publicada);
      expect(RequestStatus.fromBackend('EN_REVISION'), RequestStatus.enRevision);
    });

    test('valor desconocido o nulo cae a pendiente', () {
      expect(RequestStatus.fromBackend('OTRA_COSA'), RequestStatus.pendiente);
      expect(RequestStatus.fromBackend(null), RequestStatus.pendiente);
    });
  });

  group('RequestStatus.isEditable', () {
    test('solo EN_REVISION y RECHAZADA son editables', () {
      expect(RequestStatus.enRevision.isEditable, isTrue);
      expect(RequestStatus.rechazada.isEditable, isTrue);
      expect(RequestStatus.pendiente.isEditable, isFalse);
      expect(RequestStatus.aprobada.isEditable, isFalse);
      expect(RequestStatus.publicada.isEditable, isFalse);
    });
  });
}
```

- [ ] **Step 2: Correr el test para verlo fallar**

Run: `cd gea_app && flutter test test/features/announcements/request_status_test.dart`
Expected: FAIL — no existe `request_status.dart`.

- [ ] **Step 3: Implementar el enum**

```dart
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

  /// El dueño puede editar y reenviar solo cuando fue devuelta (EN_REVISION)
  /// o rechazada (RECHAZADA) — igual que la plataforma web, donde editar en
  /// ese estado regresa la solicitud a PENDIENTE.
  bool get isEditable =>
      this == RequestStatus.enRevision || this == RequestStatus.rechazada;
}
```

- [ ] **Step 4: Correr el test para verlo pasar**

Run: `cd gea_app && flutter test test/features/announcements/request_status_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
cd gea_app
git add lib/features/announcements/domain/entities/request_status.dart test/features/announcements/request_status_test.dart
git commit -m "feat(anuncios): enum RequestStatus con parsing e isEditable"
```

---

## Task 3: Entidad `AnnouncementRequest`

**Files:**
- Create: `gea_app/lib/features/announcements/domain/entities/announcement_request.dart`

- [ ] **Step 1: Implementar la entidad** (sin test propio; es un data holder puro que se ejercita vía el modelo en la Tarea 4)

```dart
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
```

- [ ] **Step 2: Commit**

```bash
cd gea_app
git add lib/features/announcements/domain/entities/announcement_request.dart
git commit -m "feat(anuncios): entidad AnnouncementRequest"
```

---

## Task 4: Modelo `AnnouncementRequestModel.fromJson`

**Files:**
- Create: `gea_app/lib/features/announcements/data/models/announcement_request_model.dart`
- Test: `gea_app/test/features/announcements/announcement_request_model_test.dart`

- [ ] **Step 1: Escribir el test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:gea_app/features/announcements/data/models/announcement_request_model.dart';
import 'package:gea_app/features/announcements/domain/entities/request_status.dart';

void main() {
  group('AnnouncementRequestModel.fromJson', () {
    test('mapea una solicitud rechazada con motivo', () {
      final json = {
        'id': 42,
        'titulo': 'Mi anuncio',
        'descripcion': 'Contenido',
        'categoria': 'Cultural',
        'estado': 'RECHAZADA',
        'motivoRechazo': 'La imagen no cumple el formato',
        'observacionesRevision': null,
        'correoContacto': 'a@b.co',
        'responsableAnuncio': 'Ana',
        'fechaInicioPublicacion': '2026-07-01',
        'fechaFinPublicacion': '2026-07-10',
        'horaInicio': '08:00:00',
        'horaFin': '10:00:00',
        'piezaGraficaUrl': '/uploads/x.png',
        'requierePiezaGrafica': false,
        'idsLugaresFisicos': [3, 7],
        'lugares': ['Plaza', 'Auditorio'],
        'fechaCreacion': '2026-06-20T09:30:00',
      };

      final r = AnnouncementRequestModel.fromJson(json);

      expect(r.id, 42);
      expect(r.title, 'Mi anuncio');
      expect(r.status, RequestStatus.rechazada);
      expect(r.rejectionReason, 'La imagen no cumple el formato');
      expect(r.reviewNotes, isNull);
      expect(r.fechaInicioPublicacion, DateTime(2026, 7, 1));
      expect(r.horaInicio, '08:00:00');
      expect(r.idsLugaresFisicos, [3, 7]);
      expect(r.lugares, ['Plaza', 'Auditorio']);
    });

    test('mapea una en revisión con observaciones y tolera campos ausentes', () {
      final json = {
        'id': 5,
        'titulo': 'Otro',
        'descripcion': 'X',
        'estado': 'EN_REVISION',
        'observacionesRevision': 'Corrige las fechas',
      };

      final r = AnnouncementRequestModel.fromJson(json);

      expect(r.status, RequestStatus.enRevision);
      expect(r.reviewNotes, 'Corrige las fechas');
      expect(r.category, isNull);
      expect(r.idsLugaresFisicos, isEmpty);
      expect(r.lugares, isEmpty);
      expect(r.fechaInicioPublicacion, isNull);
    });
  });
}
```

- [ ] **Step 2: Correr el test para verlo fallar**

Run: `cd gea_app && flutter test test/features/announcements/announcement_request_model_test.dart`
Expected: FAIL — no existe el modelo.

- [ ] **Step 3: Implementar el modelo**

```dart
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
```

- [ ] **Step 4: Correr el test para verlo pasar**

Run: `cd gea_app && flutter test test/features/announcements/announcement_request_model_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
cd gea_app
git add lib/features/announcements/data/models/announcement_request_model.dart test/features/announcements/announcement_request_model_test.dart
git commit -m "feat(anuncios): AnnouncementRequestModel.fromJson"
```

---

## Task 5: Métodos de repositorio `getMyRequests` y `updateRequest`

**Files:**
- Modify: `gea_app/lib/features/announcements/domain/repositories/announcement_repository.dart`
- Modify: `gea_app/lib/features/announcements/data/repositories/announcement_repository_impl.dart`
- Test: `gea_app/test/features/announcements/announcement_request_repository_test.dart`

- [ ] **Step 1: Escribir el test** (usa mockito + build_runner, patrón ya usado en `pinned_event_repository_test.dart`)

```dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:gea_app/core/services/offline_cache_service.dart';
import 'package:gea_app/features/announcements/data/repositories/announcement_repository_impl.dart';
import 'package:gea_app/features/announcements/domain/entities/request_status.dart';
import 'announcement_request_repository_test.mocks.dart';

@GenerateMocks([Dio, OfflineCacheService])
void main() {
  late MockDio mockDio;
  late MockOfflineCacheService mockCache;
  late AnnouncementRepositoryImpl repo;

  setUp(() {
    mockDio = MockDio();
    mockCache = MockOfflineCacheService();
    repo = AnnouncementRepositoryImpl(mockDio, mockCache);
  });

  test('getMyRequests devuelve la lista mapeada en 200', () async {
    when(mockDio.get('/app/solicitudes-anuncio/mis-solicitudes')).thenAnswer(
      (_) async => Response(
        data: {
          'data': [
            {
              'id': 1,
              'titulo': 'A',
              'descripcion': 'X',
              'estado': 'EN_REVISION',
              'observacionesRevision': 'Corrige',
            }
          ]
        },
        statusCode: 200,
        requestOptions: RequestOptions(path: '/app/solicitudes-anuncio/mis-solicitudes'),
      ),
    );

    final result = await repo.getMyRequests();

    expect(result.isRight(), isTrue);
    final list = result.getOrElse((_) => []);
    expect(list, hasLength(1));
    expect(list.first.status, RequestStatus.enRevision);
    expect(list.first.reviewNotes, 'Corrige');
  });

  test('updateRequest hace PUT al id correcto y devuelve Right(null)', () async {
    when(mockDio.put('/app/solicitudes-anuncio/9', data: anyNamed('data'))).thenAnswer(
      (_) async => Response(
        data: {'success': true},
        statusCode: 200,
        requestOptions: RequestOptions(path: '/app/solicitudes-anuncio/9'),
      ),
    );

    final result = await repo.updateRequest(
      id: 9,
      title: 'Editado',
      description: 'Nuevo',
      category: 'Cultural',
      correoContacto: 'a@b.co',
      responsableAnuncio: 'Ana',
      fechaInicioPublicacion: DateTime(2026, 7, 1),
      fechaFinPublicacion: DateTime(2026, 7, 10),
      horaInicio: const TimeOfDay(hour: 8, minute: 0),
      horaFin: const TimeOfDay(hour: 10, minute: 0),
      requierePiezaGrafica: false,
      piezaGraficaUrl: '/uploads/x.png',
      idsLugaresFisicos: const [3],
    );

    expect(result.isRight(), isTrue);
    verify(mockDio.put('/app/solicitudes-anuncio/9', data: anyNamed('data'))).called(1);
  });
}
```

- [ ] **Step 2: Añadir los métodos a la interfaz** (`announcement_repository.dart`)

Añade el import y los dos métodos al `abstract class AnnouncementRepository`:

```dart
import '../entities/announcement_request.dart';
```

```dart
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
```

- [ ] **Step 3: Implementar los métodos** (`announcement_repository_impl.dart`)

Añade el import:

```dart
import '../models/announcement_request_model.dart';
import '../../domain/entities/announcement_request.dart';
```

Y dentro de la clase `AnnouncementRepositoryImpl` (por ejemplo justo después de `requestAnnouncement`):

```dart
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
      return Left(ServerFailure(e.message ?? 'Error cargando tus solicitudes'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
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
      return Left(ServerFailure(e.message ?? 'Error actualizando la solicitud'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
```

- [ ] **Step 4: Generar los mocks**

Run: `cd gea_app && flutter pub run build_runner build --delete-conflicting-outputs`
Expected: genera `test/features/announcements/announcement_request_repository_test.mocks.dart`.

- [ ] **Step 5: Correr el test para verlo pasar**

Run: `cd gea_app && flutter test test/features/announcements/announcement_request_repository_test.dart`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
cd gea_app
git add lib/features/announcements/domain/repositories/announcement_repository.dart lib/features/announcements/data/repositories/announcement_repository_impl.dart test/features/announcements/announcement_request_repository_test.dart test/features/announcements/announcement_request_repository_test.mocks.dart
git commit -m "feat(anuncios): repositorio getMyRequests + updateRequest"
```

---

## Task 6: Providers `myRequestsProvider` y edición en el notifier

**Files:**
- Modify: `gea_app/lib/features/announcements/presentation/providers/announcement_providers.dart`

- [ ] **Step 1: Añadir el provider del historial y el método de edición**

Añade el import al inicio del archivo:

```dart
import '../../domain/entities/announcement_request.dart';
```

Añade el provider (por ejemplo debajo de `announcementsProvider`):

```dart
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
```

Añade el método `submitEdit` dentro de `RequestFormNotifier` (junto a `submitRequest`):

```dart
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
```

- [ ] **Step 2: Verificar que compila**

Run: `cd gea_app && dart analyze lib/features/announcements/presentation/providers/announcement_providers.dart`
Expected: "No issues found!"

- [ ] **Step 3: Commit**

```bash
cd gea_app
git add lib/features/announcements/presentation/providers/announcement_providers.dart
git commit -m "feat(anuncios): myRequestsProvider + submitEdit en el notifier"
```

---

## Task 7: Widget `RequestStatusBadge`

**Files:**
- Create: `gea_app/lib/features/announcements/presentation/widgets/request_status_badge.dart`
- Test: `gea_app/test/features/announcements/request_status_badge_test.dart`

- [ ] **Step 1: Escribir el test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gea_app/features/announcements/domain/entities/request_status.dart';
import 'package:gea_app/features/announcements/presentation/widgets/request_status_badge.dart';

void main() {
  Future<void> pump(WidgetTester tester, RequestStatus status) {
    return tester.pumpWidget(MaterialApp(
      home: Scaffold(body: RequestStatusBadge(status: status)),
    ));
  }

  testWidgets('muestra la etiqueta correcta por estado', (tester) async {
    await pump(tester, RequestStatus.enRevision);
    expect(find.text('En revisión'), findsOneWidget);

    await pump(tester, RequestStatus.rechazada);
    expect(find.text('Rechazada'), findsOneWidget);

    await pump(tester, RequestStatus.aprobada);
    expect(find.text('Aprobada'), findsOneWidget);

    await pump(tester, RequestStatus.publicada);
    expect(find.text('Publicada'), findsOneWidget);

    await pump(tester, RequestStatus.pendiente);
    expect(find.text('Pendiente'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Correr el test para verlo fallar**

Run: `cd gea_app && flutter test test/features/announcements/request_status_badge_test.dart`
Expected: FAIL — no existe el widget.

- [ ] **Step 3: Implementar el widget**

```dart
import 'package:flutter/material.dart';
import 'package:gea_app/config/theme/app_tokens.dart';
import '../../domain/entities/request_status.dart';

/// Chip de color según el estado de una solicitud.
class RequestStatusBadge extends StatelessWidget {
  final RequestStatus status;
  const RequestStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = _styleFor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }

  (String, Color) _styleFor(RequestStatus status) {
    switch (status) {
      case RequestStatus.pendiente:
        return ('Pendiente', AppTokens.warning);
      case RequestStatus.enRevision:
        return ('En revisión', AppTokens.warning);
      case RequestStatus.rechazada:
        return ('Rechazada', AppTokens.error);
      case RequestStatus.aprobada:
        return ('Aprobada', AppTokens.success);
      case RequestStatus.publicada:
        return ('Publicada', AppTokens.success);
    }
  }
}
```

- [ ] **Step 4: Correr el test para verlo pasar**

Run: `cd gea_app && flutter test test/features/announcements/request_status_badge_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
cd gea_app
git add lib/features/announcements/presentation/widgets/request_status_badge.dart test/features/announcements/request_status_badge_test.dart
git commit -m "feat(anuncios): RequestStatusBadge"
```

---

## Task 8: Widget `MyRequestCard`

Muestra una solicitud en el historial: título, badge de estado, fecha, y el motivo (rechazo) u observaciones (revisión) cuando existan. Recibe un callback `onEdit` que la pantalla decide si mostrar (solo si `status.isEditable`).

**Files:**
- Create: `gea_app/lib/features/announcements/presentation/widgets/my_request_card.dart`

- [ ] **Step 1: Implementar el widget** (widget de presentación; se ejercita en la verificación manual de la Tarea 12)

```dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gea_app/config/theme/app_tokens.dart';
import '../../domain/entities/announcement_request.dart';
import '../../domain/entities/request_status.dart';
import 'request_status_badge.dart';

class MyRequestCard extends StatelessWidget {
  final AnnouncementRequest request;
  final VoidCallback? onEdit;

  const MyRequestCard({super.key, required this.request, this.onEdit});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fecha = request.fechaCreacion != null
        ? DateFormat('d MMM, yyyy', 'es_ES').format(request.fechaCreacion!)
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  request.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              RequestStatusBadge(status: request.status),
            ],
          ),
          if (fecha.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(fecha, style: theme.textTheme.bodySmall),
          ],
          const SizedBox(height: 8),
          Text(
            request.description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium,
          ),
          if (request.status == RequestStatus.rechazada &&
              (request.rejectionReason?.isNotEmpty ?? false))
            _reasonBox(
              context,
              icon: Icons.cancel_outlined,
              color: AppTokens.error,
              title: 'Motivo del rechazo',
              body: request.rejectionReason!,
            ),
          if (request.status == RequestStatus.enRevision &&
              (request.reviewNotes?.isNotEmpty ?? false))
            _reasonBox(
              context,
              icon: Icons.edit_note_outlined,
              color: AppTokens.warning,
              title: 'Observaciones para corregir',
              body: request.reviewNotes!,
            ),
          if (onEdit != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Editar y reenviar'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _reasonBox(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String body,
  }) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: color, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(body, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Verificar que compila**

Run: `cd gea_app && dart analyze lib/features/announcements/presentation/widgets/my_request_card.dart`
Expected: "No issues found!"

- [ ] **Step 3: Commit**

```bash
cd gea_app
git add lib/features/announcements/presentation/widgets/my_request_card.dart
git commit -m "feat(anuncios): MyRequestCard con motivo/observaciones y acción editar"
```

---

## Task 9: Pantalla `MyRequestsScreen` (historial)

Lista el historial vía `myRequestsProvider`, con pull-to-refresh, estados de carga/error/vacío, y navega a la edición cuando la solicitud es editable. La navegación de edición se conecta en la Tarea 10 (ruta `/request-announcement` con `extra`).

**Files:**
- Create: `gea_app/lib/features/announcements/presentation/screens/my_requests_screen.dart`

- [ ] **Step 1: Implementar la pantalla**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/announcement_providers.dart';
import '../widgets/my_request_card.dart';
import '../../domain/entities/request_status.dart';

class MyRequestsScreen extends ConsumerWidget {
  const MyRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final requestsAsync = ref.watch(myRequestsProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Mis Solicitudes'),
        centerTitle: true,
        elevation: 0,
      ),
      body: requestsAsync.when(
        data: (requests) {
          if (requests.isEmpty) {
            return _EmptyState();
          }
          return RefreshIndicator(
            onRefresh: () async => ref.refresh(myRequestsProvider.future),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              itemCount: requests.length,
              itemBuilder: (context, index) {
                final r = requests[index];
                return MyRequestCard(
                  request: r,
                  onEdit: r.status.isEditable
                      ? () async {
                          await context.push('/request-announcement', extra: r);
                          ref.invalidate(myRequestsProvider);
                        }
                      : null,
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                const SizedBox(height: 12),
                Text('No se pudieron cargar tus solicitudes.\n$err',
                    textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => ref.invalidate(myRequestsProvider),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: theme.disabledColor),
            const SizedBox(height: 16),
            Text('Aún no has enviado solicitudes',
                style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'Cuando solicites un anuncio, aquí verás su estado.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Verificar que compila**

Run: `cd gea_app && dart analyze lib/features/announcements/presentation/screens/my_requests_screen.dart`
Expected: "No issues found!"

- [ ] **Step 3: Commit**

```bash
cd gea_app
git add lib/features/announcements/presentation/screens/my_requests_screen.dart
git commit -m "feat(anuncios): pantalla MyRequestsScreen (historial)"
```

---

## Task 10: Modo edición en `RequestAnnouncementScreen`

Reutiliza el formulario existente. Se añade un parámetro opcional `editingRequest`; si viene, precarga los campos, oculta la obligatoriedad de imagen nueva (ya tiene una), y en el submit llama a `submitEdit` (PUT) en vez de `submitRequest` (POST).

**Files:**
- Modify: `gea_app/lib/features/announcements/presentation/screens/request_announcement_screen.dart`

- [ ] **Step 1: Añadir imports y el parámetro del widget**

En los imports del archivo, añade:

```dart
import '../../domain/entities/announcement_request.dart';
```

Cambia la declaración del widget y su constructor para aceptar la solicitud a editar:

```dart
class RequestAnnouncementScreen extends ConsumerStatefulWidget {
  final AnnouncementRequest? editingRequest;
  const RequestAnnouncementScreen({super.key, this.editingRequest});

  @override
  ConsumerState<RequestAnnouncementScreen> createState() => _RequestAnnouncementScreenState();
}
```

- [ ] **Step 2: Precargar los campos en `initState`**

Reemplaza el `initState` existente por:

```dart
  @override
  void initState() {
    super.initState();
    final editing = widget.editingRequest;
    if (editing != null) {
      _titleController.text = editing.title;
      _descriptionController.text = editing.description;
      _correoContactoController.text = editing.correoContacto ?? '';
      _responsableController.text = editing.responsableAnuncio ?? '';
      _fechaInicio = editing.fechaInicioPublicacion;
      _fechaFin = editing.fechaFinPublicacion;
      _horaInicio = _parseTime(editing.horaInicio);
      _horaFin = _parseTime(editing.horaFin);
      _requierePiezaGrafica = editing.requierePiezaGrafica;
      _selectedLugares.addAll(editing.idsLugaresFisicos);
      _hasInitializedUserData = true;
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final authState = ref.read(authProvider);
        if (authState.user != null) {
          _responsableController.text = authState.user!.name;
          _correoContactoController.text = authState.user!.email;
        }
      });
    }
  }

  /// Convierte "HH:mm:ss" del backend en TimeOfDay. Null si no aplica.
  static TimeOfDay? _parseTime(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final parts = raw.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }
```

- [ ] **Step 3: Ramificar el submit para edición**

En `_onSubmit`, reemplaza el bloque de validación de imagen y la llamada a `submitRequest` por lo siguiente. La imagen deja de ser obligatoria cuando se edita (ya existe una `piezaGraficaUrl`):

```dart
      final editing = widget.editingRequest;
      final bool yaTienePieza =
          editing?.piezaGraficaUrl != null && editing!.piezaGraficaUrl!.isNotEmpty;

      if (!_requierePiezaGrafica && _imageFile == null && !yaTienePieza) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Por favor, selecciona una imagen para el anuncio'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        return;
      }

      if (editing != null) {
        await ref.read(requestFormProvider.notifier).submitEdit(
              id: editing.id,
              title: _titleController.text.trim(),
              description: _descriptionController.text.trim(),
              category: editing.category,
              correoContacto: _correoContactoController.text.trim(),
              responsableAnuncio: _responsableController.text.trim(),
              fechaInicioPublicacion: _fechaInicio!,
              fechaFinPublicacion: _fechaFin!,
              horaInicio: _horaInicio!,
              horaFin: _horaFin!,
              requierePiezaGrafica: _requierePiezaGrafica,
              idsLugaresFisicos: _selectedLugares,
              existingPiezaGraficaUrl: editing.piezaGraficaUrl,
              imageFile: _imageFile,
            );
      } else {
        await ref.read(requestFormProvider.notifier).submitRequest(
              title: _titleController.text.trim(),
              description: _descriptionController.text.trim(),
              category: null,
              correoContacto: _correoContactoController.text.trim(),
              responsableAnuncio: _responsableController.text.trim(),
              fechaInicioPublicacion: _fechaInicio!,
              fechaFinPublicacion: _fechaFin!,
              horaInicio: _horaInicio!,
              horaFin: _horaFin!,
              requierePiezaGrafica: _requierePiezaGrafica,
              idsLugaresFisicos: _selectedLugares,
              imageFile: _imageFile,
            );
      }
```

Y en el mensaje de éxito de `_onSubmit`, ajusta el texto para ambos casos:

```dart
      final state = ref.read(requestFormProvider);
      if (state.isSuccess) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.editingRequest != null
                  ? 'Solicitud actualizada y reenviada'
                  : 'Solicitud enviada con éxito'),
              backgroundColor: Theme.of(context).colorScheme.primary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
          Navigator.pop(context);
        }
      } else if (state.errorMessage != null) {
        // (bloque de error existente, sin cambios)
      }
```

- [ ] **Step 4: (Opcional pero recomendado) Título del AppBar según modo**

Si la pantalla tiene un `AppBar` con título fijo, cámbialo a:

```dart
title: Text(widget.editingRequest != null ? 'Editar Solicitud' : 'Solicitar Anuncio'),
```

(Localiza el `AppBar` de esta pantalla; si el título viene de `l10n`, deja el texto de creación como está y solo cambia cuando `editingRequest != null`.)

- [ ] **Step 5: Verificar que compila**

Run: `cd gea_app && dart analyze lib/features/announcements/presentation/screens/request_announcement_screen.dart`
Expected: "No issues found!"

- [ ] **Step 6: Commit**

```bash
cd gea_app
git add lib/features/announcements/presentation/screens/request_announcement_screen.dart
git commit -m "feat(anuncios): modo edición en RequestAnnouncementScreen (reenvío)"
```

---

## Task 11: Ruta y botón en Perfil

**Files:**
- Modify: `gea_app/lib/config/router/app_router.dart`
- Modify: `gea_app/lib/features/auth/presentation/screens/profile_screen.dart`

- [ ] **Step 1: Registrar las rutas**

En `app_router.dart`, añade los imports:

```dart
import 'package:gea_app/features/announcements/presentation/screens/my_requests_screen.dart';
import 'package:gea_app/features/announcements/domain/entities/announcement_request.dart';
```

Añade la ruta del historial dentro de la lista `routes` (junto a las demás `GoRoute`):

```dart
    GoRoute(
      path: '/my-requests',
      builder: (context, state) => const MyRequestsScreen(),
    ),
```

Y modifica la ruta existente `/request-announcement` para aceptar una solicitud a editar vía `extra`:

```dart
    GoRoute(
      path: '/request-announcement',
      builder: (context, state) => RequestAnnouncementScreen(
        editingRequest: state.extra as AnnouncementRequest?,
      ),
    ),
```

- [ ] **Step 2: Añadir el botón en el Perfil (solo vista logueada)**

En `profile_screen.dart`, dentro del bloque `else ...[` (vista logueada), justo **antes** del `GeaButton` de logout (la línea `const SizedBox(height: 48)` que lo precede), inserta:

```dart
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.receipt_long_outlined, color: AppTokens.primary),
                    title: const Text('Mis Solicitudes',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Estado de tus solicitudes de anuncio'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/my-requests'),
                  ),
                ),
```

(El `import` de `go_router` y de `AppTokens` ya están presentes en `profile_screen.dart`.)

- [ ] **Step 3: Verificar que compila**

Run: `cd gea_app && dart analyze lib/config/router/app_router.dart lib/features/auth/presentation/screens/profile_screen.dart`
Expected: "No issues found!"

- [ ] **Step 4: Commit**

```bash
cd gea_app
git add lib/config/router/app_router.dart lib/features/auth/presentation/screens/profile_screen.dart
git commit -m "feat(anuncios): ruta /my-requests + botón 'Mis Solicitudes' en Perfil"
```

---

## Task 12: Verificación end-to-end y build

**Files:** ninguno (verificación).

- [ ] **Step 1: Correr toda la suite de tests Flutter**

Run: `cd gea_app && flutter test`
Expected: todos los tests pasan (incluye los nuevos de Tareas 2, 4, 5, 7).

- [ ] **Step 2: Analizar todo el proyecto**

Run: `cd gea_app && flutter analyze`
Expected: sin errores.

- [ ] **Step 3: Construir el APK con las variables**

Run: `cd gea_app && flutter build apk --debug --dart-define-from-file=dart_define.json`
Expected: `Built build\app\outputs\flutter-apk\app-debug.apk`.

- [ ] **Step 4: Verificación manual en dispositivo** (con backend corriendo y el usuario logueado como estudiante)

Verifica el flujo completo:
1. Perfil → botón "Mis Solicitudes" → se abre el historial.
2. Se ven **solo** las solicitudes propias, cada una con su badge de estado.
3. Una RECHAZADA muestra el motivo; una EN_REVISION muestra las observaciones.
4. En una EN_REVISION o RECHAZADA, "Editar y reenviar" abre el formulario precargado.
5. Al guardar, la solicitud vuelve a PENDIENTE y el historial se refresca mostrando el nuevo estado.
6. Cerrar sesión y entrar con otro usuario: no aparecen las solicitudes del primero.

- [ ] **Step 5: Commit final (si hubo ajustes de la verificación manual)**

```bash
cd gea_app
git add -A
git commit -m "chore(anuncios): ajustes de verificación del historial de solicitudes"
```

---

## Self-Review (cobertura del spec)

| Requisito del usuario | Tarea que lo implementa |
|---|---|
| Botón en sección usuario que muestra historial | Tarea 11 (botón) + Tarea 9 (pantalla) |
| Estado: rechazada / en revisión / aceptada | Tarea 7 (badge) + Tarea 8 (card) |
| El "porqué" (motivo/observaciones) | Tarea 8 (`_reasonBox`) + Tarea 4 (mapea `motivoRechazo`/`observacionesRevision`) |
| Misma lógica que la plataforma | Backend sin cambios (ya la tiene) + Tarea 1 (la blinda) |
| Si está en revisión, editar y reenviar | Tarea 10 (modo edición) + Tarea 6 (`submitEdit`) — backend regresa a PENDIENTE |
| Solo ve las propias | Backend `listarPropias` + Tarea 1 (test) + Tarea 5 (endpoint `mis-solicitudes`) |
| Debe estar logueado | El botón solo aparece en la vista logueada del Perfil (Tarea 11); endpoints ya requieren auth |

**Decisión registrada (actualizada 2026-07-03):** solo EN_REVISION es editable/reenviable. RECHAZADA es un estado definitivo — no se puede reenviar, ese es el propósito del modo revisión. Corregido en backend, app móvil y plataforma web.
```
