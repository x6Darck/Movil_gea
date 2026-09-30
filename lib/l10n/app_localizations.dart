import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In es, this message translates to:
  /// **'GEA App'**
  String get appTitle;

  /// No description provided for @navCalendar.
  ///
  /// In es, this message translates to:
  /// **'Calendario'**
  String get navCalendar;

  /// No description provided for @navProfile.
  ///
  /// In es, this message translates to:
  /// **'Perfil'**
  String get navProfile;

  /// No description provided for @navAnnouncements.
  ///
  /// In es, this message translates to:
  /// **'Anuncios'**
  String get navAnnouncements;

  /// No description provided for @requestAnnouncement.
  ///
  /// In es, this message translates to:
  /// **'Solicitar Anuncio'**
  String get requestAnnouncement;

  /// No description provided for @loginRequired.
  ///
  /// In es, this message translates to:
  /// **'Inicio de sesión requerido'**
  String get loginRequired;

  /// No description provided for @loginRequiredMessage.
  ///
  /// In es, this message translates to:
  /// **'Para realizar una solicitud de anuncio, debes iniciar sesión con tu cuenta institucional.'**
  String get loginRequiredMessage;

  /// No description provided for @cancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get cancel;

  /// No description provided for @welcomeTitle.
  ///
  /// In es, this message translates to:
  /// **'Bienvenido a GEA'**
  String get welcomeTitle;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Ingresa con tu cuenta institucional para continuar.'**
  String get welcomeSubtitle;

  /// No description provided for @emailLabel.
  ///
  /// In es, this message translates to:
  /// **'Correo Institucional'**
  String get emailLabel;

  /// No description provided for @emailHint.
  ///
  /// In es, this message translates to:
  /// **'nombre@institucion.edu.co'**
  String get emailHint;

  /// No description provided for @passwordLabel.
  ///
  /// In es, this message translates to:
  /// **'Contraseña'**
  String get passwordLabel;

  /// No description provided for @forgotPassword.
  ///
  /// In es, this message translates to:
  /// **'¿Olvidaste tu contraseña?'**
  String get forgotPassword;

  /// No description provided for @loginButton.
  ///
  /// In es, this message translates to:
  /// **'Iniciar Sesión'**
  String get loginButton;

  /// No description provided for @microsoftLogin.
  ///
  /// In es, this message translates to:
  /// **'Iniciar sesión con Microsoft'**
  String get microsoftLogin;

  /// No description provided for @guestButton.
  ///
  /// In es, this message translates to:
  /// **'Continuar como invitado'**
  String get guestButton;

  /// No description provided for @fieldRequired.
  ///
  /// In es, this message translates to:
  /// **'Este campo es requerido'**
  String get fieldRequired;

  /// No description provided for @emailInvalid.
  ///
  /// In es, this message translates to:
  /// **'Ingresa un correo válido'**
  String get emailInvalid;

  /// No description provided for @calendarTitle.
  ///
  /// In es, this message translates to:
  /// **'Calendario'**
  String get calendarTitle;

  /// No description provided for @noEvents.
  ///
  /// In es, this message translates to:
  /// **'Sin eventos'**
  String get noEvents;

  /// No description provided for @noEventsDesc.
  ///
  /// In es, this message translates to:
  /// **'No hay eventos programados para este día.'**
  String get noEventsDesc;

  /// No description provided for @upcomingEvents.
  ///
  /// In es, this message translates to:
  /// **'Próximos Eventos'**
  String get upcomingEvents;

  /// No description provided for @featured.
  ///
  /// In es, this message translates to:
  /// **'DESTACADO'**
  String get featured;

  /// No description provided for @errorTitle.
  ///
  /// In es, this message translates to:
  /// **'Ocurrió un error'**
  String get errorTitle;

  /// No description provided for @eventsError.
  ///
  /// In es, this message translates to:
  /// **'No pudimos cargar los eventos. Intenta nuevamente más tarde.'**
  String get eventsError;

  /// No description provided for @announcementsTitle.
  ///
  /// In es, this message translates to:
  /// **'Anuncios'**
  String get announcementsTitle;

  /// No description provided for @noAnnouncements.
  ///
  /// In es, this message translates to:
  /// **'Sin anuncios'**
  String get noAnnouncements;

  /// No description provided for @noAnnouncementsDesc.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay anuncios publicados en la plataforma.'**
  String get noAnnouncementsDesc;

  /// No description provided for @announcementsError.
  ///
  /// In es, this message translates to:
  /// **'No pudimos cargar los anuncios. Intenta nuevamente más tarde.'**
  String get announcementsError;

  /// No description provided for @retry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get retry;

  /// No description provided for @profileTitle.
  ///
  /// In es, this message translates to:
  /// **'Mi Perfil'**
  String get profileTitle;

  /// No description provided for @guestWelcome.
  ///
  /// In es, this message translates to:
  /// **'Bienvenido, Invitado'**
  String get guestWelcome;

  /// No description provided for @guestMessage.
  ///
  /// In es, this message translates to:
  /// **'Inicia sesión con tu cuenta institucional para solicitar anuncios de la universidad, registrar tus dispositivos y acceder a todas las funciones del sistema.'**
  String get guestMessage;

  /// No description provided for @offlineBanner.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión — mostrando datos guardados'**
  String get offlineBanner;

  /// No description provided for @logout.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get logout;

  /// No description provided for @notifications.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones'**
  String get notifications;

  /// No description provided for @loginAction.
  ///
  /// In es, this message translates to:
  /// **'Iniciar Sesión'**
  String get loginAction;

  /// No description provided for @markAllRead.
  ///
  /// In es, this message translates to:
  /// **'Marcar todo leído'**
  String get markAllRead;

  /// No description provided for @noNotifications.
  ///
  /// In es, this message translates to:
  /// **'Sin notificaciones'**
  String get noNotifications;

  /// No description provided for @noNotificationsDesc.
  ///
  /// In es, this message translates to:
  /// **'Aquí verás los últimos eventos y anuncios publicados.'**
  String get noNotificationsDesc;

  /// No description provided for @notificationSectionImportant.
  ///
  /// In es, this message translates to:
  /// **'IMPORTANTE'**
  String get notificationSectionImportant;

  /// No description provided for @notificationSectionRecent.
  ///
  /// In es, this message translates to:
  /// **'NUEVOS Y RECIENTES'**
  String get notificationSectionRecent;

  /// No description provided for @loadingError.
  ///
  /// In es, this message translates to:
  /// **'Error de carga'**
  String get loadingError;

  /// No description provided for @announcementBadge.
  ///
  /// In es, this message translates to:
  /// **'Anuncio'**
  String get announcementBadge;

  /// No description provided for @featuredEvents.
  ///
  /// In es, this message translates to:
  /// **'EVENTOS DESTACADOS'**
  String get featuredEvents;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
