import 'package:flutter/material.dart';

Widget buildCircleButton({
  required IconData icon,
  required VoidCallback onPressed,
  Color backgroundColor = Colors.blue,
  double size = 56,
}) {
  return RawMaterialButton(
    onPressed: onPressed,
    constraints: BoxConstraints.tightFor(
      width: size,
      height: size,
    ),
    shape: CircleBorder(),
    fillColor: backgroundColor,
    elevation: 2,
    child: Icon(icon, color: Colors.white),
  );
}
