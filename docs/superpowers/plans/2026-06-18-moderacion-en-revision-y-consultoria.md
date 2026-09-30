# Moderación "En revisión" y Rol "Consultoría" — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Agregar a GEA (1) una opción de moderación "En revisión" que devuelve solicitudes con observaciones a la oficina para que las corrija y reenvíe la misma solicitud, y (2) un rol "Consultoría" de solo lectura global que también puede crear sus propios eventos/anuncios.

**Architecture:** Backend Spring Boot añade un estado `EN_REVISION`, un campo `observacionesRevision`, endpoints `/devolver`, un valor de rol `CONSULTORIA` y reglas de seguridad. El front React añade el botón "En revisión" con caja de observaciones en los modales de moderación, muestra las observaciones a la oficina, hace editable el estado devuelto, y habilita las rutas para Consultoría sin exponer acciones de moderación ni el panel de usuarios. El control real de permisos vive en el backend (`@PreAuthorize` + `SecurityConfig`); el front solo oculta UI.

**Tech Stack:** Spring Boot 3, JPA/Hibernate, MapStruct, JUnit 5 + AssertJ (`@SpringBootTest`, perfil `test`), Spring Security (JWT). Front: React + Vite, react-router, axios, react-toastify.

**Repos / rutas:**
- Backend: `C:\Users\Administrador\Documents\test\GEA_BACKEND`
- Web: `C:\Users\Administrador\Documents\Proyecto 2\GEA_FRONT`

**Comandos:**
- Backend test (un solo test): `./mvnw -q -Dtest=NombreTest test` (en la raíz del backend)
- Backend build (regenera MapStruct): `./mvnw -q -DskipTests compile`
- Web dev: `npm run dev` (en la raíz del front)

**Orden recomendado:** Fase 1 → Fase 2 (backend, con tests) antes de Fase 3 → Fase 4 (web). El backend es la parte crítica de seguridad y se hace con TDD primero.

**Nota de scope:** Este plan cubre dos funcionalidades en dos capas. Cada Fase produce software coherente y verificable. Si se prefiere, las Fases 1+3 (En revisión) y 2+4 (Consultoría) pueden ejecutarse como dos entregas independientes.

---

## FASE 1 — Backend: estado "En revisión" (devolver para corregir)

### Task 1: Agregar el estado `EN_REVISION` al enum

**Files:**
- Modify: `src/main/java/com/calendario/callapp/callapp_backend/entity/EstadoSolicitud.java`
- Test: `src/test/java/com/calendario/callapp/callapp_backend/smoke/EstadoSolicitudTest.java`

- [ ] **Step 1: Escribir el test que falla**

```java
package com.calendario.callapp.callapp_backend.smoke;

import com.calendario.callapp.callapp_backend.entity.EstadoSolicitud;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.catchThrowable;

class EstadoSolicitudTest {

    @Test
    void existe_el_estado_en_revision() {
        EstadoSolicitud estado = EstadoSolicitud.valueOf("EN_REVISION");
        assertThat(estado).isNotNull();
    }

    @Test
    void el_enum_conserva_los_estados_previos() {
        assertThat(catchThrowable(() -> EstadoSolicitud.valueOf("PENDIENTE"))).isNull();
        assertThat(catchThrowable(() -> EstadoSolicitud.valueOf("APROBADA"))).isNull();
        assertThat(catchThrowable(() -> EstadoSolicitud.valueOf("RECHAZADA"))).isNull();
        assertThat(catchThrowable(() -> EstadoSolicitud.valueOf("PUBLICADA"))).isNull();
    }
}
```

- [ ] **Step 2: Ejecutar el test y verlo fallar**

Run: `./mvnw -q -Dtest=EstadoSolicitudTest test`
Expected: FAIL — `IllegalArgumentException: No enum constant ... EN_REVISION`

- [ ] **Step 3: Implementación mínima**

En `EstadoSolicitud.java`:

```java
public enum EstadoSolicitud {
    PENDIENTE,
    APROBADA,
    RECHAZADA,
    PUBLICADA,
    EN_REVISION
}
```

- [ ] **Step 4: Ejecutar el test y verlo pasar**

Run: `./mvnw -q -Dtest=EstadoSolicitudTest test`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add src/main/java/com/calendario/callapp/callapp_backend/entity/EstadoSolicitud.java src/test/java/com/calendario/callapp/callapp_backend/smoke/EstadoSolicitudTest.java
git commit -m "feat(solicitud): agrega estado EN_REVISION al enum EstadoSolicitud"
```

---

### Task 2: Campo `observacionesRevision` en las entidades

**Files:**
- Modify: `src/main/java/com/calendario/callapp/callapp_backend/entity/SolicitudEvento.java:79`
- Modify: `src/main/java/com/calendario/callapp/callapp_backend/entity/SolicitudAnuncio.java:79`

Ambas entidades usan Lombok `@Data` (getters/setters automáticos). El campo `motivoRechazo` ya existe con `@Column(length = 1000)`.

- [ ] **Step 1: Agregar el campo en `SolicitudEvento.java`** (inmediatamente después de `private String motivoRechazo;`)

```java
    @Column(length = 1000)
    private String observacionesRevision;
```

- [ ] **Step 2: Agregar el mismo campo en `SolicitudAnuncio.java`** (después de `private String motivoRechazo;`)

```java
    @Column(length = 1000)
    private String observacionesRevision;
```

- [ ] **Step 3: Compilar para validar JPA/Lombok**

Run: `./mvnw -q -DskipTests compile`
Expected: BUILD SUCCESS

- [ ] **Step 4: Commit**

```bash
git add src/main/java/com/calendario/callapp/callapp_backend/entity/SolicitudEvento.java src/main/java/com/calendario/callapp/callapp_backend/entity/SolicitudAnuncio.java
git commit -m "feat(solicitud): agrega campo observacionesRevision a entidades de evento y anuncio"
```

---

### Task 3: Exponer `observacionesRevision` en los Response DTOs

**Files:**
- Modify: `src/main/java/com/calendario/callapp/callapp_backend/dto/response/SolicitudEventoResponse.java:32`
- Modify: `src/main/java/com/calendario/callapp/callapp_backend/dto/response/SolicitudAnuncioResponse.java:30`

MapStruct auto-mapea propiedades con el mismo nombre; basta con declarar el campo en el DTO.

- [ ] **Step 1: En `SolicitudEventoResponse.java`, después de `private String motivoRechazo;`**

```java
    private String observacionesRevision;
```

- [ ] **Step 2: En `SolicitudAnuncioResponse.java`, después de `private String motivoRechazo;`**

```java
    private String observacionesRevision;
