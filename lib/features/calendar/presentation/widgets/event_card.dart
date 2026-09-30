import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/entities/event.dart';
import 'package:gea_app/core/utils/image_utils.dart';
import 'package:gea_app/config/theme/app_tokens.dart';
import 'package:gea_app/core/presentation/widgets/gea_glass_card.dart';
import 'package:gea_app/core/presentation/widgets/info_row.dart';
import 'package:gea_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:gea_app/features/calendar/presentation/widgets/event_countdown_chip.dart';
import 'package:gea_app/features/calendar/presentation/widgets/pin_button.dart';
import 'package:gea_app/features/calendar/presentation/widgets/share_event_bottom_sheet.dart';
import 'package:gea_app/features/calendar/presentation/widgets/stream_badge.dart';

class EventCard extends ConsumerWidget {
  final Event event;
  const EventCard({super.key, required this.event});

  void _showEventDetails(BuildContext context, WidgetRef ref) {
    showDetails(context, event);
  }

  static void showDetails(BuildContext context, Event event) {
    final theme = Theme.of(context);
    final eventColor = event.colorHex != null 
        ? Color(int.parse(event.colorHex!.replaceFirst('#', '0xFF')))
        : theme.colorScheme.primary;
    final imageUrl = ImageUtils.getFullUrl(event.imageUrl);

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
                      AspectRatio(
                        aspectRatio: 16 / 9,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(color: AppTokens.surface2),
                            errorWidget: (_, __, ___) => Container(
                              color: AppTokens.surface2,
                              child: const Icon(Icons.image_not_supported_outlined, color: AppTokens.textMuted),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        if (event.category != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: eventColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              event.category!,
                              style: TextStyle(color: eventColor, fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ),
                        if (event.link != null) ...[
                          const SizedBox(width: 8),
                          StreamBadge(event: event),
                        ],
                        const Spacer(),
                        if (event.isImportant)
                          const Icon(Icons.star_rounded, color: AppTokens.important),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            event.title,
                            style: theme.textTheme.displayLarge?.copyWith(fontSize: 26, letterSpacing: -0.5),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Consumer(
                          builder: (context, ref, _) {
                            final isAuthenticated = ref.watch(authProvider).user != null;
                            return PinButton(
                              eventId: event.id,
                              isAuthenticated: isAuthenticated,
                              size: 28,
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    InfoRow(
                      icon: Icons.calendar_today_rounded,
                      text: DateFormat('EEEE d MMMM, yyyy', 'es_ES').format(event.date),
                    ),
                    const SizedBox(height: 12),
                    InfoRow(
                      icon: Icons.access_time_rounded,
                      text: DateFormat('h:mm a', 'es_ES').format(event.date) +
                            (event.endDate != null ? ' - ${DateFormat('h:mm a', 'es_ES').format(event.endDate!)}' : ''),
                    ),
                    const SizedBox(height: 12),
                    InfoRow(
                      icon: Icons.location_on_outlined,
                      text: (event.externalLocation?.isNotEmpty == true ? event.externalLocation! : null) ?? event.location ?? (event.locations?.isNotEmpty == true ? event.locations!.join(', ') : null) ?? 'Por definir',
                    ),
                    if (event.link != null && event.link!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        icon: const Icon(Icons.play_circle_outline_rounded, size: 20),
                        label: const Text('Ver stream'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTokens.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 44),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          final uri = Uri.tryParse(event.link!);
                          if (uri != null) launchUrl(uri, mode: LaunchMode.externalApplication);
                        },
                      ),
                    ],
                    const SizedBox(height: 32),
                    const Divider(),
                    const SizedBox(height: 32),
                    Text(
                      'Acerca de este evento',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      event.description,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
                    ),
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.share_outlined),
                      label: const Text('Compartir evento'),
                      onPressed: () {
                        Navigator.of(context).pop();
                        ShareEventBottomSheet.show(context, event);
                      },
                    ),
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
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final eventColor = event.colorHex != null 
        ? Color(int.parse(event.colorHex!.replaceFirst('#', '0xFF')))
        : theme.colorScheme.primary;
    final imageUrl = ImageUtils.getFullUrl(event.imageUrl);

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
                      Row(
                        children: [
                          if (event.isImportant)
                            const Padding(
                              padding: EdgeInsets.only(right: 6),
                              child: Icon(Icons.star_rounded, color: AppTokens.important, size: 16),
                            ),
                          Expanded(
                            child: Text(
                              event.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium,
                            ),
                          ),
                        ],
                      ),
                      if (event.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          event.description,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.access_time_rounded, size: 14, color: theme.colorScheme.secondary),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('h:mm a', 'es_ES').format(event.date) +
                            (event.endDate != null ? ' - ${DateFormat('h:mm a', 'es_ES').format(event.endDate!)}' : ''),
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: 14, color: theme.colorScheme.secondary),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              (event.location ?? (event.locations?.isNotEmpty == true ? event.locations!.join(', ') : null)) ?? 'Por definir',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          EventCountdownChip(date: event.date, endDate: event.endDate),
                          if (event.link != null) ...[
                            const SizedBox(width: 6),
                            StreamBadge(event: event),
                          ],
                        ],
                      ),
                      if (event.category != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            event.category!,
                            style: TextStyle(
                              color: event.isImportant ? AppTokens.important : eventColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (imageUrl != null)
                Consumer(
                  builder: (context, ref, _) {
                    final isAuthenticated = ref.watch(authProvider).user != null;
                    return SizedBox(
                      width: 120,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.horizontal(right: Radius.circular(AppTokens.radiusCard)),
                            child: ShaderMask(
                              shaderCallback: (rect) => const LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [Colors.transparent, Colors.black],
                                stops: [0.0, 0.35],
                              ).createShader(rect),
                              blendMode: BlendMode.dstIn,
                              child: CachedNetworkImage(
                                imageUrl: imageUrl,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Container(color: AppTokens.surface2),
                                errorWidget: (_, __, ___) => Container(
                                  color: AppTokens.surface2,
                                  child: const Icon(Icons.image_not_supported_outlined, color: AppTokens.textMuted, size: 24),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 6,
                            right: 6,
                            child: Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.45),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: PinButton(
                                eventId: event.id,
                                isAuthenticated: isAuthenticated,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

