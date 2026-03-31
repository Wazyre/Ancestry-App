import 'dart:io';

import 'package:ancestry_app/src/ui/mainMenu/family_history_editor.dart';
import 'package:ancestry_app/src/ui/base/dropdown_avatar_family.dart';
import 'package:ancestry_app/src/ui/base/image_form_field.dart';
import 'package:ancestry_app/src/ui/base/image_popup.dart';
import 'package:ancestry_app/src/ui/base/settings_provider.dart';
import 'package:ancestry_app/src/ui/base/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'db_services.dart';
import 'package:ancestry_app/l10n/app_localizations.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminState();
}

class _AdminState extends State<AdminScreen> {

  List<Family>? familyList;
  String? _familyName;
  Family? _selectedPerson;

  final _editFormKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  int? _parentController;
  final TextEditingController _yearBornController = TextEditingController();
  final TextEditingController _yearDiedController = TextEditingController();
  String? _imgUrlController;
  File? _portraitImg;
  int _genderController = 1;
  final TextEditingController _bioController = TextEditingController();

  bool _visDropEdit = false;
  bool _visFormEdit = false;
  bool _visFormAdd = false;
  bool _visImageAdd = false;
  bool _visFormQuick = false;
  final _quickFormKey = GlobalKey<FormState>();
  final TextEditingController _quickNameController = TextEditingController();
  int _quickGenderController = 1;
  int? _quickParentController;
  final TextEditingController _quickYearBornController = TextEditingController();

