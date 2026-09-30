import 'package:flutter/material.dart';
import 'package:gea_app/config/theme/app_tokens.dart';

enum GeaButtonVariant { primary, secondary, danger, ghost }

class GeaButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final GeaButtonVariant variant;
  final IconData? icon;

  const GeaButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.variant = GeaButtonVariant.primary,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    if (variant == GeaButtonVariant.secondary) {
      return OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        child: _buildChild(context),
      );
    }
    
    if (variant == GeaButtonVariant.ghost) {
      return TextButton(
        onPressed: isLoading ? null : onPressed,
        style: TextButton.styleFrom(
          foregroundColor: AppTokens.textSecondary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Inter'),
        ),
        child: _buildChild(context),
      );
    }

    // Primary or Danger
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: variant == GeaButtonVariant.danger
          ? ElevatedButton.styleFrom(backgroundColor: AppTokens.error)
          : null, // Uses default from theme
      child: _buildChild(context),
    );
  }

  Widget _buildChild(BuildContext context) {
    if (isLoading) {
      return SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withValues(alpha: 0.7)),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Text(text),
        ],
      );
    }

    return Text(text);
  }
}
