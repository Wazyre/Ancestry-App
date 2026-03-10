import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {

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

  ColorScheme get darkScheme => _darkScheme;
  ColorScheme get lightScheme => _lightScheme;

  double get fontSizeBody => _fontSizeBody;

  TextStyle get bodyBold => _bodyBold;
  TextStyle get bodyNormal => _bodyNormal;
  TextStyle treeNode(Color onNodeColor) =>
      TextStyle(color: onNodeColor, fontSize: 18.0, fontWeight: FontWeight.w700);
  
  ThemeData getCurrentScheme(BuildContext context) {
    if (Theme.of(context).brightness == Brightness.light) {
      return ThemeData(colorScheme: _lightScheme);
    }
    else {
      return ThemeData(colorScheme: _darkScheme);
    }
  }

  String getCurrentThemeMode(BuildContext context) {
    if (Theme.of(context).brightness == Brightness.light) {
      return 'light';
    } else {
      return 'dark';
    }
  }
}