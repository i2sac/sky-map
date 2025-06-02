import 'package:flutter/material.dart';

class RotatedText extends StatelessWidget {
  final String text;
  final double x;
  final double y;
  final double rotation;
  final VoidCallback onTap;

  const RotatedText({
    required this.text,
    required this.x,
    required this.y,
    required this.rotation,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: x,
      top: y,
      child: Transform.rotate(
        angle: -rotation, // Contre-rotation pour maintenir le texte vertical
        child: GestureDetector(
          onTap: onTap,
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}