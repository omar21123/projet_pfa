import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:flutter/material.dart';

class LastConnectionBanner extends StatelessWidget {
  final String timestampLabel; // e.g. "Aujourd'hui à 14h32"

  const LastConnectionBanner({
    super.key,
    required this.timestampLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.softBg(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.access_time_rounded,
            size: 20,
            color: AppColors.primaryText(context),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 14,
                  height: 1.35,
                  color: AppColors.primaryText(context),
                ),
                children: [
                  const TextSpan(
                    text: 'Dernière connexion: ',
                    style: TextStyle(fontWeight: FontWeight.w400),
                  ),
                  TextSpan(
                    text: timestampLabel,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}