  final double _bigSpacing = 16.0;
  final double _smallSpacing = 8.0;

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);
    final colorScheme = Theme.of(context).colorScheme;

    return FutureBuilder(
      future: grabFamily(settings),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) {
              Navigator.popUntil(context, (route) => route.isFirst);
            }
          },
          child: Scaffold(
            body: NestedScrollView(
              headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
                return [
                  SliverAppBar(
                    title: Text(_familyName ?? '',
                        style: const TextStyle(fontFamily: 'Monadi')),
                    centerTitle: true,
                    floating: true,
                    snap: true,
                  ),
                ];
              },
              body: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: ListView(
                  children: [
                    // Add / Edit toggle row
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.tonal(
                            onPressed: () {
                              setState(() {
                                _visDropEdit = false;
                                _visFormEdit = false;
                                _visFormAdd = true;
                                _visImageAdd = false;
                                _visFormQuick = false;
                                _genderController = 1;
                              });
                            },
                            child: Text(AppLocalizations.of(context)!.adminAddPerson,
                                style: theme.bodyNormal),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _visFormAdd = false;
                                _visDropEdit = true;
                                _visImageAdd = false;
                                _visFormQuick = false;
                              });
                            },
                            child: Text(AppLocalizations.of(context)!.adminEditPerson,
                                style: theme.bodyNormal),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        icon: const Icon(Icons.bolt),
                        label: Text(AppLocalizations.of(context)!.adminQuickAdd),
                        onPressed: () {
                          setState(() {
                            _visDropEdit = false;
                            _visFormEdit = false;
                            _visFormAdd = false;
                            _visImageAdd = false;
                            _visFormQuick = true;
                            _quickGenderController = 1;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Edit family biography with rich text editor
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.menu_book_outlined),
                        label: Text(AppLocalizations.of(context)!.familyBio),
                        onPressed: () async {
                          final existingBio = await DbServices.instance
                              .getFamilyBio(_familyName!);
                          if (context.mounted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => FamilyHistoryEditor(
                                  familyName: _familyName!,
                                  initialContent: existingBio,
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Dropdown to select person for editing
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: _visDropEdit
                          ? Padding(
                              key: const ValueKey('edit-dropdown'),
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: DropdownAvatarFamily(
                                familyList: familyList!,
                                onChangedFn: ((CircleAvatar, Family)? value) {
                                  setState(() {
                                    _selectedPerson = value!.$2;
                                    _nameController.text = _selectedPerson!.name!.split(' ')[0];
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
                          : const SizedBox.shrink(),
                    ),

                    // Form
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: (_visFormEdit || _visFormAdd)
                          ? Form(
                              key: ValueKey('form-${_visFormEdit ? 'edit' : 'add'}'),
                              child: Form(
                                key: _editFormKey,
                                child: Column(
                                  children: [
                                    // Personal info card
                                    _FormCard(
                                      colorScheme: colorScheme,
                                      child: Column(
                                        children: [
                                          TextFormField(
                                            controller: _nameController,
                                            decoration: InputDecoration(
                                              label: Text(AppLocalizations.of(context)!.adminFormName,
                                                  style: theme.bodyNormal),
                                              border: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(10)),
                                            ),
                                            validator: (value) {
                                              if (value == null || value.isEmpty) {
                                                return AppLocalizations.of(context)!.adminFormNameVal;
                                              }
                                              return null;
                                            },
                                          ),
                                          SizedBox(height: _bigSpacing),
                                          Align(
                                            alignment: AlignmentDirectional.centerStart,
                                            child: Text(AppLocalizations.of(context)!.adminFormGender,
                                                style: theme.bodyNormal),
                                          ),
                                          RadioGroup<int>(
                                            groupValue: _genderController,
                                            onChanged: (value) {
                                              if (value != null) setState(() { _genderController = value; });
                                            },
                                            child: Row(
                                              children: [
                                                Expanded(child: RadioListTile(
                                                  title: Text(AppLocalizations.of(context)!.adminFormMale,
                                                      style: theme.bodyNormal),
                                                  value: 1,
                                                )),
                                                Expanded(child: RadioListTile(
                                                  title: Text(AppLocalizations.of(context)!.adminFormFemale,
                                                      style: theme.bodyNormal),
                                                  value: 0,
                                                )),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    SizedBox(height: _smallSpacing),

                                    // Dates card
                                    _FormCard(
                                      colorScheme: colorScheme,
                                      child: Column(
                                        children: [
                                          TextFormField(
                                            controller: _yearBornController,
                                            decoration: InputDecoration(
                                              label: Text(AppLocalizations.of(context)!.adminFormYearBorn,
                                                  style: theme.bodyNormal),
                                              border: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(10)),
                                            ),
                                            keyboardType: TextInputType.number,
                                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
                                            decoration: InputDecoration(
                                              label: Text(AppLocalizations.of(context)!.adminFormYearDied,
                                                  style: theme.bodyNormal),
                                              border: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(10)),
                                            ),
                                            keyboardType: TextInputType.number,
                                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                            validator: (value) {
                                              if (value == null || value.isEmpty) return null;
                                              final yearDied = int.tryParse(value);
                                              final yearBorn = int.tryParse(_yearBornController.text);
                                              if (yearDied != null && yearBorn != null && yearDied < yearBorn) {
                                                return AppLocalizations.of(context)!.adminFormYearDiedVal;
                                              }
                                              return null;
                                            },
                                          ),
                                        ],
                                      ),
                                    ),

                                    SizedBox(height: _smallSpacing),

                                    // Parent card
                                    _FormCard(
                                      colorScheme: colorScheme,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(AppLocalizations.of(context)!.adminFormParent,
                                              style: theme.bodyNormal),
                                          const SizedBox(height: 8),
                                          DropdownAvatarFamily(
                                            familyList: familyList!,
                                            maleOnly: true,
                                            initalFamily: _parentController,
                                            onChangedFn: ((CircleAvatar, Family)? value) {
                                              setState(() {
                                                _parentController = value!.$2.id;
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                    ),

                                    SizedBox(height: _smallSpacing),

                                    // Bio card
                                    _FormCard(
                                      colorScheme: colorScheme,
                                      child: TextFormField(
                                        controller: _bioController,
                                        decoration: InputDecoration(
                                          label: Text(AppLocalizations.of(context)!.adminFormBio,
                                              style: theme.bodyNormal),
                                          border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(10)),
                                        ),
                                        keyboardType: TextInputType.multiline,
                                        maxLines: null,
                                      ),
                                    ),

                                    SizedBox(height: _smallSpacing),

                                    // Image card
                                    _FormCard(
                                      colorScheme: colorScheme,
                                      child: Column(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.only(left: 8.0),
                                            child: ImageFormField(
                                              validator: (File? file) { return ''; },
                                              onChanged: (File file) {
                                                setState(() {
                                                  _portraitImg = file;
                                                  _visImageAdd = true;
                                                });
                                              },
                                            ),
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
                                              const Spacer(),
                                            ],
                                          ),
                                          if (_visImageAdd) ...[
                                            SizedBox(height: _bigSpacing),
                                            Row(
                                              children: [
                                                Padding(
                                                  padding: const EdgeInsets.only(left: 30.0),
                                                  child: Text(AppLocalizations.of(context)!.adminFormImageNew,
                                                      style: theme.bodyNormal),
                                                ),
                                                buildImage(null, _portraitImg),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),

                                    SizedBox(height: _bigSpacing),

                                    SizedBox(
                                      width: double.infinity,
                                      child: FilledButton(
                                        onPressed: () {
                                          uploadData(_visFormEdit ? 'edit' : 'add');
                                        },
                                        style: FilledButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                        child: Text(AppLocalizations.of(context)!.submit,
                                            style: theme.bodyNormal),
                                      ),
                                    ),

                                    SizedBox(height: _bigSpacing),
                                  ],
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),

                    // Quick Add form
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: _visFormQuick
                          ? Form(
                              key: _quickFormKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _FormCard(
                                    colorScheme: colorScheme,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        TextFormField(
                                          controller: _quickNameController,
                                          decoration: InputDecoration(
                                            label: Text(AppLocalizations.of(context)!.adminFormName,
                                                style: theme.bodyNormal),
                                            border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(10)),
                                          ),
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return AppLocalizations.of(context)!.adminFormNameVal;
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Text(AppLocalizations.of(context)!.adminFormGender,
                                                style: theme.bodyNormal),
                                            const Spacer(),
                                            SegmentedButton<int>(
                                              segments: [
                                                ButtonSegment(value: 1, label: Text(AppLocalizations.of(context)!.adminFormMale)),
                                                ButtonSegment(value: 0, label: Text(AppLocalizations.of(context)!.adminFormFemale)),
                                              ],
                                              selected: {_quickGenderController},
                                              onSelectionChanged: (values) => setState(() => _quickGenderController = values.first),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        TextFormField(
                                          controller: _quickYearBornController,
                                          decoration: InputDecoration(
                                            label: Text(AppLocalizations.of(context)!.adminFormYearBorn,
                                                style: theme.bodyNormal),
                                            border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(10)),
                                          ),
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return AppLocalizations.of(context)!.adminFormYearBornVal;
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 12),
                                        Text(AppLocalizations.of(context)!.adminFormParent,
                                            style: theme.bodyNormal),
                                        const SizedBox(height: 8),
                                        DropdownAvatarFamily(
                                          familyList: familyList!,
                                          maleOnly: true,
                                          initalFamily: _quickParentController,
                                          onChangedFn: ((CircleAvatar, Family)? value) {
                                            setState(() {
                                              _quickParentController = value!.$2.id;
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () => setState(() => _visFormQuick = false),
                                          child: Text(AppLocalizations.of(context)!.adminQuickAddDone),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: FilledButton(
                                          onPressed: _quickSave,
                                          child: Text(AppLocalizations.of(context)!.adminQuickAddSaveAnother),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future grabFamily(SettingsProvider prov) async {
    final familyName = DbServices.instance.adminFamilyName ?? prov.savedSettings.tabFamily;

    DbServices.instance.getFamily(familyName).then((value) {
      if (mounted) setState(() { familyList = value; });
    });

    if (mounted) setState(() { _familyName = familyName; });

    return familyList;
  }

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
    } else if (file != null) {
      return CircleAvatar(
        radius: 80.0,
        backgroundImage: Image.file(file).image,
        child: GestureDetector(
          onTap: () async {
            await showDialog(
                context: context, builder: (_) => ImagePopup(imgUrl: null));
          },
        ),
      );
    } else {
      return CircleAvatar(
        radius: 80.0,
        backgroundColor: Color.fromARGB(0, 0, 0, 0),
        backgroundImage: const AssetImage('assets/profile.png'),
        child: GestureDetector(
          onTap: () async {
            await showDialog(
                context: context,
                builder: (_) => ImagePopup(imgUrl: 'assets/profile.png'));
          },
        ),
      );
    }
  }

  Future<String?> _persistImage(File file) async {
    return await DbServices.instance.uploadImage(file);
  }

  Future<void> _quickSave() async {
    if (!(_quickFormKey.currentState?.validate() ?? false)) return;
    final family = Family(
      name: _quickNameController.text.trim(),
      gender: _quickGenderController,
      yearBorn: int.parse(_quickYearBornController.text),
      parent: _quickParentController,
    );
    await DbServices.instance.insert(_familyName!, family);
    final updated = await DbServices.instance.getFamily(_familyName!);
    if (mounted) {
      setState(() {
        familyList = updated;
        _quickNameController.clear();
        _quickYearBornController.clear();
      });
    }
  }

  void uploadData(String mode) async {
    String? savedImgUrl = _imgUrlController;
    if (_portraitImg != null) {
      savedImgUrl = await _persistImage(_portraitImg!);
    }

    Family newFamily = Family(
      id: mode == 'edit' ? _selectedPerson!.id : null,
      bio: _bioController.text,
      name: _nameController.text,
      parent: _parentController,
      gender: _genderController,
      yearBorn: int.parse(_yearBornController.text),
      yearDied: int.tryParse(_yearDiedController.text),
      imgUrl: savedImgUrl,
    );

    if (mode == 'add') {
      DbServices.instance.insert(_familyName!, newFamily);
    } else if (mode == 'edit') {
      DbServices.instance.update(_familyName!, newFamily);
    }
  }
}

class _FormCard extends StatelessWidget {
  final Widget child;
  final ColorScheme colorScheme;

  const _FormCard({required this.child, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: child,
      ),
    );
  }
}