import 'package:ancestry_app/src/ui/base/dropdown_avatar_family.dart';
// import 'package:ancestry_app/src/ui/base/dropdown_search_widget.dart';
import 'package:ancestry_app/src/ui/base/settings_provider.dart';
import 'package:ancestry_app/src/ui/base/theme_provider.dart';
// import 'package:ancestry_app/src/ui/mainMenu/family_paint_screen.dart';
import 'package:ancestry_app/src/ui/mainMenu/family_tree_screen.dart';
import 'package:ancestry_app/src/ui/mainMenu/find_relation_screen.dart';
import 'package:ancestry_app/src/ui/mainMenu/profile_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import 'db_services.dart';

class FamilyMainScreen extends StatefulWidget {
  const FamilyMainScreen({super.key});


  @override
  State<FamilyMainScreen> createState() => _FamilyMainState();
}

class _FamilyMainState extends State<FamilyMainScreen> {

  List<Family>? _familyList;
  Family? _selectedPerson; 
  final double _bigSpacing = 16.0;
  // String? _familyName;

  // @override
  // void initState() {
  //   super.initState();
  //   setState(() {
  //     _familyName = widget.familyName;
  //   });
  // }
  
  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);
    final familyName = settings.savedSettings.tabFamily;
    final maleOnly = settings.savedSettings.maleOnly;

    return FutureBuilder(future: grabFamily(familyName, maleOnly), 
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
              ],
            ),
          ),
        ); 
      }
      else {
        return Scaffold(
          appBar: AppBar(
            title: Text(familyName),
            centerTitle: true,
          ),
          body: Column(
            children: [
              Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text('نبذة عن العائلة', //TODO figure out where to get bio from
                            style: theme.bodyNormal),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: DropdownAvatarFamily(
                  // context: context, 
                  familyList: _familyList!, 
                  onChangedFn: ((CircleAvatar, Family)? value) {
                    setState(() {
                      _selectedPerson = value!.$2;
                    });
                  },
                )
              ),
               
              SizedBox(height: _bigSpacing),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: _bigSpacing,
                children: [
                  OutlinedButton(
                    onPressed: () {
                      if (_selectedPerson != null) {
                        // Open small bio
                        Navigator.push(
                            context,
                            MaterialPageRoute( builder: (context) => ProfileScreen(person: _selectedPerson!)));
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(AppLocalizations.of(context)!.selectPersonValidateErr))); //TODO font size
                      }
                      
                    },
                    child: Text(AppLocalizations.of(context)!.familyEnterProfile,
                              style: theme.bodyNormal)
                  ),
                            
                  // const SizedBox(height: 16.0),
                            
                  FilledButton(
                    style: ButtonStyle(
                      padding: WidgetStatePropertyAll<EdgeInsets>(EdgeInsets.all(18.0)),
                      shape: WidgetStatePropertyAll<RoundedRectangleBorder>(
                      RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)))),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => TreeViewScreen(graphFamily: _familyList!)), //TODO debug between tree and paint
                      );
                    }, 
                    child: Column(
                      children: [
                        SvgPicture.asset('assets/tree.svg', width: 100.0, height: 100.0),
                        Text(AppLocalizations.of(context)!.showTree,
                              style: theme.bodyNormal) //TODO put font size for button text
                      ],
                    )
                    // Text(AppLocalizations.of(context)!.showTree,
                    //           style: theme.bodyNormal)
                  ),
                ],
              ),
          
              SizedBox(height: _bigSpacing),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: _bigSpacing,
                children: [
                  FilledButton(
                    style: ButtonStyle(
                    padding: WidgetStatePropertyAll<EdgeInsets>(EdgeInsets.all(18.0)),
                    shape: WidgetStatePropertyAll<RoundedRectangleBorder>(
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)))),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => FindRelationScreen(),
                      ));
                    }, 
                    child: Column(
                      children: [
                        SvgPicture.asset('assets/relation.svg', width: 100.0, height: 100.0),
                        Text(AppLocalizations.of(context)!.familyCompareMembers,
                              style: theme.bodyNormal) //TODO put font size for button text
                      ]
                    )
                  ),
                            
                  // SizedBox(height: _bigSpacing),
                            
                  FilledButton(
                    style: ButtonStyle(
                    padding: WidgetStatePropertyAll<EdgeInsets>(EdgeInsets.all(18.0)),
                    shape: WidgetStatePropertyAll<RoundedRectangleBorder>(
                        RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)))),
                    onPressed: () {
                            
                    }, 
                    child: Column(
                      children: [
                        SvgPicture.asset('assets/phone.svg', width: 100.0, height: 100.0),
                        Text(AppLocalizations.of(context)!.familyContactAdmin,
                              style: theme.bodyNormal) //TODO put font size for button text
                      ]
                    )
                  ),
                ],
              ),
            ],
          ),
        );
      }
    });
  }

  Future grabFamily(String familyName, bool maleOnly) async {
    if (familyName == '') {
      return null;
    }

    DbServices.instance.getFamily(familyName, maleOnly: maleOnly).then((value) {
      setState(() {
        _familyList = value;
      });
    });
    return _familyList;
  }

}