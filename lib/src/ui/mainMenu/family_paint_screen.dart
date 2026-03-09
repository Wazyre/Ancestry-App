import 'package:ancestry_app/src/ui/base/settings_provider.dart';
import 'package:ancestry_app/src/ui/mainMenu/db_services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';

class FamilyPaintScreen extends StatefulWidget {
  const FamilyPaintScreen({super.key});


  @override
  State<FamilyPaintScreen> createState() => _FamilyPaintState();
}

class _FamilyPaintState extends State<FamilyPaintScreen> {
  List<Family>? familyList;

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final familyName = settings.savedSettings.tabFamily;

    return FutureBuilder(future: grabFamily(familyName), 
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
          appBar: AppBar(),
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.max, 
              children: [
                FamilyTree(root: familyList![0], familyList: familyList!),
              ],
            ),
          )
        );
      }
    });
  }

  Future grabFamily(String familyName) async {
    if (familyName == '') {
      return null;
    }

    DbServices.instance.getFamily(familyName).then((value) {
      setState(() {
        familyList = value;
      });
    });
    return familyList;
  }
}

class FamilyTree extends StatelessWidget {
  final Family root;
  final List<Family> familyList;
  
  const FamilyTree({super.key, required this.root, required this.familyList});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InteractiveViewer(
        boundaryMargin: const EdgeInsets.all(100),
        constrained: false,
        minScale: 0.01,
        maxScale: 5.6,
        child: CustomPaint(
          size: Size(1080, 1920), // TODO surround with interactive viewer
          painter: TreePainter(root: root, familyList: familyList),
        ),
      ),
    );
  }
}

class TreePainter extends CustomPainter {
  final Family root;
  final List<Family> familyList;
  final Map<Family, Offset> positions = {};
  final double textPadding = 20; // Padding around text to prevent collisions
  final double horizontalSpacing = 100; // Base horizontal spacing
  final double verticalSpacing = 80; // Base vertical spacing
  final double maxTrunkWidth = 70; // Maximum trunk width at the root
  final double minTrunkWidth = 5; // Minimum trunk width at the deepest level

  TreePainter({required this.root, required this.familyList});
  
  @override
  void paint(Canvas canvas, Size size) {
    _calculatePositions(root, size.width / 2, 50, 0);
    _drawTree(canvas, root, 0);
  }

  double _calculatePositions(Family person, double x, double y, int depth) {
     // Calculate the width required for this node's text
    final textPainter = _createTextPainter(person.name!);
    final nodeWidth = textPainter.width + textPadding * 2;

    // Store the position of this node
    positions[person] = Offset(x, y);

    List<Family> children = familyList.where((p) => p.parent == person.id).toList();
    if (children.isEmpty) {

      // If this node has no children, return its width
      return nodeWidth;
    } else {
      // Calculate the total width required for all children
      double totalChildrenWidth = 0;
      final List<double> childWidths = [];

      for (var child in children) {
        final childWidth = _calculatePositions(
          child,
          x + totalChildrenWidth,
          y + verticalSpacing,
          depth + 1,
        );
        childWidths.add(childWidth);
        totalChildrenWidth += childWidth;
      }

      // Center the parent node above its children
      final double childrenCenter = x + totalChildrenWidth / 2;
      positions[person] = Offset(childrenCenter - nodeWidth / 2, y);

      // Adjust child positions to center them under the parent
      double childX = childrenCenter - totalChildrenWidth / 2;
      for (int i = 0; i < children.length; i++) {
        final child = children[i];
        final childWidth = childWidths[i];
        positions[child] =
            Offset(childX + childWidth / 2 - textPadding, y + verticalSpacing);
        childX += childWidth;
      }

      // Return the total width of this subtree
      return totalChildrenWidth;
    }
  }

