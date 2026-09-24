// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Portal de Servicios';

  @override
  String get labLogin => 'Sesión de laboratorio';

  @override
  String get labNotice =>
      'Datos ficticios. Estas cuentas no son autenticación de producción.';

  @override
  String get loginAna => 'Entrar como Ana';

  @override
  String get loginBruno => 'Entrar como Bruno';

  @override
  String get requests => 'Solicitudes';

  @override
  String get settings => 'Ajustes';

  @override
  String get logout => 'Cerrar sesión';

  @override
  String get search => 'Buscar por título';

  @override
  String get all => 'Todos los estados';

  @override
  String get open => 'Abierta';

  @override
  String get inProgress => 'En curso';

  @override
  String get closed => 'Cerrada';

  @override
  String get unknown => 'Estado no disponible';

  @override
  String get empty => 'No hay solicitudes para este filtro';

  @override
  String get retry => 'Reintentar';

  @override
  String get refresh => 'Actualizar';

  @override
  String get more => 'Cargar más';

  @override
  String get newRequest => 'Nueva solicitud';

  @override
  String get titleLabel => 'Título';

  @override
  String get reasonLabel => 'Motivo';

  @override
  String get requiredField => 'Completa este campo';

  @override
  String get titleLength => 'El título debe tener entre 3 y 80 caracteres';

  @override
  String get reasonLength => 'El motivo debe tener entre 5 y 500 caracteres';

  @override
  String get save => 'Enviar solicitud';

  @override
  String get sending => 'Enviando solicitud';

  @override
  String get draftRestored => 'Borrador recuperado';

  @override
  String get draftError => 'No se ha podido guardar el borrador';

  @override
  String get genericError => 'No se ha podido completar la operación';

  @override
  String get notFound => 'La solicitud no está disponible';

  @override
  String get forbidden => 'No tienes acceso a esta solicitud';

  @override
  String get expired => 'La sesión ha caducado. Vuelve a iniciar sesión';

  @override
  String get validationError => 'Revisa los campos indicados';

  @override
  String get conflict => 'La solicitud ha cambiado. Consulta su versión actual';

  @override
  String get unknownResult =>
      'No sabemos si se confirmó. Reintenta la misma operación antes de modificar los datos';

  @override
  String get language => 'Idioma';

  @override
  String get systemLanguage => 'Idioma del sistema';

  @override
  String get backToList => 'Volver al listado';

  @override
  String requestVersion(int version) {
    return 'Versión $version';
  }

  @override
  String loadedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count solicitudes cargadas',
      one: 'Una solicitud cargada',
      zero: 'Ninguna solicitud cargada',
    );
    return '$_temp0';
  }
}
