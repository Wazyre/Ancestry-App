import 'package:flutter/material.dart';

class ImagePopup extends StatelessWidget {
  final String? imgUrl;

  const ImagePopup({super.key, required this.imgUrl});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: InteractiveViewer(
        // boundaryMargin: EdgeInsets.all(80),
        minScale: 1.0,
        maxScale: 4.0,
        child: Container(
          width: 400,
          height: 400,
          decoration: BoxDecoration(
              image: DecorationImage(
                  image: (imgUrl != null && imgUrl!.startsWith('http'))
                      ? NetworkImage(imgUrl!) as ImageProvider
                      : AssetImage(imgUrl ?? 'assets/profile.png'),
                  fit: BoxFit.cover)),
        ),
      ),
    );
  }
}
