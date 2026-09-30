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
