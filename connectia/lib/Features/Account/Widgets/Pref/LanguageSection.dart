import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:connectia/Features/Account/Widgets/Pref/SectionCard.dart';
import 'package:connectia/Features/Account/Widgets/Pref/SectionHeader.dart';
import 'package:connectia/Features/Account/Widgets/Pref/LanguageTile.dart';
import 'package:flutter/material.dart';

class LanguageSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(icon: Icons.language, title: 'Langue'),
          const SizedBox(height: 4),
          Text(
            "Pour le moment, seul le français est disponible sur connectia. "
            "D'autres langues seront ajoutées prochainement.",
            style: TextStyle(
              color: AppColors.secondary(context),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          LanguageTile(flag: '🇫🇷', label: 'Français', enabled: true),
          const SizedBox(height: 8),
          LanguageTile(flag: '🇬🇧', label: 'English', enabled: false),
          const SizedBox(height: 8),
          LanguageTile(flag: '🇸🇦', label: 'العربية', enabled: false),
        ],
      ),
    );
  }
}
