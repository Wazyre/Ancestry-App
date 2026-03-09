import 'package:ancestry_app/src/ui/base/image_popup.dart';
import 'package:ancestry_app/src/ui/base/photo_based_avatar.dart';
import 'package:ancestry_app/src/ui/base/theme_provider.dart';
import 'package:ancestry_app/src/ui/mainMenu/db_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
// import 'package:path/path.dart';

class ProfileScreen extends StatefulWidget {
  final Family person;

  const ProfileScreen({super.key, required this.person});


  @override
  State<ProfileScreen> createState() => _ProfileState();
}

class _ProfileState extends State<ProfileScreen> {
  Family? _person;
  Family? _parent;
  Family? _grandparent;
  List<Family>? _children;
  List<Family>? _familyList;

  final double _bigSpacing = 16.0;

  // int? _childrenCount;
  // bool _showParent = true;
  // bool _showGrandparent = true;

  @override
  void initState(){
    super.initState();
    
    setState(() {
      _person = widget.person;
    });
    getFamily();
    buildFamilyListView();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    return Scaffold(
      appBar: AppBar(),
      body: Directionality(
        textDirection: TextDirection.ltr,
        child: ListView(
            
            children: [
              Column(
                children: [Padding(
                  padding: const EdgeInsets.fromLTRB(0, 0, 0, 8.0),
                  child: CircleAvatar(
                    radius: 100.0,
                    backgroundImage: AssetImage(_person!.imgUrl ??= 'images/ahm.png'),
                    child: GestureDetector(
                      onTap: () async {
                        await showDialog(
                          context: context, 
                          builder: (_) => ImagePopup(imgUrl: _person?.imgUrl)
                        );
                      },
                    ),  
                  ),
                )
              ]),
              Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      decoration: ShapeDecoration(
                        color: Color(0xFFF3E09F),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(topLeft: Radius.circular(12.0), bottomLeft: Radius.circular(12.0))
                        )),
                      padding: EdgeInsets.fromLTRB(9.0, 3.0, 3.0, 3.0),
                      child: Text(_person!.name!, 
                              style: TextStyle(color: Colors.black))),
                    Container(
                      decoration: ShapeDecoration(
                        color: Color(0xFFF3E09F),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            // topLeft: Radius.circular(12.0),
                            bottomLeft: Radius.circular(12.0)))),
                        padding: EdgeInsets.fromLTRB(9.0, 3.0, 3.0, 3.0),
                      child: Text('${_person!.yearBorn} - ${_person!.yearDied ?? ''}',
                              style: TextStyle(color: Colors.black))),
                    SizedBox(height: _bigSpacing),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      spacing: 4.0,
                      textDirection: TextDirection.rtl,
                      children: [
                        Visibility(
                          visible: _children != null,
                          child: Text(AppLocalizations.of(context)!.profileSonM,
                            style: theme.bodyBold)
                        ),
                        Visibility(
                          visible: _children != null,
                          child: Column(
                            children: _children!.map((c) {
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute( builder: (context) => ProfileScreen(person: c)));
                                },
                                child: PhotoBasedAvatar(person: c)
                              );
                            }).toList()
                          )
                        ),
                        
                        Visibility(
                          visible: _parent != null,
                          child: Text(_person!.gender == 1 ? AppLocalizations.of(context)!.profileParentM : AppLocalizations.of(context)!.profileParentF,
                            style: theme.bodyBold)
                        ),
                        Visibility(
                            visible: _parent != null,
                            child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute( builder: (context) => ProfileScreen(person: _parent!)));
                                },
                                child: PhotoBasedAvatar(person: _parent)
                              //   Text(_parent?.name! ?? '',
                              // style: theme.bodyNormal),
                              )
                        ),
                        
                        Visibility(
                          visible: _grandparent != null,
                          child: Text(_person!.gender == 1 ? AppLocalizations.of(context)!.profileGrandparentM : AppLocalizations.of(context)!.profileGrandparentF,
                            style: theme.bodyBold)
                        ),
                        Visibility(
                          visible: _grandparent != null,
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          ProfileScreen(person: _grandparent!)));
                            },
                            child: PhotoBasedAvatar(person: _grandparent)
                          )
                        ),
                      ],
                    )
                  ],
                ),
              Container(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  _person!.bio ?? 'bio',
                  textDirection: TextDirection.rtl,
                  style: theme.bodyNormal
                ),
              )
            ],
          ),
        ),
      );
  }

  Future getFamily() async {
    List<Family>? tempFamilyList = DbServices.instance.storedFamily;
    setState(() {
      _familyList = tempFamilyList;
    });
  }

  void buildFamilyListView() {
    if (_person!.parent != null) {
      setState(() {
        _parent = _familyList?.firstWhere((p) => p.id == _person!.parent);
      });
    
      if (_parent!.parent != null) {
        setState(() {
          _grandparent = _familyList?.firstWhere((p) => p.id == _parent!.parent);
        });
      }
    }

    setState(() {
      _children = _familyList?.where((c) => c.parent == _person!.id).toList();
    });
  }
  
} 