import 'dart:math';
import 'dart:ui' as ui;
import 'package:ancestry_app/src/ui/base/settings_provider.dart';
import 'package:ancestry_app/src/ui/base/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:graphview/GraphView.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:ancestry_app/l10n/app_localizations.dart';
import 'db_services.dart';
import 'profile_screen.dart';

class TreeViewScreen extends StatefulWidget {
  final Family? focusedPerson;
  final List<Family> graphFamily;
  final bool isRelationPath; // When true, shows tree/path/list tabs for a relation result

  const TreeViewScreen({super.key, this.focusedPerson, required this.graphFamily, this.isRelationPath = false});

  @override
  State<TreeViewScreen> createState() => _TreeViewState();
}

class _TreeViewState extends State<TreeViewScreen> {
  DbServices db = DbServices.instance;
  List<Family>? _graphFamily; // Contains only members to be displayed
  List<Family>? _storedFamily; // Contains full imported family for reference
  final TransformationController _transformationController = TransformationController();
  final GlobalKey _repaintKey = GlobalKey();
  bool _centered = false;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    setState(() {
      _graphFamily = widget.graphFamily;
    });

    builder
      ..siblingSeparation = (100)
      ..levelSeparation = (150)
      ..subtreeSeparation = (150)
      ..orientation = (BuchheimWalkerConfiguration.ORIENTATION_TOP_BOTTOM);
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _centerOnRoot(BuildContext context) {
    if (_centered || _graphFamily == null || !mounted) return;

    // Wait until every node has been measured by the layout algorithm
    final nodes = graph.nodes;
    if (nodes.isEmpty || nodes.any((n) => n.width == 0)) return;

    final size       = MediaQuery.of(context).size;
    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight;
    final viewWidth  = size.width;
    final viewHeight = size.height - topPadding;

    // If a focused person was requested, zoom in on their node instead of
    // fitting the whole tree. Match by id because the focusedPerson instance
    // may be a copy with a modified name from the search results.
    if (widget.focusedPerson != null) {
      final focusedNode = nodes
          .where((n) => (n.key!.value as Family).id == widget.focusedPerson!.id)
          .firstOrNull;
      if (focusedNode != null) {
        const scale = 1.5;
        final nodeCenterX = focusedNode.position.dx + focusedNode.width  / 2;
        final nodeCenterY = focusedNode.position.dy + focusedNode.height / 2;
        final tx = viewWidth  / 2 - scale * nodeCenterX;
        final ty = viewHeight / 2 - scale * nodeCenterY;
        _transformationController.value = Matrix4.identity()
          ..translateByDouble(tx, ty, 0, 1)
          ..scaleByDouble(scale, scale, 1, 1);
        _centered = true;
        return;
      }
    }

    // Default: fit the entire tree in the viewport
    double minX = double.infinity,  minY = double.infinity;
    double maxX = double.negativeInfinity, maxY = double.negativeInfinity;
    for (final node in nodes) {
      minX = min(minX, node.position.dx);
      minY = min(minY, node.position.dy);
      maxX = max(maxX, node.position.dx + node.width);
      maxY = max(maxY, node.position.dy + node.height);
    }

    final treeWidth  = maxX - minX;
    final treeHeight = maxY - minY;

    // Scale down so the whole tree fits, with a small margin on each side
    const margin = 32.0;
    final scale = min(
      (viewWidth  - margin * 2) / treeWidth,
      (viewHeight - margin * 2) / treeHeight,
    ).clamp(0.01, 5.6);

    // Translate so the scaled tree is centred in the viewport
    final tx = (viewWidth  - treeWidth  * scale) / 2 - minX * scale;
    final ty = (viewHeight - treeHeight * scale) / 2 - minY * scale;

    _transformationController.value = Matrix4.identity()
      ..translateByDouble(tx, ty, 0, 1)
      ..scaleByDouble(scale, scale, 1, 1);

    _centered = true;
  }