```

- [ ] **Step 3: Recompilar para regenerar los mappers de MapStruct**

Run: `./mvnw -q -DskipTests compile`
Expected: BUILD SUCCESS. Verificar en `target/generated-sources/.../SolicitudEventoMapperImpl.java` que aparece `response.setObservacionesRevision( solicitud.getObservacionesRevision() );`

- [ ] **Step 4: Commit**

```bash
git add src/main/java/com/calendario/callapp/callapp_backend/dto/response/SolicitudEventoResponse.java src/main/java/com/calendario/callapp/callapp_backend/dto/response/SolicitudAnuncioResponse.java
git commit -m "feat(solicitud): expone observacionesRevision en los response DTOs"
```

---

### Task 4: DTO `DevolucionRequest`

**Files:**
- Create: `src/main/java/com/calendario/callapp/callapp_backend/dto/request/DevolucionRequest.java`

- [ ] **Step 1: Crear el DTO** (espejo de `RechazoRequest`)

```java
package com.calendario.callapp.callapp_backend.dto.request;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class DevolucionRequest {

    @NotBlank
    private String observaciones;
}
```

- [ ] **Step 2: Compilar**

Run: `./mvnw -q -DskipTests compile`
Expected: BUILD SUCCESS

- [ ] **Step 3: Commit**

```bash
git add src/main/java/com/calendario/callapp/callapp_backend/dto/request/DevolucionRequest.java
git commit -m "feat(solicitud): agrega DevolucionRequest para observaciones de moderación"
```

---

### Task 5: `devolver()` en `SolicitudEventoServiceImpl`

**Files:**
- Modify: `src/main/java/com/calendario/callapp/callapp_backend/service/impl/SolicitudEventoServiceImpl.java` (después del método `rechazar`, ~línea 417)
- Test: `src/test/java/com/calendario/callapp/callapp_backend/smoke/EventoDevolucionTest.java`

- [ ] **Step 1: Escribir el test que falla**

```java
package com.calendario.callapp.callapp_backend.smoke;

import com.calendario.callapp.callapp_backend.dto.request.DevolucionRequest;
import com.calendario.callapp.callapp_backend.entity.*;
import com.calendario.callapp.callapp_backend.repository.*;
import com.calendario.callapp.callapp_backend.service.impl.SolicitudEventoServiceImpl;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest
@ActiveProfiles("test")
@Transactional
class EventoDevolucionTest {

    @Autowired private SolicitudEventoServiceImpl service;
    @Autowired private SolicitudEventoRepository solicitudEventoRepository;
    @Autowired private UsuarioRepository usuarioRepository;
    @Autowired private OficinaRepository oficinaRepository;
    @Autowired private RolRepository rolRepository;
    @Autowired private TipoEventoCatalogoRepository tipoEventoCatalogoRepository;

    private Usuario revisor;
    private SolicitudEvento solicitud;

    @BeforeEach
    void setUp() {
        RolEntity rol = rolRepository.findByNombre("Comunicaciones")
                .orElseGet(() -> { RolEntity r = new RolEntity(); r.setNombre("Comunicaciones"); return rolRepository.save(r); });

        Oficina oficina = new Oficina();
        oficina.setNombre("Oficina Dev " + System.currentTimeMillis());
        oficina.setActiva(true);
        oficina = oficinaRepository.save(oficina);

        revisor = new Usuario();
        revisor.setNombre("Revisor Test");
        revisor.setCorreo("revisor." + System.currentTimeMillis() + "@gea.edu.co");
        revisor.setPassword("dummy");
        revisor.setRolEntity(rol);
        revisor.setOficina(oficina);
        revisor.setEstado("ACTIVO");
        revisor.setAuthProvider(AuthProvider.LOCAL);
        revisor = usuarioRepository.save(revisor);

        TipoEventoCatalogo tipo = new TipoEventoCatalogo();
        tipo.setNombre("Tipo Dev " + System.currentTimeMillis());
        tipo.setColorHex("#CE1126");
        tipo.setActivo(true);
        tipo = tipoEventoCatalogoRepository.save(tipo);

        solicitud = new SolicitudEvento();
        solicitud.setNombreEvento("Evento a devolver");
        solicitud.setFechaEvento(LocalDate.now().plusDays(5));
        solicitud.setHoraInicio(LocalTime.of(9, 0));
        solicitud.setHoraFin(LocalTime.of(10, 0));
        solicitud.setOficina(oficina);
        solicitud.setUsuarioSolicitante(revisor);
        solicitud.setTipoEventoCatalogo(tipo);
        solicitud.setEstado(EstadoSolicitud.PENDIENTE);
        solicitud = solicitudEventoRepository.save(solicitud);
    }

    private Authentication authDe(Usuario u) {
        return new UsernamePasswordAuthenticationToken(u.getCorreo(), null, List.of());
    }

    @Test
    void devolver_pone_estado_en_revision_y_guarda_observaciones() {
        DevolucionRequest req = new DevolucionRequest();
        req.setObservaciones("Corregir la fecha y agregar el lugar.");

        service.devolver(solicitud.getId(), req, authDe(revisor));

        SolicitudEvento actualizada = solicitudEventoRepository.findById(solicitud.getId()).orElseThrow();
        assertThat(actualizada.getEstado()).isEqualTo(EstadoSolicitud.EN_REVISION);
        assertThat(actualizada.getObservacionesRevision()).isEqualTo("Corregir la fecha y agregar el lugar.");
        assertThat(actualizada.getUsuarioRevisor()).isNotNull();
        assertThat(actualizada.getFechaRevision()).isNotNull();
    }
}
```

- [ ] **Step 2: Ejecutar el test y verlo fallar**

Run: `./mvnw -q -Dtest=EventoDevolucionTest test`
Expected: FAIL — `service.devolver(...)` no existe (no compila)

- [ ] **Step 3: Implementar `devolver()`** (insertar después del método `rechazar`, antes de `aprobarSerie`)

```java
    @Transactional
    public SolicitudEventoResponse devolver(Long id, DevolucionRequest request, Authentication authentication) {
        SolicitudEvento solicitud = buscarSolicitud(id);

        Usuario revisor = obtenerUsuario(authentication);
        solicitud.setEstado(EstadoSolicitud.EN_REVISION);
        solicitud.setObservacionesRevision(request.getObservaciones());
        solicitud.setUsuarioRevisor(revisor);
        solicitud.setFechaRevision(LocalDateTime.now());

        SolicitudEvento guardada = solicitudEventoRepository.save(solicitud);
        return solicitudEventoMapper.toResponse(guardada);
    }
