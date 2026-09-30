// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'GEA App';

  @override
  String get navCalendar => 'Calendario';

  @override
  String get navProfile => 'Perfil';

  @override
  String get navAnnouncements => 'Anuncios';

  @override
  String get requestAnnouncement => 'Solicitar Anuncio';

  @override
  String get loginRequired => 'Inicio de sesión requerido';

  @override
  String get loginRequiredMessage =>
      'Para realizar una solicitud de anuncio, debes iniciar sesión con tu cuenta institucional.';

  @override
  String get cancel => 'Cancelar';

  @override
  String get welcomeTitle => 'Bienvenido a GEA';

  @override
  String get welcomeSubtitle =>
      'Ingresa con tu cuenta institucional para continuar.';

  @override
  String get emailLabel => 'Correo Institucional';

  @override
  String get emailHint => 'nombre@institucion.edu.co';

  @override
  String get passwordLabel => 'Contraseña';

  @override
  String get forgotPassword => '¿Olvidaste tu contraseña?';

  @override
  String get loginButton => 'Iniciar Sesión';

  @override
  String get microsoftLogin => 'Iniciar sesión con Microsoft';

  @override
  String get guestButton => 'Continuar como invitado';

  @override
  String get fieldRequired => 'Este campo es requerido';

  @override
  String get emailInvalid => 'Ingresa un correo válido';

  @override
  String get calendarTitle => 'Calendario';

  @override
  String get noEvents => 'Sin eventos';

  @override
  String get noEventsDesc => 'No hay eventos programados para este día.';

  @override
  String get upcomingEvents => 'Próximos Eventos';

  @override
  String get featured => 'DESTACADO';

  @override
  String get errorTitle => 'Ocurrió un error';

  @override
  String get eventsError =>
      'No pudimos cargar los eventos. Intenta nuevamente más tarde.';

  @override
  String get announcementsTitle => 'Anuncios';

  @override
  String get noAnnouncements => 'Sin anuncios';

  @override
  String get noAnnouncementsDesc =>
      'Aún no hay anuncios publicados en la plataforma.';

  @override
  String get announcementsError =>
      'No pudimos cargar los anuncios. Intenta nuevamente más tarde.';

  @override
  String get retry => 'Reintentar';

  @override
  String get profileTitle => 'Mi Perfil';

  @override
  String get guestWelcome => 'Bienvenido, Invitado';

  @override
  String get guestMessage =>
      'Inicia sesión con tu cuenta institucional para solicitar anuncios de la universidad, registrar tus dispositivos y acceder a todas las funciones del sistema.';

  @override
  String get offlineBanner => 'Sin conexión — mostrando datos guardados';

  @override
  String get logout => 'Cerrar sesión';

  @override
  String get notifications => 'Notificaciones';

  @override
  String get loginAction => 'Iniciar Sesión';

  @override
  String get markAllRead => 'Marcar todo leído';

  @override
  String get noNotifications => 'Sin notificaciones';

  @override
  String get noNotificationsDesc =>
      'Aquí verás los últimos eventos y anuncios publicados.';

  @override
  String get notificationSectionImportant => 'IMPORTANTE';

  @override
  String get notificationSectionRecent => 'NUEVOS Y RECIENTES';

  @override
  String get loadingError => 'Error de carga';

  @override
  String get announcementBadge => 'Anuncio';

  @override
  String get featuredEvents => 'EVENTOS DESTACADOS';
}
