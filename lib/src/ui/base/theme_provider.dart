import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {

  // ThemeProvider() {
  //   getThemeAtInit();
  // }

  // getThemeAtInit() async {
  //   SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
  //   // TODO currently thememode is a string in settings provider
  //   String? isDarkTheme = sharedPreferences.getString('themeMode');
  //   if (isDarkTheme != null) {
  //     _themeMode = ThemeMode.dark;
  //   }
  //   else {
  //     _themeMode = ThemeMode.light;
  //   }
  // }

  // // TODO remove unnecessary _themeMode
  // String _themeMode = '';
  final ColorScheme _lightScheme = ColorScheme.fromSeed(
            brightness: Brightness.light,
            seedColor: Colors.amber,
          );
  final ColorScheme _darkScheme = ColorScheme.fromSeed(
          brightness: Brightness.dark,
          seedColor: Colors.amber,
        );

  final double _fontSizeBody = 14.0; 
  final TextStyle _bodyBold = TextStyle(fontSize: 14.0, fontWeight: FontWeight.w700);
  final TextStyle _bodyNormal = TextStyle(fontSize: 14.0);

  // String get themeMode => _themeMode;
  // void setThemeMode(String value) {
  //   _themeMode = value;
  //   notifyListeners();
  // }

  ColorScheme get darkScheme => _darkScheme;
  ColorScheme get lightScheme => _lightScheme;

  double get fontSizeBody => _fontSizeBody;

  TextStyle get bodyBold => _bodyBold;
  TextStyle get bodyNormal => _bodyNormal;
  
  ThemeData getCurrentScheme(context) {
    if (Theme.of(context).brightness == Brightness.light) {
      return ThemeData(colorScheme: _lightScheme);
    }
    else {
      return ThemeData(colorScheme: _darkScheme);
    }
  }

  String getCurrentThemeMode(context) {
    if (Theme.of(context).brightness == Brightness.light) {
      return 'light';
    } else {
      return 'dark';
    }
  }
}