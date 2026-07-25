
import 'package:flutter/material.dart';

class CircleIconActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color backgroundColor;
  final Color borderColor;
  final VoidCallback? onTap;
  final bool expanded;
  final bool isLoading;

  const CircleIconActionButton({
    required this.icon,
    required this.color,
    required this.backgroundColor,
    required this.borderColor,
    required this.onTap,
    this.expanded = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: expanded ? null : 52,
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: expanded ? BoxShape.rectangle : BoxShape.circle,
          borderRadius: expanded ? BorderRadius.circular(14) : null,
          color: backgroundColor,
          border: Border.all(color: borderColor),
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: color),
              )
            : Icon(icon, color: color),
      ),
    );
  }
}
