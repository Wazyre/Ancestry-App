
import 'package:ancestry_app/src/ui/base/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
    
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.optionsTitle),
        actions: [
          // Hero(
          //   tag: 'hero-settings-icon', 
          //   child: RotatedBox(
          //     quarterTurns: 0, 
          //     child: Padding(
          //       padding: const EdgeInsets.symmetric(horizontal: 11.0),
          //       child: Icon(Icons.settings),
          //     ),
          //   )
          // )
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(AppLocalizations.of(context)!.optNameLengthLabel),
          ),
          
               RadioListTile(
                  title: Text(AppLocalizations.of(context)!.nameLengthThree),
                  value: 3, 
                  groupValue: nameLength, 
                  onChanged: (int? value) {
                    settings.setNameLength(value!);
                    setState(() {
                      nameLength = value;
                    });
                  }
                ),
              
               RadioListTile(
                  title: Text(AppLocalizations.of(context)!.nameLengthFour),
                  value: 4,
                  groupValue: nameLength,
                  onChanged: (int? value) {
                    settings.setNameLength(value!);
                    setState(() {
                      nameLength = value;
                    });
                  }
                ),
              
                RadioListTile(
                  title: Text(AppLocalizations.of(context)!.nameLengthFive),
                  value: 5,
                  groupValue: nameLength,
                  onChanged: (int? value) {
                    settings.setNameLength(value!);
                    setState(() {
                      nameLength = value;
                    });
                  }
                ),
          Row(
            children: [
              Expanded(
                child: CheckboxListTile(
                  title: Text(AppLocalizations.of(context)!.optMalesOnlyLabel),
                  value: maleOnly, 
                  onChanged: (bool? value) {
                    settings.setMaleOnly(value!);
                    setState(() {
                      maleOnly = !maleOnly;
                    });
                  }
                ),
              )
            ],
          )
        ],
      ),
    );
  }
}