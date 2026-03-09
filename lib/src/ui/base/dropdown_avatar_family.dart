import 'package:ancestry_app/src/ui/base/settings_provider.dart';
import 'package:ancestry_app/src/ui/base/theme_provider.dart';
import 'package:ancestry_app/src/ui/mainMenu/db_services.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class DropdownAvatarFamily extends StatefulWidget {
  // final BuildContext context;
  final List<Family> familyList;
  final bool? maleOnly;
  final int? initalFamily;
  final ValueChanged<(CircleAvatar, Family)?>? onChangedFn;


  const DropdownAvatarFamily({
    super.key,
    // required this.context, 
    required this.familyList,
    this.maleOnly,
    this.initalFamily, 
    required this.onChangedFn, 
  });

  @override
  State<DropdownAvatarFamily> createState() => _DropdownAvatarFamilyState();
}

class _DropdownAvatarFamilyState extends State<DropdownAvatarFamily> {
  // BuildContext? _context;
  List<Family>? _familyList;
  bool? _maleOnly = false;
  int? _initalFamily;
  (CircleAvatar, Family)? _initalFamilyBuilt;
  ValueChanged<(CircleAvatar, Family)?>? _onChangedFn;

  @override
  void initState() {
    super.initState();
    setState(() {
      // _context = widget.context;
      _familyList = widget.familyList;
      _maleOnly = widget.maleOnly ?? false;
      _initalFamily = widget.initalFamily;
      _onChangedFn = widget.onChangedFn;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);

    return DropdownSearch<(CircleAvatar, Family)>(
      items: (f, cs) => buildDropdown(context),
      compareFn: (item1, item2) => item1.$2.id! == item2.$2.id!,
      selectedItem: _initalFamilyBuilt,
      // clickProps: ClickProps(
      //   autofocus: true
      // ),
      suffixProps: DropdownSuffixProps(
          dropdownButtonProps: DropdownButtonProps(
              iconClosed: Icon(Icons.keyboard_arrow_down),
              iconOpened: Icon(Icons.keyboard_arrow_up))),
      decoratorProps: DropDownDecoratorProps(
          baseStyle: TextStyle(
                      color: theme
                          .getCurrentScheme(context)
                          .colorScheme
                          .primary),
          decoration: InputDecoration(
            floatingLabelBehavior: FloatingLabelBehavior.auto,
            label: Text(AppLocalizations.of(context)!.familyChooseMember,
                    style: TextStyle(
                        color: theme
                            .getCurrentScheme(context)
                            .colorScheme
                            .primary)),
            border: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.transparent),
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(),
              borderRadius: BorderRadius.circular(12),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.transparent),
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.white,
            // hintText: 'Please choose family...'
          )),
      dropdownBuilder: (context, selectedItem) {
        return ListTile(
          leading: selectedItem?.$1,
          title: Text(selectedItem?.$2.name! ?? ''),
        );
      },
      popupProps: PopupProps.menu(
        itemBuilder: (context, item, isDisabled, isSelected) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: ListTile(
              leading: item.$1,
              title: Text(item.$2.name!),
            ),
          );
        },
        showSearchBox: true,
        searchFieldProps: TextFieldProps(
              decoration: InputDecoration(icon: Icon(Icons.search))),
        constraints: BoxConstraints(maxHeight: 260),
        menuProps: MenuProps(
          margin: EdgeInsets.only(top: 12),
          shape: const RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.all(Radius.circular(12))),
        ),
      ),
      onChanged: _onChangedFn, 
      validator: (value) {
        if (value == null) {
          return AppLocalizations.of(context)!.selectPersonValidateErr;
        }
        return null;
      },
    );
  }

  List<(CircleAvatar, Family)> buildDropdown(context) {
    List<(CircleAvatar, Family)> builtFamily = [];
    String fullName = '';
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    int nameLength = settings.savedSettings.nameLength;

    for (final person in _familyList!) {
      if (_maleOnly! && person.gender == 0) {
        continue;
      }
      fullName = '${person.name}';

      Family? tempParent = person.parent != null
          ? _familyList!.firstWhere((p) => p.id == person.parent)
          : null;

      for (int i = 0; i < nameLength - 2; i++) {
        if (tempParent?.name != null) {
          // In case of head of family
          fullName += ' ${tempParent?.name}';

          if (tempParent?.parent != null) {
            tempParent =
                _familyList!.firstWhere((p) => p.id == tempParent?.parent);
          } else {
            break;
          }
        } else {
          break;
        }
      }
      fullName += ' ${person.familyName!}';
      Family tempPerson = person.copy();
      tempPerson.name = fullName;

      builtFamily.add((
        CircleAvatar(
          // radius: 5.0,
          backgroundImage: AssetImage(person.imgUrl ?? 'images/ahm.png'),
        ),
        tempPerson
      ));
    }
    if (_initalFamily != null && _initalFamilyBuilt == null) {
      setState(() {
        _initalFamilyBuilt = builtFamily.firstWhere((f) => f.$2.id == _initalFamily);
      });
      print(_initalFamilyBuilt);
    }

    return builtFamily;
  }
  

}