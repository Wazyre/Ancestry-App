// import 'package:flutter/material.dart';

// class RadioListFormField extends FormField<bool> {

//   RadioListFormField({super.key, 
//     required FormFieldSetter<bool> onSaved,
//     required FormFieldValidator<bool> validator,
//     bool initialValue = false,
//   }) : super(
//     onSaved: onSaved,
//     validator: validator,
//     builder: (FormFieldState<bool> state) {
//       return Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text('Where is occurrence happened?'),
//           state.hasError
//             ? Text(
//                 state.errorText,
//                 style: TextStyle(color: Colors.red),
//               )
//             : Container(),
//             RadioListTile(value: 0, groupValue: groupValue, onChanged: onChanged)
//         ]
//       );
//     }
//   );
// }