
import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:flutter/material.dart';

class SuggestionCard extends StatelessWidget {
  final bool isHistory;
  final String text;
  final VoidCallback onTap;
  const SuggestionCard({
    super.key,
    required this.isHistory,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        isHistory ? Icons.history_rounded : Icons.search_rounded,
        size: 20,
        color: AppColors.secondary(context),
      ),
      title: Text(
        text,
        style: TextStyle(fontSize: 15, color: AppColors.primaryText(context)),
      ),
      trailing: Icon(
        Icons.north_west_rounded,
        size: 16,
        color: AppColors.secondary(context),
      ),
      onTap: onTap,
    );
  }
}
