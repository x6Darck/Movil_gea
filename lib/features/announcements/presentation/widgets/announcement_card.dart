import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/announcement.dart';
import 'package:gea_app/core/utils/image_utils.dart';
import 'package:gea_app/config/theme/app_tokens.dart';
import 'package:gea_app/core/presentation/widgets/gea_glass_card.dart';
import 'package:gea_app/core/presentation/widgets/info_row.dart';

class AnnouncementCard extends StatelessWidget {
  final Announcement announcement;
  const AnnouncementCard({super.key, required this.announcement});

  String _formatTime12h(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty || timeStr == '-') return '';
    try {
      final parts = timeStr.split(':');
      if (parts.length >= 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        final period = hour >= 12 ? 'PM' : 'AM';
        final formattedHour = hour % 12 == 0 ? 12 : hour % 12;
        return '$formattedHour:${minute.toString().padLeft(2, '0')} $period';
      }
    } catch (e) {
      // ignore
    }
    return timeStr;
  }

  String _getVigenciaText() {
    if (announcement.fechaInicioPublicacion != null) {
      final start = DateFormat('d MMMM, yyyy', 'es_ES').format(announcement.fechaInicioPublicacion!);
      final end = announcement.fechaFinPublicacion != null 
          ? DateFormat('d MMMM, yyyy', 'es_ES').format(announcement.fechaFinPublicacion!)
          : 'N/A';
      return '$start al $end';
    }
    return 'Vigencia no especificada';
  }

  String? _getHorarioText() {
    final start = _formatTime12h(announcement.horaInicio);
    final end = _formatTime12h(announcement.horaFin);
    if (start.isNotEmpty) {
      return start + (end.isNotEmpty ? ' - $end' : '');
    }
    return null;
  }

  String _getLugaresText() {
    final placesArr = announcement.lugares ?? [];
    if (placesArr.isNotEmpty) {
      return placesArr.join(', ');
    }
    return announcement.lugar ?? 'General / Múltiples ubicaciones';
  }

  static void showDetails(BuildContext context, Announcement announcement) {
    AnnouncementCard(announcement: announcement)._showAnnouncementDetails(context);
  }

  void _showAnnouncementDetails(BuildContext context) {
    final theme = Theme.of(context);
    final imageUrl = ImageUtils.getFullUrl(announcement.imageUrl);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  children: [
                    if (imageUrl != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          width: double.infinity,
                          fit: BoxFit.fitWidth,
                          placeholder: (_, __) => Container(
                            height: 200,
                            color: AppTokens.surface2,
                          ),
                          errorWidget: (_, __, ___) => Container(
                            height: 160,
                            color: theme.colorScheme.surface,
                            child: const Icon(Icons.image_not_supported_outlined, color: AppTokens.textMuted),
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        if (announcement.category != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              announcement.category!,
                              style: TextStyle(color: theme.colorScheme.primary, fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ),
                        const Spacer(),
                        Text(
                          DateFormat('d MMMM, yyyy', 'es_ES').format(announcement.date),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      announcement.title,
                      style: theme.textTheme.displayLarge?.copyWith(fontSize: 26, letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      announcement.content,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 24),
                    InfoRow(
                      icon: Icons.calendar_today_rounded,
                      text: _getVigenciaText(),
                    ),
                    if (_getHorarioText() != null) ...[
                      const SizedBox(height: 12),
                      InfoRow(
                        icon: Icons.access_time_rounded,
                        text: _getHorarioText()!,
                      ),
                    ],
                    const SizedBox(height: 12),
                    InfoRow(
                      icon: Icons.location_on_outlined,
                      text: _getLugaresText(),
                    ),
                    if (announcement.responsableAnuncio != null && announcement.responsableAnuncio!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      InfoRow(
                        icon: Icons.person_outline_rounded,
                        text: announcement.responsableAnuncio!,
                      ),
                    ],
                    if (announcement.correoContacto != null && announcement.correoContacto!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      InfoRow(
                        icon: Icons.mail_outline_rounded,
                        text: announcement.correoContacto!,
                      ),
                    ],
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final imageUrl = ImageUtils.getFullUrl(announcement.imageUrl);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GeaGlassCard(
        onTap: () => _showAnnouncementDetails(context),
        padding: EdgeInsets.zero,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(AppTokens.radiusCard)),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              announcement.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              announcement.content,
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.access_time_rounded, size: 14, color: theme.colorScheme.secondary),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    _getVigenciaText() + 
                                    (_getHorarioText() != null ? ' (${_getHorarioText()})' : ''),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.location_on_outlined, size: 14, color: theme.colorScheme.secondary),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    _getLugaresText(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ),
                              ],
                            ),
                            if (announcement.category != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  announcement.category!,
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (imageUrl != null) ...[
                        const SizedBox(width: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: imageUrl,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              width: 80,
                              height: 80,
                              color: AppTokens.surface2,
                            ),
                            errorWidget: (_, __, ___) => Container(
                              width: 80,
                              height: 80,
                              color: AppTokens.surface2,
                              child: const Icon(Icons.image_not_supported_outlined, color: AppTokens.textMuted, size: 24),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


