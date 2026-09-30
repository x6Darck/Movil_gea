import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gea_app/core/models/app_notification.dart';
import 'package:gea_app/features/calendar/presentation/providers/calendar_providers.dart';
import 'package:gea_app/features/announcements/presentation/providers/announcement_providers.dart';

class ReadNotificationIdsNotifier extends StateNotifier<Set<String>> {
  ReadNotificationIdsNotifier() : super(const {}) {
    _loadFromPrefs();
  }

  static const _prefsKey = 'read_notification_ids';

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? ids = prefs.getStringList(_prefsKey);
      if (ids != null) {
        state = ids.toSet();
      }
    } catch (e) {
      // ignore
    }
  }

  Future<void> markAsRead(String id) async {
    if (state.contains(id)) return;
    state = {...state, id};
    await _saveToPrefs();
  }

  Future<void> markAllAsRead(List<String> ids) async {
    state = {...state, ...ids};
    await _saveToPrefs();
  }

  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefsKey, state.toList());
    } catch (e) {
      // ignore
    }
  }
}

// Proveedor para persistir y rastrear los IDs de notificaciones leídas
final readNotificationIdsProvider = StateNotifierProvider<ReadNotificationIdsNotifier, Set<String>>((ref) {
  return ReadNotificationIdsNotifier();
});

// Proveedor que combina Eventos y Anuncios cargados desde la API en notificaciones unificadas
final appNotificationsProvider = Provider<AsyncValue<List<AppNotification>>>((ref) {
  final eventsAsync = ref.watch(eventsProvider);
  final announcementsAsync = ref.watch(announcementsProvider);

  if (eventsAsync.hasError) return AsyncValue.error(eventsAsync.error!, eventsAsync.stackTrace!);
  if (announcementsAsync.hasError) return AsyncValue.error(announcementsAsync.error!, announcementsAsync.stackTrace!);

  if (eventsAsync.isLoading || announcementsAsync.isLoading) {
    return const AsyncValue.loading();
  }

  final events = eventsAsync.value ?? [];
  final announcements = announcementsAsync.value ?? [];

  final List<AppNotification> notifications = [];

  // Mapear Eventos a AppNotification
  for (final event in events) {
    notifications.add(AppNotification(
      id: 'event_${event.id}',
      title: event.title,
      description: event.description,
      date: event.date,
      isImportant: event.isImportant,
      type: NotificationType.event,
      originalObject: event,
    ));
  }

  // Mapear Anuncios a AppNotification
  for (final announcement in announcements) {
    notifications.add(AppNotification(
      id: 'announcement_${announcement.id}',
      title: announcement.title,
      description: announcement.content,
      date: announcement.date,
      isImportant: false, // Los anuncios en GEA no tienen flag esImportante nativo
      type: NotificationType.announcement,
      originalObject: announcement,
    ));
  }

  // Ordenar de manera descendente (las más recientes primero)
  notifications.sort((a, b) => b.date.compareTo(a.date));

  return AsyncValue.data(notifications);
});

// Conteo de notificaciones no leídas
final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notificationsAsync = ref.watch(appNotificationsProvider);
  final readIds = ref.watch(readNotificationIdsProvider);

  return notificationsAsync.maybeWhen(
    data: (notifications) {
      return notifications.where((n) => !readIds.contains(n.id)).length;
    },
    orElse: () => 0,
  );
});
