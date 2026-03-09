import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ImageFormField extends StatelessWidget {

  final String? Function(File?) validator;
  final Function(File) onChanged;

  const ImageFormField({super.key, required this.validator, required this.onChanged});
  
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
        return OutlinedButton.icon(
          
          icon: Icon(Icons.image_outlined),
          label: Text(AppLocalizations.of(context)!.adminFormImageUpload ),
        
          onPressed: () async {
            FilePickerResult? file = await FilePicker.platform
                .pickFiles(type: FileType.image);
            if (file != null) {
              File pickedFile = File(file.files.first.path!);
              onChanged.call(pickedFile);
            }
          },
        );
                  
      }
    );
  }

}