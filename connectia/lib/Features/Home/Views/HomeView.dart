import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:connectia/Core/DI/locator.dart';
import 'package:connectia/Core/Navigations/CustomNavigator.dart';
import 'package:connectia/Features/Home/data/CategoryCubit.dart';
import 'package:connectia/Features/Home/data/HomeCubit.dart';
import 'package:connectia/Features/Home/data/Models/ProductModel.dart';
import 'package:connectia/Features/Home/data/ProductRepo.dart';
import 'package:connectia/Features/Home/widgets/CategoryCard.dart';
import 'package:connectia/Features/Home/widgets/HomeHeaderBar.dart';
import 'package:connectia/Features/Home/widgets/Products/ProductsHorizontalSection.dart';
import 'package:connectia/Features/Home/widgets/PromoBannerCard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';

class Homeview extends StatelessWidget {
  const Homeview({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => CategoryCubit(repo: locator())..fetchCategories(),
        ),
        BlocProvider(
          create: (_) => HomeCubit(repo: locator())..fetchRecommendations(),
        ),
      ],
      child: const _HomeBody(),
    );
  }
}

class _HomeBody extends StatefulWidget {
  const _HomeBody();

  @override
  State<_HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends State<_HomeBody> {
  @override
  Widget build(BuildContext context) {
    return BlocListener<CategoryCubit, CategoryState>(
      listenWhen: (prev, curr) {
        if (prev is! CategoryLoaded || curr is! CategoryLoaded) return false;
        return prev.selectedCategoryId != curr.selectedCategoryId;
      },
      listener: (context, state) {
        if (state is CategoryLoaded) {
          final catId = state.selectedCategoryId != -1
              ? state.selectedCategoryId
              : null;
          context.read<HomeCubit>().fetchRecommendations(categoryId: catId);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.softBg(context),
        body: SafeArea(
          child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: HomeHeaderBar(
                userName: 'Mohammed',
                notificationCount: 4,
                onNotificationTap: () async {
                  await CustomNavigator.navigateNotificationsPagePage();
                },
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // ── Categories ──
            SliverToBoxAdapter(
              child: BlocBuilder<CategoryCubit, CategoryState>(
                builder: (context, state) {
                  if (state is CategoryLoading) {
                    return _buildCategoryShimmer(context);
                  }
                  if (state is CategoryError) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Text(
                        state.message,
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.secondary(context)),
                      ),
                    );
                  }
                  if (state is CategoryLoaded) {
                    return _buildCategorySection(state, context);
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // ── Promo banner ──
            SliverToBoxAdapter(
              child: PromoBannerCard(
                title: 'Passe au niveau superieur',
                subtitle:
                    'Trouve du materiel top pour ta prochaine session.',
                imageUrl: 'https://picsum.photos/seed/promo/800/600',
                primaryActionLabel: 'Explorer',
                onPrimaryActionTap: () {},
                secondaryActionLabel: 'Selection editeur',
                onSecondaryActionTap: () {},
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 28)),

            // ── Product sections from API ──
            BlocBuilder<HomeCubit, HomeState>(
              builder: (context, state) {
                if (state is HomeLoading) {
                  return _buildProductsShimmer();
                }
                if (state is HomeError) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          state.message,
                          style: TextStyle(
                              color: AppColors.secondary(context)),
                        ),
                      ),
                    ),
                  );
                }
                if (state is HomeLoaded) {
                  return _buildProductSections(state, context);
                }
                return const SliverToBoxAdapter(
                    child: SizedBox.shrink());
              },
            ),

            SliverToBoxAdapter(
              child: SizedBox(
                height: MediaQuery.of(context).padding.bottom + 24,
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────
  // Product sections
  // ──────────────────────────────────────────────────────

  Widget _buildProductSections(HomeLoaded state, BuildContext context) {
    final sections = <Widget>[];

    int? getCategoryId() {
      final catState = context.read<CategoryCubit>().state;
      if (catState is CategoryLoaded && catState.selectedCategoryId != -1) {
        return catState.selectedCategoryId;
      }
      return null;
    }

    void addSection(
      String title,
      List<ProductModel> products,
      LoadMoreEndpoint endpoint,
    ) {
      if (products.isEmpty) return;
      sections.addAll([
        ProductsHorizontalSection(
          title: title,
          products: products,
          onSeeAllTap: () => CustomNavigator.navigateProductLoadMorePage(
            endpoint,
            categoryId: getCategoryId(),
          ),
        ),
        const SizedBox(height: 24),
      ]);
    }

    addSection('Les plus vendus', state.mostSold, LoadMoreEndpoint.mostSold);
    addSection(
        'En promotion', state.promotions, LoadMoreEndpoint.mostPromoted);
    addSection('Tendances', state.trending, LoadMoreEndpoint.trending);
    addSection(
      'Populaire pres de chez toi',
      state.popularInYourRegion,
      LoadMoreEndpoint.popularInRegion,
    );
    addSection('Les plus vus', state.mostViewed, LoadMoreEndpoint.mostViewed);
    addSection(
      "D'après ton activité",
      state.fromYourLastActivity,
      LoadMoreEndpoint.lastActivity,
    );
    addSection(
        'Nouveautés', state.newestProducts, LoadMoreEndpoint.newest);

    if (sections.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: sections,
      ),
    );
  }

  Widget _buildProductsShimmer() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(3, (section) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 140,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 300,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: 4,
                      separatorBuilder: (_, __) =>
                          const SizedBox(width: 12),
                      itemBuilder: (_, __) => Container(
                        width: 160,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────
  // Category section
  // ──────────────────────────────────────────────────────

  Widget _buildCategorySection(CategoryLoaded state, BuildContext context) {
    final cubit = context.read<CategoryCubit>();
    final hasPath = state.path.isNotEmpty;
    final hasChildren = state.currentChildren.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        CategoriesSection(
          categories: state.allCategories,
          selectedCategoryId: hasPath ? state.path.first.id : null,
          onCategoryTap: (id) {
            if (state.path.isNotEmpty && state.path.first.id == id) {
              cubit.clearSelection();
            } else {
              cubit.selectTopLevel(id);
            }
          },
        ),
        if (hasPath) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 32,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: state.path.length,
              separatorBuilder: (_, __) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(Icons.chevron_right_rounded,
                    size: 18, color: AppColors.secondary(context)),
              ),
              itemBuilder: (_, index) {
                final cat = state.path[index];
                final isLast = index == state.path.length - 1;
                return GestureDetector(
                  onTap: () => cubit.navigateToLevel(index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isLast
                          ? AppColors.primary(context)
                              .withValues(alpha: 0.1)
                          : AppColors.surface(context),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isLast
                            ? AppColors.primary(context)
                            : AppColors.secondary(context)
                                .withValues(alpha: 0.15),
                      ),
                    ),
                    child: Text(
                      cat.name,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            isLast ? FontWeight.w700 : FontWeight.w500,
                        color: isLast
                            ? AppColors.primary(context)
                            : AppColors.primaryText(context),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
        if (hasChildren) ...[
          const SizedBox(height: 10),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: state.currentChildren.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, index) {
                final child = state.currentChildren[index];
                return GestureDetector(
                  onTap: () => cubit.selectCategory(child.id),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surface(context),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.secondary(context)
                            .withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          child.name,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryText(context),
                          ),
                        ),
                        if (child.hasChildren) ...[
                          const SizedBox(width: 4),
                          Icon(Icons.chevron_right_rounded,
                              size: 14,
                              color: AppColors.secondary(context)),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCategoryShimmer(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.softBg(context),
      highlightColor: AppColors.surface(context),
      child: SizedBox(
        height: 110,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: 5,
          itemBuilder: (_, __) => Container(
            width: 90,
            margin: const EdgeInsets.only(right: 12),
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 50,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
