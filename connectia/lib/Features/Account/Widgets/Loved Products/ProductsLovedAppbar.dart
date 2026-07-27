import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:flutter/material.dart';

class ProductsLovedAppbar extends StatelessWidget {
  final int itemCount;
  const ProductsLovedAppbar({super.key, required this.itemCount});

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
              itemCount > 0
                  ? 'Produits aimés ($itemCount)'
                  : 'Produits aimés',
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
                    // Cœur plein + couleur "wishlist" : c'est la même
                    // combinaison que ProductCard utilise pour son bouton
                    // like, donc l'icône reste cohérente avec ce qu'elle
                    // représente ici (produits likés, pas bookmarkés).
                    child: Icon(
                      Icons.favorite,
                      size: 64,
                      color: AppColors.wishlist(context).withValues(alpha: 0.25),
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