```

Agregar el import al inicio del archivo:

```java
import com.calendario.callapp.callapp_backend.dto.request.DevolucionRequest;
```

- [ ] **Step 4: Ejecutar el test y verlo pasar**

Run: `./mvnw -q -Dtest=EventoDevolucionTest test`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add src/main/java/com/calendario/callapp/callapp_backend/service/impl/SolicitudEventoServiceImpl.java src/test/java/com/calendario/callapp/callapp_backend/smoke/EventoDevolucionTest.java
git commit -m "feat(eventos): devolver() deja la solicitud EN_REVISION con observaciones"
```

---

### Task 6: Reenvío `EN_REVISION → PENDIENTE` al editar (eventos)

La lógica existente en `actualizarPropia` (`SolicitudEventoServiceImpl.java:309-315`) ya resetea a `PENDIENTE` y limpia `motivoRechazo` cuando NO es `(isAdmin && isAprobada)`. Se debe limpiar también `observacionesRevision` en ese reseteo.

**Files:**
- Modify: `src/main/java/com/calendario/callapp/callapp_backend/service/impl/SolicitudEventoServiceImpl.java:309-315`
- Test: agregar al archivo `EventoDevolucionTest.java`

- [ ] **Step 1: Agregar el test que falla** (nuevo método en `EventoDevolucionTest`)

```java
    @Test
    void editar_una_solicitud_en_revision_la_regresa_a_pendiente_y_limpia_observaciones() {
        // dejarla EN_REVISION
        DevolucionRequest dev = new DevolucionRequest();
        dev.setObservaciones("Falta el lugar");
        service.devolver(solicitud.getId(), dev, authDe(revisor));

        // el solicitante edita y reenvía
        com.calendario.callapp.callapp_backend.dto.request.SolicitudEventoRequest edit =
                new com.calendario.callapp.callapp_backend.dto.request.SolicitudEventoRequest();
        edit.setNombreEvento("Evento corregido");
        edit.setFechaEvento(LocalDate.now().plusDays(6));
        edit.setHoraInicio(LocalTime.of(9, 0));
        edit.setHoraFin(LocalTime.of(11, 0));
        edit.setTipoEvento(solicitud.getTipoEventoCatalogo().getNombre());

        service.actualizarPropia(solicitud.getId(), edit, authDe(revisor));

        SolicitudEvento r = solicitudEventoRepository.findById(solicitud.getId()).orElseThrow();
        assertThat(r.getEstado()).isEqualTo(EstadoSolicitud.PENDIENTE);
        assertThat(r.getObservacionesRevision()).isNull();
    }
```

- [ ] **Step 2: Ejecutar y ver fallar**

Run: `./mvnw -q -Dtest=EventoDevolucionTest test`
Expected: FAIL — `observacionesRevision` sigue con texto (no se limpia)

- [ ] **Step 3: Implementar** — en el bloque `if (!(isAdmin && isAprobada)) { ... }` (línea ~310) agregar la limpieza:

```java
        if (!(isAdmin && isAprobada)) {
            solicitud.setEstado(EstadoSolicitud.PENDIENTE);
            solicitud.setMotivoRechazo(null);
            solicitud.setObservacionesRevision(null);
            solicitud.setUsuarioRevisor(null);
            solicitud.setFechaRevision(null);
        }
```

- [ ] **Step 4: Ejecutar y ver pasar**

Run: `./mvnw -q -Dtest=EventoDevolucionTest test`
Expected: PASS (ambos tests)

- [ ] **Step 5: Commit**

```bash
git add src/main/java/com/calendario/callapp/callapp_backend/service/impl/SolicitudEventoServiceImpl.java src/test/java/com/calendario/callapp/callapp_backend/smoke/EventoDevolucionTest.java
git commit -m "feat(eventos): editar solicitud EN_REVISION la reenvía a PENDIENTE y limpia observaciones"
```

---

### Task 7: `devolver()` en `SolicitudAnuncioServiceImpl`

**Files:**
- Modify: `src/main/java/com/calendario/callapp/callapp_backend/service/impl/SolicitudAnuncioServiceImpl.java` (después de `rechazar`, ~línea 205)
- Test: `src/test/java/com/calendario/callapp/callapp_backend/smoke/AnuncioDevolucionTest.java`

- [ ] **Step 1: Escribir el test que falla**

```java
package com.calendario.callapp.callapp_backend.smoke;

import com.calendario.callapp.callapp_backend.dto.request.DevolucionRequest;
import com.calendario.callapp.callapp_backend.dto.request.SolicitudAnuncioRequest;
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

import java.time.LocalDate;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest
@ActiveProfiles("test")
@Transactional
class AnuncioDevolucionTest {

    @Autowired private SolicitudAnuncioServiceImpl service;
    @Autowired private SolicitudAnuncioRepository solicitudAnuncioRepository;
    @Autowired private UsuarioRepository usuarioRepository;
    @Autowired private OficinaRepository oficinaRepository;
    @Autowired private RolRepository rolRepository;

    private Usuario solicitante;
    private SolicitudAnuncio solicitud;

    @BeforeEach
    void setUp() {
        RolEntity rol = rolRepository.findByNombre("Oficina")
                .orElseGet(() -> { RolEntity r = new RolEntity(); r.setNombre("Oficina"); return rolRepository.save(r); });

        Oficina oficina = new Oficina();
        oficina.setNombre("Oficina AnunDev " + System.currentTimeMillis());
        oficina.setActiva(true);
        oficina = oficinaRepository.save(oficina);

        solicitante = new Usuario();
        solicitante.setNombre("Solicitante Anuncio");
        solicitante.setCorreo("anun." + System.currentTimeMillis() + "@gea.edu.co");
        solicitante.setPassword("dummy");
        solicitante.setRolEntity(rol);
        solicitante.setOficina(oficina);
        solicitante.setEstado("ACTIVO");
        solicitante.setAuthProvider(AuthProvider.LOCAL);
        solicitante = usuarioRepository.save(solicitante);

        solicitud = new SolicitudAnuncio();
        solicitud.setTitulo("Anuncio a devolver");
        solicitud.setDescripcion("Contenido");
        solicitud.setCategoria("Informativo");
        solicitud.setFechaInicioPublicacion(LocalDate.now());
        solicitud.setFechaFinPublicacion(LocalDate.now().plusDays(10));
        solicitud.setUsuarioSolicitante(solicitante);
        solicitud.setEstado(EstadoSolicitud.PENDIENTE);
        solicitud = solicitudAnuncioRepository.save(solicitud);
    }

    private Authentication authDe(Usuario u) {
        return new UsernamePasswordAuthenticationToken(u.getCorreo(), null, List.of());
    }

    @Test
    void devolver_pone_estado_en_revision_y_guarda_observaciones() {
        DevolucionRequest req = new DevolucionRequest();
        req.setObservaciones("Ajustar las fechas de publicación.");

        service.devolver(solicitud.getId(), req, authDe(solicitante));

        SolicitudAnuncio r = solicitudAnuncioRepository.findById(solicitud.getId()).orElseThrow();
        assertThat(r.getEstado()).isEqualTo(EstadoSolicitud.EN_REVISION);
        assertThat(r.getObservacionesRevision()).isEqualTo("Ajustar las fechas de publicación.");
        assertThat(r.getFechaRevision()).isNotNull();
    }
}
```

