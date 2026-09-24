import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_es.dart';
import 'app_localizations_eu.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('es'),
    Locale('eu'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In es, this message translates to:
  /// **'Portal de Servicios'**
  String get appTitle;

  /// No description provided for @labLogin.
  ///
  /// In es, this message translates to:
  /// **'Sesión de laboratorio'**
  String get labLogin;

  /// No description provided for @labNotice.
  ///
  /// In es, this message translates to:
  /// **'Datos ficticios. Estas cuentas no son autenticación de producción.'**
  String get labNotice;

  /// No description provided for @loginAna.
  ///
  /// In es, this message translates to:
  /// **'Entrar como Ana'**
  String get loginAna;

  /// No description provided for @loginBruno.
  ///
  /// In es, this message translates to:
  /// **'Entrar como Bruno'**
  String get loginBruno;

  /// No description provided for @requests.
  ///
  /// In es, this message translates to:
  /// **'Solicitudes'**
  String get requests;

  /// No description provided for @settings.
  ///
  /// In es, this message translates to:
  /// **'Ajustes'**
  String get settings;

  /// No description provided for @logout.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get logout;

  /// No description provided for @search.
  ///
  /// In es, this message translates to:
  /// **'Buscar por título'**
  String get search;

  /// No description provided for @all.
  ///
  /// In es, this message translates to:
  /// **'Todos los estados'**
  String get all;

  /// No description provided for @open.
  ///
  /// In es, this message translates to:
  /// **'Abierta'**
  String get open;

  /// No description provided for @inProgress.
  ///
  /// In es, this message translates to:
  /// **'En curso'**
  String get inProgress;

  /// No description provided for @closed.
  ///
  /// In es, this message translates to:
  /// **'Cerrada'**
  String get closed;

  /// No description provided for @unknown.
  ///
  /// In es, this message translates to:
  /// **'Estado no disponible'**
  String get unknown;

  /// No description provided for @empty.
  ///
  /// In es, this message translates to:
  /// **'No hay solicitudes para este filtro'**
  String get empty;

  /// No description provided for @retry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get retry;

  /// No description provided for @refresh.
  ///
  /// In es, this message translates to:
  /// **'Actualizar'**
  String get refresh;

  /// No description provided for @more.
  ///
  /// In es, this message translates to:
  /// **'Cargar más'**
  String get more;

  /// No description provided for @newRequest.
  ///
  /// In es, this message translates to:
  /// **'Nueva solicitud'**
  String get newRequest;

  /// No description provided for @titleLabel.
  ///
  /// In es, this message translates to:
  /// **'Título'**
  String get titleLabel;

  /// No description provided for @reasonLabel.
  ///
  /// In es, this message translates to:
  /// **'Motivo'**
  String get reasonLabel;

  /// No description provided for @requiredField.
  ///
  /// In es, this message translates to:
  /// **'Completa este campo'**
  String get requiredField;

  /// No description provided for @titleLength.
  ///
  /// In es, this message translates to:
  /// **'El título debe tener entre 3 y 80 caracteres'**
  String get titleLength;

  /// No description provided for @reasonLength.
  ///
  /// In es, this message translates to:
  /// **'El motivo debe tener entre 5 y 500 caracteres'**
  String get reasonLength;

  /// No description provided for @save.
  ///
  /// In es, this message translates to:
  /// **'Enviar solicitud'**
  String get save;

  /// No description provided for @sending.
  ///
  /// In es, this message translates to:
  /// **'Enviando solicitud'**
  String get sending;

  /// No description provided for @draftRestored.
  ///
  /// In es, this message translates to:
  /// **'Borrador recuperado'**
  String get draftRestored;

  /// No description provided for @draftError.
  ///
  /// In es, this message translates to:
  /// **'No se ha podido guardar el borrador'**
  String get draftError;

  /// No description provided for @genericError.
  ///
  /// In es, this message translates to:
  /// **'No se ha podido completar la operación'**
  String get genericError;

  /// No description provided for @notFound.
  ///
  /// In es, this message translates to:
  /// **'La solicitud no está disponible'**
  String get notFound;

  /// No description provided for @forbidden.
  ///
  /// In es, this message translates to:
  /// **'No tienes acceso a esta solicitud'**
  String get forbidden;

  /// No description provided for @expired.
  ///
  /// In es, this message translates to:
  /// **'La sesión ha caducado. Vuelve a iniciar sesión'**
  String get expired;

  /// No description provided for @validationError.
  ///
  /// In es, this message translates to:
  /// **'Revisa los campos indicados'**
  String get validationError;

  /// No description provided for @conflict.
  ///
  /// In es, this message translates to:
  /// **'La solicitud ha cambiado. Consulta su versión actual'**
  String get conflict;

  /// No description provided for @unknownResult.
  ///
  /// In es, this message translates to:
  /// **'No sabemos si se confirmó. Reintenta la misma operación antes de modificar los datos'**
  String get unknownResult;

  /// No description provided for @language.
  ///
  /// In es, this message translates to:
  /// **'Idioma'**
  String get language;

  /// No description provided for @systemLanguage.
  ///
  /// In es, this message translates to:
  /// **'Idioma del sistema'**
  String get systemLanguage;

  /// No description provided for @backToList.
  ///
  /// In es, this message translates to:
  /// **'Volver al listado'**
  String get backToList;

  /// No description provided for @requestVersion.
  ///
  /// In es, this message translates to:
  /// **'Versión {version}'**
  String requestVersion(int version);

  /// No description provided for @loadedCount.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =0{Ninguna solicitud cargada} =1{Una solicitud cargada} other{{count} solicitudes cargadas}}'**
  String loadedCount(int count);
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
      <String>['es', 'eu'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'es':
      return AppLocalizationsEs();
    case 'eu':
      return AppLocalizationsEu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
