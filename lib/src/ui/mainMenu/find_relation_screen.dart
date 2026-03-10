import 'package:ancestry_app/src/ui/base/dropdown_avatar_family.dart';
import 'package:ancestry_app/src/ui/base/theme_provider.dart';
import 'package:ancestry_app/src/ui/mainMenu/db_services.dart';
import 'package:ancestry_app/src/ui/mainMenu/family_tree_screen.dart';
import 'package:ancestry_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FindRelationScreen extends StatefulWidget {
  const FindRelationScreen({super.key});

  @override
  State<FindRelationScreen> createState() => _FindRelationState();
}

class _FindRelationState extends State<FindRelationScreen> {
  List<Family>? _familyList;
  Family? personA;
  Family? personB;

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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Person A card
            _PersonSelectorCard(
              label: '1',
              familyList: _familyList!,
              onChanged: (value) => setState(() { personA = value?.$2; }),
              colorScheme: colorScheme,
              theme: theme,
            ),

            // Arrow between
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Icon(
                Icons.swap_vert_rounded,
                size: 36,
                color: colorScheme.primary,
              ),
            ),

            // Person B card
            _PersonSelectorCard(
              label: '2',
              familyList: _familyList!,
              onChanged: (value) => setState(() { personB = value?.$2; }),
              colorScheme: colorScheme,
              theme: theme,
            ),

            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          TreeViewScreen(graphFamily: findRelationship()),
                    ),
                  );
                },
                icon: const Icon(Icons.account_tree_outlined),
                label: Text(AppLocalizations.of(context)!.showTree,
                    style: theme.bodyNormal),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /*
  Responsible for finding relationship between two Family objects.
  Outputs a list of Family containing all nodes on the path between them
  through their lowest common ancestor (LCA).
  */
  List<Family> findRelationship() {
    if (personA == null || personB == null) return [];

    // Build ancestor chain from a person up to root (inclusive).
    // Returns copies with first name only (avoids mutating the stored list).
    List<Family> ancestorChain(Family start) {
      final chain = <Family>[];
      Family current = start;
      while (true) {
        chain.add(current.copy(name: current.name?.split(' ')[0]));
        if (current.parent == null) break;
        final matches = _familyList!.where((p) => p.id == current.parent).toList();
        if (matches.isEmpty) break;
        current = matches.first;
      }
      return chain;
    }

    final chainA = ancestorChain(personA!);
    final chainB = ancestorChain(personB!);

    // Find LCA: first node in chainB that also appears in chainA
    for (int i = 0; i < chainB.length; i++) {
      final indexInA = chainA.indexWhere((p) => p.id == chainB[i].id);
      if (indexInA != -1) {
        // Path: A → ... → LCA ← ... ← B
        // chainA[0..indexInA] covers A's side including LCA
        // chainB[0..i-1] covers B's side excluding LCA (already included)
        final result = <Family>[];
        result.addAll(chainA.sublist(0, indexInA + 1));
        result.addAll(chainB.sublist(0, i));
        return result;
      }
    }

    return [];
  }
}

class _PersonSelectorCard extends StatelessWidget {
  final String label;
  final List<Family> familyList;
  final ValueChanged<(CircleAvatar, Family)?> onChanged;
  final ColorScheme colorScheme;
  final ThemeProvider theme;

  const _PersonSelectorCard({
    required this.label,
    required this.familyList,
    required this.onChanged,
    required this.colorScheme,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person_outline, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(label, style: theme.bodyBold),
              ],
            ),
            const SizedBox(height: 10),
            DropdownAvatarFamily(
              familyList: familyList,
              onChangedFn: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}