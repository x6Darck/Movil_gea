import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gea_app/config/theme/app_tokens.dart';
import 'package:gea_app/core/models/app_notification.dart';
import 'package:gea_app/l10n/app_localizations.dart';
import 'package:gea_app/core/providers/notification_providers.dart';
import 'package:gea_app/features/calendar/presentation/widgets/event_card.dart';
import 'package:gea_app/features/announcements/presentation/widgets/announcement_card.dart';
import 'package:gea_app/core/presentation/widgets/gea_empty_state.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final notificationsAsync = ref.watch(appNotificationsProvider);
    final readIds = ref.watch(readNotificationIdsProvider);
    final theme = Theme.of(context);
    const goldColor = AppTokens.warning;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.notifications),
        actions: [
          notificationsAsync.maybeWhen(
            data: (notifications) {
              final unreadCount = notifications.where((n) => !readIds.contains(n.id)).length;
              if (unreadCount == 0) return const SizedBox.shrink();
              return TextButton.icon(
                icon: const Icon(Icons.done_all, size: 18),
                label: Text(l10n.markAllRead),
                onPressed: () {
                  final unreadIds = notifications.where((n) => !readIds.contains(n.id)).map((n) => n.id).toList();
                  ref.read(readNotificationIdsProvider.notifier).markAllAsRead(unreadIds);
                },
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return Center(
              child: GeaEmptyState(
                icon: Icons.notifications_none_rounded,
                title: l10n.noNotifications,
                description: l10n.noNotificationsDesc,
              ),
            );
          }

          // Dividir en secciones: importantes (eventos con flag esImportante) y recientes (el resto)
          final importantes = notifications.where((n) => n.isImportant).toList();
          final recientes = notifications.where((n) => !n.isImportant).toList();

          return ListView(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
            children: [
              // Sección de Importantes
              if (importantes.isNotEmpty) ...[
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: goldColor, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      l10n.notificationSectionImportant,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: goldColor,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: importantes.length,
                  itemBuilder: (context, index) {
                    final item = importantes[index];
                    final isRead = readIds.contains(item.id);
                    return _NotificationCard(
                      notification: item,
                      isRead: isRead,
                      isImportantLayout: true,
                    );
                  },
                ),
                const SizedBox(height: 24),
              ],

              // Sección de Recientes
              if (recientes.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(Icons.access_time_rounded, color: theme.colorScheme.secondary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      l10n.notificationSectionRecent,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recientes.length,
                  itemBuilder: (context, index) {
                    final item = recientes[index];
                    final isRead = readIds.contains(item.id);
                    return _NotificationCard(
                      notification: item,
                      isRead: isRead,
                      isImportantLayout: false,
                    );
                  },
                ),
              ],
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(strokeWidth: 3),
        ),
        error: (err, stack) => Center(
          child: GeaEmptyState(
            icon: Icons.error_outline_rounded,
            title: l10n.loadingError,
            description: 'No pudimos sincronizar tus notificaciones. $err',
          ),
        ),
      ),
    );
  }
}

class _NotificationCard extends ConsumerWidget {
  final AppNotification notification;
  final bool isRead;
  final bool isImportantLayout;

  const _NotificationCard({
    required this.notification,
    required this.isRead,
    required this.isImportantLayout,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    const goldColor = AppTokens.warning;
    final dateStr = DateFormat('d MMMM, yyyy - h:mm a', 'es_ES').format(notification.date);

    // Definición de colores según categoría de evento (si es evento)
    Color categoryColor = theme.primaryColor;
    if (notification.type == NotificationType.event && notification.originalObject.colorHex != null) {
      try {
        final hexStr = (notification.originalObject.colorHex as String).replaceAll('#', '');
        categoryColor = Color(int.parse('FF$hexStr', radix: 16));
      } catch (e) {
        // ignore
      }
    } else if (notification.type == NotificationType.announcement) {
      categoryColor = theme.colorScheme.secondary;
    }

    return Opacity(
      opacity: isRead ? 0.7 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          gradient: isImportantLayout && !isRead
              ? LinearGradient(
                  colors: [
                    AppTokens.warning.withValues(alpha: 0.08),
                    theme.colorScheme.surface,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isImportantLayout && !isRead
                ? goldColor.withValues(alpha: 0.8)
                : theme.dividerColor,
            width: isImportantLayout && !isRead ? 1.5 : 1.0,
          ),
          boxShadow: [
            if (!isRead)
              BoxShadow(
                color: (isImportantLayout ? goldColor : theme.primaryColor).withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              // Marcar como leída
              ref.read(readNotificationIdsProvider.notifier).markAsRead(notification.id);

              // Abrir detalle correspondiente
              if (notification.type == NotificationType.event) {
                EventCard.showDetails(context, notification.originalObject);
              } else {
                AnnouncementCard.showDetails(context, notification.originalObject);
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icono indicador de tipo con dot de no leído
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: categoryColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          notification.type == NotificationType.event
                              ? Icons.calendar_month_rounded
                              : Icons.campaign_rounded,
                          color: categoryColor,
                          size: 24,
                        ),
                      ),
                      if (!isRead)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: isImportantLayout ? goldColor : AppTokens.error,
                              shape: BoxShape.circle,
                              border: Border.all(color: theme.colorScheme.surface, width: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  // Textos e información
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: categoryColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  notification.type == NotificationType.event
                                      ? (notification.originalObject.category ?? 'Evento')
                                      : l10n.announcementBadge,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: categoryColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              dateStr,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          notification.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                            fontSize: 15,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          notification.description,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
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
