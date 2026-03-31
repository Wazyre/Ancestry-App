import 'package:ancestry_app/src/ui/base/image_popup.dart';
import 'package:ancestry_app/src/ui/base/photo_based_avatar.dart';
import 'package:ancestry_app/src/ui/base/settings_provider.dart';
import 'package:ancestry_app/src/ui/base/theme_provider.dart';
import 'package:ancestry_app/src/ui/mainMenu/db_services.dart';
import 'package:flutter/material.dart';
import 'package:ancestry_app/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

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

  @override
  void initState() {
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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.profileTitle, style: const TextStyle(fontFamily: 'Monadi')),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share',
            onPressed: () => Share.share(_buildShareText()),
          ),
        ],
      ),
      body: ListView(
        children: [
          // Avatar
          Center(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
              child: Hero(
                tag: 'avatar-${_person!.id}',
                child: CircleAvatar(
                  radius: 90.0,
                  backgroundImage: (_person!.imgUrl != null && _person!.imgUrl!.startsWith('http'))
                      ? NetworkImage(_person!.imgUrl!) as ImageProvider
                      : AssetImage(_person!.imgUrl ?? 'assets/profile.png'),
                  child: GestureDetector(
                    onTap: () async {
                      await showDialog(
                        context: context,
                        builder: (_) => ImagePopup(imgUrl: _person?.imgUrl),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),

          // Name & dates pill — always flush to the physical right edge
          Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _person!.name!,
                        style: TextStyle(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${_person!.yearBorn ?? ''} - ${_person!.yearDied ?? ''}',
                        style: TextStyle(color: colorScheme.onPrimaryContainer),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: _bigSpacing),

          // Lineage row: grandparent → parent → children (RTL)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              textDirection: TextDirection.rtl,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_children != null && _children!.isNotEmpty) ...[
                  _LineageGroup(
                    label: AppLocalizations.of(context)!.profileSonM,
                    theme: theme,
                    colorScheme: colorScheme,
                    children: (_children ?? []).map((c) {
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => ProfileScreen(person: c)),
                          );
                        },
                        child: PhotoBasedAvatar(person: c.copy(name: c.name?.split(' ').first), genderColor: false),
                      );
                    }).toList(),
                  ),
                  const SizedBox(width: 20),
                ],
                if (_parent != null) ...[
                  _LineageGroup(
                    label: _person!.gender == 1
                        ? AppLocalizations.of(context)!.profileParentM
                        : AppLocalizations.of(context)!.profileParentF,
                    theme: theme,
                    colorScheme: colorScheme,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    ProfileScreen(person: _parent!)),
                          );
                        },
                        child: PhotoBasedAvatar(person: _parent!.copy(name: _parent!.name?.split(' ').first), genderColor: false),
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),
                ],
                if (_grandparent != null) ...[
                  _LineageGroup(
                    label: _person!.gender == 1
                        ? AppLocalizations.of(context)!.profileGrandparentM
                        : AppLocalizations.of(context)!.profileGrandparentF,
                    theme: theme,
                    colorScheme: colorScheme,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    ProfileScreen(person: _grandparent!)),
                          );
                        },
                        child: PhotoBasedAvatar(person: _grandparent!.copy(name: _grandparent!.name?.split(' ').first), genderColor: false),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Bio card
          if (_person!.bio != null && _person!.bio!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
              child: Card(
                elevation: 0,
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Text(_person!.bio!, style: theme.bodyNormal),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future getFamily() async {
    List<Family>? tempFamilyList = DbServices.instance.storedFamily;
    setState(() {
      _familyList = tempFamilyList;
    });
  }

  Family _withFullName(Family person) {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final nameLength = settings.savedSettings.nameLength;
    String fullName = person.name ?? '';
    Family? tempParent = person.parent != null
        ? _familyList?.firstWhere((p) => p.id == person.parent, orElse: () => person)
        : null;
    for (int i = 0; i < nameLength - 2; i++) {
      if (tempParent?.name != null && tempParent?.id != person.id) {
        fullName += ' ${tempParent!.name}';
        if (tempParent.parent != null) {
          tempParent = _familyList?.firstWhere((p) => p.id == tempParent!.parent, orElse: () => tempParent!);
        } else {
          break;
        }
      } else {
        break;
      }
    }
    if (person.familyName != null && person.familyName!.isNotEmpty) {
      fullName += ' ${person.familyName}';
    }
    return person.copy(name: fullName.trim());
  }

  // Builds a plain-text summary of the person's profile for the share sheet.
  // Includes name, years, lineage (grandparent → parent), children, and bio.
  String _buildShareText() {
    final loc = AppLocalizations.of(context)!;
    final buf = StringBuffer();

    buf.writeln(_person!.name ?? '');

    if (_person!.yearBorn != null || _person!.yearDied != null) {
      buf.writeln('${_person!.yearBorn ?? ''} - ${_person!.yearDied ?? ''}');
    }

    if (_grandparent != null) {
      buf.writeln('${loc.profileGrandparentM}: ${_grandparent!.name}');
    }

    if (_parent != null) {
      buf.writeln('${loc.profileParentM}: ${_parent!.name}');
    }

    if (_children != null && _children!.isNotEmpty) {
      buf.writeln('${loc.profileSonM}: ${_children!.map((c) => c.name).join(', ')}');
    }

    if (_person!.bio != null && _person!.bio!.isNotEmpty) {
      buf.writeln();
      buf.write(_person!.bio);
    }

    return buf.toString().trim();
  }

  void buildFamilyListView() {
    if (_person!.parent != null) {
      final rawParent = _familyList?.firstWhere((p) => p.id == _person!.parent);
      setState(() {
        _parent = rawParent != null ? _withFullName(rawParent) : null;
      });

      if (_parent?.parent != null) {
        final rawGrandparent = _familyList?.firstWhere((p) => p.id == _parent!.parent);
        setState(() {
          _grandparent = rawGrandparent != null ? _withFullName(rawGrandparent) : null;
        });
      }
    }

    setState(() {
      _children = _familyList?.where((c) => c.parent == _person!.id).map(_withFullName).toList();
    });
  }
}

class _LineageGroup extends StatelessWidget {
  final String label;
  final ThemeProvider theme;
  final ColorScheme colorScheme;
  final List<Widget> children;

  const _LineageGroup({
    required this.label,
    required this.theme,
    required this.colorScheme,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(label, style: theme.bodyBold),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}
