import 'package:flutter/material.dart';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';

class EnlargedImage extends StatelessWidget {
  EnlargedImage(this.imagePath, this.isFirebaseImage);

  final String imagePath;
  final bool isFirebaseImage;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        child: Center(
          child: isFirebaseImage
              ? CachedNetworkImage(
                  imageUrl: imagePath == ""
                      ? 'https://picsum.photos/250?image=9'
                      : imagePath,
                  errorWidget: (context, url, error) => Icon(Icons.error),
                )
              : Hero(
                  tag: 'ImagePreview',
                  child: Image.file(File(imagePath)),
                ),
        ),
        onTap: () {
          Navigator.pop(context);
        },
      ),
    );
  }
}
