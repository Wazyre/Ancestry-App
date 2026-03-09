import 'package:ancestry_app/src/ui/mainMenu/db_services.dart';
import 'package:flutter/material.dart';

class PhotoBasedAvatar extends StatelessWidget {
  final Family? person;

  const PhotoBasedAvatar({super.key, required this.person});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(50),
          decoration: BoxDecoration(
            image: DecorationImage(
              fit: BoxFit.fill,
              image: AssetImage(person?.imgUrl ?? 'images/ahm.png'),
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
                color: person?.gender == 1 ? Colors.black : Colors.white),
          ),
        )
      ],
    );
  }
}