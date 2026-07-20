import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:connectia/Features/Account/Widgets/Pref/SectionCard.dart';
import 'package:connectia/Features/Account/Widgets/Pref/SectionHeader.dart';
import 'package:flutter/material.dart';

class ThemeSection extends StatefulWidget {
  final bool isDark;
  final VoidCallback onDarkMode;
  final VoidCallback onWhiteMode;

  const ThemeSection({
    super.key,
    required this.isDark,
    required this.onDarkMode,
    required this.onWhiteMode,
  });

  @override
  State<ThemeSection> createState() => _ThemeSectionState();
}

class _ThemeSectionState extends State<ThemeSection> {
  // État local pour un retour visuel immédiat, indépendant du timing
  // du rebuild parent.
  late bool _isDark = widget.isDark;

  @override
  void didUpdateWidget(covariant ThemeSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si le thème change depuis l'extérieur (ex: suit le système),
    // on resynchronise l'état local.
    if (oldWidget.isDark != widget.isDark) {
      setState(() => _isDark = widget.isDark);
    }
  }

  void _handleChanged(bool value) {
    setState(() => _isDark = value);
    if (value) {
      widget.onDarkMode();
    } else {
      widget.onWhiteMode();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(icon: Icons.dark_mode_outlined, title: 'Thème'),
          const SizedBox(height: 4),
          Text(
            "Choisis l'apparence de l'application.",
            style: TextStyle(color: AppColors.secondary(context), fontSize: 13),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                _isDark ? Icons.dark_mode : Icons.light_mode,
                color: AppColors.primaryText(context),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _isDark ? 'Mode sombre' : 'Mode clair',
                  style: TextStyle(
                    color: AppColors.primaryText(context),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Switch.adaptive(
                value: _isDark,
                activeColor: AppColors.primary(context),
                onChanged: _handleChanged,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
