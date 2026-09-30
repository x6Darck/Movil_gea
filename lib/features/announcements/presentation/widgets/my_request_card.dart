import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gea_app/config/theme/app_tokens.dart';
import '../../domain/entities/announcement_request.dart';
import '../../domain/entities/request_status.dart';
import 'request_status_badge.dart';

class MyRequestCard extends StatelessWidget {
  final AnnouncementRequest request;
  final VoidCallback? onEdit;

  const MyRequestCard({super.key, required this.request, this.onEdit});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fecha = request.fechaCreacion != null
        ? DateFormat('d MMM, yyyy', 'es_ES').format(request.fechaCreacion!)
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  request.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              RequestStatusBadge(status: request.status),
            ],
          ),
          if (fecha.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(fecha, style: theme.textTheme.bodySmall),
          ],
          const SizedBox(height: 8),
          Text(
            request.description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium,
          ),
          if (request.status == RequestStatus.rechazada &&
              (request.rejectionReason?.isNotEmpty ?? false))
            _reasonBox(
              context,
              icon: Icons.cancel_outlined,
              color: AppTokens.error,
              title: 'Motivo del rechazo',
              body: request.rejectionReason!,
            ),
          if (request.status == RequestStatus.enRevision &&
              (request.reviewNotes?.isNotEmpty ?? false))
            _reasonBox(
              context,
              icon: Icons.edit_note_outlined,
              color: AppTokens.warning,
              title: 'Observaciones para corregir',
              body: request.reviewNotes!,
            ),
          if (onEdit != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Editar y reenviar'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _reasonBox(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String body,
  }) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: color, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(body, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
