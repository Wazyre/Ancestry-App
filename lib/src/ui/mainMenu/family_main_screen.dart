import 'dart:convert';

import 'package:ancestry_app/l10n/app_localizations.dart';
import 'package:ancestry_app/src/ui/base/dropdown_avatar_family.dart';
import 'package:ancestry_app/src/ui/base/settings_provider.dart';
import 'package:ancestry_app/src/ui/base/theme_provider.dart';
import 'package:ancestry_app/src/ui/mainMenu/family_paint_screen.dart';
import 'package:ancestry_app/src/ui/mainMenu/family_tree_screen.dart';
import 'package:ancestry_app/src/ui/mainMenu/find_relation_screen.dart';
import 'package:ancestry_app/src/ui/mainMenu/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ancestry_app/src/ui/mainMenu/family_history_editor.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

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

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);
    final familyName = settings.savedSettings.tabFamily;
    final maleOnly = settings.savedSettings.maleOnly;

    return FutureBuilder(
      future: grabFamily(familyName, maleOnly),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final colorScheme = Theme.of(context).colorScheme;

        return Scaffold(
          appBar: AppBar(
            title: Text(familyName, style: const TextStyle(fontFamily: 'Monadi')),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.park_outlined),
                tooltip: 'Paint Tree (experimental)',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FamilyPaintScreen()),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              // Member selector
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: DropdownAvatarFamily(
                  familyList: _familyList!,
                  onChangedFn: ((CircleAvatar, Family)? value) {
                    setState(() {
                      _selectedPerson = value!.$2;
                    });
                  },
                ),
              ),

              // Selected person chip
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _selectedPerson != null
                    ? Padding(
                        key: ValueKey(_selectedPerson!.id),
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                        child: Chip(
                          avatar: CircleAvatar(
                            backgroundImage: _selectedPerson!.imgUrl != null &&
                                    _selectedPerson!.imgUrl!.startsWith('http')
                                ? NetworkImage(_selectedPerson!.imgUrl!) as ImageProvider
                                : AssetImage(_selectedPerson!.imgUrl ?? 'assets/profile.png'),
                          ),
                          label: Text(_selectedPerson!.name ?? '',
                              style: theme.bodyNormal),
                          backgroundColor:
                              colorScheme.primaryContainer.withValues(alpha: 0.6),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),

              SizedBox(height: _bigSpacing),

              // Action cards grid (2x2): Tree, Relation, Profile, Bio
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                  child: Column(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            _ActionCard(
                              icon: SvgPicture.asset('assets/tree.svg',
                                  width: 56, height: 56),
                              label: AppLocalizations.of(context)!.showTree,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => TreeViewScreen(
                                          graphFamily: _familyList!)),
                                );
                              },
                            ),
                            const SizedBox(width: 12),
                            _ActionCard(
                              icon: SvgPicture.asset('assets/relation.svg',
                                  width: 56, height: 56),
                              label: AppLocalizations.of(context)!
                                  .familyCompareMembers,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          FindRelationScreen()),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: Row(
                          children: [
                            _ActionCard(
                              icon: const Icon(Icons.person_outline, size: 56),
                              label: AppLocalizations.of(context)!
                                  .familyEnterProfile,
                              onTap: () {
                                if (_selectedPerson != null) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => ProfileScreen(
                                            person: _selectedPerson!)),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        AppLocalizations.of(context)!
                                            .selectPersonValidateErr,
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                            const SizedBox(width: 12),
                            // Biography card — fetches and displays the family's history text
                            _ActionCard(
                              icon: const Icon(Icons.menu_book_outlined, size: 56),
                              label: AppLocalizations.of(context)!.familyBio,
                              onTap: () async {
                                final bio = await DbServices.instance
                                    .getFamilyBio(familyName);
                                if (context.mounted) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => _FamilyBioScreen(
                                        familyName: familyName,
                                        bio: bio,
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Contact admin button — centered below the grid
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                child: Center(
                  child: TextButton.icon(
                    icon: SvgPicture.asset('assets/phone.svg', width: 22, height: 22),
                    label: Text(
                      AppLocalizations.of(context)!.familyContactAdmin,
                      style: theme.bodyNormal,
                    ),
                    onPressed: () async {
                      final phone = await DbServices.instance
                          .getAdminPhone(familyName);
                      if (phone == null || phone.isEmpty) {
                        if (context.mounted) {
                          final loc = AppLocalizations.of(context)!;
                          final cs = Theme.of(context).colorScheme;
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              icon: Icon(
                                Icons.phone_disabled_outlined,
                                size: 40,
                                color: cs.primary,
                              ),
                              title: Text(
                                loc.noAdminPhone,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontFamily: 'Monadi', fontSize: 20),
                              ),
                              content: Text(
                                loc.noAdminPhoneBody,
                                textAlign: TextAlign.center,
                              ),
                              actionsAlignment: MainAxisAlignment.center,
                              actions: [
                                FilledButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text(loc.dismiss),
                                ),
                              ],
                            ),
                          );
                        }
                        return;
                      }
                      final digits = phone.replaceAll(RegExp(r'[^\d]'), '');
                      final uri = Uri.parse('https://wa.me/$digits');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri,
                            mode: LaunchMode.externalApplication);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future grabFamily(String familyName, bool maleOnly) async {
    if (familyName == '') {
      return null;
    }

    DbServices.instance.getFamily(familyName, maleOnly: maleOnly).then((value) {
      if (mounted) setState(() { _familyList = value; });
    });
    return _familyList;
  }
}

class _ActionCard extends StatelessWidget {
  final Widget icon;
  final String label;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Provider.of<ThemeProvider>(context, listen: false);

    return Expanded(
      child: Card(
        elevation: 0,
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                icon,
                const SizedBox(height: 10),
                Text(
                  label,
                  style: theme.bodyNormal,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Screen that renders the family's biography stored as Quill Delta JSON.
// Supports rich text (headers, bold/italic, lists, blockquotes) and images.
class _FamilyBioScreen extends StatefulWidget {
  final String familyName;
  final String? bio;

  const _FamilyBioScreen({required this.familyName, this.bio});

  @override
  State<_FamilyBioScreen> createState() => _FamilyBioScreenState();
}

class _FamilyBioScreenState extends State<_FamilyBioScreen> {
  late QuillController _controller;
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller = _buildController(widget.bio);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Parse Quill Delta JSON; fall back to plain text for legacy content.
  QuillController _buildController(String? content) {
    if (content != null && content.trim().isNotEmpty) {
      try {
        final ops = jsonDecode(content) as List<dynamic>;
        return QuillController(
          document: Document.fromJson(ops),
          selection: const TextSelection.collapsed(offset: 0),
          readOnly: true,
        );
      } catch (_) {
        final doc = Document()..insert(0, content);
        return QuillController(
          document: doc,
          selection: const TextSelection.collapsed(offset: 0),
          readOnly: true,
        );
      }
    }
    return QuillController(
      document: Document(),
      selection: const TextSelection.collapsed(offset: 0),
      readOnly: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context)!;
    final isEmpty = widget.bio == null || widget.bio!.trim().isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.familyName,
            style: const TextStyle(fontFamily: 'Monadi')),
        centerTitle: true,
      ),
      body: isEmpty
          // Placeholder when no biography has been written yet
          ? Center(
              child: Text(
                loc.familyBioEmpty,
                style: TextStyle(color: colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            )
          // Read-only Quill viewer — same renderer as the editor
          : QuillEditor(
              controller: _controller,
              focusNode: _focusNode,
              scrollController: _scrollController,
              config: QuillEditorConfig(
                padding: const EdgeInsets.all(20),
                embedBuilders: [const FamilyHistoryImageEmbedBuilder()],
                showCursor: false,
                enableInteractiveSelection: false,
              ),
            ),
    );
  }
}