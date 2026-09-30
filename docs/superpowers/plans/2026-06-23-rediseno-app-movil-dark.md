# Rediseño App Móvil GEA — Dark OLED + Glassmorphism — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rediseñar visualmente toda la app Flutter GEA a un estilo dark OLED con rojo de acento, navegación flotante glassmorphism y tarjetas glass, manteniendo Inter, sin tocar lógica de negocio ni navegación funcional.

**Architecture:** Token-first. Fase 1 reescribe `AppTheme` a un tema oscuro (paleta, radios, sombras, tipografía, sub-temas). Fase 2 barre colores hardcodeados → tokens. Fase 3 añade `GeaFloatingNavBar`. Fase 4 añade `GeaGlassCard` y reestiliza las tarjetas. Fase 5 pule pantalla por pantalla (calendario, login, perfil, notificaciones). Cada fase compila y es revisable de forma independiente.

**Tech Stack:** Flutter, Material 3, `google_fonts` (Inter), `BackdropFilter` (glass), `table_calendar`, Riverpod, GoRouter.

**Spec:** `docs/superpowers/specs/2026-06-23-rediseno-app-movil-dark-design.md`

**Nota sobre pruebas:** El rediseño es visual; no es unit-testeable de forma significativa. La verificación de cada tarea es `flutter analyze` sin errores nuevos + verificación visual en dispositivo/emulador. Se añaden 2 smoke tests de widget (que los widgets nuevos rendericen sin lanzar excepción) donde aporta valor real.

**Comandos de verificación (raíz del proyecto `c:\Users\Administrador\Documents\gea_app`):**
- `flutter analyze`
- `flutter test`
- `flutter run` (verificación visual)

---

## File Structure

**Crear:**
- `lib/config/theme/app_tokens.dart` — tokens crudos (colores, radios, sombras, blur) como `static const`, fuente única de verdad.
- `lib/core/presentation/widgets/gea_glass_card.dart` — contenedor glass reutilizable.
- `lib/core/presentation/widgets/gea_floating_nav_bar.dart` — barra de navegación flotante glass.
- `test/widgets/gea_glass_card_test.dart` — smoke test.
- `test/widgets/gea_floating_nav_bar_test.dart` — smoke test.

**Modificar:**
- `lib/config/theme/app_theme.dart` — reescribir a tema oscuro consumiendo `app_tokens.dart`.
- `lib/config/router/app_router.dart:60-85` — sustituir `NavigationBar` por `GeaFloatingNavBar` + extender body bajo la barra.
- `lib/core/presentation/widgets/gea_button.dart` — quitar hex hardcodeados.
- `lib/features/calendar/presentation/widgets/event_card.dart` — glass + tokens.
- `lib/features/announcements/presentation/widgets/announcement_card.dart` — glass + tokens.
- Widgets core y de feature con colores hardcodeados (Fase 2 y 5, lista en cada tarea).

---

## FASE 1 — Tokens + Tema Oscuro

### Task 1: Crear el archivo de tokens

**Files:**
- Create: `lib/config/theme/app_tokens.dart`

- [ ] **Step 1: Crear el archivo con todos los tokens**

```dart
import 'package:flutter/material.dart';

/// Fuente única de verdad de los tokens visuales de GEA (tema dark OLED).
class AppTokens {
  AppTokens._();

  // ── Superficies (OLED) ──────────────────────────────────────────────
  static const Color background = Color(0xFF000000); // negro puro (scaffold)
  static const Color surface1 = Color(0xFF0D0D0D);   // cards base
  static const Color surface2 = Color(0xFF141414);   // inputs, chips
  static const Color surface3 = Color(0xFF1C1C1C);   // dividers, bordes

  // ── Marca ───────────────────────────────────────────────────────────
  static const Color primary = Color(0xFFE53935);    // rojo GEA (dark)
  static const Color primaryHover = Color(0xFFC62828);
  static const Color primaryGlow = Color(0x40E53935);  // 25% — sombra roja
  static const Color primaryLight = Color(0x1FE53935); // 12% — superficies con tinte

  // ── Texto ───────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFF1F5F9);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF475569);

  // ── Semánticos ──────────────────────────────────────────────────────
  static const Color success = Color(0xFF22D3A5);
  static const Color warning = Color(0xFFFBBF24);
  static const Color important = Color(0xFFFBBF24); // alias eventos importantes
  static const Color error = Color(0xFFF87171);

  // ── Glass ───────────────────────────────────────────────────────────
  static const Color glassBorder = Color(0x1AFFFFFF); // 10% blanco
  static const Color glassFill = Color(0x0AFFFFFF);    // 4% blanco
  static const double glassBlur = 14.0;

  // ── Radios ──────────────────────────────────────────────────────────
  static const double radiusCard = 16;
  static const double radiusInput = 12;
  static const double radiusPill = 100;
  static const double radiusSheet = 24;

  // ── Sombra de color (elementos elevados) ────────────────────────────
  static const List<BoxShadow> glowShadow = [
    BoxShadow(color: primaryGlow, blurRadius: 20, spreadRadius: -4, offset: Offset(0, 8)),
  ];
}
```

