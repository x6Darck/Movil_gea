# Rediseño App Móvil GEA — Dark OLED + Glassmorphism — Design Spec

**Fecha:** 2026-06-23
**Estado:** Aprobado para planificación
**Alcance:** Toda la app Flutter (`c:\Users\Administrador\Documents\gea_app`)

---

## Goal

Rediseñar visualmente la app móvil completa hacia un estilo **moderno y fluido**: tema **dark OLED** (negro puro de fondo) con el **rojo GEA como color de acento**, **navegación flotante con glassmorphism**, **tarjetas con efecto glass** y la tipografía **Inter** afinada para mejor jerarquía. El cambio es puramente visual: no se modifica lógica de negocio, navegación funcional, providers, ni capa de datos.

## Dirección visual (decisiones acordadas)

| Tema | Decisión |
|---|---|
| Sensación general | Moderna y fluida (glassmorphism, sombras profundas, radios grandes) |
| Paleta | Dark OLED (negro puro) con rojo GEA brillante como acento; gradientes negro→gris oscuro |
| Navegación | Floating nav bar con blur/glassmorphism, elevada, sombra de color roja |
| Tarjetas | Glassmorphism: fondo semi-transparente con blur, borde luminoso sutil, sombra de color según tipo de evento |
| Tipografía | Mantener Inter; afinar tamaños/pesos para jerarquía |
| Enfoque de implementación | Token-first (Opción A): definir el sistema de tokens primero, luego componentes por capa |

---

## Realidad del código actual (reconocimiento)

- El tema vive en `lib/config/theme/app_theme.dart` como **un único `lightTheme`** aplicado en `lib/main.dart:55` (`theme: AppTheme.lightTheme`). No existe `darkTheme` ni `themeMode`.
- La navegación es un `Scaffold` con `IndexedStack` + `NavigationBar` Material 3 estándar en `lib/config/router/app_router.dart:60-85` (3 destinos: Calendario, Perfil, Anuncios) + un `FloatingActionButton.extended` condicional.
- **Tokens vs hardcode:** solo 8 archivos referencian `AppTheme.*` (mayormente `importantColor`, `dividerColor`, `borderColor`) y 16 usan `Theme.of(context)`. Pero hay **colores hardcodeados por toda la app**: 33 `Colors.white`, 11 `Colors.black` y docenas de hex sueltos (`Color(0xFF111827)`, `Color(0xFF6B7280)`, etc.).

> **Implicación crítica para la arquitectura:** cambiar `AppTheme` **no** propaga solo. El trabajo real del rediseño incluye **barrer los colores hardcodeados** y reemplazarlos por referencias a tokens. El plan debe tratar esto como tarea explícita, no asumir propagación automática.

---

## Sistema de tokens (Sección 1 — base de todo)

### Paleta OLED Dark + Rojo acento

```
Background:     #000000   negro puro OLED (scaffold)
Surface-1:      #0D0D0D   cards base
Surface-2:      #141414   inputs, chips
Surface-3:      #1C1C1C   dividers, bordes

Primary:        #E53935   rojo GEA (un tono más vivo en oscuro)
Primary Glow:   rgba(229, 57, 53, 0.25)   sombra de color roja
Primary Light:  rgba(229, 57, 53, 0.12)   superficies con tinte

Text-primary:   #F1F5F9
Text-secondary: #94A3B8
Text-muted:     #475569

Success:        #22D3A5
Warning:        #FBBF24
Important:      #FBBF24   (alias de warning, eventos importantes)
Error:          #F87171

Glass border:   rgba(255, 255, 255, 0.10)   borde luminoso sutil
Glass fill:     rgba(255, 255, 255, 0.04)   relleno de superficie glass
```

### Radios unificados
- Cards: `16`
- Inputs / botones rectangulares: `12`
- Pills, chips, botones de acción: `100`
- Bottom sheets (top): `24`

### Sombras con color
Los elementos elevados (nav flotante, cards destacadas, FAB) usan sombra con **tinte rojo** en vez de negra genérica:
`BoxShadow(color: PrimaryGlow, blurRadius: 20, spreadRadius: -4, offset: Offset(0, 8))`

