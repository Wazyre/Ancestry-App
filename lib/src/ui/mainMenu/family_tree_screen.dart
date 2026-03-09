import 'package:ancestry_app/src/ui/base/settings_provider.dart';
import 'package:ancestry_app/src/ui/base/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';
import 'package:provider/provider.dart';
import 'db_services.dart';
// import 'dart:async';
import 'profile_screen.dart';

class TreeViewScreen extends StatefulWidget {
  final Family? focusedPerson;
  final List<Family> graphFamily;

  const TreeViewScreen({super.key, this.focusedPerson, required this.graphFamily});
  
  @override
  State<TreeViewScreen> createState() => _TreeViewState();
}

class _TreeViewState extends State<TreeViewScreen> {
  DbServices db = DbServices.instance;
  List<Family>? _graphFamily; // Contains only members to be displayed
  List<Family>? _storedFamily; // Contains full imported family for reference
  // Family? _focusedPerson;

  @override
  void initState() {
    super.initState();
    setState(() {
      // _focusedPerson = widget.focusedPerson;
      _graphFamily = widget.graphFamily;
    });
    

    builder
      ..siblingSeparation = (100)
      ..levelSeparation = (150)
      ..subtreeSeparation = (150)
      ..orientation = (BuchheimWalkerConfiguration.ORIENTATION_TOP_BOTTOM);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);
    // final maleOnly = settings.savedSettings.maleOnly;
    final familyName = settings.savedSettings.tabFamily;

    return FutureBuilder(future: buildGraph(), 
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
            actions: [
              // IconButton(
              //   icon: const Icon(Icons.search),
              //   tooltip: 'Search',
              //   onPressed: (){},
              // )
            ]
          ),
          body: Center(
            child: Column(mainAxisSize: MainAxisSize.max, 
            children: [
              Expanded(
                child: InteractiveViewer(
                  boundaryMargin: const EdgeInsets.all(100),
                  constrained: false,
                  minScale: 0.01,
                  maxScale: 5.6,
                  child: GraphView(
                    graph: graph,
                    algorithm:
                        BuchheimWalkerAlgorithm(builder, TreeEdgeRenderer(builder)),
                    paint: Paint()
                      ..color =  theme.getCurrentThemeMode(context) == 'dark' ? Colors.white : Colors.black
                      ..strokeWidth = 2
                      ..style = PaintingStyle.stroke,
                    builder: (Node node) {
                      var endNode = node.key!.value;
                      return squareWidget(endNode);
                    }
                  ),
                )
              )
            ]),
          )
        );
      }
    });
  }

  Widget squareWidget(Family person) {
    Family? parent;
    int gender = person.gender!;

    if (person.parent != null) { 
      parent = _storedFamily?.firstWhere((p) => p.id == person.parent);
    }
  
    return Consumer<SettingsProvider>(builder: (context, settings, child) {
      return InkWell(
        onTap: () {
          String fullName = '${person.name}';
          int nameLength = settings.savedSettings.nameLength;
          Family? tempParent = parent;

          for (int i = 0; i < nameLength-2; i++) {

            if (tempParent?.name != null) { // In case of head of family
              fullName += ' ${tempParent?.name}';

              if (tempParent?.parent != null) {
                tempParent = _storedFamily?.firstWhere((p) => p.id == tempParent?.parent);
              }
              else {
                break;
              }
            }
            else {
              break;
            }
          }
          fullName += ' ${person.familyName!}';
          
          final newPerson = person.copy();
          newPerson.name = fullName;

          // Open profile screen with person details
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ProfileScreen(person: newPerson))
          );
        },
        child: Container(
          padding: const EdgeInsets.fromLTRB(7, 7, 7, 20),
          decoration: BoxDecoration(
            shape: BoxShape.rectangle,
            border: Border.all(width: 1, color: Colors.black),
            color: gender == 1 ? const Color(0xFFE7DE99) : const Color(0xFF5E7A44)
            // boxShadow: [
            //   BoxShadow(color: (Colors.blue[100])!, spreadRadius: 1),
            // ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(50),
                decoration: BoxDecoration(
                  image: DecorationImage(
                    fit: BoxFit.fill,
                    image: AssetImage(person.imgUrl ??= 'images/ahm.png'),
                  ),
                  shape: BoxShape.rectangle,
                  border: Border.all(width: 1, color: Colors.black),
                  // color: gender == 1 ? const Color(0xFFE7DE99) : const Color(0xFF5E7A44)
                  // boxShadow: [
                  //   BoxShadow(color: (Colors.blue[100])!, spreadRadius: 1),
                  // ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  person.name!,
                  style: TextStyle(
                      color: gender == 1 ? Colors.black : Colors.white),
                ),
              )
            ],
          ) 
          
        ));
    });
    
  }

  // Graph settings
  final Graph graph = Graph()..isTree = true;
  BuchheimWalkerConfiguration builder = BuchheimWalkerConfiguration();

  /* 
  Builds graph from passed Family list parameter
  */
  Future buildGraph() async {
    // if (familyName == '') {
    //   return null;
    // }
    // family = await DbServices.instance.getFamily(familyName, maleOnly: maleOnly);
    setState(() {
      _storedFamily = DbServices.instance.storedFamily;
    });
  
    for (final person in _graphFamily!) {
      // if (maleOnly && person.gender == 0) {continue;} 
      Family findFamily = _graphFamily!.firstWhere((p) => p.id == person.parent, orElse: () {return Family(id: -1);});
      if (findFamily.id != -1) {
        graph.addEdge(Node.Id(findFamily), Node.Id(person));
      }
    }

    return true;
  }

}