- [ ] **Step 2: Verificar que analiza sin errores**

Run: `flutter analyze lib/config/theme/app_tokens.dart`
Expected: No issues found.

- [ ] **Step 3: Commit**

```bash
git add lib/config/theme/app_tokens.dart
git commit -m "feat(theme): tokens de diseño dark OLED como fuente unica de verdad"
```

---

### Task 2: Reescribir AppTheme a tema oscuro

**Files:**
- Modify: `lib/config/theme/app_theme.dart` (reemplazo completo)

> `AppTheme` conserva los nombres `static const Color` que ya usan 8 archivos (`importantColor`, `dividerColor`, `borderColor`, etc.) pero ahora apuntan a valores oscuros de `AppTokens`. Conserva el getter `lightTheme` con el mismo nombre (lo usa `main.dart:55`) para evitar tocar el import; internamente es un tema oscuro.

- [ ] **Step 1: Reemplazar el archivo completo**

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gea_app/config/theme/app_tokens.dart';

class AppTheme {
  // Alias retrocompatibles (apuntan a tokens dark). NO renombrar: los usan widgets existentes.
  static const Color primaryColor = AppTokens.primary;
  static const Color primaryHover = AppTokens.primaryHover;
  static const Color primaryLight = AppTokens.primaryLight;

  static const Color backgroundColor = AppTokens.background;
  static const Color surfaceColor = AppTokens.surface1;

  static const Color textMain = AppTokens.textPrimary;
  static const Color textSecondary = AppTokens.textSecondary;
  static const Color textMuted = AppTokens.textMuted;

  static const Color borderColor = AppTokens.surface3;
  static const Color dividerColor = AppTokens.surface3;

  static const Color successColor = AppTokens.success;
  static const Color warningColor = AppTokens.warning;
  static const Color importantColor = AppTokens.important;
  static const Color errorColor = AppTokens.error;