### Escala tipográfica Inter

```
displayLarge:   32sp  w700  letterSpacing -0.5
titleLarge:     22sp  w700  letterSpacing -0.3
titleMedium:    17sp  w600
bodyLarge:      15sp  w400  height 1.5
bodyMedium:     13sp  w400  height 1.5
labelSmall:     11sp  w600  letterSpacing 0.4   (badges/chips)
```

### Estrategia de aplicación del tema
Convertir `AppTheme` a un esquema oscuro:
- Reemplazar los valores de las `static const Color` por la paleta OLED (esto cubre los 8 archivos que usan `AppTheme.*`).
- Definir el `ThemeData` con `brightness: Brightness.dark`, `ColorScheme.dark(...)`, y todos los sub-temas (AppBar, Card, ElevatedButton, OutlinedButton, InputDecoration, NavigationBar, BottomSheet) en versión oscura.
- En `main.dart`, aplicar el tema oscuro (renombrar a `darkTheme` o mantener `lightTheme` apuntando a la versión oscura para no romper el import; el plan elegirá la opción de menor fricción).

---

## Sección 2 — Componentes

### 2.1 Floating Nav Bar (nuevo widget)
- Nuevo widget reutilizable `GeaFloatingNavBar` en `lib/core/presentation/widgets/`.
- Barra **flotante** (margen lateral + inferior), `borderRadius: 100` o `28`, fondo glass (`BackdropFilter` blur + `Glass fill`), borde luminoso (`Glass border`), sombra roja (`Primary Glow`).
- Indicador de selección tipo **pill** con tinte rojo (`Primary Light`) e ícono con color `Primary` + glow al seleccionar; ítems no seleccionados en `Text-muted`.
- Sustituye el `NavigationBar` en `app_router.dart` sin cambiar la lógica de `_selectedIndex` / `IndexedStack`.
- El `FloatingActionButton.extended` condicional se reestiliza para coexistir con la barra flotante (color `Primary`, sombra roja, sobre la barra).

### 2.2 Glassmorphism Cards
Patrón glass reutilizable (helper o widget `GeaGlassCard`):
- Fondo `Glass fill` + `BackdropFilter` (blur ~12-16).
- Borde `1px` `Glass border`.
- Radio `16`.
- Sombra de color según el **tipo de evento** (usa `colorHex` del tipo; cae a `Primary Glow` si no hay color).

Aplicar a:
- `event_card.dart` (calendario) — jerarquía: título, hora, lugar, badges (transmisión/cubrimiento/importante), countdown chip, stream badge.
- `announcement_card.dart` (anuncios).
- Tarjetas de detalle (bottom sheets de evento/anuncio).

### 2.3 Botones, inputs y bottom sheets
- **ElevatedButton:** primario en `Primary` (rojo) con sombra roja, radio `12`, texto `15 w600`. (Hoy es oscuro estilo Vercel; en dark pasa a rojo de acción.)
- **OutlinedButton:** borde `Glass border`, texto `Text-primary`, fondo transparente.
- **Inputs:** fondo `Surface-2`, borde `Surface-3`, foco con borde `Primary 1.5px`, texto `Text-primary`, hint `Text-muted`.
- **Bottom sheets:** fondo `Surface-1`, top radius `24`, handle `Text-muted`, opcionalmente con leve gradiente al fondo `#000000`.

---

## Sección 3 — Pantallas (aplicación de los tokens/componentes)

Cada pantalla se revisa para: (a) eliminar colores hardcodeados → tokens, (b) aplicar fondo OLED, (c) usar cards glass, (d) coexistir con la nav flotante (padding inferior).

