import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:flutter/material.dart';

class Textsearchbar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final bool autofocus;
  final String hintText;

  const Textsearchbar({
    super.key,
    required this.controller,
    this.focusNode,
    this.onChanged,
    this.onClear,
    this.autofocus = false,
    this.hintText = 'Rechercher un produit, une marque...',
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(16),
        ),
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          autofocus: autofocus,
          style: TextStyle(color: AppColors.primaryText(context)),
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: AppColors.secondary(context)),
            prefixIcon: Icon(Icons.search, color: AppColors.secondary(context)),
            suffixIcon: controller.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.close_rounded,
                        size: 20, color: AppColors.secondary(context)),
                    onPressed: onClear,
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }
}