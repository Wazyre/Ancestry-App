import 'package:ancestry_app/src/ui/base/dropdown_search_widget.dart';
import 'package:ancestry_app/src/ui/base/settings_provider.dart';
import 'package:ancestry_app/src/ui/base/theme_provider.dart';
import 'package:ancestry_app/src/ui/mainMenu/admin_screen.dart';
import 'package:ancestry_app/src/ui/mainMenu/family_main_screen.dart';
import 'package:ancestry_app/src/ui/mainMenu/login_admin_screen.dart';
import 'package:ancestry_app/src/ui/mainMenu/options_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

// TODO define fonts, weights, and sizes while matching accessibility settings

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SharedPreferences prefs = await SharedPreferences.getInstance();

  runApp(
    MultiProvider(providers: [
      ChangeNotifierProvider(create: (context) => ThemeProvider()),
      ChangeNotifierProvider(create: (context) => SettingsProvider(prefs: prefs))
    ],
    child: const FamilyTreeApp()
    )
  );
}

class FamilyTreeApp extends StatelessWidget {
  const FamilyTreeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, SettingsProvider>(builder: (context, themeProvider, settings, child) {
      String themeMode = settings.savedSettings.themeMode;
      return MaterialApp(
            title: 'Family Tree',
            theme: ThemeData(colorScheme: themeProvider.lightScheme),
            darkTheme: ThemeData(colorScheme: themeProvider.darkScheme),
            themeMode:  themeMode == '' ? ThemeMode.system : themeMode == 'dark' ? ThemeMode.dark : ThemeMode.light,
            home: IntroScreen(),
            locale: settings.savedSettings.locale == 'ar' ? Locale('ar', 'KW') : Locale('en', 'US'),
            debugShowCheckedModeBanner: false,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          );
    });
  }
}

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroState();
}