- [ ] **Step 2: Ejecutar y ver fallar**

Run: `./mvnw -q -Dtest=AnuncioDevolucionTest test`
Expected: FAIL — `service.devolver(...)` no existe

- [ ] **Step 3: Implementar `devolver()`** (insertar después de `rechazar`, ~línea 205)

```java
    @Transactional
    public SolicitudAnuncioResponse devolver(Long id, DevolucionRequest request, Authentication authentication) {
        SolicitudAnuncio solicitud = buscarSolicitud(id);
        solicitud.setEstado(EstadoSolicitud.EN_REVISION);
        solicitud.setObservacionesRevision(request.getObservaciones());
        solicitud.setUsuarioRevisor(obtenerUsuario(authentication));
        solicitud.setFechaRevision(LocalDateTime.now());

        SolicitudAnuncio guardada = solicitudAnuncioRepository.save(solicitud);
        return solicitudAnuncioMapper.toResponse(guardada);
    }
```

Agregar el import:

```java
import com.calendario.callapp.callapp_backend.dto.request.DevolucionRequest;
```

- [ ] **Step 4: Ejecutar y ver pasar**

Run: `./mvnw -q -Dtest=AnuncioDevolucionTest test`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add src/main/java/com/calendario/callapp/callapp_backend/service/impl/SolicitudAnuncioServiceImpl.java src/test/java/com/calendario/callapp/callapp_backend/smoke/AnuncioDevolucionTest.java
git commit -m "feat(anuncios): devolver() deja la solicitud EN_REVISION con observaciones"
```

---

### Task 8: Reenvío `EN_REVISION → PENDIENTE` al editar (anuncios)

A diferencia de eventos, `SolicitudAnuncioServiceImpl.actualizar` (línea 94-122) **no** resetea el estado. Hay que agregar: si el solicitante (no admin) edita una solicitud en `EN_REVISION` o `RECHAZADA`, vuelve a `PENDIENTE` y se limpian motivo y observaciones.

**Files:**
- Modify: `src/main/java/com/calendario/callapp/callapp_backend/service/impl/SolicitudAnuncioServiceImpl.java:119-121`
- Test: agregar a `AnuncioDevolucionTest.java`

- [ ] **Step 1: Agregar el test que falla**

```java
    @Test
    void editar_anuncio_en_revision_lo_regresa_a_pendiente_y_limpia_observaciones() {
        DevolucionRequest dev = new DevolucionRequest();
        dev.setObservaciones("Faltan fechas");
        service.devolver(solicitud.getId(), dev, authDe(solicitante));

        SolicitudAnuncioRequest edit = new SolicitudAnuncioRequest();
        edit.setTitulo("Anuncio corregido");

        service.actualizar(solicitud.getId(), edit, authDe(solicitante));

        SolicitudAnuncio r = solicitudAnuncioRepository.findById(solicitud.getId()).orElseThrow();
        assertThat(r.getEstado()).isEqualTo(EstadoSolicitud.PENDIENTE);
        assertThat(r.getObservacionesRevision()).isNull();
    }
```

- [ ] **Step 2: Ejecutar y ver fallar**

Run: `./mvnw -q -Dtest=AnuncioDevolucionTest test`
Expected: FAIL — el estado sigue `EN_REVISION`

- [ ] **Step 3: Implementar** — en `actualizar`, justo antes de `return enrichResponse(...)` (línea 121), agregar:

```java
        boolean devueltaOReprobada = solicitud.getEstado() == EstadoSolicitud.EN_REVISION
                || solicitud.getEstado() == EstadoSolicitud.RECHAZADA;
        if (isOwner && !isAdmin && devueltaOReprobada) {
            solicitud.setEstado(EstadoSolicitud.PENDIENTE);
            solicitud.setMotivoRechazo(null);
            solicitud.setObservacionesRevision(null);
            solicitud.setUsuarioRevisor(null);
            solicitud.setFechaRevision(null);
        }
```

(las variables `isOwner` e `isAdmin` ya existen en el método, líneas 98-99)

- [ ] **Step 4: Ejecutar y ver pasar**

Run: `./mvnw -q -Dtest=AnuncioDevolucionTest test`
Expected: PASS (ambos tests)

- [ ] **Step 5: Commit**

```bash
git add src/main/java/com/calendario/callapp/callapp_backend/service/impl/SolicitudAnuncioServiceImpl.java src/test/java/com/calendario/callapp/callapp_backend/smoke/AnuncioDevolucionTest.java
git commit -m "feat(anuncios): editar solicitud devuelta/rechazada la reenvía a PENDIENTE"
```

---

### Task 9: Endpoints `/devolver` en los controllers

**Files:**
- Modify: `src/main/java/com/calendario/callapp/callapp_backend/controller/SolicitudEventoController.java` (después de `rechazar`, ~línea 114)
- Modify: `src/main/java/com/calendario/callapp/callapp_backend/controller/SolicitudAnuncioController.java` (después de `rechazar`, ~línea 77)

- [ ] **Step 1: Endpoint en `SolicitudEventoController.java`**

```java
    @PostMapping("/comunicaciones/solicitudes-evento/{id}/devolver")
    @PreAuthorize("hasAnyRole('SUPER_ADMIN', 'COMUNICACIONES', 'ADMIN')")
    public ResponseEntity<ApiResponse<SolicitudEventoResponse>> devolver(
            @PathVariable Long id,
            @Valid @RequestBody com.calendario.callapp.callapp_backend.dto.request.DevolucionRequest request,
            Authentication authentication) {
        return ResponseEntity.ok(ApiResponse.success(
                solicitudEventoService.devolver(id, request, authentication),
                "Solicitud devuelta para revisión"));
    }
