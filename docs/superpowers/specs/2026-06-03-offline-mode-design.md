# Modo Offline — Calendario y Anuncios
**Fecha:** 2026-06-03  
**Estado:** Aprobado

## Goal

La app Flutter guarda automáticamente eventos y anuncios al abrir con internet. Si se pierde la conexión, muestra los datos guardados con un banner discreto en la parte superior. Cuando vuelve la conexión, refresca y oculta el banner.

## Scope

Solo la app Flutter (`gea_app`). No toca backend ni frontend web.

---

## Componentes nuevos

### `ConnectivityService`
`lib/core/services/connectivity_service.dart`

Wrapper sobre `connectivity_plus`. Expone:
- `Future<bool> isOnline()` — consulta puntual
- `Stream<bool> onConnectivityChanged` — stream de cambios

### Riverpod `connectivityProvider`
`lib/core/providers/connectivity_providers.dart`

`StreamProvider<bool>` que expone el estado de conectividad. Las pantallas lo consumen para mostrar/ocultar el banner sin lógica propia.

### `OfflineCacheService`
`lib/core/services/offline_cache_service.dart`

Usa `SharedPreferences` (ya instalado). Guarda la respuesta cruda de la API como JSON string.
- `saveEvents(List<dynamic> rawJson)`
- `loadEvents() → List<dynamic>?`
- `saveAnnouncements(List<dynamic> rawJson)`
- `loadAnnouncements() → List<dynamic>?`

### `OfflineBanner` widget
`lib/core/presentation/widgets/offline_banner.dart`

Barra gris oscura en la parte superior. Texto: "Sin conexión — mostrando datos guardados". Desaparece cuando vuelve internet. Solo se muestra si hay datos cacheados disponibles.

---

## Cambios en repositorios existentes

### `EventRepositoryImpl`
- Recibe `OfflineCacheService` por inyección
- En `getEvents()`: si API responde bien → guarda raw JSON en caché. Si API falla por conexión → carga caché. Si no hay caché → retorna `ServerFailure`

### `AnnouncementRepositoryImpl`
- Mismo patrón que `EventRepositoryImpl`

---

## Cambios en pantallas

### `CalendarScreen` y `AnnouncementsScreen`
- Agregan `OfflineBanner` en la parte superior del `Column` principal
- El banner se muestra/oculta automáticamente vía `connectivityProvider`

---

## Criterios de aceptación

1. Con internet: app carga normalmente, datos se guardan en caché silenciosamente
2. Sin internet: app muestra datos del último caché + banner "Sin conexión"
3. Sin internet y sin caché previo: muestra error normal (sin banner)
4. Al recuperar internet: datos se refrescan, banner desaparece
5. El caché persiste entre reinicios de la app
