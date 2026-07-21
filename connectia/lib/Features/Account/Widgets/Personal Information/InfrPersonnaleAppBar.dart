import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:flutter/material.dart';

class Infrpersonnaleappbar extends StatelessWidget {
  final VoidCallback onPressed;
  const Infrpersonnaleappbar({super.key , required this.onPressed});

  Widget _buildSaveButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Center(
        child: TextButton.icon(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            backgroundColor: AppColors.accent20(context),
            foregroundColor: AppColors.primary(context),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            visualDensity: VisualDensity.compact,
          ),
          icon: const Icon(Icons.check, size: 18),
          label: const Text(
            'Enregistrer',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppColors.background(context),
      elevation: 0,
      expandedHeight: 130,
      iconTheme: IconThemeData(color: AppColors.primaryText(context)),
      actions: [_buildSaveButton(context)],
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final expandRatio =
              ((constraints.maxHeight - kToolbarHeight) /
                      (130 - kToolbarHeight))
                  .clamp(0.0, 1.0);

          return FlexibleSpaceBar(
            titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
            centerTitle: false,
            title: Text(
              "Informations personnelles",
              style: TextStyle(
                color: AppColors.primaryText(context),
                fontWeight: FontWeight.bold,
                fontSize: 16 + (4 * expandRatio),
              ),
            ),
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.background(context),
                    AppColors.accent20(context),
                  ],
                ),
              ),
              child: Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 24, top: 10),
                  child: Opacity(
                    opacity: expandRatio,
                    child: Icon(
                      Icons.badge_outlined,
                      size: 64,
                      color: AppColors.primary(context).withValues(alpha: 0.25),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
