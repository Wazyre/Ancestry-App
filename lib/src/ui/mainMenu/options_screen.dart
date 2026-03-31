import 'package:ancestry_app/src/ui/base/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ancestry_app/l10n/app_localizations.dart';

class OptionsScreen extends StatefulWidget {
  const OptionsScreen({super.key});

  @override
  State<OptionsScreen> createState() => _OptionsState();
}

class _OptionsState extends State<OptionsScreen> {

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    int nameLength = settings.savedSettings.nameLength;
    bool maleOnly = settings.savedSettings.maleOnly;
    double textScale = settings.savedSettings.textScale;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.optionsTitle),
        actions: [
          Hero(
            tag: 'hero-settings-icon',
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 11.0),
              child: Icon(Icons.settings, color: colorScheme.onSurface),
            ),
          ),
        ],
      ),
      body: ListView(
        children: [
          _SectionHeader(title: AppLocalizations.of(context)!.optNameLengthLabel),
          _SettingsCard(
            child: RadioGroup<int>(
              groupValue: nameLength,
              onChanged: (value) {
                if (value != null) {
                  settings.setNameLength(value);
                  setState(() { nameLength = value; });
                }
              },
              child: Column(
                children: [
                  RadioListTile(title: Text(AppLocalizations.of(context)!.nameLengthThree), value: 3),
                  RadioListTile(title: Text(AppLocalizations.of(context)!.nameLengthFour), value: 4),
                  RadioListTile(title: Text(AppLocalizations.of(context)!.nameLengthFive), value: 5),
                ],
              ),
            ),
          ),

          _SectionHeader(title: AppLocalizations.of(context)!.optTextSizeLabel),
          _SettingsCard(
            child: RadioGroup<double>(
              groupValue: textScale,
              onChanged: (value) {
                if (value != null) {
                  settings.setTextScale(value);
                  setState(() { textScale = value; });
                }
              },
              child: Column(
                children: [
                  RadioListTile(title: Text(AppLocalizations.of(context)!.textSizeSystem), value: 1.0),
                  RadioListTile(title: Text(AppLocalizations.of(context)!.textSizeLarge), value: 1.2),
                  RadioListTile(title: Text(AppLocalizations.of(context)!.textSizeXLarge), value: 1.4),
                ],
              ),
            ),
          ),

          _SectionHeader(title: AppLocalizations.of(context)!.extraSettings),
          _SettingsCard(
            child: CheckboxListTile(
              title: Text(AppLocalizations.of(context)!.optMalesOnlyLabel),
              value: maleOnly,
              onChanged: (bool? value) {
                settings.setMaleOnly(value!);
                setState(() { maleOnly = !maleOnly; });
              },
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: 'Monadi',
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: colorScheme.primary,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final Widget child;
  const _SettingsCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: child,
    );
  }
}