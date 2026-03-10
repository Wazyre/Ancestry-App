import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SavedSettings {
  bool maleOnly;
  int nameLength;
  String locale;
  String tabFamily;
  String themeMode;
  double textScale;

  SavedSettings({
    required this.maleOnly,
    required this.nameLength,
    required this.locale,
    required this.tabFamily,
    required this.themeMode,
    required this.textScale,
  });
}

class SettingsProvider with ChangeNotifier {

  final SharedPreferences prefs;
  SavedSettings savedSettings = SavedSettings(
      maleOnly: false, nameLength: -1, locale: '', tabFamily: '', themeMode: '', textScale: 1.0
    );

  SettingsProvider({required this.prefs}) {
    _getAllPrefItems();
  }

  // void _setPrefItems(String key, value) {
  //   prefs.setString(key, value);
  // } 

  void setMaleOnly(bool value) {
    prefs.setBool('maleOnly', value);
    savedSettings.maleOnly = value;
    notifyListeners();
  }

  void setNameLength(int value) {
    prefs.setInt('nameLength', value);
    savedSettings.nameLength = value;
    notifyListeners();
  }

  void setLocale(String value) {
    prefs.setString('locale', value);
    savedSettings.locale = value;
    notifyListeners();
  }

  void setTabFamily(String value) {
    prefs.setString('tabFamily', value);
    savedSettings.tabFamily = value;
    notifyListeners();
  }

  void setThemeMode(String value) {
    prefs.setString('themeMode', value);
    savedSettings.themeMode = value;
    notifyListeners();
  }

  void setTextScale(double value) {
    prefs.setDouble('textScale', value);
    savedSettings.textScale = value;
    notifyListeners();
  }

  void flipThemeMode() {
    if (savedSettings.themeMode == 'dark') {
      prefs.setString('themeMode', 'light');
      savedSettings.themeMode = 'light';
    }
    else {
      prefs.setString('themeMode', 'dark');
      savedSettings.themeMode = 'dark';
    }
    
    notifyListeners();
  }

  void _getAllPrefItems() {
    savedSettings.maleOnly = prefs.getBool('maleOnly') ?? false;
    savedSettings.nameLength = prefs.getInt('nameLength') ?? 3;
    savedSettings.themeMode = prefs.getString('themeMode') ?? '';
    savedSettings.locale = prefs.getString('locale') ?? 'ar';
    savedSettings.tabFamily = prefs.getString('tabFamily') ?? '';
    savedSettings.textScale = prefs.getDouble('textScale') ?? 1.0;
  }

  Object? getPrefItem(String key) {
    return prefs.get(key);
  }
}