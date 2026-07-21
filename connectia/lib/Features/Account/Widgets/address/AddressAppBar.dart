import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:flutter/material.dart';

class Addressappbar extends StatelessWidget {
  final VoidCallback onTap;

  const Addressappbar({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppColors.background(context),
      elevation: 0,
      expandedHeight: 130,
      iconTheme: IconThemeData(color: AppColors.primaryText(context)),
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final expandRatio =
              ((constraints.maxHeight - kToolbarHeight) /
                      (130 - kToolbarHeight))
                  .clamp(0.0, 1.0);

          return FlexibleSpaceBar(
            titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
            centerTitle: true,
            title: Text(
              'Gestion des adresses',
              style: TextStyle(
                color: AppColors.primaryText(context),
                fontWeight: FontWeight.bold,
                fontSize: 18 + (4 * expandRatio), // grossit un peu déplié
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
                      Icons.location_on_outlined,
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