  /// Nombre conservado por compatibilidad con main.dart; es un tema OSCURO.
  static ThemeData get lightTheme => darkTheme;

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: AppTokens.primary,
        secondary: AppTokens.textSecondary,
        surface: AppTokens.surface1,
        onSurface: AppTokens.textPrimary,
        error: AppTokens.error,
      ),
      scaffoldBackgroundColor: AppTokens.background,
      dividerColor: AppTokens.surface3,
      fontFamily: GoogleFonts.inter().fontFamily,
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.inter(
          fontWeight: FontWeight.w700, color: AppTokens.textPrimary, fontSize: 32, letterSpacing: -0.5),
        titleLarge: GoogleFonts.inter(
          fontWeight: FontWeight.w700, color: AppTokens.textPrimary, fontSize: 22, letterSpacing: -0.3),
        titleMedium: GoogleFonts.inter(
          fontWeight: FontWeight.w600, color: AppTokens.textPrimary, fontSize: 17),
        bodyLarge: GoogleFonts.inter(
          color: AppTokens.textSecondary, fontSize: 15, height: 1.5),
        bodyMedium: GoogleFonts.inter(
          color: AppTokens.textSecondary, fontSize: 13, height: 1.5),
        bodySmall: GoogleFonts.inter(
          color: AppTokens.textMuted, fontSize: 13),
        labelSmall: GoogleFonts.inter(
          fontWeight: FontWeight.w600, color: AppTokens.textSecondary, fontSize: 11, letterSpacing: 0.4),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppTokens.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: AppTokens.textPrimary, fontSize: 18, fontWeight: FontWeight.w600,
          fontFamily: 'Inter', letterSpacing: -0.5),
        iconTheme: IconThemeData(color: AppTokens.textPrimary, size: 22),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusCard),
          side: const BorderSide(color: AppTokens.glassBorder, width: 1),
        ),
        color: AppTokens.surface1,
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTokens.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 48),
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.radiusInput)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, fontFamily: 'Inter'),
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) return Colors.white.withValues(alpha: 0.1);
            return null;
          }),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTokens.textPrimary,
          minimumSize: const Size(double.infinity, 48),
          side: const BorderSide(color: AppTokens.glassBorder, width: 1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.radiusInput)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, fontFamily: 'Inter'),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppTokens.surface2,
        hoverColor: Colors.transparent,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusInput),
          borderSide: const BorderSide(color: AppTokens.surface3)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusInput),
          borderSide: const BorderSide(color: AppTokens.surface3)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusInput),
          borderSide: const BorderSide(color: AppTokens.primary, width: 1.5)),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusInput),
          borderSide: const BorderSide(color: AppTokens.error)),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusInput),
          borderSide: const BorderSide(color: AppTokens.error, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: const TextStyle(color: AppTokens.textMuted, fontSize: 14),
        hintStyle: const TextStyle(color: AppTokens.textMuted, fontSize: 14),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppTokens.surface1,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppTokens.radiusSheet))),
      ),
    );
  }
}
```

> Se elimina `navigationBarTheme` porque la nav pasa a ser un widget propio (`GeaFloatingNavBar`, Fase 3). Hasta esa fase, la `NavigationBar` vieja usará el default oscuro de Material 3 (aceptable temporalmente).

- [ ] **Step 2: Aplicar el tema oscuro en main.dart**

En `lib/main.dart:52-56`, asegurar uso de modo oscuro forzado. Reemplazar el bloque del `MaterialApp.router`:

```dart
    return MaterialApp.router(
      title: 'GEA App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      routerConfig: appRouter,
```

(las demás líneas del widget quedan igual.)

- [ ] **Step 3: Verificar análisis y arranque**

Run: `flutter analyze`
Expected: No issues nuevos relacionados con el tema.

Run: `flutter run` y confirmar visualmente que la app arranca en oscuro (fondo negro, texto claro). Los colores hardcodeados aún se verán mal (esperado, se corrigen en Fase 2).

- [ ] **Step 4: Commit**

```bash
git add lib/config/theme/app_theme.dart lib/main.dart
git commit -m "feat(theme): aplicar tema dark OLED en toda la app via AppTheme"
```

---

## FASE 2 — Barrido de colores hardcodeados

> Objetivo: reemplazar `Colors.white`, `Colors.black`, `Colors.grey` y hex sueltos por tokens, en los widgets core y donde rompan el modo oscuro. Trabajar archivo por archivo, un commit por archivo o grupo lógico.

### Task 3: Inventariar los colores hardcodeados restantes

**Files:** ninguno (reconocimiento).

- [ ] **Step 1: Generar el inventario**

Run (Git Bash):
```bash
cd "c:/Users/Administrador/Documents/gea_app"
grep -rn "Colors\.white\|Colors\.black\|Colors\.grey\|Color(0xFF" lib/ > /tmp/hardcoded_colors.txt
wc -l /tmp/hardcoded_colors.txt
```
Expected: lista con archivo:línea de cada ocurrencia. Úsala como checklist viva para las tareas siguientes.

- [ ] **Step 2: No commit** (es reconocimiento).

---

### Task 4: Limpiar gea_button.dart

**Files:**
- Modify: `lib/core/presentation/widgets/gea_button.dart:34,45,58`

- [ ] **Step 1: Reemplazar los hex y blancos hardcodeados por tokens**

Añadir el import al inicio del archivo (tras `import 'package:flutter/material.dart';`):
```dart
import 'package:gea_app/config/theme/app_tokens.dart';
```

Reemplazar línea 34 (`foregroundColor: const Color(0xFF374151)`):
```dart
          foregroundColor: AppTokens.textSecondary,
```

Reemplazar línea 45 (`ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444))`):
```dart
          ? ElevatedButton.styleFrom(backgroundColor: AppTokens.error)
