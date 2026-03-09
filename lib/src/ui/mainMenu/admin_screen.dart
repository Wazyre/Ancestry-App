import 'dart:io';

import 'package:ancestry_app/src/ui/base/dropdown_avatar_family.dart';
import 'package:ancestry_app/src/ui/base/image_form_field.dart';
import 'package:ancestry_app/src/ui/base/image_popup.dart';
import 'package:ancestry_app/src/ui/base/settings_provider.dart';
import 'package:ancestry_app/src/ui/base/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'db_services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

// TODO add form details that appear after selecting dropdown use selectedPerson

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  
  @override
  State<AdminScreen> createState() => _AdminState();
}

class _AdminState extends State<AdminScreen> {

  List<Family>? familyList;
  String? _familyName; //=  settings.savedSettings.tabFamily; // TODO uncomment this when fixed pulling family name logic 'العبدالجليل';
  Family? _selectedPerson; 

  final _editFormKey = GlobalKey<FormState>();

  TextEditingController _nameController = TextEditingController();
  int? _parentController;
  TextEditingController _yearBornController = TextEditingController();
  TextEditingController _yearDiedController = TextEditingController();
  String? _imgUrlController;
  File? _portraitImg;
  int _genderController = 1;
  TextEditingController _bioController = TextEditingController();

  bool _visDropEdit = false;
  bool _visFormEdit = false;
  bool _visFormAdd = false;
  bool _visImageAdd = false;

  final double _bigSpacing = 16.0;
  final double _smallSpacing = 8.0;

  @override
  void initState() {
    super.initState();
    
    // DbServices db = DbServices.instance;

    // family = await db.getFamily();
  }

