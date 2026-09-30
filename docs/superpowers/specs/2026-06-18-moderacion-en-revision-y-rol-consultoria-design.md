# Diseño — Moderación "En revisión" y Rol "Consultoría"

- **Fecha:** 2026-06-18
- **Estado:** Aprobado (pendiente de plan de implementación)
- **Alcance de plataformas:** Backend (Spring Boot, `GEA_BACKEND`) + Web (React, `GEA_FRONT`). **No** incluye la app móvil (Flutter).

---

## Contexto

Hallazgos del código actual relevantes para el diseño:

- `EstadoSolicitud` tiene 4 valores: `PENDIENTE`, `APROBADA`, `RECHAZADA`, `PUBLICADA`
  (`entity/EstadoSolicitud.java`).
- La moderación la realiza el rol `COMUNICACIONES` (y `SUPER_ADMIN`/`ADMIN`) vía
  `POST /comunicaciones/solicitudes-evento/{id}/aprobar` y `/rechazar`. El rechazo ya
  recibe un `RechazoRequest { motivo }` y guarda `motivoRechazo`.
- Al editar una solicitud (`actualizarPropia`), si no es admin sobre una aprobada, el
  backend ya la regresa a `PENDIENTE` y limpia `motivoRechazo`, `usuarioRevisor` y
  `fechaRevision` (`SolicitudEventoServiceImpl.java:310-315`). Es decir, el mecanismo de
  "corregir y reenviar la misma solicitud" ya existe parcialmente para rechazadas.
- Roles: hay un enum `Rol` + una tabla `RolEntity` (mapeo por nombre vía `Rol.fromNombre`).
  Los roles se siembran en `DataInitializer.inicializarRoles()`. El control de acceso real
  vive en `SecurityConfig` (rutas) y en anotaciones `@PreAuthorize` por endpoint.
- Existe `NotificacionServiceImpl` + `PushNotificationService`, orientados a la app móvil.
  Como el alcance es backend + web, la oficina verá las observaciones en su propio panel
  (igual que hoy ve `motivoRechazo`); no se usa push para esta entrega.

---

## Funcionalidad 1 — Moderación "En revisión" (devolver para corregir)

### Concepto

Un tercer botón en moderación, junto a Aprobar y Rechazar. **Devuelve** la solicitud a la
oficina que la creó, con observaciones del moderador, sin convertirla en un rechazo
definitivo. La oficina edita **la misma** solicitud (no crea una nueva), aplica los ajustes
y la reenvía, volviendo al flujo normal de aprobación.

Aplica a **eventos y anuncios**.

### Modelo de datos

- Nuevo valor en `EstadoSolicitud`: `EN_REVISION`.
- Nuevo campo de texto en `SolicitudEvento` **y** `SolicitudAnuncio`:
  `observacionesRevision` (nullable). Guarda el último texto de observaciones del moderador.
  Se limpia cuando la oficina reenvía.

### Estados (semántica)

- `RECHAZADA`: rechazo definitivo (comportamiento actual, sin cambios).
- `EN_REVISION`: devuelta para corregir. La oficina puede editarla; al guardar vuelve a
  `PENDIENTE`.
- Transición de reenvío: `EN_REVISION → PENDIENTE` (se extiende la lógica que hoy hace
  `RECHAZADA → PENDIENTE` en `actualizarPropia`), limpiando `observacionesRevision`,
  `usuarioRevisor` y `fechaRevision`.

### Backend

- `EstadoSolicitud`: agregar `EN_REVISION`.
- Entidades `SolicitudEvento` y `SolicitudAnuncio`: agregar campo `observacionesRevision`.
- Nuevo DTO `DevolucionRequest { @NotBlank String observaciones }`.
- Nuevos endpoints (espejo de `rechazar`):
  - `POST /comunicaciones/solicitudes-evento/{id}/devolver`
  - `POST /comunicaciones/solicitudes-anuncio/{id}/devolver`
  - `@PreAuthorize("hasAnyRole('SUPER_ADMIN', 'COMUNICACIONES', 'ADMIN')")`
  - Efecto: `estado = EN_REVISION`, `observacionesRevision = request.observaciones`,
    setear `usuarioRevisor` y `fechaRevision`.
- Servicios `SolicitudEventoServiceImpl` y `SolicitudAnuncioServiceImpl`: método `devolver(...)`.
- `actualizarPropia` (eventos y anuncios): la condición de reseteo a `PENDIENTE` debe cubrir
  también `EN_REVISION` y limpiar `observacionesRevision`.
- Responses (`SolicitudEventoResponse` / `SolicitudAnuncioResponse`): incluir
  `observacionesRevision` y exponer el estado `EN_REVISION`.
