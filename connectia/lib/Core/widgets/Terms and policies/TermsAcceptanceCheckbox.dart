import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class TermsAcceptanceCheckbox extends StatelessWidget {
  const TermsAcceptanceCheckbox({
    super.key,
    required this.isChecked,
    required this.onChanged,
    this.onTermsTap,
    this.onPrivacyTap,
  });

  final bool isChecked;
  final ValueChanged<bool> onChanged;
  final VoidCallback? onTermsTap;
  final VoidCallback? onPrivacyTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => onChanged(!isChecked),
          child: Container(
            width: 24,
            height: 24,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: isChecked ? AppColors.primary(context) : Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isChecked
                    ? AppColors.primary(context)
                    : Colors.grey.shade300,
                width: 1.5,
              ),
            ),
            child: isChecked
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () => onChanged(!isChecked),
            behavior: HitTestBehavior.translucent,
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 14,
                  height: 1.4,
                ),
                children: [
                  const TextSpan(text: "J'accepte les "),
                  TextSpan(
                    text: 'Conditions d\'utilisation',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary(context),
                    ),
                    recognizer: onTermsTap != null
                        ? (TapGestureRecognizer()..onTap = onTermsTap)
                        : null,
                  ),
                  const TextSpan(text: ' et la '),
                  TextSpan(
                    text: 'Politique de confidentialité',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary(context),
                    ),
                    recognizer: onPrivacyTap != null
                        ? (TapGestureRecognizer()..onTap = onPrivacyTap)
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}