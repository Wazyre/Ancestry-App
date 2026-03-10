import 'package:ancestry_app/src/ui/mainMenu/db_services.dart';
import 'package:flutter/material.dart';

class PhotoBasedAvatar extends StatelessWidget {
  final Family? person;
  final bool genderColor;

  const PhotoBasedAvatar({super.key, required this.person, required this.genderColor});

  static ImageProvider _imageFor(String? url) {
    if (url != null && url.startsWith('http')) return NetworkImage(url);
    return AssetImage(url ?? 'assets/profile.png');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(50),
          decoration: BoxDecoration(
            image: DecorationImage(
              fit: BoxFit.fill,
              image: _imageFor(person?.imgUrl),
            ),
            shape: BoxShape.rectangle,
            border: Border.all(width: 1, color: Colors.black),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Text(
            person?.name! ?? '',
            style: TextStyle(
                color: person?.gender == 0 && genderColor ? Colors.white : Colors.black),
          ),
        )
      ],
    );
  }
}