```

- [ ] **Step 2: Endpoint en `SolicitudAnuncioController.java`**

```java
    @PostMapping("/comunicaciones/solicitudes-anuncio/{id}/devolver")
    @PreAuthorize("hasAnyRole('SUPER_ADMIN', 'COMUNICACIONES', 'ADMIN')")
    public ResponseEntity<ApiResponse<SolicitudAnuncioResponse>> devolver(
            @PathVariable Long id,
            @Valid @RequestBody com.calendario.callapp.callapp_backend.dto.request.DevolucionRequest request,
            Authentication authentication) {
        return ResponseEntity.ok(ApiResponse.success(
                solicitudAnuncioService.devolver(id, request, authentication),
                "Anuncio devuelto para revisión"));
    }
```

- [ ] **Step 3: Compilar y correr toda la suite de la Fase 1**

Run: `./mvnw -q -Dtest=EstadoSolicitudTest,EventoDevolucionTest,AnuncioDevolucionTest test`
Expected: BUILD SUCCESS, todos PASS

- [ ] **Step 4: Commit**

```bash
git add src/main/java/com/calendario/callapp/callapp_backend/controller/SolicitudEventoController.java src/main/java/com/calendario/callapp/callapp_backend/controller/SolicitudAnuncioController.java
git commit -m "feat(moderacion): endpoints POST /devolver para eventos y anuncios"
```

---

## FASE 2 — Backend: rol "Consultoría" (solo lectura global)

### Task 10: Valor `CONSULTORIA` en el enum `Rol`

**Files:**
- Modify: `src/main/java/com/calendario/callapp/callapp_backend/entity/Rol.java`
- Test: `src/test/java/com/calendario/callapp/callapp_backend/smoke/RolMappingTest.java`

- [ ] **Step 1: Escribir el test que falla**

```java
package com.calendario.callapp.callapp_backend.smoke;

