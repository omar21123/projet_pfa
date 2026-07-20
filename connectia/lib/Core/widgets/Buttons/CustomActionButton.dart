import 'package:flutter/material.dart';

/// Bouton pill avec icône encadrée + texte, style "Supprimer mon compte".
class CustomActionButton extends StatelessWidget {
  final VoidCallback onClick;
  final IconData icon;
  final String text;
  final Color color;
  final Color backgroundColor;

  const CustomActionButton({
    super.key,
    required this.onClick,
    required this.icon,
    required this.text,
    required this.color,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onClick,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              child: Icon(icon, color: color, size: 40),
            ),
            const SizedBox(width: 14),
            Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