```

Reemplazar línea 58 (`AlwaysStoppedAnimation<Color>(Colors.white70)`):
```dart
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withValues(alpha: 0.7)),
```
(Se mantiene blanco porque el spinner va sobre el botón rojo/oscuro; es correcto.)

- [ ] **Step 2: Verificar**

Run: `flutter analyze lib/core/presentation/widgets/gea_button.dart`
Expected: No issues found.

- [ ] **Step 3: Commit**

```bash
git add lib/core/presentation/widgets/gea_button.dart
git commit -m "refactor(ui): gea_button usa tokens en vez de hex hardcodeados"
```

---

### Task 5: Limpiar los widgets core restantes

**Files:**
- Modify: `lib/core/presentation/widgets/gea_text_field.dart`
- Modify: `lib/core/presentation/widgets/gea_empty_state.dart`
- Modify: `lib/core/presentation/widgets/notification_bell.dart`
- Modify: `lib/core/presentation/widgets/offline_banner.dart`
- Modify: `lib/core/presentation/widgets/info_row.dart`

> Para CADA archivo: abrirlo, localizar cada `Colors.white/black/grey` y `Color(0xFF...)` (usar el inventario de Task 3) y aplicar el mapeo de abajo. Si un color no encaja en el mapeo, elegir el token más cercano por rol (fondo→`surface*`, texto→`text*`, borde→`surface3`/`glassBorder`).

**Mapeo de reemplazo (hex viejo → token):**
```
Color(0xFF111827) (gray 900, texto fuerte)   → AppTokens.textPrimary
Color(0xFF374151) (gray 700, texto)          → AppTokens.textSecondary
Color(0xFF6B7280) / 0xFF9CA3AF (gray 500/400)→ AppTokens.textMuted
Color(0xFFE5E7EB) / 0xFFF3F4F6 (bordes/divs) → AppTokens.surface3
Color(0xFFF9FAFB) (fondo gris claro)         → AppTokens.surface2
Colors.white  (como fondo de superficie)     → AppTokens.surface1
Colors.white  (como texto sobre rojo)        → conservar (correcto)
Colors.black  (sombras)                       → conservar o AppTokens.primaryGlow si es elevación
Colors.grey   (iconos/placeholder)            → AppTokens.textMuted
Color(0xFFF59E0B) (warning/important)         → AppTokens.warning
Color(0xFFEF4444) (error)                     → AppTokens.error
```

Añadir `import 'package:gea_app/config/theme/app_tokens.dart';` en cada archivo que pase a usar `AppTokens`.

- [ ] **Step 1: Aplicar el mapeo en `gea_text_field.dart`**
- [ ] **Step 2: Aplicar el mapeo en `gea_empty_state.dart`**
- [ ] **Step 3: Aplicar el mapeo en `notification_bell.dart`** (el badge de conteo debe quedar `AppTokens.primary` con texto blanco)
- [ ] **Step 4: Aplicar el mapeo en `offline_banner.dart`** (fondo `AppTokens.warning` con texto oscuro `AppTokens.background`, o estilo de aviso a discreción manteniendo contraste)
- [ ] **Step 5: Aplicar el mapeo en `info_row.dart`** (icono `AppTokens.textSecondary`, texto `AppTokens.textPrimary`)

- [ ] **Step 6: Verificar**

Run: `flutter analyze`
Expected: No issues nuevos.

- [ ] **Step 7: Commit**

```bash
git add lib/core/presentation/widgets/
git commit -m "refactor(ui): widgets core usan tokens dark en vez de colores hardcodeados"
```

---

## FASE 3 — Floating Nav Bar

### Task 6: Crear GeaFloatingNavBar

**Files:**
- Create: `lib/core/presentation/widgets/gea_floating_nav_bar.dart`
- Test: `test/widgets/gea_floating_nav_bar_test.dart`

- [ ] **Step 1: Crear el widget**

```dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:gea_app/config/theme/app_tokens.dart';

class GeaNavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  const GeaNavItem({required this.icon, required this.selectedIcon, required this.label});
}

