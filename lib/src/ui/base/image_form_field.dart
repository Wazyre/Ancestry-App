import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:ancestry_app/l10n/app_localizations.dart';

class ImageFormField extends StatelessWidget {

  final String? Function(File?) validator;
  final Function(File) onChanged;

  const ImageFormField({super.key, required this.validator, required this.onChanged});

  Future<void> _pickFromGallery(BuildContext context) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null) {
      onChanged.call(File(result.files.first.path!));
    }
  }

  Future<void> _pickFromCamera(BuildContext context) async {
    final XFile? photo = await ImagePicker().pickImage(source: ImageSource.camera);
    if (photo != null) {
      onChanged.call(File(photo.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormField<File>(
      validator: validator,
      builder: (formFieldState) {
        if (formFieldState.hasError) {
          return Padding(
            padding: const EdgeInsets.only(left: 8, top: 10),
            child: Text(
              formFieldState.errorText!,
              style: TextStyle(
                  fontStyle: FontStyle.normal,
                  fontSize: 13,
                  color: Colors.red[700],
                  height: 0.5),
            ),
          );
        }
        return Row(
          children: [
            OutlinedButton.icon(
              icon: const Icon(Icons.image_outlined),
              label: Text(AppLocalizations.of(context)!.adminFormImageUpload),
              onPressed: () => _pickFromGallery(context),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.camera_alt_outlined),
              label: Text(AppLocalizations.of(context)!.adminFormImageCamera),
              onPressed: () => _pickFromCamera(context),
            ),
          ],
        );
      }
    );
  }

}