| Pantalla | Archivo | Notas de rediseño |
|---|---|---|
| Calendario | `lib/features/calendar/presentation/screens/calendar_screen.dart` | `table_calendar` con tema oscuro (selección roja, hoy con tinte, fines de semana en muted); lista de eventos en cards glass; padding inferior por nav flotante |
| Eventos fijados | `.../calendar/.../pinned_events_screen.dart` | Cards glass; estado vacío `gea_empty_state` en versión oscura |
| Anuncios | `lib/features/announcements/.../announcements_screen.dart` | `announcement_card` glass; FAB rojo de "solicitar" |
| Solicitar anuncio | `.../request_announcement_screen.dart` | Inputs oscuros, botón primario rojo |
| Login | `lib/features/auth/.../login_screen.dart` | Fondo OLED con gradiente sutil rojo; logo GEA; botón Microsoft re-estilizado para fondo oscuro |
| Perfil | `lib/features/auth/.../profile_screen.dart` | Header glass; filas de info (`info_row`) en tokens oscuros |
| Notificaciones | `lib/core/presentation/screens/notifications_screen.dart` | Lista en cards glass; `notification_bell` con badge rojo |

Widgets core a migrar a tokens oscuros: `gea_button`, `gea_text_field`, `gea_empty_state`, `notification_bell`, `offline_banner`, `info_row`, y los widgets de calendario (`event_countdown_chip`, `important_event_pulse`, `pin_button`, `stream_badge`, `share_event_bottom_sheet`, `event_share_card`).

---

## Decomposición en fases (el alcance "toda la app" es grande)

El rediseño se ejecuta en **fases incrementales**, cada una compilable y revisable de forma independiente:

1. **Fase 1 — Tokens + tema oscuro.** Reescribir `AppTheme` a OLED dark (paleta, radios, sombras, tipografía, sub-temas) y aplicarlo en `main.dart`. Resultado: la app entra en modo oscuro; los widgets que usan `Theme.of(context)` ya se ven bien; los hardcodeados aún se ven mal (esperado).
2. **Fase 2 — Barrido de colores hardcodeados.** Reemplazar `Colors.white`/`Colors.black`/hex sueltos por referencias a tokens en los widgets core y pantallas. Resultado: consistencia total de color.
3. **Fase 3 — Floating Nav Bar + FAB.** Nuevo `GeaFloatingNavBar` glass y re-estilo del FAB; cablear en `app_router.dart`.
4. **Fase 4 — Glassmorphism cards.** Helper/`GeaGlassCard` y aplicarlo a `event_card`, `announcement_card` y tarjetas de detalle.
5. **Fase 5 — Pulido por pantalla.** Calendario (tema de `table_calendar`), login (gradiente), perfil, notificaciones, estados vacíos y badges.

Cada fase es un conjunto de commits atómicos. El plan de implementación detallará las tareas de cada fase.

---

## No-objetivos (YAGNI)
- **No** se implementa toggle claro/oscuro ni persistencia de tema: la app va 100% dark (se puede agregar después si se pide).
- **No** se cambia la estructura de navegación, rutas, providers ni capa de datos.
- **No** se añaden animaciones complejas más allá de las transiciones/efectos glass descritos.
- **No** se rediseñan flujos ni se agregan pantallas nuevas.

## Riesgos
- **Colores hardcodeados dispersos:** el mayor riesgo de inconsistencia. Mitigación: Fase 2 dedicada + revisión visual por pantalla en Fase 5.
- **Rendimiento de `BackdropFilter`:** múltiples blurs (nav + cards) pueden costar en gama baja. Mitigación: blur moderado (12-16), limitar capas glass simultáneas, probar en dispositivo real.
- **Contraste/accesibilidad:** texto sobre superficies glass debe mantener contraste legible. Mitigación: usar `Text-primary`/`Text-secondary` definidos, evitar texto sobre blur sin relleno suficiente.
- **`table_calendar` y paquetes de terceros:** requieren tematización manual (no heredan todo del `ThemeData`). Cubierto en Fase 5.

---

## Self-Review
- **Placeholders:** ninguno; paleta, radios, tipografía y archivos concretos están especificados.
- **Consistencia:** la dirección (dark/rojo/glass/floating/Inter) es coherente en tokens, componentes y pantallas.
- **Scope:** es grande pero está descompuesto en 5 fases independientes; cada fase es un plan de tareas atómicas.
- **Ambigüedad:** la única decisión diferida (renombrar `lightTheme`→`darkTheme` vs. reutilizar el nombre) se resuelve en el plan eligiendo la de menor fricción; no afecta el diseño.