/// Barra de navegación flotante con glassmorphism y acento rojo.
class GeaFloatingNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<GeaNavItem> items;

  const GeaFloatingNavBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTokens.radiusPill),
          boxShadow: AppTokens.glowShadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTokens.radiusPill),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: AppTokens.glassBlur, sigmaY: AppTokens.glassBlur),
            child: Container(
              height: 66,
              decoration: BoxDecoration(
                color: AppTokens.glassFill,
                borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                border: Border.all(color: AppTokens.glassBorder, width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  for (int i = 0; i < items.length; i++)
                    _NavButton(
                      item: items[i],
                      selected: i == selectedIndex,
                      onTap: () => onDestinationSelected(i),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final GeaNavItem item;
  final bool selected;
  final VoidCallback onTap;
  const _NavButton({required this.item, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTokens.radiusPill),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(horizontal: selected ? 18 : 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppTokens.primaryLight : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTokens.radiusPill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? item.selectedIcon : item.icon,
              color: selected ? AppTokens.primary : AppTokens.textMuted,
              size: 24,
            ),
            if (selected) ...[
              const SizedBox(width: 8),
              Text(
                item.label,
                style: const TextStyle(
                  color: AppTokens.primary, fontSize: 13, fontWeight: FontWeight.w600, fontFamily: 'Inter'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Escribir el smoke test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gea_app/core/presentation/widgets/gea_floating_nav_bar.dart';

void main() {
  testWidgets('GeaFloatingNavBar renderiza items y reporta selección', (tester) async {
    int tapped = -1;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: GeaFloatingNavBar(
          selectedIndex: 0,
          onDestinationSelected: (i) => tapped = i,
          items: const [
            GeaNavItem(icon: Icons.calendar_today_outlined, selectedIcon: Icons.calendar_today, label: 'Cal'),
            GeaNavItem(icon: Icons.person_outline, selectedIcon: Icons.person, label: 'Perfil'),
            GeaNavItem(icon: Icons.campaign_outlined, selectedIcon: Icons.campaign, label: 'Anuncios'),
          ],
        ),
      ),
    ));

    expect(find.text('Cal'), findsOneWidget); // label visible solo en el seleccionado
    await tester.tap(find.byIcon(Icons.person_outline));
    expect(tapped, 1);
  });
}
```

- [ ] **Step 3: Ejecutar el test**

Run: `flutter test test/widgets/gea_floating_nav_bar_test.dart`
Expected: PASS (1 test).

- [ ] **Step 4: Commit**

```bash
git add lib/core/presentation/widgets/gea_floating_nav_bar.dart test/widgets/gea_floating_nav_bar_test.dart
git commit -m "feat(ui): GeaFloatingNavBar glassmorphism con acento rojo"
```

---

### Task 7: Cablear GeaFloatingNavBar en el router

**Files:**
- Modify: `lib/config/router/app_router.dart:60-85`

- [ ] **Step 1: Importar el widget**

Añadir al bloque de imports (tras la línea 14):
```dart
import 'package:gea_app/core/presentation/widgets/gea_floating_nav_bar.dart';
```

- [ ] **Step 2: Reemplazar el Scaffold body + bottomNavigationBar**

Reemplazar el `Scaffold` (líneas 60-85, hasta el cierre de `bottomNavigationBar: NavigationBar(...)`) por:

```dart
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: GeaFloatingNavBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        items: [
          GeaNavItem(
            icon: Icons.calendar_today_outlined,
            selectedIcon: Icons.calendar_today,
            label: l10n.navCalendar,
          ),
          GeaNavItem(
            icon: Icons.person_outline,
            selectedIcon: Icons.person,
            label: l10n.navProfile,
          ),
          GeaNavItem(
            icon: Icons.campaign_outlined,
            selectedIcon: Icons.campaign,
            label: l10n.navAnnouncements,
          ),
        ],
      ),
```

> El `floatingActionButton` condicional (líneas 86+) se conserva tal cual. `extendBody: true` permite que el contenido se vea bajo la barra translúcida.

- [ ] **Step 3: Verificar**

Run: `flutter analyze lib/config/router/app_router.dart`
Expected: No issues found.

Run: `flutter run` → confirmar la barra flotante glass, que el ítem activo muestra label rojo, y que el contenido de cada pantalla no queda tapado (si una lista queda tapada al final, se corrige con padding inferior en la Fase 5 de esa pantalla).

- [ ] **Step 4: Commit**

```bash
git add lib/config/router/app_router.dart
git commit -m "feat(nav): sustituir NavigationBar por GeaFloatingNavBar flotante"
```

---

## FASE 4 — Glassmorphism Cards

### Task 8: Crear GeaGlassCard

**Files:**
- Create: `lib/core/presentation/widgets/gea_glass_card.dart`
- Test: `test/widgets/gea_glass_card_test.dart`

- [ ] **Step 1: Crear el widget**

```dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:gea_app/config/theme/app_tokens.dart';

/// Contenedor con efecto glassmorphism. [accentColor] tiñe la sombra
/// (p. ej. el color del tipo de evento); por defecto usa el glow rojo.
class GeaGlassCard extends StatelessWidget {
  final Widget child;
  final Color? accentColor;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final double borderRadius;

  const GeaGlassCard({
    super.key,
    required this.child,
    this.accentColor,
    this.padding,
    this.onTap,
    this.borderRadius = AppTokens.radiusCard,
  });

  @override
  Widget build(BuildContext context) {
    final glow = (accentColor ?? AppTokens.primary).withValues(alpha: 0.22);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(color: glow, blurRadius: 20, spreadRadius: -6, offset: const Offset(0, 8)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: AppTokens.glassBlur, sigmaY: AppTokens.glassBlur),
          child: Material(
            color: AppTokens.glassFill,
            child: InkWell(
              onTap: onTap,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(borderRadius),
                  border: Border.all(color: AppTokens.glassBorder, width: 1),
                ),
                padding: padding ?? const EdgeInsets.all(16),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Escribir el smoke test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gea_app/core/presentation/widgets/gea_glass_card.dart';

void main() {
  testWidgets('GeaGlassCard renderiza su child y responde al tap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: GeaGlassCard(
          onTap: () => tapped = true,
          child: const Text('contenido'),
        ),
      ),
    ));
    expect(find.text('contenido'), findsOneWidget);
    await tester.tap(find.text('contenido'));
    expect(tapped, true);
  });
}
```

- [ ] **Step 3: Ejecutar el test**

Run: `flutter test test/widgets/gea_glass_card_test.dart`
Expected: PASS (1 test).

- [ ] **Step 4: Commit**

```bash
git add lib/core/presentation/widgets/gea_glass_card.dart test/widgets/gea_glass_card_test.dart
git commit -m "feat(ui): GeaGlassCard contenedor glassmorphism con sombra de acento"
```

---

### Task 9: Reestilizar event_card.dart con glass

**Files:**
- Modify: `lib/features/calendar/presentation/widgets/event_card.dart:197-373` (método `build`) y refs hardcodeadas en `showDetails`.

- [ ] **Step 1: Envolver la tarjeta de lista en GeaGlassCard**

Añadir import (tras la línea 14):
```dart
import 'package:gea_app/core/presentation/widgets/gea_glass_card.dart';
import 'package:gea_app/config/theme/app_tokens.dart';
```

Reemplazar el `return InkWell(...)` del `build` (líneas 197-373) de modo que el contenedor exterior sea un `GeaGlassCard` con `accentColor` = color del evento, conservando la franja lateral de color, la imagen y todos los `Row`/`Column` internos. El nuevo esqueleto:

```dart
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GeaGlassCard(
        onTap: () => _showEventDetails(context, ref),
        accentColor: event.isImportant ? AppTokens.important : eventColor,
        padding: EdgeInsets.zero,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: event.isImportant ? AppTokens.important : eventColor,
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(AppTokens.radiusCard)),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ... CONSERVAR todo el contenido interno actual de las líneas 233-309
                      // (título con estrella, descripción, hora, lugar, countdown, categoría)
                    ],
                  ),
                ),
              ),
              // ... CONSERVAR el bloque de imagen (líneas 314-368), cambiando
              //     ClipRRect right radius a AppTokens.radiusCard y
              //     placeholder Container(color: AppTokens.dividerColor) → AppTokens.surface2
            ],
          ),
        ),
      ),
    );
