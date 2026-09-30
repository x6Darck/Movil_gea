import 'package:flutter/material.dart';
import 'package:gea_app/config/theme/app_tokens.dart';

/// Tarjeta con superficie sólida y acento de color en el borde
/// (p. ej. el color del tipo de evento); por defecto usa el rojo de marca.
///
/// Antes tenía efecto glassmorphism (BackdropFilter + sombra de color
/// difuminada al 22%) — pensado para un fondo negro OLED, donde el brillo de
/// color se veía sutil y el blur difuminaba contenido oscuro. Sobre el fondo
/// claro actual, esa misma sombra de color se ve como un halo sangrando
/// fuera de la tarjeta, y el blur recoge los colores de las tarjetas de
/// atrás (rojos/naranjas) en vez de fundirse. Una superficie sólida con
/// sombra neutra y borde tintado da la misma identidad de color sin esos
/// efectos impredecibles.
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
    final accent = accentColor ?? AppTokens.primary;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Material(
          color: AppTokens.surface1,
          child: InkWell(
            onTap: onTap,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(color: accent.withValues(alpha: 0.25), width: 1),
              ),
              padding: padding ?? const EdgeInsets.all(16),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
