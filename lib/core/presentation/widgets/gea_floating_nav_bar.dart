import 'package:flutter/material.dart';
import 'package:gea_app/config/theme/app_tokens.dart';

class GeaNavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  const GeaNavItem({required this.icon, required this.selectedIcon, required this.label});
}

/// Barra de navegación flotante, superficie sólida con acento rojo.
///
/// Antes usaba BackdropFilter (glassmorphism) — con fondo oscuro se veía
/// bien porque difuminaba contenido oscuro; sobre el fondo claro actual
/// difumina las tarjetas de eventos (rojas/naranjas) que quedan detrás y
/// tiñe la barra con un lavado de color impredecible según qué haya
/// scrolleado detrás. Una superficie sólida es predecible en cualquier caso.
class GeaFloatingNavBar extends StatelessWidget {
  static const double barHeight = 66;
  static const double bottomMargin = 20;

  /// Espacio total que la barra ocupa desde el borde inferior de la pantalla,
  /// incluyendo el inset del sistema (barra de gestos o de 3 botones). Las
  /// pantallas con contenido scrolleable deben usar esto como padding inferior
  /// para que nada quede oculto detrás de la barra flotante.
  static double footprint(BuildContext context) =>
      barHeight + bottomMargin + MediaQuery.of(context).padding.bottom;

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
    // 20 fijo no alcanzaba en celulares con barra de navegación de 3 botones
    // (le suma altura real a la pantalla, a diferencia de la barra de gestos
    // que es una línea fina) — la barra flotante quedaba pegada o tapada por
    // los botones físicos/virtuales del sistema. MediaQuery.padding.bottom
    // da el alto real de esa zona en cada dispositivo.
    final systemInset = MediaQuery.of(context).padding.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, bottomMargin + systemInset),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTokens.radiusPill),
          boxShadow: AppTokens.glowShadow,
        ),
        child: Container(
          height: barHeight,
          decoration: BoxDecoration(
            color: AppTokens.surface1,
            borderRadius: BorderRadius.circular(AppTokens.radiusPill),
            border: Border.all(color: AppTokens.surface3, width: 1),
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
                    color: AppTokens.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Inter'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