```

> Eliminar la variable local `const importantColor = AppTheme.importantColor;` (línea 195) y usar `AppTokens.important`. En el contenido interno, donde decía `importantColor` usar `AppTokens.important`.

- [ ] **Step 2: Corregir hardcodes en `showDetails`**

En `showDetails` (líneas 24-186) reemplazar:
- Línea 69 y 339 `Container(color: AppTheme.dividerColor)` → `Container(color: AppTokens.surface2)`
- Línea 146 `backgroundColor: Colors.red.shade700` → `backgroundColor: AppTokens.primary`
- Líneas 72, 342 `Icon(..., color: Colors.grey)` → `color: AppTokens.textMuted`
- Línea 98 `Icon(Icons.star_rounded, color: AppTheme.importantColor)` → `color: AppTokens.important`

> Las superficies del bottom sheet (`theme.colorScheme.surface`) ya resuelven a `surface1` por el tema; no tocar.

- [ ] **Step 3: Verificar**

Run: `flutter analyze lib/features/calendar/presentation/widgets/event_card.dart`
Expected: No issues found.

Run: `flutter run` → confirmar que la card de evento se ve glass con sombra del color del tipo, y el detalle (bottom sheet) coherente.

- [ ] **Step 4: Commit**

```bash
git add lib/features/calendar/presentation/widgets/event_card.dart
git commit -m "feat(ui): event_card con estilo glassmorphism y tokens dark"
```

---

### Task 10: Reestilizar announcement_card.dart con glass

**Files:**
- Modify: `lib/features/announcements/presentation/widgets/announcement_card.dart`

- [ ] **Step 1: Inspeccionar y envolver**

Abrir el archivo, identificar el contenedor raíz de la tarjeta (probablemente `Card`, `Container` o `InkWell`). Envolver el contenido en `GeaGlassCard` (import como en Task 9), usando `accentColor` = color de categoría si existe, o el primary por defecto. Reemplazar cualquier `Colors.white/black/grey`/hex según el mapeo de Task 5.

- [ ] **Step 2: Verificar**

Run: `flutter analyze lib/features/announcements/presentation/widgets/announcement_card.dart`
Expected: No issues found.

- [ ] **Step 3: Commit**

```bash
git add lib/features/announcements/presentation/widgets/announcement_card.dart
git commit -m "feat(ui): announcement_card con estilo glassmorphism y tokens dark"
```

---

## FASE 5 — Pulido por pantalla

### Task 11: Calendario (table_calendar tema oscuro + padding nav)

**Files:**
- Modify: `lib/features/calendar/presentation/screens/calendar_screen.dart`

- [ ] **Step 1: Tematizar `TableCalendar`**

Localizar el `TableCalendar(...)` y aplicar/ajustar su `calendarStyle` y `headerStyle` con tokens:
```dart
      calendarStyle: const CalendarStyle(
        defaultTextStyle: TextStyle(color: AppTokens.textPrimary),
        weekendTextStyle: TextStyle(color: AppTokens.textMuted),
        outsideTextStyle: TextStyle(color: AppTokens.textMuted),
        todayDecoration: BoxDecoration(color: AppTokens.primaryLight, shape: BoxShape.circle),
        todayTextStyle: TextStyle(color: AppTokens.primary, fontWeight: FontWeight.w700),
        selectedDecoration: BoxDecoration(color: AppTokens.primary, shape: BoxShape.circle),
        selectedTextStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        markerDecoration: BoxDecoration(color: AppTokens.primary, shape: BoxShape.circle),
      ),
      headerStyle: const HeaderStyle(
        titleCentered: true,
        formatButtonVisible: false,
        titleTextStyle: TextStyle(color: AppTokens.textPrimary, fontSize: 17, fontWeight: FontWeight.w600),
        leftChevronIcon: Icon(Icons.chevron_left, color: AppTokens.textSecondary),
        rightChevronIcon: Icon(Icons.chevron_right, color: AppTokens.textSecondary),
      ),