  void _drawTree(Canvas canvas, Family person, int depth) {
    // final paint = Paint()
    //   ..color = Colors.brown
    //   ..strokeWidth = 3
    //   ..style = PaintingStyle.stroke;

    // final textPainter = TextPainter(
    //   text: TextSpan(
    //     text: person.name,
    //     style: TextStyle(color: Colors.black, fontSize: 16),
    //   ),
    //   textDirection: TextDirection.ltr,
    // );
    // textPainter.layout();

    final textPainter = _createTextPainter(person.name!);
    final offset = positions[person]!;
    // textPainter.paint(canvas, Offset(offset.dx - textPainter.width / 2, offset.dy - 10));

    List<Family> children = familyList.where((p) => p.parent == person.id).toList();

    if (children.isNotEmpty) {

      // Draw the trunk from the parent to the midpoint of its children
      final double trunkWidth = _calculateTrunkWidth(depth);
      final Paint trunkPaint = Paint()
        ..color = Colors.brown
        ..strokeWidth = trunkWidth
        ..style = PaintingStyle.stroke;

      // Calculate the midpoint of the children
      double minChildX = double.infinity;
      double maxChildX = -double.infinity;
      for (var child in children) {
        final childOffset = positions[child]!;
        if (childOffset.dx < minChildX) minChildX = childOffset.dx;
        if (childOffset.dx > maxChildX) maxChildX = childOffset.dx;
      }
      final double childrenMidX = (minChildX + maxChildX) / 2;

      // Draw the trunk from the parent to the midpoint of its children
      final Path trunkPath = Path();
      trunkPath.moveTo(offset.dx, offset.dy);
      trunkPath.lineTo(childrenMidX, offset.dy + verticalSpacing / 2);
      canvas.drawPath(trunkPath, trunkPaint);

      for (var child in children) {
        final childOffset = positions[child]!;
        _drawCurvedBranch(canvas, offset, childOffset, depth);
        _drawTree(canvas, child, depth + 1);
        // Draw the name for nodes with children
        textPainter.paint(
            canvas, Offset(offset.dx - textPainter.width / 2, offset.dy - 10));
      }
    }
    else {
      // Draw the leaf first
      _drawLeaf(canvas, offset);
      // Draw the name on top of the leaf
      textPainter.paint(
          canvas, Offset(offset.dx - textPainter.width / 2, offset.dy - 10));
      _drawRotatedText(canvas, person.name!, offset);
    }
  }

  void _drawCurvedBranch(Canvas canvas, Offset start, Offset end, int depth) {
    final paint = Paint()
      ..color = Colors.brown
      ..strokeWidth =  _calculateTrunkWidth(depth+1) // Adjust trunk width based on depth
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(start.dx, start.dy);

    // Create a curved path
    final controlPoint =
        Offset((start.dx + end.dx) / 2, start.dy + (end.dy - start.dy) / 2);
    path.quadraticBezierTo(controlPoint.dx, controlPoint.dy, end.dx, end.dy);

    canvas.drawPath(path, paint);

    // // Draw a thicker base at the start of the branch to connect to the parent
    // final basePaint = Paint()
    //   ..color = Colors.brown
    //   ..strokeWidth =
    //       _calculateTrunkWidth(depth - 1) // Use parent's trunk width
    //   ..style = PaintingStyle.stroke;

    // canvas.drawLine(start, controlPoint, basePaint);
  }
  
  void _drawLeaf(Canvas canvas, Offset position) {
    final paint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.fill;

    // Define a leaf shape using a Path
    final leafPath = Path();
    leafPath.moveTo(position.dx, position.dy);
    leafPath.quadraticBezierTo(
      position.dx + 20,
      position.dy - 30,
      position.dx + 40,
      position.dy,
    );
    leafPath.quadraticBezierTo(
      position.dx + 20,
      position.dy + 30,
      position.dx,
      position.dy,
    );
    leafPath.close();

    canvas.drawPath(leafPath, paint);
  }

  void _drawRotatedText(Canvas canvas, String text, Offset position) {
    final textPainter = _createTextPainter(text);
    final angle = -pi / 4; // Rotate text by 45 degrees

    // Save the canvas state
    canvas.save();
    // Translate to the position of the leaf
    canvas.translate(position.dx, position.dy);
    // Rotate the canvas
    canvas.rotate(angle);
    // Draw the text at the translated and rotated position
    textPainter.paint(
        canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
    // Restore the canvas state
    canvas.restore();
  }

  double _calculateTrunkWidth(int depth) {
    // Calculate trunk width based on depth
    // The trunk gets thinner as depth increases
    return maxTrunkWidth -
        (depth * (maxTrunkWidth - minTrunkWidth) / 5)
            .clamp(minTrunkWidth, maxTrunkWidth);
  }

  TextPainter _createTextPainter(String text) {
    return TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: Colors.black, fontSize: 16),
      ),
      textDirection: TextDirection.rtl,
    )..layout();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}