// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Basque (`eu`).
class AppLocalizationsEu extends AppLocalizations {
  AppLocalizationsEu([String locale = 'eu']) : super(locale);

  @override
  String get appTitle => 'Zerbitzuen ataria';

  @override
  String get labLogin => 'Laborategiko saioa';

  @override
  String get labNotice =>
      'Fikziozko datuak. Kontu hauek ez dira produkzioko autentifikazioa.';

  @override
  String get loginAna => 'Ana gisa sartu';

  @override
  String get loginBruno => 'Bruno gisa sartu';

  @override
  String get requests => 'Eskaerak';

  @override
  String get settings => 'Ezarpenak';

  @override
  String get logout => 'Saioa amaitu';

  @override
  String get search => 'Izenburuaren arabera bilatu';

  @override
  String get all => 'Egoera guztiak';

  @override
  String get open => 'Irekita';

  @override
  String get inProgress => 'Abian';

  @override
  String get closed => 'Itxita';

  @override
  String get unknown => 'Egoera ez dago erabilgarri';

  @override
  String get empty => 'Ez dago eskaerarik iragazki honetarako';

  @override
  String get retry => 'Berriro saiatu';

  @override
  String get refresh => 'Eguneratu';

  @override
  String get more => 'Gehiago kargatu';

  @override
  String get newRequest => 'Eskaera berria';

  @override
  String get titleLabel => 'Izenburua';

  @override
  String get reasonLabel => 'Arrazoia';

  @override
  String get requiredField => 'Bete eremu hau';

  @override
  String get titleLength =>
      'Izenburuak 3 eta 80 karaktere artean izan behar ditu';

  @override
  String get reasonLength =>
      'Arrazoiak 5 eta 500 karaktere artean izan behar ditu';

  @override
  String get save => 'Eskaera bidali';

  @override
  String get sending => 'Eskaera bidaltzen';

  @override
  String get draftRestored => 'Zirriborroa berreskuratu da';

  @override
  String get draftError => 'Ezin izan da zirriborroa gorde';

  @override
  String get genericError => 'Ezin izan da eragiketa osatu';

  @override
  String get notFound => 'Eskaera ez dago erabilgarri';

  @override
  String get forbidden => 'Ez duzu eskaera hau ikusteko baimenik';

  @override
  String get expired => 'Saioa iraungi da. Hasi saioa berriro';

  @override
  String get validationError => 'Berrikusi adierazitako eremuak';

  @override
  String get conflict => 'Eskaera aldatu da. Kontsultatu uneko bertsioa';

  @override
  String get unknownResult =>
      'Ez dakigu baieztatu den. Saiatu eragiketa berarekin datuak aldatu aurretik';

  @override
  String get language => 'Hizkuntza';

  @override
  String get systemLanguage => 'Sistemaren hizkuntza';

  @override
  String get backToList => 'Zerrendara itzuli';

  @override
  String requestVersion(int version) {
    return '$version. bertsioa';
  }

  @override
  String loadedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count eskaera kargatu dira',
      one: 'Eskaera bat kargatu da',
      zero: 'Ez dago kargatutako eskaerarik',
    );
    return '$_temp0';
  }
}