```
Añadir import `package:gea_app/config/theme/app_tokens.dart`. Ajustar nombres si el archivo ya define estos estilos (fusionar, no duplicar).

- [ ] **Step 2: Padding inferior por la nav flotante**

En la lista de eventos (el `ListView`/`SliverList` de la pantalla), asegurar `padding` inferior de al menos `100` para que el último ítem no quede bajo la barra flotante:
```dart
      padding: const EdgeInsets.only(bottom: 100),
```

- [ ] **Step 3: Barrer hardcodes** restantes del archivo según mapeo de Task 5.

- [ ] **Step 4: Verificar**

Run: `flutter analyze lib/features/calendar/presentation/screens/calendar_screen.dart`
Expected: No issues found. Verificar visualmente en `flutter run`.

- [ ] **Step 5: Commit**

```bash
git add lib/features/calendar/presentation/screens/calendar_screen.dart
git commit -m "feat(ui): calendario con table_calendar oscuro y padding de nav flotante"
```

---

### Task 12: Login (gradiente OLED + botón Microsoft)

**Files:**
- Modify: `lib/features/auth/presentation/screens/login_screen.dart`

- [ ] **Step 1: Fondo OLED con gradiente sutil rojo**

Envolver el body en un `Container` con `BoxDecoration` de gradiente:
```dart
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppTokens.background, Color(0xFF0A0000)],
        ),
      ),