  Future<void> _exportToPdf(String familyName) async {
    final boundary = _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;

    if (mounted) setState(() => _exporting = true);

    try {
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final pngBytes = byteData.buffer.asUint8List();

      final pdf = pw.Document();
      final pdfImage = pw.MemoryImage(pngBytes);
      pdf.addPage(pw.Page(
        pageFormat: PdfPageFormat(
          image.width.toDouble() + 80,
          image.height.toDouble() + 80,
          marginAll: 200,
        ),
        build: (pw.Context ctx) => pw.Image(pdfImage),
      ));

      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: '$familyName.pdf',
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);
    final familyName = settings.savedSettings.tabFamily;

    return FutureBuilder(future: buildGraph(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        // Show loading spinner while graph builds
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
        WidgetsBinding.instance.addPostFrameCallback((_) => _centerOnRoot(context));

        // For relation path results, offer three viewing modes: Tree, Path, List
        if (widget.isRelationPath) {
          final l10n = AppLocalizations.of(context)!;
          return DefaultTabController(
            length: 3,
            child: Scaffold(
              appBar: AppBar(
                bottom: TabBar(
                  tabs: [
                    Tab(icon: const Icon(Icons.account_tree_outlined), text: l10n.treeTabTree),
                    Tab(icon: const Icon(Icons.timeline_outlined), text: l10n.treeTabPath),
                    Tab(icon: const Icon(Icons.list_outlined), text: l10n.treeTabList),
                  ],
                ),
              ),
              body: TabBarView(
                children: [
                  _buildTreeTab(theme),
                  _buildPathTab(context),
                  _buildListTab(context),
                ],
              ),
            ),
          );
        }

        // Standard full family tree view with PDF export option
        return Scaffold(
          appBar: AppBar(
            title: Text(familyName, style: const TextStyle(fontFamily: 'Monadi')),
            centerTitle: true,
            actions: [
              IconButton(
                icon: _exporting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.picture_as_pdf_outlined),
                tooltip: 'Export as PDF',
                onPressed: _exporting ? null : () => _exportToPdf(familyName),
              ),
            ],
          ),
          body: Center(
            child: Column(mainAxisSize: MainAxisSize.max,
            children: [
              Expanded(
                child: _buildTreeTab(theme),
              ),
            ]),
          ),
        );
      }
    });
  }

  // Builds the interactive zoomable graph view, shared by both the full tree and the tree tab
  Widget _buildTreeTab(ThemeProvider theme) {
    return InteractiveViewer(
      transformationController: _transformationController,
      boundaryMargin: const EdgeInsets.all(double.infinity),
      constrained: false,
      minScale: 0.01,
      maxScale: 5.6,
      child: RepaintBoundary(
        key: _repaintKey,
        child: GraphView(
          graph: graph,
          algorithm: BuchheimWalkerAlgorithm(builder, TreeEdgeRenderer(builder)),
          paint: Paint()
            ..color = theme.getCurrentThemeMode(context) == 'dark'
                ? Colors.white
                : Colors.black
            ..strokeWidth = 2
            ..style = PaintingStyle.stroke,
          builder: (Node node) {
            var endNode = node.key!.value;
            return squareWidget(endNode);
          },
        ),
      ),
    );
  }

  // Returns the index of the common ancestor (LCA) in the path.
  // The LCA is the pivot point where the path transitions from ascending (going up to a parent)
  // to descending (going down to a child). Returns -1 if the path is entirely one direction
  // (i.e. one person is a direct ancestor of the other — no shared ancestor in between).
  int _findLcaIndex(List<Family> path) {
    for (int i = 0; i < path.length - 1; i++) {
      if (path[i + 1].parent == path[i].id) return i;
    }
    return -1;
  }

  // Returns a localized label describing the relationship from [above] to [below].
  // "is parent of" means above is the parent (descending), "is child of" means ascending.
  String _relationLabel(BuildContext context, Family above, Family below) {
    final l10n = AppLocalizations.of(context)!;
    if (below.parent == above.id) return l10n.relationIsParentOf;
    return l10n.relationIsChildOf;
  }

  // Builds a linear path view showing the chain between two people.
  // Each connector between cards shows the relationship direction ("is parent of" / "is child of").
  // The common ancestor is marked with a badge. Endpoints (A and B) are highlighted.
  Widget _buildPathTab(BuildContext context) {
    final path = _graphFamily!;
    final colorScheme = Theme.of(context).colorScheme;
    final lcaIndex = _findLcaIndex(path);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      itemCount: path.length * 2 - 1,
      itemBuilder: (context, index) {
        // Odd indices are relationship connectors between adjacent person cards
        if (index.isOdd) {
          final above = path[index ~/ 2];
          final below = path[index ~/ 2 + 1];
          final goingDown = below.parent == above.id;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  goingDown ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                  color: colorScheme.primary,
                  size: 18,
                ),
                // const SizedBox(width: 6),
                // Text(
                //   _relationLabel(context, above, below),
                //   style: TextStyle(color: colorScheme.primary, fontSize: 12),
                // ),
              ],
            ),
          );
        }

        final personIndex = index ~/ 2;
        final person = path[personIndex];
        final isEndpoint = personIndex == 0 || personIndex == path.length - 1;
        final isLca = personIndex == lcaIndex && lcaIndex > 0 && lcaIndex < path.length - 1;

        return Card(
          elevation: 0,
          color: isEndpoint
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: (person.imgUrl != null && person.imgUrl!.startsWith('http'))
                  ? NetworkImage(person.imgUrl!) as ImageProvider
                  : AssetImage(person.imgUrl ?? 'assets/profile.png'),
            ),
            title: Text(person.name ?? ''),
            // Show year and, for the LCA, a "Common Ancestor" badge
            subtitle: isLca
                ? Wrap(
                    spacing: 6,
                    children: [
                      if (person.yearBorn != null) Text('${person.yearBorn}'),
                      Chip(
                        label: Text(AppLocalizations.of(context)!.relationCommonAncestor, style: const TextStyle(fontSize: 10)),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        backgroundColor: colorScheme.secondaryContainer,
                      ),
                    ],
                  )
                : person.yearBorn != null
                    ? Text('${person.yearBorn}')
                    : null,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ProfileScreen(person: person)),
            ),
          ),
        );
      },
    );
  }

  // Builds a compact list of everyone on the relation path.
  // Separators between items show the relationship ("is parent of" / "is child of").
  // The common ancestor is labeled. Endpoints (A and B) are shown in bold.
  Widget _buildListTab(BuildContext context) {
    final path = _graphFamily!;
    final colorScheme = Theme.of(context).colorScheme;
    final lcaIndex = _findLcaIndex(path);

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: path.length,
      // Each separator shows how the person above relates to the person below
      separatorBuilder: (_, index) {
        if (index >= path.length - 1) return const SizedBox.shrink();
        final above = path[index];
        final below = path[index + 1];
        final goingDown = below.parent == above.id;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                goingDown ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                size: 14,
                color: colorScheme.outline,
              ),
              const SizedBox(width: 4),
              Text(
                _relationLabel(context, above, below),
                style: TextStyle(fontSize: 11, color: colorScheme.outline),
              ),
            ],
          ),
        );
      },
      itemBuilder: (context, index) {
        final person = path[index];
        final isEndpoint = index == 0 || index == path.length - 1;
        final isLca = index == lcaIndex && lcaIndex > 0 && lcaIndex < path.length - 1;
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: (person.imgUrl != null && person.imgUrl!.startsWith('http'))
                ? NetworkImage(person.imgUrl!) as ImageProvider
                : AssetImage(person.imgUrl ?? 'assets/profile.png'),
            backgroundColor: isEndpoint ? colorScheme.primaryContainer : null,
          ),
          title: Text(
            person.name ?? '',
            style: isEndpoint
                ? TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary)
                : null,
          ),
          // Show years and mark the common ancestor with a note
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (person.yearBorn != null)
                Text(person.yearDied != null
                    ? '${person.yearBorn} – ${person.yearDied}'
                    : '${person.yearBorn}'),
              if (isLca)
                Text(AppLocalizations.of(context)!.relationCommonAncestor,
                    style: TextStyle(fontSize: 11, color: colorScheme.secondary)),
            ],
          ),
          trailing: Icon(
            person.gender == 1 ? Icons.male : Icons.female,
            color: person.gender == 1 ? colorScheme.primary : colorScheme.tertiary,
          ),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ProfileScreen(person: person)),
          ),
        );
      },
    );
  }

  Widget squareWidget(Family person) {
    final theme = Provider.of<ThemeProvider>(context);
    Family? parent;
    int gender = person.gender!;

    if (person.parent != null) {
      parent = _storedFamily?.firstWhere((p) => p.id == person.parent);
    }

    return Consumer<SettingsProvider>(builder: (context, settings, child) {
      final colorScheme = Theme.of(context).colorScheme;
      final nodeColor = gender == 1 ? colorScheme.primaryContainer : colorScheme.tertiary;
      final onNodeColor = gender == 1 ? colorScheme.onPrimaryContainer : colorScheme.onTertiary;

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
              } else {
                break;
              }
            } else {
              break;
            }
          }
          fullName += ' ${person.familyName!}';

          final newPerson = person.copy();
          newPerson.name = fullName;

          // Navigate to person's profile page
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ProfileScreen(person: newPerson)),
          );
        },
        child: Container(
          padding: const EdgeInsets.fromLTRB(7, 7, 7, 20),
          decoration: BoxDecoration(
            shape: BoxShape.rectangle,
            border: Border.all(width: 1, color: colorScheme.outline),
            color: nodeColor,
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(50),
                decoration: BoxDecoration(
                  image: DecorationImage(
                    fit: BoxFit.fill,
                    image: (person.imgUrl != null && person.imgUrl!.startsWith('http'))
                        ? NetworkImage(person.imgUrl!) as ImageProvider
                        : AssetImage(person.imgUrl ?? 'assets/profile.png'),
                  ),
                  shape: BoxShape.rectangle,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  person.name!,
                  style: theme.treeNode(onNodeColor),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  // Graph settings
  final Graph graph = Graph()..isTree = true;
  BuchheimWalkerConfiguration builder = BuchheimWalkerConfiguration();

  Future buildGraph() async {
    setState(() {
      _storedFamily = DbServices.instance.storedFamily;
    });

    for (final person in _graphFamily!) {
      Family findFamily = _graphFamily!.firstWhere(
        (p) => p.id == person.parent,
        orElse: () => Family(id: -1),
      );
      if (findFamily.id != -1) {
        graph.addEdge(Node.Id(findFamily), Node.Id(person));
      }
    }

    return true;
  }
}
