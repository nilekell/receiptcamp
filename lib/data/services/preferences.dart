import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {

  PreferencesService._getInstance();
  static final PreferencesService _instance = PreferencesService._getInstance();
  static PreferencesService get instance => _instance;

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    // setting default values for the first time app is ever opened
    if (_prefs!.containsKey('lastOrder') == false) await saveString('lastOrder', 'ASC');
    if (_prefs!.containsKey('lastColumn') == false) await saveString('lastColumn', 'name');
    if (_prefs!.containsKey('isFirstAppOpen') == false) await saveBool('IsFirstAppOpen', true);
  }

  String getLastOrder() {
    return _prefs?.getString('lastOrder') ?? 'ASC';
  }
  String getLastColumn() {
    return _prefs?.getString('lastColumn') ?? 'name';
  }

  Future<void> setLastOrder(String order) async {
    await _prefs?.setString('lastOrder', order);
  }

  Future<void> setLastColumn(String column) async {
    await _prefs?.setString('lastColumn', column);
  }

  bool getIsFirstAppOpen() {
    return _prefs?.getBool('IsFirstAppOpen') ?? true;
  }

  Future<void> setIsFirstAppOpen(bool value) async {
    await _prefs?.setBool('IsFirstAppOpen', value);
  }

  // Asynchronous methods to save various types of values
  Future<void> saveInt(String key, int value) async {
    await _prefs?.setInt(key, value);
  }

  Future<void> saveBool(String key, bool value) async {
    await _prefs?.setBool(key, value);
  }

  Future<void> saveDouble(String key, double value) async {
    await _prefs?.setDouble(key, value);
  }

  Future<void> saveString(String key, String value) async {
    await _prefs?.setString(key, value);
  }

  Future<void> saveStringList(String key, List<String> value) async {
    await _prefs?.setStringList(key, value);
  }

  // Synchronous methods to read various types of values
  int? getInt(String key) {
    return _prefs?.getInt(key);
  }

  bool? getBool(String key) {
    return _prefs?.getBool(key);
  }

  double? getDouble(String key) {
    return _prefs?.getDouble(key);
  }

  String? getString(String key) {
    return _prefs?.getString(key);
  }

  List<String>? getStringList(String key) {
    return _prefs?.getStringList(key);
  }
}
