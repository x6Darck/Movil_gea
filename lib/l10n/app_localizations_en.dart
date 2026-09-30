// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'GEA App';

  @override
  String get navCalendar => 'Calendar';

  @override
  String get navProfile => 'Profile';

  @override
  String get navAnnouncements => 'Announcements';

  @override
  String get requestAnnouncement => 'Request Announcement';

  @override
  String get loginRequired => 'Login required';

  @override
  String get loginRequiredMessage =>
      'To request an announcement, you must sign in with your institutional account.';

  @override
  String get cancel => 'Cancel';

  @override
  String get welcomeTitle => 'Welcome to GEA';

  @override
  String get welcomeSubtitle =>
      'Sign in with your institutional account to continue.';

  @override
  String get emailLabel => 'Institutional Email';

  @override
  String get emailHint => 'name@institution.edu.co';

  @override
  String get passwordLabel => 'Password';

  @override
  String get forgotPassword => 'Forgot your password?';

  @override
  String get loginButton => 'Sign In';

  @override
  String get microsoftLogin => 'Sign in with Microsoft';

  @override
  String get guestButton => 'Continue as guest';

  @override
  String get fieldRequired => 'This field is required';

  @override
  String get emailInvalid => 'Enter a valid email';

  @override
  String get calendarTitle => 'Calendar';

  @override
  String get noEvents => 'No events';

  @override
  String get noEventsDesc => 'No events scheduled for this day.';

  @override
  String get upcomingEvents => 'Upcoming Events';

  @override
  String get featured => 'FEATURED';

  @override
  String get errorTitle => 'An error occurred';

  @override
  String get eventsError => 'Could not load events. Please try again later.';

  @override
  String get announcementsTitle => 'Announcements';

  @override
  String get noAnnouncements => 'No announcements';

  @override
  String get noAnnouncementsDesc => 'No announcements published yet.';

  @override
  String get announcementsError =>
      'Could not load announcements. Please try again later.';

  @override
  String get retry => 'Retry';

  @override
  String get profileTitle => 'My Profile';

  @override
  String get guestWelcome => 'Welcome, Guest';

  @override
  String get guestMessage =>
      'Sign in with your institutional account to request announcements, register your devices, and access all system features.';

  @override
  String get offlineBanner => 'Offline — showing saved data';

  @override
  String get logout => 'Sign out';

  @override
  String get notifications => 'Notifications';

  @override
  String get loginAction => 'Sign In';

  @override
  String get markAllRead => 'Mark all read';

  @override
  String get noNotifications => 'No notifications';

  @override
  String get noNotificationsDesc =>
      'Here you\'ll see the latest events and announcements.';

  @override
  String get notificationSectionImportant => 'IMPORTANT';

  @override
  String get notificationSectionRecent => 'NEW AND RECENT';

  @override
  String get loadingError => 'Loading error';

  @override
  String get announcementBadge => 'Announcement';

  @override
  String get featuredEvents => 'FEATURED EVENTS';
}
