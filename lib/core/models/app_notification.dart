enum NotificationType { event, announcement }

class AppNotification {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final bool isImportant;
  final NotificationType type;
  final dynamic originalObject; // Event o Announcement

  AppNotification({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.isImportant,
    required this.type,
    required this.originalObject,
  });
}