class _IntroState extends State<IntroScreen> {
  // Future<Database> db = DbServices.instance.database;
  // Future<List<Family>> sf = DbServices.instance.storedFamily;
  
  
  // void tryDB() async {
  //   DbServices db = DbServices.instance;
  //   await db.ps();
  //   // print(family);
  // }
  bool _pressedLangBtn = true;
  String? _selectedFamily;
  // final _selectFamilyKey = GlobalKey<FormState>();
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      final theme = Provider.of<ThemeProvider>(context, listen: false);
      final settings = Provider.of<SettingsProvider>(context, listen: false);
      setState(() {
        settings.setThemeMode(theme.getCurrentThemeMode(context));
        _pressedLangBtn = settings.savedSettings.locale == 'ar';
      });
    });
    
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);
      
    return Scaffold(
      appBar: AppBar(
        leading: TextButton(
          style: ButtonStyle(
            
          ),
          child: Text(_pressedLangBtn ? 'عر' : 'EN', style: theme.bodyNormal), 
          onPressed: () {
            setState(() {
              _pressedLangBtn = !_pressedLangBtn;
              settings.setLocale(_pressedLangBtn ? 'ar' : 'en');
            });
          }),
        actions: [
          IconButton(
            icon: settings.savedSettings.themeMode == 'dark' ? Icon(Icons.wb_sunny_outlined) : Icon(Icons.wb_sunny), 
            tooltip: 'Change theme mode',
            onPressed: () {
              settings.flipThemeMode();
            }
          ),
          IconButton(
            icon: Hero(
              tag: 'hero-settings-icon', 
              child: RotatedBox(
                quarterTurns: 0, 
                child: Icon(Icons.settings),
              )
            ),
            tooltip: 'Open settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => OptionsScreen()),
              );
            },
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Logo',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: DropdownSearchWidget(
                // TODO grab table family names properly
                itemValueBuilder: (filter, cs) => ['العبدالجليل', 'العبدالجليل', 'العبدالجليل'], 
                popupItemBuilder: (context, item, isDisabled, isSelected) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: Text(
                        item,
                        textAlign: TextAlign.center,
                      ),
                    );
                  }, 
                context: context, 
                label: Text(AppLocalizations.of(context)!.selectFamily,
                      style: TextStyle(color: theme.getCurrentScheme(context).colorScheme.primary)), //TODO font size
                onChangedFn: (value) {
                  setState(() {
                    _selectedFamily = value!;
                  });
                }, 
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppLocalizations.of(context)!.selectFamilyValidateErr;
                  }
                  return null;
                },
                baseStyle: TextStyle(color: theme.getCurrentScheme(context).colorScheme.primary), //TODO font size
              )
              // child: DropdownSearch<String>(
              //   key: _selectFamilyKey,
               
              //   items: (filter, cs) => ['العبدالجليل', 'العبدالجليل', 'العبدالجليل'],
              //   suffixProps: DropdownSuffixProps(
              //     dropdownButtonProps: DropdownButtonProps(
              //       iconClosed: Icon(Icons.keyboard_arrow_down),
              //       iconOpened: Icon(Icons.keyboard_arrow_up))),
              //   decoratorProps: DropDownDecoratorProps(
              //     baseStyle: TextStyle(color: theme.getCurrentScheme(context).colorScheme.primary),
              //     decoration: InputDecoration(
              //       floatingLabelBehavior: FloatingLabelBehavior.auto,
              //       labelText: AppLocalizations.of(context)!.selectFamily,
              //       labelStyle: TextStyle(color: theme.getCurrentScheme(context).colorScheme.primary),
              //       border: OutlineInputBorder(
              //         borderSide: BorderSide(color: Colors.transparent),
              //         borderRadius: BorderRadius.circular(12),
              //       ),
              //       focusedBorder: OutlineInputBorder(
              //         borderSide: BorderSide(),
              //         borderRadius: BorderRadius.circular(12),
              //       ),
              //       enabledBorder: OutlineInputBorder(
              //         borderSide: BorderSide(color: Colors.transparent),
              //         borderRadius: BorderRadius.circular(12),
              //       ),
              //       filled: true,
              //       fillColor: Colors.white,
              //       // hintText: 'Please choose family...'
              //     )
              //   ),
              //   popupProps: PopupProps.menu(
              //     itemBuilder: (context, item, isDisabled, isSelected) {
              //       return Padding(
              //         padding: const EdgeInsets.symmetric(vertical: 12.0),
              //         child: Text(
              //           item,
              //           textAlign: TextAlign.center,
              //         ),
              //       );
              //     },
              //     showSearchBox: true,
              //     searchFieldProps: TextFieldProps(
              //       decoration: InputDecoration(
              //         icon: Icon(Icons.search)
              //       )
              //     ),
              //     constraints: BoxConstraints(maxHeight: 260),
              //     menuProps: MenuProps(
              //       margin: EdgeInsets.only(top: 12),
              //       shape: const RoundedRectangleBorder(
              //           borderRadius: BorderRadius.all(Radius.circular(12))),
              //     ),
              //   ),
              //   // validator: (value) {
              //   //   if 
              //   // },
              //   onChanged: (value) {
              //     setState(() {
              //       _selectedFamily = value!;
              //     });
              //   },
              //   validator: (value) {
              //     if (value == null || value.isEmpty) {
              //       return AppLocalizations.of(context)!.selectValidateErr;
              //     }
              //     return null;
              //   },
              // ),
            ),
            ElevatedButton(
              onPressed: () {
                if (_selectedFamily != null) {
                  settings.setTabFamily(_selectedFamily! );
                  // Navigate to main app screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => FamilyMainScreen()),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(AppLocalizations.of(context)!.selectFamilyValidateErr,
                          style: theme.bodyNormal)));
                }
                
              },
              child: Text(AppLocalizations.of(context)!.enterFamily),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Navigate to admin screen
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AdminScreen()), //TODO fix to login after debugging
                );
              },
              child: Text(AppLocalizations.of(context)!.adminButton,
                  style: theme.bodyNormal),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}