  // TODO use WillPopScope here to define going back to main menu instead of login
  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);
    // final ScrollController scrollController = ScrollController();

    return FutureBuilder(future: grabFamily(settings), 
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
          body: NestedScrollView(
            headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
              return [
                SliverAppBar()
              ];
            }, 
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: ListView(
              // mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                onPressed: () {
                  setState(() {
                    _visDropEdit = false;
                    _visFormEdit = false;
                    _visFormAdd = true;
                    _visImageAdd = false;
                    _genderController = 1;
                  });
                },
                child: Text(AppLocalizations.of(context)!.adminAddPerson,
                                style: theme.bodyNormal)
                ),
                OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _visFormAdd = false;
                      _visDropEdit = true;
                      _visImageAdd = false;
                    });
                  }, 
                  child: Text(AppLocalizations.of(context)!.adminEditPerson,
                                  style: theme.bodyNormal)
                ),

                // Dropdown to edit person
                Visibility(
                  visible: _visDropEdit,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: DropdownAvatarFamily(
                      familyList: familyList!, 
                      onChangedFn: ((CircleAvatar, Family)? value) {
                        setState(() {
                          _selectedPerson = value!.$2;
                          _nameController.text = _selectedPerson!.name!.split(' ')[0]; // Isolate first name
                          _genderController = _selectedPerson!.gender!;
                          _yearBornController.text = _selectedPerson!.yearBorn.toString();
                          _yearDiedController.text = _selectedPerson!.yearDied.toString();
                          _parentController = _selectedPerson!.parent;
                          _bioController.text = _selectedPerson!.bio ?? '';
                          _visFormEdit = true;
                        });
                      },
                    ),
                  )
                ),
                        
                // Editing Form
                Visibility(
                  visible: _visFormEdit || _visFormAdd,
                  child: Form(
                    key: _editFormKey, 
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration:
                              InputDecoration(label: Text(AppLocalizations.of(context)!.adminFormName,
                                                style: theme.bodyNormal)),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return AppLocalizations.of(context)!.adminFormNameVal;
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: _bigSpacing),
                        Row(
                          children: [
                            Expanded(child: Text(AppLocalizations.of(context)!.adminFormGender,
                                                  style: theme.bodyNormal)),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: RadioListTile(
                                title: Text(AppLocalizations.of(context)!.adminFormMale,
                                                    style: theme.bodyNormal),
                                value: 1, 
                                groupValue: _genderController, 
                                onChanged: (int? value) {
                                  setState(() {
                                    _genderController = value!;
                                  });
                                }
                              ),
                            ),
                            Expanded(
                              child: RadioListTile(
                                title: Text(AppLocalizations.of(context)!.adminFormFemale,
                                                    style: theme.bodyNormal),
                                value: 0,
                                groupValue: _genderController,
                                onChanged: (int? value) {
                                  setState(() {
                                    _genderController = value!;
                                  });
                                }),
                            ),
                          ],
                        ),
                        SizedBox(height: _smallSpacing),
                        TextFormField(
                          controller: _yearBornController,
                          decoration:
                              InputDecoration(label: Text(AppLocalizations.of(context)!.adminFormYearBorn,
                                                style: theme.bodyNormal)),
                          keyboardType: TextInputType.number,
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return AppLocalizations.of(context)!.adminFormYearBornVal;
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: _bigSpacing),
                        TextFormField(
                          controller: _yearDiedController,
                          decoration:
                              InputDecoration(label: Text(AppLocalizations.of(context)!.adminFormYearDied,
                                                style: theme.bodyNormal)),
                          keyboardType: TextInputType.number,
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          validator: (value) {
                            if (int.parse(value!) < int.parse(_yearBornController.text)) {
                              return 'lease enter the ye';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: _bigSpacing),
                        Row(
                          children: [
                            Text(AppLocalizations.of(context)!.adminFormParent,
                                              style: theme.bodyNormal),
                          ],
                        ),
                        DropdownAvatarFamily(
                          // context: context, 
                          // TODO fix initial parent if editing
                          familyList: familyList!, 
                          maleOnly: true,
                          initalFamily: _parentController,
                          onChangedFn: ((CircleAvatar, Family)? value) {
                            setState(() {
                              _parentController = value!.$2.id;
                            });
                          },
                        ),
                        SizedBox(height: _bigSpacing),
                        TextFormField(
                          controller: _bioController,
                          decoration:
                              InputDecoration(label: Text(AppLocalizations.of(context)!.adminFormBio,
                                                style: theme.bodyNormal)),
                          keyboardType: TextInputType.multiline,
                          maxLines: null,
                          // validator: (value) {
                          //   if (value == null || value.isEmpty) {
                          //     return 'Please a first name';
                          //   }
                          //   return null;
                          // },
                        ),
                        SizedBox(height: _bigSpacing),
                        Padding(
                          padding:
                              const EdgeInsets.only(left: 8.0),
                          child: ImageFormField(
                              validator: (File? file) {
                            return '';
                          }, onChanged: (File file) {
                            // TODO upload picture after submitting
                            setState(() {
                              _portraitImg = file;
                              _visImageAdd = true;
                            });
                          }),
                        ),
                        SizedBox(height: _bigSpacing),
                        Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 30.0),
                              child: Text(AppLocalizations.of(context)!.adminFormImageCurrent,
                                                style: theme.bodyNormal),
                            ),
                            Expanded(flex: 2, child: buildImage(_imgUrlController, null)),
                            Spacer(),
                          ],
                        ),
                        SizedBox(height: _bigSpacing), // TODO remove if trailing
                        Visibility(
                          visible: _visImageAdd,
                          child: Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                    left: 30.0),
                                child: Text(AppLocalizations.of(context)!.adminFormImageCurrent,
                                                  style: theme.bodyNormal),
                              ),
                              buildImage(null, _portraitImg),
                            ],
                          ),
                        ),
                        SizedBox(height: _bigSpacing),
                        OutlinedButton(
                          onPressed: () {
                            uploadData(_visFormEdit ? 'edit' : 'add');
                          }, 
                          child: Text(AppLocalizations.of(context)!.submit,
                                              style: theme.bodyNormal))
                      ],
                    )
                  )
                )
              ],
            ),
            )
        )
        );
      }
    }); 
  }

  /* 
  Grabs selected family from database
  */
  Future grabFamily(SettingsProvider prov) async {
    // if (familyName == '') {
    //   return null;
    // }

    DbServices.instance.getFamily(prov.savedSettings.tabFamily).then((value) {
      setState(() {
        familyList = value;
      });
    });

    final settings = Provider.of<SettingsProvider>(context);
    setState(() {
      _familyName = settings.savedSettings.tabFamily;
    });

    return familyList;
  }

  /*
  Takes in an image url and outputs a Circle Avatar version
  of it
  */
  Widget buildImage(String? imgUrl, File? file) {
    if (imgUrl != null) {
      return CircleAvatar(
        radius: 80.0, 
        backgroundImage: NetworkImage(imgUrl),
        child: GestureDetector(
          onTap: () async {
            await showDialog(
                context: context,
                builder: (_) => ImagePopup(imgUrl: imgUrl));
          },
        ),  
      );
    }
    else if (file != null) {
      return CircleAvatar(
        radius: 80.0,
        backgroundImage: Image.file(file).image,
        child: GestureDetector(
          onTap: () async {
            await showDialog(
                context: context, builder: (_) => ImagePopup(imgUrl: imgUrl));
          },
        ),
      );
    }
    else {
      return CircleAvatar(
        radius: 80.0, 
        backgroundImage: AssetImage('images/blank.png'),
        child: GestureDetector(
          onTap: () async {
            await showDialog(
                context: context,
                builder: (_) => ImagePopup(imgUrl: 'images/blank.png'));
          },
        ),    
      );
    }
  }

  /*
  Uploads additions and edits to family database
  TODO Reformat to settled database format
  */
  void uploadData(String mode) async {
    // TODO make input validation checks
    Family newFamily = Family(
      id: _selectedPerson?.id ?? (await DbServices.instance.maxId(_familyName!) + 1),
      bio: _bioController.text,
      name: _nameController.text,
      parent: _parentController,
      gender: _genderController,
      yearBorn: int.parse(_yearBornController.text),
      yearDied: int.parse(_yearDiedController.text),
      imgUrl: _imgUrlController
    );

    if (mode == 'add') {
      DbServices.instance.insert(_familyName!, newFamily);

    }
    else if (mode == 'edit') {
      DbServices.instance.update(_familyName!, newFamily);
    }
  }
}