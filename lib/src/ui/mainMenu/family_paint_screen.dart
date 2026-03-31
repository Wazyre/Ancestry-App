import 'dart:math';

import 'package:ancestry_app/src/ui/base/settings_provider.dart';
import 'package:ancestry_app/src/ui/mainMenu/db_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

// ─── Screen ──────────────────────────────────────────────────────────────────

class FamilyPaintScreen extends StatefulWidget {
  const FamilyPaintScreen({super.key});

  @override
  State<FamilyPaintScreen> createState() => _FamilyPaintState();
}

class _FamilyPaintState extends State<FamilyPaintScreen> {
  List<Family>? familyList;

  @override
  Widget build(BuildContext context) {
    final settings    = Provider.of<SettingsProvider>(context);
    final familyName  = settings.savedSettings.tabFamily;

    return FutureBuilder(
      future: _grabFamily(familyName),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final ids  = familyList!.map((p) => p.id).toSet();
        final root = familyList!.firstWhere(
          (p) => p.parent == null || !ids.contains(p.parent),
        );

        return Scaffold(
          appBar: AppBar(
            title: Text(familyName,
                style: const TextStyle(fontFamily: 'Monadi')),
            centerTitle: true,
          ),
          body: FamilyTree(
              root: root, familyList: familyList!, familyName: familyName),
        );
      },
    );
  }

  Future _grabFamily(String familyName) async {
    if (familyName == '') return null;
    DbServices.instance.getFamily(familyName).then((value) {
      if (mounted) setState(() => familyList = value);
    });
    return familyList;
  }
}

// ─── Interactive viewer ───────────────────────────────────────────────────────

class FamilyTree extends StatelessWidget {
  final Family       root;
  final List<Family> familyList;
  final String       familyName;

  const FamilyTree({
    super.key,
    required this.root,
    required this.familyList,
    required this.familyName,
  });

  @override
  Widget build(BuildContext context) {
    final svg  = _TreeSvg(root: root, familyList: familyList, familyName: familyName);
    final size = svg.canvasSize;
    return InteractiveViewer(
      boundaryMargin: const EdgeInsets.all(300),
      constrained:    false,
      minScale: 0.01,
      maxScale: 6.0,
      child: SvgPicture.string(svg.build(), width: size.width, height: size.height),
    );
  }
}

// ─── SVG generator ───────────────────────────────────────────────────────────

class _TreeSvg {
  // ── Layout ────────────────────────────────────────────────────────────────
  static const double _hSlot      = 130.0; // horizontal space per leaf node
  static const double _vGap       = 115.0; // vertical gap between levels
  static const double _trunkH     =  95.0; // trunk height below root badge
  static const double _margin     =  60.0; // inner canvas margin
  static const double _grassH     =  52.0; // grass strip
  static const double _titleH     = 130.0; // space reserved for title band
  static const double _fi         =  22.0; // frame inset from canvas edge
  static const double _badgeRx    =  45.0; // name badge half-width
  static const double _badgeRy    =  17.5; // name badge half-height
  static const double _trunkBaseW =  56.0; // trunk width at ground
  static const double _maxBrW     =  17.0; // thickest branch stroke
  static const double _minBrW     =   2.5; // thinnest branch stroke

  final Family       root;
  final List<Family> familyList;
  final String       familyName;

  final Map<int, double> _subW = {};
  final Map<int, Offset>  _pos = {};

  _TreeSvg({
    required this.root,
    required this.familyList,
    required this.familyName,
  }) {
    _calcWidth(root);
  }

  // ── Two-pass layout ───────────────────────────────────────────────────────

  double _calcWidth(Family node) {
    final ch = _kids(node);
    if (ch.isEmpty) return _subW[node.id!] = _hSlot;
    double t = 0;
    for (final c in ch) { t += _calcWidth(c); }
    return _subW[node.id!] = t;
  }

