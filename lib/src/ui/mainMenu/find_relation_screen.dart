import 'package:ancestry_app/src/ui/base/dropdown_avatar_family.dart';
// import 'package:ancestry_app/src/ui/base/settings_provider.dart';
import 'package:ancestry_app/src/ui/base/theme_provider.dart';
import 'package:ancestry_app/src/ui/mainMenu/db_services.dart';
import 'package:ancestry_app/src/ui/mainMenu/family_tree_screen.dart';
// import 'package:ancestry_app/src/ui/mainMenu/profile_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
// import 'package:graphview/GraphView.dart';
import 'package:provider/provider.dart';

// class ModFamilyList {
//   final Family root;
//   final List<List<Family>> children;

//   ModFamilyList({required this.root, required this.children});
// }

class FindRelationScreen extends StatefulWidget {
  const FindRelationScreen({super.key});

  @override
  State<FindRelationScreen> createState() => _FindRelationState();
}

class _FindRelationState extends State<FindRelationScreen> {
  List<Family>? _familyList;
  Family? personA;
  Family? personB;
  // Family? _focusedPerson;

  @override
  void initState() {
    super.initState();
    setState(() {
      _familyList = DbServices.instance.storedFamily;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    // final settings = Provider.of<SettingsProvider>(context);
    // final maleOnly = settings.savedSettings.maleOnly;
    // final familyName = settings.savedSettings.tabFamily;
    
    // return FutureBuilder(future: grabFamily(familyName, maleOnly), 
    // builder: (context, snapshot) {
    //   if (!snapshot.hasData) {
    //     return Scaffold(
    //       body: Center(
    //         child: Column(
    //           mainAxisAlignment: MainAxisAlignment.center,
    //           children: [
    //             CircularProgressIndicator(),
    //           ],
    //         ),
    //       ),
    //     ); 
    //   }
    //   else {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.max, 
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: DropdownAvatarFamily(
                // context: context,
                familyList: _familyList!,
                onChangedFn: ((CircleAvatar, Family)? value) {
                  setState(() {
                    personA = value!.$2;
                  });
                },
              )
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: DropdownAvatarFamily(
                // context: context,
                familyList: _familyList!,
                onChangedFn: ((CircleAvatar, Family)? value) {
                  setState(() {
                    personB = value!.$2;
                  });
                },
              )
            ),
            OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => TreeViewScreen(graphFamily: findRelationship())), //TODO debug between tree and paint
                );
              },
              child: Text(AppLocalizations.of(context)!.showTree,
                      style: theme.bodyNormal)),
          ],
        ),
      )
    );
    //   }
    // }
    // );
  }

  
  
  // Future grabFamily(String familyName, bool maleOnly) async {
  //   if (familyName == '') {
  //     return null;
  //   }

  //   DbServices.instance.getFamily(familyName, maleOnly: maleOnly).then((value) {
  //     setState(() {
  //       familyList = value;
  //     });
  //   });
  //   return familyList;
  // }

  /* 
  Responsible for finding relationship betweeen two Family objects
  Outputs a list of Family containing all Family objects between the two
  inputs
  */
  List<Family> findRelationship() {
    List<Family> ancestorsA = [];
    List<Family> ancestorsB = [];
    Family currentA = personA!;
    Family currentB = personB!;
    bool parentInB = false;
    bool parentInA = false;

    // Isolate first name since Avatar dropdown contained full name
    currentA.name = currentA.name!.split(' ')[0];
    currentB.name = currentB.name!.split(' ')[0];
    

    // TODO Add a condition where one of the people is the root of the family
    while(currentA != _familyList![0] || currentB != _familyList![0]) {
      if(currentA != _familyList![0]) { // If not root of family
        ancestorsA.add(currentA);
        Family test = ancestorsB.firstWhere((p) => p.id == currentA.parent, orElse: () {return Family(id: -1);});
        // Family test2 = Family(id: -1);
        parentInB = test.id != -1;
      
        if (parentInB) {
          int index = ancestorsB.indexWhere((p) => p.id == currentA.parent);
          // ModFamilyList result = ModFamilyList(root: ancestorsB[index], children: [ancestorsA, ancestorsB.sublist(0, index)]);
          List<Family> result = [];
          result.addAll(ancestorsA);
          result.addAll(ancestorsB.sublist(0, index+1));
          return result;
        }
        currentA = _familyList!.firstWhere((p) => p.id == currentA.parent);
      }

      if (currentB != _familyList![0]) {
        ancestorsB.add(currentB);
        Family test = ancestorsA.firstWhere((p) => p.id == currentB.parent, orElse: () {
                  return Family(id: -1);
                });
        parentInA = test.id != -1;
            

        if (parentInA) {
          int index = ancestorsA.indexWhere((p) => p.id == currentB.parent);
          // ModFamilyList result = ModFamilyList(
          //     root: ancestorsA[index],
          //     children: [ancestorsA.sublist(0, index), ancestorsB]);
          List<Family> result = [];
          result.addAll(ancestorsB);
          result.addAll(ancestorsA.sublist(0, index + 1));
          return result;
        }
        currentB = _familyList!.firstWhere((p) => p.id == currentB.parent);
      }
    }
    return [];
  }

  
  
}