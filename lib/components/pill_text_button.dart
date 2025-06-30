import 'package:flutter/material.dart';

// GENERATED USING CHATGPT 
class PillButton extends StatelessWidget {
  final String label;

  final bool selected;

  final VoidCallback onPressed;

  final Color activeColor;
  final Color inactiveColor;
  final Color activeTextColor;
  final Color inactiveTextColor;

  const PillButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onPressed,
    this.activeColor = Colors.white,
    this.inactiveColor = const Color(0xFFE0E0E0),
    this.activeTextColor = Colors.black,
    this.inactiveTextColor = Colors.black54,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextButton(
        style: TextButton.styleFrom(
          backgroundColor: selected ? activeColor : inactiveColor,
          shape: const StadiumBorder(),           // pill shape
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 12,
          ),
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? activeTextColor : inactiveTextColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