  void _assignPos(Family node, double cx, double y) {
    _pos[node.id!] = Offset(cx, y);
    final ch = _kids(node);
    if (ch.isEmpty) return;
    double x = cx - _subW[node.id!]! / 2;
    for (final c in ch) {
      final w = _subW[c.id!]!;
      _assignPos(c, x + w / 2, y - _vGap);
      x += w;
    }
  }

  List<Family> _kids(Family n) =>
      familyList.where((p) => p.parent == n.id).toList();

  int _maxDepth(Family n) {
    final ch = _kids(n);
    if (ch.isEmpty) return 0;
    return 1 + ch.map(_maxDepth).reduce(max);
  }

  Size get canvasSize => Size(
        _subW[root.id!]! + _margin * 2,
        _maxDepth(root) * _vGap +
            _trunkH +
            _badgeRy * 2 +
            _grassH +
            _margin * 2 +
            _titleH,
      );

  double _branchW(int depth) =>
      (_maxBrW - depth * (_maxBrW - _minBrW) / 8).clamp(_minBrW, _maxBrW);

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _f(double d)   => d.toStringAsFixed(2);
  String _fi2(double d) => d.toStringAsFixed(1); // lighter precision for paths

  String _xml(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');

  // ── Entry point ───────────────────────────────────────────────────────────

  String build() {
    final size    = canvasSize;
    final w       = size.width;
    final h       = size.height;
    final rootCX  = w / 2;
    final groundY = h - _margin - _grassH;
    final rootY   = groundY - _trunkH;

    _assignPos(root, rootCX, rootY);

    final depth = _maxDepth(root);
    final topY  = (depth > 0) ? rootY - depth * _vGap : rootY - _vGap;

    // Canopy geometry
    final treeW        = _subW[root.id!]!;
    final canopyBottom = rootY   - _vGap * 0.18;
    final canopyTop    = topY    - _badgeRy * 2.5;
    final canoyCY      = (canopyBottom + canopyTop) / 2;
    final canopyH      = canopyBottom - canopyTop;
    final crx          = treeW * 0.96 / 2;
    final cry          = canopyH / 2;

    // Title vertical centre (within the top _titleH band)
    final titleCY = _fi + (_titleH * 0.52);

    final buf = StringBuffer();
    buf.write(
      '<svg xmlns="http://www.w3.org/2000/svg" '
      'width="${_f(w)}" height="${_f(h)}" '
      'viewBox="0 0 ${_f(w)} ${_f(h)}">',
    );

    _writeDefs(buf, rootCX, canoyCY, crx, cry, groundY, w, h);

    // ── Draw order: back → front ─────────────────────────────────────────

    // 1. Parchment background
    buf.write('<rect width="${_f(w)}" height="${_f(h)}" fill="url(#pgBg)"/>');

    // 2. Tree content clipped to inner frame rect (keeps tree inside the border)
    final clip = _fi + 14.0;
    buf.write(
      '<clipPath id="fc">'
      '<rect x="${_f(clip)}" y="${_f(clip)}" '
      'width="${_f(w - clip * 2)}" height="${_f(h - clip * 2)}"/>'
      '</clipPath>',
    );
    buf.write('<g clip-path="url(#fc)">');
    if (depth > 0) _writeCanopy(buf, rootCX, canoyCY, crx, cry);
    _writeTrunk(buf, rootCX, groundY, rootY);
    _writeGrass(buf, rootCX, groundY, w);
    _writeBranches(buf, root, 0);
    _writeNodes(buf, root, 0);
    buf.write('</g>');

    // 3. Decorative frame drawn on top (not clipped, overlaps tree edges)
    _writeFrame(buf, w, h);

    // 4. Title (inside frame, above tree)
    _writeTitle(buf, w, titleCY);

    buf.write('</svg>');
    return buf.toString();
  }

  // ── Gradients & filters ───────────────────────────────────────────────────

  void _writeDefs(StringBuffer buf,
      double cx, double canoyCY, double crx, double cry,
      double groundY, double w, double h) {
    buf.write('<defs>');

    // Parchment background — warm cream, darker at edges
    buf.write(
      '<radialGradient id="pgBg" cx="50%" cy="44%" r="72%" gradientUnits="objectBoundingBox">'
      '<stop offset="0%"   stop-color="#FFFDF5"/>'
      '<stop offset="55%"  stop-color="#FFF8E8"/>'
      '<stop offset="100%" stop-color="#EDD898"/>'
      '</radialGradient>',
    );

    // Canopy — radial gradient, light source upper-left
    buf.write(
      '<radialGradient id="cg" gradientUnits="userSpaceOnUse" '
      'cx="${_f(cx - crx * 0.20)}" cy="${_f(canoyCY - cry * 0.28)}" r="${_f(crx * 1.10)}">'
      '<stop offset="0%"   stop-color="#9CCC65"/>'
      '<stop offset="28%"  stop-color="#558B2F"/>'
      '<stop offset="65%"  stop-color="#2E7D32"/>'
      '<stop offset="100%" stop-color="#1B5E20"/>'
      '</radialGradient>',
    );

    // Trunk — horizontal gradient (dark sides, lighter centre)
    buf.write(
      '<linearGradient id="tg" gradientUnits="userSpaceOnUse" '
      'x1="${_f(cx - _trunkBaseW / 2)}" y1="0" '
      'x2="${_f(cx + _trunkBaseW / 2)}" y2="0">'
      '<stop offset="0%"   stop-color="#3E1F07"/>'
      '<stop offset="20%"  stop-color="#6D3B1A"/>'
      '<stop offset="50%"  stop-color="#8D5524"/>'
      '<stop offset="80%"  stop-color="#6D3B1A"/>'
      '<stop offset="100%" stop-color="#3E1F07"/>'
      '</linearGradient>',
    );

    // Badge fill — bright white → warm cream
    buf.write(
      '<radialGradient id="bg" cx="0.38" cy="0.30" r="0.72">'
      '<stop offset="0%"   stop-color="#FFFFFF"/>'
      '<stop offset="100%" stop-color="#FFF0C0"/>'
      '</radialGradient>',
    );

    // Root badge fill — gold gradient
    buf.write(
      '<radialGradient id="rbg" cx="0.32" cy="0.26" r="0.72">'
      '<stop offset="0%"   stop-color="#FFEE58"/>'
      '<stop offset="100%" stop-color="#FFB300"/>'
      '</radialGradient>',
    );

    // Grass — top-to-bottom dark green gradient
    buf.write(
      '<linearGradient id="gg" x1="0" y1="0" x2="0" y2="1">'
      '<stop offset="0%"   stop-color="#558B2F"/>'
      '<stop offset="100%" stop-color="#1B5E20"/>'
      '</linearGradient>',
    );

    // Leaf fill — bright centre fading to rich green at edges
    buf.write(
      '<radialGradient id="lfg" cx="0.38" cy="0.28" r="0.70">'
      '<stop offset="0%"   stop-color="#C5E1A5"/>'
      '<stop offset="55%"  stop-color="#66BB6A"/>'
      '<stop offset="100%" stop-color="#2E7D32"/>'
      '</radialGradient>',
    );

    // Drop shadow for badges
    buf.write(
      '<filter id="ds" x="-25%" y="-35%" width="155%" height="185%">'
      '<feDropShadow dx="2" dy="3" stdDeviation="3.5" '
      'flood-color="#000000" flood-opacity="0.22"/>'
      '</filter>',
    );

    buf.write('</defs>');
  }

  // ── Decorative frame ──────────────────────────────────────────────────────
  //
  // Triple-line gold border with corner medallions inspired by the reference.

  void _writeFrame(StringBuffer buf, double w, double h) {
    final i1 = _fi;
    final i2 = _fi + 8.0;
    final i3 = _fi + 14.0;

    // Three nested rectangles
    buf.write(
      '<rect x="${_f(i1)}" y="${_f(i1)}" '
      'width="${_f(w - i1 * 2)}" height="${_f(h - i1 * 2)}" '
      'fill="none" stroke="#C9820A" stroke-width="3.5"/>',
    );
    buf.write(
      '<rect x="${_f(i2)}" y="${_f(i2)}" '
      'width="${_f(w - i2 * 2)}" height="${_f(h - i2 * 2)}" '
      'fill="none" stroke="#C9820A" stroke-width="0.9"/>',
    );
    buf.write(
      '<rect x="${_f(i3)}" y="${_f(i3)}" '
      'width="${_f(w - i3 * 2)}" height="${_f(h - i3 * 2)}" '
      'fill="none" stroke="#C9820A" stroke-width="0.5"/>',
    );

    // Corner medallions at all four corners
    for (final c in [
      (_fi, _fi),
      (w - _fi, _fi),
      (_fi, h - _fi),
      (w - _fi, h - _fi),
    ]) {
      _writeCornerMedallion(buf, c.$1, c.$2);
    }

    // Side mid-point small diamond accents
    final midX = w / 2;
    final midY = h / 2;
    for (final pos in [
      (midX, _fi),          // top
      (midX, h - _fi),      // bottom
      (_fi, midY),          // left
      (w - _fi, midY),      // right
    ]) {
      _writeDiamond(buf, pos.$1, pos.$2, 6.0);
    }
  }

  void _writeCornerMedallion(StringBuffer buf, double cx, double cy) {
    // Concentric circles
    buf.write('<circle cx="${_f(cx)}" cy="${_f(cy)}" r="20" fill="#C9820A"/>');
    buf.write('<circle cx="${_f(cx)}" cy="${_f(cy)}" r="14" fill="#FFF9EC"/>');
    buf.write('<circle cx="${_f(cx)}" cy="${_f(cy)}" r="7"  fill="#C9820A"/>');
    buf.write('<circle cx="${_f(cx)}" cy="${_f(cy)}" r="3"  fill="#FFF9EC"/>');
    // 8 radiating lines (alternating thick/thin)
    for (int i = 0; i < 8; i++) {
      final a  = i * pi / 4;
      final x2 = cx + 28 * cos(a);
      final y2 = cy + 28 * sin(a);
      final sw = (i % 2 == 0) ? '2.0' : '1.2';
      buf.write(
        '<line x1="${_f(cx)}" y1="${_f(cy)}" x2="${_f(x2)}" y2="${_f(y2)}" '
        'stroke="#C9820A" stroke-width="$sw"/>',
      );
    }
    // Small diamonds at 4-axis tips
    for (int i = 0; i < 4; i++) {
      final a  = i * pi / 2;
      final dx = cx + 28 * cos(a);
      final dy = cy + 28 * sin(a);
      _writeDiamond(buf, dx, dy, 4.5);
    }
  }

  void _writeDiamond(StringBuffer buf, double cx, double cy, double r) {
    buf.write(
      '<polygon points="${_f(cx)},${_f(cy - r)} ${_f(cx + r)},${_f(cy)} '
      '${_f(cx)},${_f(cy + r)} ${_f(cx - r)},${_f(cy)}" fill="#C9820A"/>',
    );
  }

  // ── Title band ────────────────────────────────────────────────────────────
  //
  // Title "شجرة عائلة <name>" with arabesque-style decorative lines above
  // and a double-line divider below, mirroring the reference PDF layout.

  void _writeTitle(StringBuffer buf, double w, double titleCY) {
    final cx    = w / 2;
    final lineY = titleCY - 26.0; // decorative line above title text

    // ── Above-title ornamental line ───────────────────────────────────────
    buf.write(
      '<line x1="${_f(_fi + 28)}" y1="${_f(lineY)}" '
      'x2="${_f(cx - 115)}" y2="${_f(lineY)}" '
      'stroke="#C9820A" stroke-width="1.0"/>',
    );
    buf.write(
      '<line x1="${_f(cx + 115)}" y1="${_f(lineY)}" '
      'x2="${_f(w - _fi - 28)}" y2="${_f(lineY)}" '
      'stroke="#C9820A" stroke-width="1.0"/>',
    );

    // Small diamonds along the ornamental line
    for (final dx in [-80.0, -45.0, 45.0, 80.0]) {
      _writeDiamond(buf, cx + dx, lineY, 4.0);
    }

    // Central rosette where the two lines meet
    buf.write('<circle cx="${_f(cx)}" cy="${_f(lineY)}" r="10" fill="#C9820A"/>');
    buf.write('<circle cx="${_f(cx)}" cy="${_f(lineY)}" r="6.5" fill="#FFF9EC"/>');
    buf.write('<circle cx="${_f(cx)}" cy="${_f(lineY)}" r="3" fill="#C9820A"/>');

    // ── Title text ────────────────────────────────────────────────────────
    final title = _xml('شجرة عائلة $familyName');
    buf.write(
      '<text x="${_f(cx)}" y="${_f(titleCY)}" dy="0.35em" '
      'text-anchor="middle" direction="rtl" '
      'font-size="32" font-weight="bold" fill="#5D3A1A" '
      'font-family="Monadi,Traditional Arabic,serif">$title</text>',
    );

    // ── Below-title double divider ────────────────────────────────────────
    final d1 = titleCY + 34.0;
    final d2 = d1 + 5.0;
    final lx1 = _fi + 28.0;
    final lx2 = w - _fi - 28.0;

    buf.write(
      '<line x1="${_f(lx1)}" y1="${_f(d1)}" x2="${_f(lx2)}" y2="${_f(d1)}" '
      'stroke="#C9820A" stroke-width="1.3"/>',
    );
    buf.write(
      '<line x1="${_f(lx1)}" y1="${_f(d2)}" x2="${_f(lx2)}" y2="${_f(d2)}" '
      'stroke="#C9820A" stroke-width="0.6"/>',
    );

    // Central diamond on the divider
    _writeDiamond(buf, cx, (d1 + d2) / 2, 6.5);
  }

  // ── Canopy ────────────────────────────────────────────────────────────────
  //
  // Outer dark rim → N perimeter lump circles (organic bumpy silhouette) →
  // main gradient-filled ellipse → inner highlight.

  void _writeCanopy(
      StringBuffer buf, double cx, double canoyCY, double crx, double cry) {
    // Dark outer rim — casts the edge in shadow
    buf.write(
      '<ellipse cx="${_f(cx)}" cy="${_f(canoyCY)}" '
      'rx="${_f(crx * 1.13)}" ry="${_f(cry * 1.11)}" '
      'fill="#1A4A0D" opacity="0.55"/>',
    );

    // Perimeter lump circles — scale count with tree width for coverage
    final int n = max(14, min(32, (crx / 35).round()));
    for (int i = 0; i < n; i++) {
      final a    = (2 * pi * i / n) - pi / 2;
      final vary = 0.76 + 0.30 * sin(a * 2.8 + 0.9);
      final lr   = crx * sin(pi / n) * 1.35 * vary;
      final lx   = cx      + crx * 0.89 * cos(a);
      final ly   = canoyCY + cry * 0.91 * sin(a);
      buf.write(
        '<circle cx="${_f(lx)}" cy="${_f(ly)}" r="${_f(lr)}" fill="#2E7D32"/>',
      );
    }

    // Secondary inner lump layer — fills gaps between outer lumps
    final int n2 = max(10, min(22, (crx / 55).round()));
    for (int i = 0; i < n2; i++) {
      final a    = (2 * pi * i / n2) - pi / 2 + pi / n2; // offset by half step
      final vary = 0.70 + 0.25 * sin(a * 3.1 + 1.5);
      final lr   = crx * sin(pi / n2) * 0.95 * vary;
      final lx   = cx      + crx * 0.68 * cos(a);
      final ly   = canoyCY + cry * 0.70 * sin(a);
      buf.write(
        '<circle cx="${_f(lx)}" cy="${_f(ly)}" r="${_f(lr)}" fill="#338A35"/>',
      );
    }

    // Main body ellipse with radial gradient
    buf.write(
      '<ellipse cx="${_f(cx)}" cy="${_f(canoyCY)}" '
      'rx="${_f(crx)}" ry="${_f(cry)}" fill="url(#cg)"/>',
    );

    // Upper-left highlight blob
    buf.write(
      '<ellipse cx="${_f(cx - crx * 0.16)}" cy="${_f(canoyCY - cry * 0.20)}" '
      'rx="${_f(crx * 0.48)}" ry="${_f(cry * 0.44)}" '
      'fill="#AED581" opacity="0.18"/>',
    );
  }

  // ── Trunk ─────────────────────────────────────────────────────────────────

  void _writeTrunk(StringBuffer buf, double cx, double groundY, double rootY) {
    final bw  = _trunkBaseW;
    final tw  = _branchW(0) * 2 + 8.0;
    final mid = (groundY + rootY) / 2;

    // Main trunk body (slightly curved sides)
    final d =
        'M ${_fi2(cx - bw / 2)} ${_fi2(groundY)} '
        'Q ${_fi2(cx - bw / 2 + 6)} ${_fi2(mid)} ${_fi2(cx - tw / 2)} ${_fi2(rootY)} '
        'L ${_fi2(cx + tw / 2)} ${_fi2(rootY)} '
        'Q ${_fi2(cx + bw / 2 - 6)} ${_fi2(mid)} ${_fi2(cx + bw / 2)} ${_fi2(groundY)} Z';
    buf.write('<path d="$d" fill="url(#tg)"/>');

    // Vertical bark grain lines
    for (final i in [-1, 0, 1]) {
      buf.write(
        '<line x1="${_f(cx + i * bw / 4.0)}" y1="${_f(groundY - 2)}" '
        'x2="${_f(cx + i * tw / 4.0)}" y2="${_f(rootY + 3)}" '
        'stroke="#3E1F07" stroke-width="1.2" stroke-opacity="0.35" '
        'stroke-linecap="round"/>',
      );
    }

    // Gold dots along the trunk (representing the ancestral lineage,
    // as seen in the reference PDF)
    final steps = 3;
    for (int i = 1; i <= steps; i++) {
      final t  = i / (steps + 1);
      final dy = groundY - t * (groundY - rootY);
      final r  = 7.0 - i * 0.8; // shrinks toward root
      buf.write('<circle cx="${_f(cx)}" cy="${_f(dy)}" r="${_f(r)}" fill="#C9820A"/>');
      buf.write('<circle cx="${_f(cx)}" cy="${_f(dy)}" r="${_f(r - 3)}" fill="#FFF9EC"/>');
    }
  }

  // ── Grass ─────────────────────────────────────────────────────────────────

  void _writeGrass(StringBuffer buf, double cx, double groundY, double w) {
    // Base strip
    buf.write(
      '<rect x="0" y="${_f(groundY)}" '
      'width="${_f(w)}" height="${_f(_grassH)}" fill="url(#gg)"/>',
    );

    // Rounded hillock under the trunk
    final hw = _trunkBaseW * 2.8;
    buf.write(
      '<path d="M ${_f(cx - hw)} ${_f(groundY)} '
      'Q ${_f(cx)} ${_f(groundY - 26)} ${_f(cx + hw)} ${_f(groundY)} Z" '
      'fill="#558B2F"/>',
    );

    // Grass tuft clusters
    for (final dx in [-65.0, -40.0, -15.0, 10.0, 35.0, 60.0, 85.0]) {
      final bx = cx + dx;
      final by = groundY;
      buf.write(
        '<line x1="${_f(bx - 3)}" y1="${_f(by)}" '
        'x2="${_f(bx - 6)}" y2="${_f(by - 11)}" '
        'stroke="#8BC34A" stroke-width="2.1" stroke-linecap="round"/>'
        '<line x1="${_f(bx)}" y1="${_f(by)}" '
        'x2="${_f(bx)}" y2="${_f(by - 14)}" '
        'stroke="#8BC34A" stroke-width="2.1" stroke-linecap="round"/>'
        '<line x1="${_f(bx + 3)}" y1="${_f(by)}" '
        'x2="${_f(bx + 6)}" y2="${_f(by - 11)}" '
        'stroke="#8BC34A" stroke-width="2.1" stroke-linecap="round"/>',
      );
    }
  }

  // ── Branches ─────────────────────────────────────────────────────────────

  void _writeBranches(StringBuffer buf, Family node, int depth) {
    final from = _pos[node.id!]!;
    for (final child in _kids(node)) {
      final to  = _pos[child.id!]!;
      // Smooth S-curve
      final cp1 = Offset(from.dx, from.dy - (from.dy - to.dy) * 0.38);
      final cp2 = Offset(to.dx,   from.dy - (from.dy - to.dy) * 0.62);
      buf.write(
        '<path d="M ${_fi2(from.dx)} ${_fi2(from.dy)} '
        'C ${_fi2(cp1.dx)} ${_fi2(cp1.dy)} '
        '${_fi2(cp2.dx)} ${_fi2(cp2.dy)} '
        '${_fi2(to.dx)} ${_fi2(to.dy)}" '
        'stroke="#6D4C41" stroke-width="${_f(_branchW(depth + 1))}" '
        'fill="none" stroke-linecap="round"/>',
      );
      _writeBranches(buf, child, depth + 1);
    }
  }

  // ── Nodes ─────────────────────────────────────────────────────────────────

  void _writeNodes(StringBuffer buf, Family node, int depth) {
    final ch = _kids(node);
    if (ch.isEmpty) {
      _writeLeaf(buf, _pos[node.id!]!, node.name ?? '');
    } else {
      _writeBadge(buf, _pos[node.id!]!, node.name ?? '', isRoot: depth == 0);
    }
    for (final c in ch) {
      _writeNodes(buf, c, depth + 1);
    }
  }

  // ── Badge — oval name plate ───────────────────────────────────────────────
  //
  // Cream fill + double gold border, mirroring the small oval medallions
  // throughout the reference tree.  Root badge is larger and gold-filled.

  void _writeBadge(StringBuffer buf, Offset c, String name,
      {bool isRoot = false}) {
    final rx   = isRoot ? _badgeRx * 1.30 : _badgeRx;
    final ry   = isRoot ? _badgeRy * 1.50 : _badgeRy;
    final fill = isRoot ? 'url(#rbg)' : 'url(#bg)';
    final bc   = isRoot ? '#B84500' : '#C9820A';   // border colour
    final bw   = isRoot ? 2.8       : 1.8;          // border stroke width
    final fs   = isRoot ? 12.0      : 9.5;          // font size

    // Drop-shadow group
    buf.write('<g filter="url(#ds)">');

    // Fill
    buf.write(
      '<ellipse cx="${_f(c.dx)}" cy="${_f(c.dy)}" '
      'rx="${_f(rx)}" ry="${_f(ry)}" fill="$fill"/>',
    );

    // Outer gold border
    buf.write(
      '<ellipse cx="${_f(c.dx)}" cy="${_f(c.dy)}" '
      'rx="${_f(rx)}" ry="${_f(ry)}" '
      'fill="none" stroke="$bc" stroke-width="${_f(bw)}"/>',
    );

    // Inner gold border (double-line effect matching the reference)
    buf.write(
      '<ellipse cx="${_f(c.dx)}" cy="${_f(c.dy)}" '
      'rx="${_f(rx - 4.5)}" ry="${_f(ry - 4.0)}" '
      'fill="none" stroke="$bc" stroke-width="0.75" stroke-opacity="0.40"/>',
    );

    buf.write('</g>');

    // Name text — centred inside the badge
    buf.write(
      '<text x="${_f(c.dx)}" y="${_f(c.dy)}" dy="${_f(fs * 0.35)}" '
      'text-anchor="middle" '
      'font-size="${_f(fs)}" font-weight="bold" fill="#3E2723" '
      'font-family="sans-serif">${_xml(name)}</text>',
    );
  }

  // ── Leaf — pointed-ellipse shape for terminal (childless) nodes ───────────
  //
  // Drawn rotated –30° to mimic a natural leaf hanging from a twig.
  // Layers: drop shadow → body → highlight streak → central vein → side veins
  // → name text (white, rotated with the leaf).

  void _writeLeaf(StringBuffer buf, Offset c, String name) {
    const lw = 19.0; // half-width  (full width  38 px)
    const lh = 30.0; // half-height (full height 60 px)
    const fs = 8.5;  // font size

    final cx = _f(c.dx);
    final cy = _f(c.dy);

    // Rotate the whole leaf group –30° around its centre
    buf.write('<g transform="rotate(-30, $cx, $cy)">');

    // Drop shadow (offset ellipse, not filtered, for reliability)
    buf.write(
      '<path d="M ${_f(c.dx)} ${_f(c.dy - lh)} '
      'Q ${_f(c.dx + lw)} ${_f(c.dy)} ${_f(c.dx)} ${_f(c.dy + lh)} '
      'Q ${_f(c.dx - lw)} ${_f(c.dy)} ${_f(c.dx)} ${_f(c.dy - lh)} Z" '
      'fill="#000000" opacity="0.18" '
      'transform="translate(2,3)"/>',
    );

    // Leaf body — pointed ellipse with gradient fill + dark green stroke
    buf.write(
      '<path d="M ${_f(c.dx)} ${_f(c.dy - lh)} '
      'Q ${_f(c.dx + lw)} ${_f(c.dy)} ${_f(c.dx)} ${_f(c.dy + lh)} '
      'Q ${_f(c.dx - lw)} ${_f(c.dy)} ${_f(c.dx)} ${_f(c.dy - lh)} Z" '
      'fill="url(#lfg)" stroke="#2E7D32" stroke-width="0.9"/>',
    );

    // Right-lobe highlight streak
    buf.write(
      '<path d="M ${_f(c.dx)} ${_f(c.dy - lh)} '
      'Q ${_f(c.dx + lw * 0.55)} ${_f(c.dy - lh * 0.08)} '
      '${_f(c.dx)} ${_f(c.dy + lh * 0.12)}" '
      'fill="none" stroke="#C5E1A5" stroke-width="2.0" stroke-opacity="0.55"/>',
    );

    // Central vein
    buf.write(
      '<line x1="${_f(c.dx)}" y1="${_f(c.dy - lh + 4)}" '
      'x2="${_f(c.dx)}" y2="${_f(c.dy + lh - 4)}" '
      'stroke="#1B5E20" stroke-width="1.0"/>',
    );

    // Side veins (3 pairs, growing upward from the midrib)
    for (int i = 1; i <= 3; i++) {
      final vy  = c.dy - lh * 0.10 * i;
      final vxR = c.dx + lw * 0.52 * (1 - i * 0.18);
      final vxL = c.dx - lw * 0.52 * (1 - i * 0.18);
      buf.write(
        '<line x1="${_f(c.dx)}" y1="${_f(vy)}" '
        'x2="${_f(vxR)}" y2="${_f(vy - 7)}" '
        'stroke="#1B5E20" stroke-width="0.65"/>'
        '<line x1="${_f(c.dx)}" y1="${_f(vy)}" '
        'x2="${_f(vxL)}" y2="${_f(vy - 7)}" '
        'stroke="#1B5E20" stroke-width="0.65"/>',
      );
    }

    // Name — white text centred in the leaf, rotated with it
    buf.write(
      '<text x="$cx" y="${_f(c.dy)}" dy="${_f(fs * 0.35)}" '
      'text-anchor="middle" '
      'font-size="${_f(fs)}" font-weight="bold" fill="#FFFFFF" '
      'font-family="sans-serif"'
      ' paint-order="stroke" stroke="#1B5E20" stroke-width="2.5"'
      ' stroke-linejoin="round">'
      '${_xml(name)}</text>',
    );

    buf.write('</g>');
  }
}