```
Añadir import de tokens. Mantener el logo GEA; si está sobre fondo claro, asegurar versión que contraste en oscuro.

- [ ] **Step 2: Botón Microsoft sobre fondo oscuro**

Si hay un botón de login Microsoft con `Colors.white` de fondo, conservar el blanco (la marca Microsoft lo requiere) pero verificar que el texto/logo contraste; el resto de superficies a tokens.

- [ ] **Step 3: Barrer hardcodes** restantes según mapeo de Task 5.

- [ ] **Step 4: Verificar y commit**

Run: `flutter analyze lib/features/auth/presentation/screens/login_screen.dart`
```bash
git add lib/features/auth/presentation/screens/login_screen.dart
git commit -m "feat(ui): login con fondo OLED y gradiente rojo sutil"
```

---

### Task 13: Perfil + Notificaciones + widgets de feature restantes

**Files:**
- Modify: `lib/features/auth/presentation/screens/profile_screen.dart`
- Modify: `lib/core/presentation/screens/notifications_screen.dart`
- Modify: `lib/features/announcements/presentation/screens/announcements_screen.dart`
- Modify: `lib/features/announcements/presentation/screens/request_announcement_screen.dart`
- Modify: `lib/features/calendar/presentation/screens/pinned_events_screen.dart`
- Modify: widgets `event_countdown_chip.dart`, `important_event_pulse.dart`, `pin_button.dart`, `stream_badge.dart`, `share_event_bottom_sheet.dart`, `event_share_card.dart` (los que tengan hardcodes)

- [ ] **Step 1: Perfil** — header en `GeaGlassCard`, filas `info_row` (ya migrado en Task 5), barrer hardcodes; padding inferior `100` en el scroll.
- [ ] **Step 2: Notificaciones** — items en `GeaGlassCard`; estado vacío con `gea_empty_state`; padding inferior `100`.
- [ ] **Step 3: Anuncios (screen)** — `announcement_card` (ya glass), FAB rojo, padding inferior `100`, barrer hardcodes.
- [ ] **Step 4: Solicitar anuncio** — inputs oscuros (ya por tema), botón primario rojo (ya por tema), barrer hardcodes.
- [ ] **Step 5: Pinned events** — cards glass (reusa `EventCard`), padding inferior `100`.
- [ ] **Step 6: Widgets de feature** — aplicar mapeo de Task 5 a cada widget con hardcodes (usar inventario de Task 3). Chips/badges: fondo `AppTokens.primaryLight`/`surface2`, texto `AppTokens.primary`/`textSecondary`.

- [ ] **Step 7: Verificación global**

Run: `flutter analyze`
Expected: No issues.
Run: `flutter test`
Expected: todos los tests verdes.
Run: `flutter run` → recorrer las 3 pestañas + login + detalle de evento + notificaciones y confirmar coherencia visual (sin superficies blancas sueltas, sin texto invisible, contenido no tapado por la nav).

- [ ] **Step 8: Commit**

```bash
git add lib/
git commit -m "feat(ui): pulido dark/glass de perfil, notificaciones, anuncios y widgets de feature"
```

---

### Task 14: Verificación final con checklist E2E

**Files:** ninguno.

- [ ] **Step 1: Recorrido visual completo en dispositivo real**

Verificar, con sesión iniciada y sin sesión:
- [ ] Nav flotante glass visible en las 3 pestañas; label rojo en el activo; no tapa contenido.
- [ ] Calendario: días legibles, hoy/seleccionado en rojo, lista de eventos glass.
- [ ] Card de evento: efecto glass + sombra del color del tipo; estrella en importantes.
- [ ] Detalle de evento (bottom sheet): superficies oscuras, botón "Ver stream" rojo, sin grises rotos.
- [ ] Anuncios: cards glass; FAB rojo para solicitar.
- [ ] Login: fondo OLED con gradiente; botón Microsoft legible.
- [ ] Perfil y Notificaciones: sin superficies blancas sueltas; estados vacíos coherentes.
- [ ] Offline banner: contraste correcto.
- [ ] Rendimiento: scroll fluido con blur (probar en gama media; si hay lag, reducir `AppTokens.glassBlur` a 10).

- [ ] **Step 2: Confirmar sin regresiones de análisis/tests**

Run: `flutter analyze && flutter test`
Expected: limpio y verde.

---

## Self-Review

- **Cobertura del spec:**
  - Tokens OLED + radios + sombras + tipografía → Tasks 1-2. ✓
  - Realidad de hardcodes / barrido → Tasks 3-5 + barridos en 9-13. ✓
  - Floating nav glass → Tasks 6-7. ✓
  - Glass cards (event + announcement + detalle) → Tasks 8-10. ✓
  - Pantallas (calendario, login, perfil, notificaciones, anuncios, pinned) → Tasks 11-13. ✓
  - `table_calendar` y terceros → Task 11. ✓
  - Decisión diferida `lightTheme`→`darkTheme` → resuelta en Task 2 (se conserva `lightTheme` como alias de `darkTheme`, fricción mínima). ✓
  - No-objetivos (sin toggle de tema, sin cambios de navegación/datos) → respetados. ✓
- **Placeholders:** los tokens, el tema, los dos widgets nuevos y sus tests llevan código completo. Los barridos repetitivos usan un mapeo explícito hex→token en vez de repetir el archivo entero (DRY); cada uno indica archivo y comando de verificación.
- **Consistencia de tipos/nombres:** `AppTokens`, `GeaGlassCard`, `GeaFloatingNavBar`/`GeaNavItem`, `AppTheme.darkTheme` se usan idénticos en todas las tareas. `lightTheme` se conserva como alias para no romper `main.dart`.
- **Riesgo a vigilar en ejecución:** rendimiento de múltiples `BackdropFilter` (nav + cards) — mitigación en Task 14 (bajar blur). Contraste de blancos de marca (Microsoft) — se conservan a propósito.
```
