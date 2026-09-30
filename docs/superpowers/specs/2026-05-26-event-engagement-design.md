# Event Engagement — Diseño de Especificación
**Fecha:** 2026-05-26  
**Feature:** Interacción pasiva y activa con eventos (GEA App)  
**Estado:** Aprobado por el usuario

---

## Resumen

Tres mejoras integradas para hacer los eventos más atractivos y generar interacción real entre los usuarios universitarios:

1. **Mejoras Pasivas Visuales** — Countdown timer, badges animados de stream/live e importante
2. **Eventos Fijados (Pin)** — Guardar eventos favoritos, persistidos en backend, reflejados en calendario
3. **Compartir Evento como Imagen** — Generación de share card visual para WhatsApp/redes sociales

---

## Sección 1: Mejoras Pasivas Visuales

### Alcance
Solo Flutter. Sin cambios de backend.

### EventCountdownChip
Widget independiente que recibe `DateTime date` y `DateTime? endDate` del evento.

Estados:
| Condición | Label | Color |
|-----------|-------|-------|
| `date` es hoy y faltan horas | "Hoy · en Xh Ymin" | Verde |
| `date` es mañana | "Mañana · HH:mm" | Azul |
| Faltan 2–6 días | "Faltan X días" | Gris |
| `date <= now <= endDate` | "En curso" | Verde pulsante |
| `now > endDate` | No se muestra | — |

Se recalcula cada minuto con un `Timer.periodic` dentro de un `StatefulWidget`.  
Se ubica debajo del título en `EventCard`, antes de la fila de location/hora.

### Stream / Live Badge
Condición: `event.link != null`

- Badge **"STREAM"** con animación `ImportantEventPulse` ya existente en la app
- Al tocar: abre `event.link` con `url_launcher`
- Si evento está "en curso": badge cambia a **"EN VIVO"** color rojo

### Important Event Badge
Condición: `event.isImportant == true`

- Chip **"Destacado ★"** con color `AppTheme.importantColor`
- Borde dorado reforzado en el card (ya existe parcialmente, se potencia)

### Archivos afectados
- `lib/features/calendar/presentation/widgets/event_card.dart` — añade chips/badges
- `lib/features/calendar/presentation/widgets/event_countdown_chip.dart` — nuevo widget
- `lib/features/calendar/presentation/widgets/stream_badge.dart` — nuevo widget

---

## Sección 2: Eventos Fijados (Pin)

### Alcance
Flutter + Spring Boot backend. Solo usuarios autenticados (`AuthUser.role != guest`).

### Backend — Endpoints requeridos
```
POST   /api/eventos/fijados/{eventoId}
  Headers: Authorization: Bearer {jwt}
  Response: 200 OK

DELETE /api/eventos/fijados/{eventoId}
  Headers: Authorization: Bearer {jwt}
  Response: 200 OK

GET    /api/eventos/fijados
  Headers: Authorization: Bearer {jwt}
  Response: List<EventoDTO> (misma estructura que /api/eventos)
```

El backend identifica al usuario por el claim del JWT. No requiere body en POST/DELETE.

### Flutter — Clean Architecture

**Domain layer**
```
lib/features/calendar/domain/repositories/pinned_event_repository.dart
  abstract class PinnedEventRepository {
    Future<Either<Failure, List<Event>>> getPinnedEvents();
    Future<Either<Failure, Unit>> pinEvent(String eventId);
    Future<Either<Failure, Unit>> unpinEvent(String eventId);
  }

lib/features/calendar/domain/usecases/get_pinned_events_usecase.dart
lib/features/calendar/domain/usecases/pin_event_usecase.dart
lib/features/calendar/domain/usecases/unpin_event_usecase.dart
```

**Data layer**
```
lib/features/calendar/data/datasources/pinned_event_remote_datasource.dart
lib/features/calendar/data/repositories/pinned_event_repository_impl.dart
```
Reutiliza el `DioClient` con interceptor de auth existente.

**Presentation layer**
```
lib/features/calendar/presentation/providers/pinned_events_provider.dart
  - pinnedEventsProvider: FutureProvider<List<Event>>
  - pinnedEventIdsProvider: StateProvider<Set<String>>  ← para estado optimista

lib/features/calendar/presentation/screens/pinned_events_screen.dart
lib/features/calendar/presentation/widgets/pin_button.dart
```

