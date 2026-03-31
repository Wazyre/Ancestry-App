import 'dart:convert';
import 'dart:io';

import 'package:ancestry_app/l10n/app_localizations.dart';
import 'package:ancestry_app/src/ui/mainMenu/db_services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

// ─── Editor screen ───────────────────────────────────────────────────────────

/// Full-screen WYSIWYG editor for the family biography.
///
/// Content is stored as Quill Delta JSON in the `biography` column of the
/// `families` Supabase table.  Images are uploaded to the `portraits` storage
/// bucket and embedded by their public URL.
class FamilyHistoryEditor extends StatefulWidget {
  final String familyName;

  /// Existing biography as a Quill Delta JSON string, or null if none yet.
  final String? initialContent;

  const FamilyHistoryEditor({
    super.key,
    required this.familyName,
    this.initialContent,
  });

  @override
  State<FamilyHistoryEditor> createState() => _FamilyHistoryEditorState();
}

class _FamilyHistoryEditorState extends State<FamilyHistoryEditor> {
  late QuillController _controller;
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = _buildController(widget.initialContent);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Build a QuillController from a stored Delta JSON string.
  // Falls back to inserting as plain text if the string is not valid JSON
  // (e.g. old plain-text or Markdown content in the database).
  QuillController _buildController(String? content) {
    if (content != null && content.trim().isNotEmpty) {
      try {
        final ops = jsonDecode(content) as List<dynamic>;
        return QuillController(
          document: Document.fromJson(ops),
          selection: const TextSelection.collapsed(offset: 0),
        );
      } catch (_) {
        // Legacy plain-text — wrap it in a new document
        final doc = Document()..insert(0, content);
        return QuillController(
          document: doc,
          selection: const TextSelection.collapsed(offset: 0),
        );
      }
    }
    return QuillController.basic();
  }

  // Upload image from device gallery to Supabase Storage and insert the
  // resulting public URL as an image embed at the current cursor position.
  Future<void> _insertImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result == null || result.files.single.path == null) return;

    final file = File(result.files.single.path!);
    try {
      final url = await DbServices.instance.uploadImage(file, bucket: 'historyImgs');
      if (url == null) return;
      final index = _controller.selection.baseOffset;
      final length = _controller.selection.extentOffset - index;
      _controller.replaceText(index, length, BlockEmbed.image(url), null);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image upload failed: $e')),
        );
      }
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final deltaJson = jsonEncode(_controller.document.toDelta().toJson());
    await DbServices.instance.updateFamilyBio(widget.familyName, deltaJson);
    if (mounted) {
      setState(() => _saving = false);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.familyName,
            style: const TextStyle(fontFamily: 'Monadi')),
        centerTitle: true,
        actions: [
          _saving
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.save_outlined),
                  tooltip: AppLocalizations.of(context)!.familyBioEditorSave,
                  onPressed: _save,
                ),
        ],
      ),
      body: Column(
        children: [
          // Formatting toolbar
          QuillSimpleToolbar(
            controller: _controller,
            config: QuillSimpleToolbarConfig(
              showAlignmentButtons: true,
              showDirection: true,
              showCodeBlock: false,
              showInlineCode: false,
              showSubscript: false,
              showSuperscript: false,
              showSmallButton: false,
              customButtons: [
                QuillToolbarCustomButtonOptions(
                  icon: const Icon(Icons.image_outlined),
                  tooltip: AppLocalizations.of(context)!.familyBioEditorInsertImage,
                  onPressed: _insertImage,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Editor area
          Expanded(
            child: QuillEditor(
              controller: _controller,
              focusNode: _focusNode,
              scrollController: _scrollController,
              config: QuillEditorConfig(
                padding: const EdgeInsets.all(20),
                embedBuilders: [const FamilyHistoryImageEmbedBuilder()],
                placeholder: AppLocalizations.of(context)!.familyBioEditorHint,
                scrollable: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Image embed builder ─────────────────────────────────────────────────────

/// Renders image embeds (inserted via [FamilyHistoryEditor._insertImage]) as
/// network images.  Used in both the editor and the read-only bio screen.
class FamilyHistoryImageEmbedBuilder extends EmbedBuilder {
  const FamilyHistoryImageEmbedBuilder();

  @override
  String get key => BlockEmbed.imageType;

  @override
  Widget build(BuildContext context, EmbedContext embedContext) {
    final url = embedContext.node.value.data.toString();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: url.startsWith('http')
            ? Image.network(
                url,
                fit: BoxFit.fitWidth,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.broken_image_outlined, size: 48),
              )
            : Image.file(File(url), fit: BoxFit.fitWidth),
      ),
    );
  }
}