- Filtros de listado por estado (oficina y comunicaciones) deben aceptar `EN_REVISION`.

### Web (React)

- Servicios: `eventos.service.js` y `anuncios.service.js` → método `devolver(id, observaciones)`.
- Moderación (`EventDetailModal.jsx`, `AnnouncementDetailModal.jsx`): botón **"En revisión"**
  que abre una caja de texto **obligatoria** y llama a `devolver`.
- Panel de oficina (`Events.jsx`, `Announcements.jsx` y hooks
  `useEventManagement.js` / `useAnnouncementManagement.js`):
  - Badge de estado **"En revisión"**.
  - Banner/aviso con el texto de `observacionesRevision`.
  - La solicitud en estado `EN_REVISION` queda **editable** (hoy editable solo para
    pendiente/rechazada según la vista).
  - Filtro de estado incluye "En revisión".

---

## Funcionalidad 2 — Rol "Consultoría" (solo lectura global)

### Concepto

Un rol nuevo cuyos usuarios pueden **ver todos los registros de todas las oficinas**
(eventos y anuncios, incluyendo la cola de moderación completa: pendientes, en revisión,
aprobadas, rechazadas, publicadas) en **solo lectura**. Adicionalmente pueden **crear** sus
propios eventos y anuncios como cualquier otro rol. **No** tienen acceso al panel de
usuarios ni a acciones de moderación.

### Permisos (resumen)

| Acción | Consultoría |
|---|---|
| Ver cola de moderación de eventos/anuncios (todas las oficinas) | ✅ (GET) |
| Ver publicados / calendario / reportes | ✅ |
| Crear eventos/anuncios propios | ✅ |
| Editar/eliminar sus propias solicitudes | ✅ |
| Aprobar / Rechazar / Publicar / Devolver | ❌ |
| Panel de usuarios (`/admin/usuarios`) | ❌ |

### Backend

- `Rol`: agregar valor `CONSULTORIA` + mapeo en `fromNombre` (nombre DB `"Consultoria"`) y
  `getSecurityRole`.
- `DataInitializer.inicializarRoles()`: sembrar el rol `"Consultoria"`.
- `SecurityConfig`:
  - Conceder a `CONSULTORIA` acceso **GET** a las rutas de lectura de comunicaciones
    (`GET /comunicaciones/solicitudes-evento`, `GET /comunicaciones/solicitudes-anuncio` y
    sus `/{id}`).
  - Conceder acceso a crear/gestionar lo propio (`/oficina/solicitudes-*`, `/usuario/**`).
  - **No** incluir `CONSULTORIA` en `/admin/**` (panel de usuarios).
- `@PreAuthorize` de las acciones de moderación (`aprobar`, `rechazar`, `publicar`,
  `devolver`, toggles, deletes de publicación) **no** deben incluir `CONSULTORIA`.
- Los endpoints de lectura de comunicaciones agregan `CONSULTORIA` a su `@PreAuthorize`.

### Web (React)

- `roleUtils.js`: registrar `"Consultoria"` y su orden de visualización.
- `AuthContext.jsx`: reconocer el rol.
- `Sidebar.jsx`: Consultoría ve Eventos, Anuncios, Calendario, Reportes; **oculta** Usuarios.
- `ProtectedRoute.jsx`: bloquear la ruta de Usuarios para Consultoría.
- Vistas de moderación: ocultar botones de aprobar/rechazar/publicar/devolver cuando el rol
  es Consultoría (solo lectura). Mantener visible el botón de crear (propio).

---

## Riesgos y decisiones técnicas

- **La seguridad real está en el backend.** El front solo oculta UI; cualquier usuario podría
  llamar a la API directamente. Por eso los `@PreAuthorize` y `SecurityConfig` son la parte
  crítica y se cubrirán con tests (TDD) antes de tocar el front: un test que confirme que
  Consultoría recibe `403` en aprobar/rechazar/publicar/devolver y en `/admin/usuarios`, y
  `200` en los GET de lectura.
- **Reuso del mecanismo existente.** `EN_REVISION` se apoya en la lógica de reenvío que ya
  existe para `RECHAZADA`; se extiende, no se duplica.
- **`observacionesRevision` separado de `motivoRechazo`.** Se mantiene la distinción
  semántica entre "rechazo definitivo" y "devuelta para corregir".
- **Migración de datos:** agregar un valor de enum y una columna nullable no rompe datos
  existentes. Las solicitudes actuales conservan su estado.

---

## Fuera de alcance (YAGNI)

- App móvil (Flutter): no se toca en esta entrega.
- Historial/hilo de observaciones (varias idas y vueltas): se usa un único campo con el
  último texto.
- Notificaciones push o por correo de la devolución: la oficina ve las observaciones en su
  panel web.