### Ubicación del Pin Button
- **En el card de lista:** ícono bookmark en la esquina superior derecha del thumbnail del evento
- **En el modal de detalle:** botón secundario "Fijar evento" / "Desfijado" debajo del título

### Comportamiento del Pin Button
- Ícono `Icons.bookmark_outline` (no fijado) / `Icons.bookmark` (fijado)
- Al tocar: actualización optimista inmediata → llamada al backend en background
- Si backend falla: revertir estado + mostrar SnackBar de error
- Animación de fill al fijar (TweenAnimationBuilder sobre el ícono)

### Pantalla Eventos Fijados
- Accesible desde: ícono bookmark en AppBar de CalendarScreen
- Lista de eventos ordenados por `date` ascendente
- Cada item: mismo `EventCard` ya existente (reutilizado)
- Estado vacío: `GeaEmptyState` con mensaje "Aún no has fijado eventos"
- Estado no autenticado: `GeaEmptyState` con botón "Iniciar sesión"

### Indicador en Calendario
- Los días que tengan eventos fijados muestran un punto dorado (`AppTheme.importantColor`) adicional debajo del número del día en el `TableCalendar`
- Se logra usando el `calendarBuilders.markerBuilder` existente

### Flujo Invitado
- Usuario invitado toca pin → `showModalBottomSheet` con mensaje:
  "Inicia sesión con tu cuenta institucional para fijar eventos"
  + botón "Iniciar sesión" → `context.go('/login')`

---

## Sección 3: Compartir Evento como Imagen

### Alcance
Solo Flutter. Requiere dos paquetes nuevos: `share_plus` y `url_launcher`.

### Paquetes a añadir
```yaml
share_plus: ^10.0.0
url_launcher: ^6.3.0
```

### EventShareCard Widget
Widget off-screen renderizado con `RepaintBoundary` para captura de imagen.

Estructura visual de la card (tamaño fijo 1080×1080 lógico):
```
┌─────────────────────────────────┐
│  [Imagen del evento de fondo]   │
│  [Gradiente oscuro encima]      │
│                                 │
│  🏛 GEA — Universidad          │  ← top-left, logo/nombre
│                                 │
│  [Categoría badge con colorHex] │  ← chip de categoría
│  TÍTULO DEL EVENTO              │  ← texto grande, bold, blanco
│                                 │
│  📅 Fecha completa              │
│  🕐 Hora inicio – Hora fin     │
│  📍 Lugar                       │
│                                 │
│  "Descárgalo en GEA App"        │  ← bottom tagline
└─────────────────────────────────┘
```

Si `event.imageUrl == null`: fondo con `LinearGradient` usando `event.colorHex` o `AppTheme.importantColor`.

### Flujo de Compartir
Botón "Compartir" en el modal de detalle del evento (ya existe `showModalBottomSheet` en `EventCard`).

Al tocar "Compartir":
1. Se muestra un `BottomSheet` con dos opciones:
   - **Compartir como imagen** → `RenderRepaintBoundary.toImage()` → PNG bytes → `Share.shareXFiles()` de `share_plus`
   - **Copiar link del stream** → `Clipboard.setData(event.link)` + SnackBar confirmación (solo visible si `event.link != null`)
2. Durante la generación de imagen: `CircularProgressIndicator` en el botón

### Archivos nuevos
```
lib/features/calendar/presentation/widgets/event_share_card.dart   ← widget off-screen
lib/features/calendar/presentation/widgets/share_event_bottom_sheet.dart
```

---

## Dependencias entre secciones

| Sección | Depende de |
|---------|-----------|
| Pasiva (1) | Nada — se puede hacer primero |
| Pin (2) | Backend disponible con los 3 endpoints |
| Compartir (3) | Nada — independiente |

**Orden de implementación recomendado:** 1 → 3 → 2 (backend en paralelo)

---

## Paquetes nuevos requeridos

| Paquete | Versión | Para qué |
|---------|---------|----------|
| `share_plus` | `^10.0.0` | Share nativo del SO |
| `url_launcher` | `^6.3.0` | Abrir links de stream |

---

## Fuera de alcance
- Notificaciones push de recordatorio para eventos fijados
- Comentarios o reacciones en eventos
- Contador público de cuántas personas fijaron un evento
- Edición de eventos desde la app
