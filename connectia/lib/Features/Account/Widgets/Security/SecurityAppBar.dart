import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:flutter/material.dart';

class Securityappbar extends StatelessWidget {
  const Securityappbar({super.key});

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
            centerTitle: false,
            title: Text(
              'Sécurité',
              style: TextStyle(
                color: AppColors.primaryText(context),
                fontWeight: FontWeight.bold,
                fontSize: 18 + (4 * expandRatio),
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
                      Icons.lock_outline_rounded,
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