import com.calendario.callapp.callapp_backend.entity.Rol;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class RolMappingTest {

    @Test
    void fromNombre_mapea_consultoria() {
        assertThat(Rol.fromNombre("Consultoria")).isEqualTo(Rol.CONSULTORIA);
    }

    @Test
    void consultoria_security_role_es_CONSULTORIA() {
        assertThat(Rol.CONSULTORIA.getSecurityRole()).isEqualTo("CONSULTORIA");
    }

    @Test
    void consultoria_no_es_administrador_ni_oficina() {
        assertThat(Rol.CONSULTORIA.esAdministradorGlobal()).isFalse();
        assertThat(Rol.CONSULTORIA.esOficina()).isFalse();
        assertThat(Rol.CONSULTORIA.esComunicaciones()).isFalse();
    }
}
```

- [ ] **Step 2: Ejecutar y ver fallar**

Run: `./mvnw -q -Dtest=RolMappingTest test`
Expected: FAIL — `Rol.CONSULTORIA` no existe

- [ ] **Step 3: Implementar** — en `Rol.java` agregar el valor y el mapeo:

```java
public enum Rol {
    SUPER_ADMIN,
    COMUNICACIONES,
    OFICINA,
    USUARIO_APP,
    USUARIO_AUTENTICADO_APP,
    ADMIN,
    CONSULTORIA,
    USUARIO;
```

Y en `fromNombre`, agregar el case (antes del `default`):

```java
            case "Consultoria" -> CONSULTORIA;
```

(`getSecurityRole()` no necesita cambios: el `default` ya retorna `this.name()` → `"CONSULTORIA"`. `esAdministradorGlobal/esOficina/esComunicaciones` ya excluyen CONSULTORIA.)

- [ ] **Step 4: Ejecutar y ver pasar**

Run: `./mvnw -q -Dtest=RolMappingTest test`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add src/main/java/com/calendario/callapp/callapp_backend/entity/Rol.java src/test/java/com/calendario/callapp/callapp_backend/smoke/RolMappingTest.java
git commit -m "feat(roles): agrega rol CONSULTORIA y su mapeo desde nombre DB"
```

---

### Task 11: Sembrar el rol "Consultoria"

**Files:**
- Modify: `src/main/java/com/calendario/callapp/callapp_backend/config/DataInitializer.java:62-71`

`inicializarRoles()` solo siembra cuando `rolRepository.count() == 0`. Para que el nuevo rol aparezca también en bases ya inicializadas, se cambia a un patrón idempotente (crear si no existe).

- [ ] **Step 1: Reemplazar el cuerpo de `inicializarRoles()`** por:

```java
    @SuppressWarnings("null")
    private void inicializarRoles() {
        List.of("SuperAdmin", "Comunicaciones", "Oficina", "Usuario Autenticado", "Consultoria")
            .forEach(nombre -> {
                if (rolRepository.findByNombre(nombre).isEmpty()) {
                    log.info("Creando rol base: {}", nombre);
                    rolRepository.save(crearRol(nombre));
                }
            });
    }
```

- [ ] **Step 2: Compilar**

Run: `./mvnw -q -DskipTests compile`
Expected: BUILD SUCCESS

- [ ] **Step 3: Verificación manual** — arrancar el backend y confirmar en la tabla `roles` que existe la fila `Consultoria`. (Si la app ya estaba inicializada, este cambio la agrega sin duplicar las demás.)

- [ ] **Step 4: Commit**

```bash
git add src/main/java/com/calendario/callapp/callapp_backend/config/DataInitializer.java
git commit -m "feat(roles): siembra idempotente del rol Consultoria"
```

---

### Task 12: Reglas de seguridad para `CONSULTORIA`

**Files:**
- Modify: `src/main/java/com/calendario/callapp/callapp_backend/security/SecurityConfig.java:52-69`
- Modify: `src/main/java/com/calendario/callapp/callapp_backend/controller/SolicitudEventoController.java:85-99`
- Modify: `src/main/java/com/calendario/callapp/callapp_backend/controller/SolicitudAnuncioController.java:48-62`

Objetivo: `CONSULTORIA` puede **leer** las colas de moderación (GET) y **crear/gestionar lo propio**, pero **no** moderar ni entrar al panel de usuarios.

- [ ] **Step 1: `SecurityConfig` — dar a CONSULTORIA lectura de comunicaciones y acceso a lo propio.** Reemplazar las reglas relevantes dentro de `authorizeHttpRequests` por:

```java
                .requestMatchers(HttpMethod.GET, "/admin/usuarios").hasAnyRole("SUPER_ADMIN", "ADMIN", "COMUNICACIONES")
                .requestMatchers(HttpMethod.GET, "/admin/oficinas").hasAnyRole("SUPER_ADMIN", "ADMIN", "COMUNICACIONES", "OFICINA", "USUARIO_AUTENTICADO_APP", "CONSULTORIA")
                .requestMatchers("/admin/**").hasAnyRole("SUPER_ADMIN", "ADMIN")
                .requestMatchers("/comunicaciones/archivos/upload").hasAnyRole("SUPER_ADMIN", "ADMIN", "COMUNICACIONES", "OFICINA", "USUARIO_AUTENTICADO_APP")
                .requestMatchers(HttpMethod.GET, "/comunicaciones/**").hasAnyRole("SUPER_ADMIN", "ADMIN", "COMUNICACIONES", "CONSULTORIA")
                .requestMatchers("/comunicaciones/**").hasAnyRole("SUPER_ADMIN", "ADMIN", "COMUNICACIONES")
                .requestMatchers("/oficina/**").hasAnyRole("SUPER_ADMIN", "ADMIN", "COMUNICACIONES", "OFICINA", "CONSULTORIA")
                .requestMatchers("/app/solicitudes-anuncio/**").hasAnyRole("USUARIO_AUTENTICADO_APP", "SUPER_ADMIN", "ADMIN", "COMUNICACIONES", "OFICINA", "USUARIO_APP", "CONSULTORIA")
```

> Nota: la regla `GET /comunicaciones/**` debe ir **antes** de la regla genérica `/comunicaciones/**` para que Spring evalúe primero la de lectura. Los POST de moderación (`aprobar/rechazar/publicar/devolver`) caen en la regla genérica (sin CONSULTORIA) y además están protegidos por `@PreAuthorize` en cada método. `/admin/**` no incluye CONSULTORIA → panel de usuarios bloqueado.

- [ ] **Step 2: Permitir a CONSULTORIA los GET de eventos en el controller.** En `SolicitudEventoController`, agregar `'CONSULTORIA'` al `@PreAuthorize` de **solo** estos tres métodos GET: `listarParaRevision` (línea 86), `obtenerParaRevision` (línea 96), y a los métodos `crear`/`listarPropias`/`obtenerPropia`/`actualizarPropia` de `/oficina` (líneas 35, 44, 55, 61) para que pueda crear/editar lo propio. Ejemplo para `listarParaRevision`:

```java
    @GetMapping("/comunicaciones/solicitudes-evento")
    @PreAuthorize("hasAnyRole('SUPER_ADMIN', 'COMUNICACIONES', 'ADMIN', 'CONSULTORIA')")
    public ResponseEntity<ApiResponse<List<SolicitudEventoResponse>>> listarParaRevision(...) {
```

NO agregar CONSULTORIA a `aprobar`, `rechazar`, `publicar`, `devolver`, ni a los de serie/publicación.

- [ ] **Step 3: Permitir a CONSULTORIA los GET de anuncios.** En `SolicitudAnuncioController`, agregar `'CONSULTORIA'` al `@PreAuthorize` de `listarParaRevision` (línea 49), `obtenerParaRevision` (línea 59), `crear` (línea 29), `listarPropias` (línea 38), `actualizar` (línea 110) y `eliminarSolicitudPropia` (línea 103). NO agregarlo a `aprobar`/`rechazar`/`publicar`/`devolver`.

- [ ] **Step 4: Compilar y correr toda la suite**

Run: `./mvnw -q test`
Expected: BUILD SUCCESS, todos los tests PASS

- [ ] **Step 5: Verificación manual de seguridad** (con un usuario de rol Consultoria y su JWT):
  - `GET /comunicaciones/solicitudes-evento` → 200
  - `POST /comunicaciones/solicitudes-evento/{id}/aprobar` → 403
  - `POST /comunicaciones/solicitudes-evento/{id}/devolver` → 403
  - `GET /admin/usuarios` → 403
  - `POST /oficina/solicitudes-evento` (crear propio) → 201

- [ ] **Step 6: Commit**

```bash
git add src/main/java/com/calendario/callapp/callapp_backend/security/SecurityConfig.java src/main/java/com/calendario/callapp/callapp_backend/controller/SolicitudEventoController.java src/main/java/com/calendario/callapp/callapp_backend/controller/SolicitudAnuncioController.java
git commit -m "feat(seguridad): CONSULTORIA con lectura global y creación propia, sin moderación ni panel de usuarios"
```

---

## FASE 3 — Web: UI de "En revisión"

> El front no tiene runner de tests; cada task se verifica manualmente en `npm run dev`. Commits frecuentes.

### Task 13: Servicios `devolver` y propagación de `observacionesRevision`

**Files:**
- Modify: `src/services/eventos.service.js:82` y `:169`
- Modify: `src/services/anuncios.service.js`

- [ ] **Step 1: En `eventos.service.js`, dentro del objeto retornado por `mapEventoDTO`** (después de `motivoRechazo: evt.motivoRechazo || null,` línea 82):

```javascript
    observacionesRevision: evt.observacionesRevision || null,
```

- [ ] **Step 2: Agregar el método de servicio** (después de `rechazarEvento`, línea 169):

```javascript
export const devolverEvento = async (id, payload) => {
  return await api.post(`/comunicaciones/solicitudes-evento/${id}/devolver`, payload);
};
```

- [ ] **Step 3: En `anuncios.service.js`**, replicar: agregar `observacionesRevision` en el mapeo del DTO de anuncio y el método:

```javascript
export const devolverAnuncio = async (id, payload) => {
  return await api.post(`/comunicaciones/solicitudes-anuncio/${id}/devolver`, payload);
};
```

(Confirmar el nombre exacto del mapper en `anuncios.service.js` y agregar `observacionesRevision: <dto>.observacionesRevision || null` junto a `motivoRechazo`.)

- [ ] **Step 4: Verificación** — `npm run dev` compila sin errores de import.

- [ ] **Step 5: Commit**

```bash
git add src/services/eventos.service.js src/services/anuncios.service.js
git commit -m "feat(web): servicios devolver y propagacion de observacionesRevision"
```

---

### Task 14: Lógica del hook — acción "Devolver" (eventos)

**Files:**
- Modify: `src/hooks/useEventManagement.js`

El hook ya expone `rejecting, setRejecting, rejectReason, setRejectReason, handleStatusUpdate`. Se añade el flujo análogo para devolución.

- [ ] **Step 1: Agregar estado** junto a `rejecting`/`rejectReason`:

```javascript
  const [reviewing, setReviewing] = useState(false);
  const [reviewObservations, setReviewObservations] = useState('');
```

- [ ] **Step 2: Importar el servicio** `devolverEvento` en el bloque de imports de `eventos.service`.

- [ ] **Step 3: Extender `handleStatusUpdate`** para el caso `'Devolver'` (seguir el patrón del caso `'Rechazar'`: si no está `reviewing`, activarlo; si ya, validar texto y llamar al servicio):

```javascript
    if (action === 'Devolver') {
      if (!reviewing) { setReviewing(true); return; }
      if (!reviewObservations.trim()) { toast.warn('Escribe las observaciones para la oficina.'); return; }
      try {
        setLoadingAction(true);
        await devolverEvento(selectedEvent.id, { observaciones: reviewObservations });
        toast.success('Solicitud devuelta a la oficina para revisión.');
        setReviewing(false); setReviewObservations('');
        await refrescar(); // usar la función de recarga que ya use el hook tras aprobar/rechazar
        closeModal();       // usar el cierre que ya use el hook
      } catch (e) {
        toast.error('No se pudo devolver la solicitud.');
      } finally {
        setLoadingAction(false);
      }
      return;
    }
```

(Ajustar `refrescar()`/`closeModal()` a los nombres reales que el hook ya usa en `'Aprobar'`/`'Rechazar'`.)

- [ ] **Step 4: Exponer en el return del hook**: `reviewing, setReviewing, reviewObservations, setReviewObservations`.

- [ ] **Step 5: Verificación** — `npm run dev` sin errores.

- [ ] **Step 6: Commit**

```bash
git add src/hooks/useEventManagement.js
git commit -m "feat(web): accion Devolver en el hook de gestion de eventos"
```

---

### Task 15: Botón "En revisión" y banner de observaciones (modal de evento)

**Files:**
- Modify: `src/components/ui/EventDetailModal.jsx:52` (props del hook), `:108` (gates), `:513-534` (panel de acción)

- [ ] **Step 1: Recibir las nuevas props del hook** (línea ~52, junto a `rejecting, setRejecting, rejectReason, setRejectReason`):

```javascript
    reviewing, setReviewing, reviewObservations, setReviewObservations,
```

- [ ] **Step 2: En el panel `canReview`** (línea 513-534), agregar la caja de observaciones y el botón. Reemplazar el bloque de botones (líneas 528-532) por:

```jsx
              {reviewing && (
                <div style={{ marginBottom: '16px' }}>
                  <label className={styles.fieldLabel}>Observaciones para la oficina</label>
                  <textarea
                    value={reviewObservations}
                    onChange={e => setReviewObservations(e.target.value)}
                    placeholder="Indique los ajustes que debe corregir la oficina..."
                    className={styles.inputField}
                    style={{ minHeight: '80px' }}
                  />
                </div>
              )}
              <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '12px' }}>
                <button onClick={() => { setRejecting(false); setReviewing(false); }} style={{ display: (rejecting || reviewing) ? 'block' : 'none' }} className={styles.btnSecondary}>Volver</button>
                <button onClick={() => handleStatusUpdate('Rechazar')} disabled={loadingAction} style={{ display: reviewing ? 'none' : 'block' }} className={styles.btnDanger}>{rejecting ? 'Confirmar Rechazo' : 'Rechazar Solicitud'}</button>
                <button onClick={() => handleStatusUpdate('Devolver')} disabled={loadingAction} style={{ display: rejecting ? 'none' : 'block' }} className={styles.btnSecondary}>{reviewing ? 'Confirmar Devolución' : 'En revisión'}</button>
                {!rejecting && !reviewing && <button onClick={() => handleStatusUpdate('Aprobar')} disabled={loadingAction} className={styles.btnPrimary} style={{ background: 'linear-gradient(135deg, #ce1126 0%, #a50e1f 100%)' }}>Aprobar Solicitud</button>}
              </div>
```

- [ ] **Step 3: Banner de observaciones para la oficina.** Donde hoy se muestra `motivoRechazo` (buscar `motivoRechazo` en el modal), agregar un bloque análogo que se muestre cuando `status === 'EN_REVISION'` y exista `event.observacionesRevision`:

```jsx
        {status === 'EN_REVISION' && event.observacionesRevision && (
          <div style={{ background: '#fffbeb', border: '1px solid #fde68a', borderRadius: '12px', padding: '14px', margin: '14px 0' }}>
            <strong style={{ color: '#b45309' }}>Observaciones de revisión:</strong>
            <p style={{ margin: '6px 0 0', color: '#78350f' }}>{event.observacionesRevision}</p>
          </div>
        )}
```

- [ ] **Step 4: Verificación manual** (con usuario Comunicaciones):
  - En una solicitud PENDIENTE aparece el botón "En revisión".
  - Click → aparece la caja, el botón pasa a "Confirmar Devolución".
  - Confirmar → la solicitud queda EN_REVISION y el modal se cierra.

- [ ] **Step 5: Commit**

```bash
git add src/components/ui/EventDetailModal.jsx
git commit -m "feat(web): boton En revision y banner de observaciones en modal de evento"
```

---

### Task 16: Réplica en anuncios (hook + modal)

**Files:**
- Modify: `src/hooks/useAnnouncementManagement.js`
- Modify: `src/components/ui/AnnouncementDetailModal.jsx`

- [ ] **Step 1:** Replicar Task 14 en `useAnnouncementManagement.js` usando `devolverAnuncio`: estado `reviewing/reviewObservations`, caso `'Devolver'` en el handler de cambio de estado, y exponerlos en el return.

- [ ] **Step 2:** Replicar Task 15 en `AnnouncementDetailModal.jsx`: botón "En revisión" + caja de observaciones en el panel de moderación, y banner cuando `status === 'EN_REVISION'` con `observacionesRevision`.

- [ ] **Step 3: Verificación manual** equivalente a Task 15 sobre un anuncio.

- [ ] **Step 4: Commit**

```bash
git add src/hooks/useAnnouncementManagement.js src/components/ui/AnnouncementDetailModal.jsx
git commit -m "feat(web): flujo En revision para anuncios (hook + modal)"
```

---

### Task 17: Estado editable, filtro y badge "En revisión" en vistas de oficina

**Files:**
- Modify: `src/pages/Events.jsx` (filtros de estado ~línea 50; lógica de "editable")
- Modify: `src/pages/Announcements.jsx`

- [ ] **Step 1:** En el arreglo de filtros de estado de `Events.jsx` (donde está `{ key: 'RECHAZADA', label: 'Rechazados' }`, línea 50) agregar:

```javascript
    { key: 'EN_REVISION',       label: 'En revisión' },
```

- [ ] **Step 2:** Buscar en `Events.jsx`/modal dónde se decide si una solicitud es editable por la oficina (típicamente comparando `status === 'PENDIENTE'` o `'RECHAZADA'`). Incluir `'EN_REVISION'` en esa condición para que la oficina pueda editarla y reenviarla.

- [ ] **Step 3:** Asegurar que el badge/etiqueta de estado tenga un caso visual para `EN_REVISION` (color ámbar, label "En revisión"). Si existe un mapa de estados→estilos, agregar la entrada `EN_REVISION`.

- [ ] **Step 4:** Replicar Steps 1-3 en `Announcements.jsx`.

- [ ] **Step 5: Verificación manual** (con usuario Oficina): una solicitud devuelta aparece bajo el filtro "En revisión", muestra las observaciones, es editable, y al guardar vuelve a "Pendiente".

- [ ] **Step 6: Commit**

```bash
git add src/pages/Events.jsx src/pages/Announcements.jsx
git commit -m "feat(web): filtro, badge y edicion para estado EN_REVISION en vistas de oficina"
```

---

## FASE 4 — Web: rol "Consultoría"

### Task 18: Rutas y endpoints de lectura para Consultoría

**Files:**
- Modify: `src/App.jsx:30,34,38`
- Modify: `src/services/eventos.service.js:107,125` y `src/services/anuncios.service.js` (selección de endpoint por rol)

El JWT de Consultoría trae `rol === 'CONSULTORIA'` (de `getSecurityRole()`).

- [ ] **Step 1:** En `App.jsx`, agregar `'CONSULTORIA'` a `allowedRoles` de las rutas `/eventos` (línea 30), `/anuncios` (línea 34) y `/reportes` (línea 38). **No** tocar la ruta `/usuarios` (línea 42).

- [ ] **Step 2:** En `eventos.service.js`, las funciones `getEventosSolicitudes` (línea 106) y `getEventoById` (línea 124) eligen endpoint con `isOficina = role === 'OFICINA' || role === 'USUARIO_AUTENTICADO_APP'`. Consultoría NO es oficina → ya cae en `/comunicaciones/...` (lectura global). Confirmar que el `role` que se pasa proviene de `user.rol`. No requiere cambio salvo verificación.

- [ ] **Step 3:** Verificar el equivalente en `anuncios.service.js` (Consultoría debe leer la lista de revisión `/comunicaciones/solicitudes-anuncio`).

- [ ] **Step 4: Verificación manual** (usuario Consultoria): puede entrar a Eventos, Anuncios, Reportes y Calendario; ve registros de todas las oficinas; NO ve "Usuarios" en el sidebar (ya gateado en `Sidebar.jsx:98` a SUPER_ADMIN/ADMIN); si navega manualmente a `/usuarios`, `ProtectedRoute` muestra "Acceso Denegado".

- [ ] **Step 5: Commit**

```bash
git add src/App.jsx src/services/eventos.service.js src/services/anuncios.service.js
git commit -m "feat(web): rol Consultoria con acceso de lectura a eventos, anuncios y reportes"
```

---

### Task 19: Ocultar acciones de moderación a Consultoría

**Files:**
- Modify: `src/components/ui/EventDetailModal.jsx:105-110`
- Modify: `src/components/ui/AnnouncementDetailModal.jsx` (gate equivalente)
- Modify: `src/utils/roleUtils.js`

Hoy `isAdmin = rol === 'SUPER_ADMIN' || 'COMUNICACIONES' || 'ADMIN'` (línea 105) y `canReview/canPublish/canManage` dependen de `isAdmin`. Como CONSULTORIA no está en `isAdmin`, las acciones ya quedan ocultas. Esta task lo verifica y registra el rol en utilidades.

- [ ] **Step 1:** Confirmar que en `EventDetailModal.jsx` (línea 105) y en `AnnouncementDetailModal.jsx`, `CONSULTORIA` NO está incluido en `isAdmin`/`canReview`/`canPublish`/`canManage`. (No debe agregarse.)

- [ ] **Step 2:** En `roleUtils.js`, agregar `'Consultoria'` al `ROLE_ORDER` para que ordene/clasifique bien en listados de usuarios:

```javascript
export const ROLE_ORDER = {
  'Super Administrador': 1,
  'SuperAdmin': 1,
  'Comunicaciones': 2,
  'Consultoria': 3,
  'Usuario Autenticado': 4,
  'Oficina': 5,
  'Otros': 99
};
```

- [ ] **Step 3: Verificación manual** (usuario Consultoria): al abrir el detalle de una solicitud pendiente de cualquier oficina, NO aparecen los botones Aprobar/Rechazar/En revisión/Publicar; sí puede ver todo el detalle. En sus propias solicitudes sí puede crear/editar.

- [ ] **Step 4: Commit**

```bash
git add src/components/ui/EventDetailModal.jsx src/components/ui/AnnouncementDetailModal.jsx src/utils/roleUtils.js
git commit -m "feat(web): Consultoria en solo lectura sin acciones de moderacion"
```

---

## Verificación final (antes de cerrar)

- [ ] Backend: `./mvnw -q test` → todos PASS (incluye `EstadoSolicitudTest`, `EventoDevolucionTest`, `AnuncioDevolucionTest`, `RolMappingTest` y los smoke previos).
- [ ] Recorrido E2E "En revisión": Comunicaciones devuelve una solicitud de evento con observaciones → la oficina la ve EN_REVISION con el texto → la edita → vuelve a PENDIENTE → Comunicaciones la aprueba. Repetir con un anuncio.
- [ ] Recorrido E2E "Consultoría": el usuario Consultoria ve eventos/anuncios de todas las oficinas en solo lectura, crea un evento propio, no ve "Usuarios", y recibe 403 al intentar moderar vía API.
- [ ] Cargar `skills/verification-before-completion/SKILL.md` y ejecutar su checklist.

---

## Self-Review del plan (cobertura del spec)

- Estado `EN_REVISION` → Task 1. ✔
- Campo `observacionesRevision` (evento + anuncio, entidad + response) → Tasks 2, 3. ✔
- Endpoints `/devolver` (evento + anuncio) → Tasks 4, 5, 7, 9. ✔
- Reenvío `EN_REVISION → PENDIENTE` con limpieza (evento + anuncio) → Tasks 6, 8. ✔
- Botón "En revisión" + caja de observaciones (evento + anuncio) → Tasks 14, 15, 16. ✔
- Oficina ve observaciones, edita y reenvía; filtro + badge → Tasks 15, 16, 17. ✔
- Rol `CONSULTORIA` (enum + mapeo + seed) → Tasks 10, 11. ✔
- Seguridad: lectura global, crear propio, sin moderación, sin panel usuarios → Tasks 12, 18, 19. ✔
- Front: rutas, sidebar (ya gateado), ocultar acciones → Tasks 18, 19. ✔
