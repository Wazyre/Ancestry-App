import 'package:ancestry_app/src/ui/base/dropdown_search_widget.dart';
import 'package:ancestry_app/src/ui/base/settings_provider.dart';
import 'package:ancestry_app/src/ui/base/theme_provider.dart';
import 'package:ancestry_app/src/ui/mainMenu/db_services.dart';
import 'package:ancestry_app/src/ui/mainMenu/family_main_screen.dart';
import 'package:ancestry_app/src/ui/mainMenu/login_admin_screen.dart';
import 'package:ancestry_app/src/ui/mainMenu/options_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'l10n/app_localizations.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://wjzgojwsbdgttjxjnezm.supabase.co',
    anonKey: 'sb_publishable_XzWAtqjOsFNkboYoSR2GaA_M0vdvGTl',
  );

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
            title: 'شجرة العائلة',
            theme: ThemeData(colorScheme: themeProvider.lightScheme),
            darkTheme: ThemeData(colorScheme: themeProvider.darkScheme),
            themeMode:  themeMode == '' ? ThemeMode.system : themeMode == 'dark' ? ThemeMode.dark : ThemeMode.light,
            home: const SplashScreen(),
            locale: settings.savedSettings.locale == 'ar' ? Locale('ar', 'KW') : Locale('en', 'US'),
            debugShowCheckedModeBanner: false,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) {
              final systemScale = MediaQuery.of(context).textScaler.scale(1.0);
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(systemScale * settings.savedSettings.textScale),
                ),
                child: child!,
              );
            },
          );
    });
  }
}

// ─── Splash Screen ────────────────────────────────────────────────────────────

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashState();
}

class _SplashState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();

    Future.wait([
      DbServices.instance.getFamilyTableNames(),
      Future<void>.delayed(const Duration(milliseconds: 1800)),
    ]).then((results) {
      final familyNames = results[0] as List<String>;
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => IntroScreen(familyNames: familyNames),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'شجرة العائلة',
                style: TextStyle(
                  fontFamily: 'ArefRuqaa',
                  fontSize: 56,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Family Tree',
                style: TextStyle(
                  fontSize: 13,
                  letterSpacing: 3,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 64),
              CircularProgressIndicator(color: colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Intro Screen ─────────────────────────────────────────────────────────────

class IntroScreen extends StatefulWidget {
  final List<String> familyNames;
  const IntroScreen({super.key, required this.familyNames});

  @override
  State<IntroScreen> createState() => _IntroState();
}

class _IntroState extends State<IntroScreen> with SingleTickerProviderStateMixin {
  bool _pressedLangBtn = true;
  String? _selectedFamily;
  late List<String> _familyNames;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();

    _familyNames = widget.familyNames;

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      final theme = Provider.of<ThemeProvider>(context, listen: false);
      final settings = Provider.of<SettingsProvider>(context, listen: false);
      setState(() {
        settings.setThemeMode(theme.getCurrentThemeMode(context));
        _pressedLangBtn = settings.savedSettings.locale == 'ar';
      });
      _animCtrl.forward();
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: AppBar(
            leading: TextButton(
              child: Text(_pressedLangBtn ? 'عر' : 'EN', style: theme.bodyNormal),
              onPressed: () {
                setState(() {
                  _pressedLangBtn = !_pressedLangBtn;
                  settings.setLocale(_pressedLangBtn ? 'ar' : 'en');
                });
              },
            ),
            actions: [
              IconButton(
                icon: settings.savedSettings.themeMode == 'dark'
                    ? const Icon(Icons.wb_sunny_outlined)
                    : const Icon(Icons.wb_sunny),
                tooltip: 'Change theme mode',
                onPressed: settings.flipThemeMode,
              ),
              IconButton(
                icon: Hero(
                  tag: 'hero-settings-icon',
                  child: const Icon(Icons.settings),
                ),
                tooltip: 'Open settings',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => OptionsScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'شجرة العائلة',
                    style: TextStyle(
                      fontFamily: 'ArefRuqaa',
                      fontSize: 52,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Family Tree',
                    style: TextStyle(
                      fontSize: 13,
                      letterSpacing: 3,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Card(
                    elevation: 0,
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          DropdownSearchWidget(
                            itemValueBuilder: (filter, cs) => _familyNames,
                            popupItemBuilder: (context, item, isDisabled, isSelected) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12.0, horizontal: 16.0),
                                child: Text(item, textAlign: TextAlign.center),
                              );
                            },
                            context: context,
                            label: Text(
                              AppLocalizations.of(context)!.selectFamily,
                              style: TextStyle(color: colorScheme.primary),
                            ),
                            onChangedFn: (value) {
                              setState(() {
                                _selectedFamily = value!;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return AppLocalizations.of(context)!
                                    .selectFamilyValidateErr;
                              }
                              return null;
                            },
                            baseStyle: TextStyle(color: colorScheme.primary),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: () {
                                if (_selectedFamily != null) {
                                  settings.setTabFamily(_selectedFamily!);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => FamilyMainScreen()),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        AppLocalizations.of(context)!
                                            .selectFamilyValidateErr,
                                      ),
                                    ),
                                  );
                                }
                              },
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(AppLocalizations.of(context)!.enterFamily),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => LoginAdminScreen()),
                      );
                    },
                    icon: const Icon(Icons.admin_panel_settings_outlined),
                    label: Text(
                      AppLocalizations.of(context)!.adminButton,
                      style: theme.bodyNormal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}