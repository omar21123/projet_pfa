import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:connectia/Core/Navigations/CustomNavigator.dart';
import 'package:connectia/Features/Search/widgets/SearchEntryButton.dart';
import 'package:flutter/material.dart';

class Searchsiverappbar extends StatelessWidget {
  const Searchsiverappbar({super.key});

  static const double _expandedHeight = 120;
  static const double _searchBarHeight = 66;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppColors.background(context),
      elevation: 0,
      expandedHeight: _expandedHeight,
      iconTheme: IconThemeData(color: AppColors.primaryText(context)),
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final expandRatio =
              ((constraints.maxHeight - kToolbarHeight - _searchBarHeight) /
                      (_expandedHeight - kToolbarHeight - _searchBarHeight))
                  .clamp(0.0, 1.0);

          return FlexibleSpaceBar(
            titlePadding: const EdgeInsets.only(left: 20, bottom: 78),
            centerTitle: false,
            title: Text(
              'Recherche',
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
                  padding: const EdgeInsets.only(right: 24, top: 6),
                  child: Opacity(
                    opacity: expandRatio,
                    child: Icon(
                      Icons.search_rounded,
                      size: 56,
                      color: AppColors.primary(context).withValues(alpha: 0.25),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(_searchBarHeight),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          child: SearchEntryButton(
            onTap: () {
              CustomNavigator.navigateToSearchtypingsuggestions();
            },
          ),
        ),
      ),
    );
  }
}
