import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:connectia/Core/DI/locator.dart';
import 'package:connectia/Core/Navigations/CustomNavigator.dart';
import 'package:connectia/Features/Home/data/CategoryCubit.dart';
import 'package:connectia/Features/Home/data/Models/ProductModel.dart';
import 'package:connectia/Features/Home/data/ProductRepo.dart';
import 'package:connectia/Features/Home/widgets/CategoryCard.dart';
import 'package:connectia/Features/Home/widgets/Products/ProductsHorizontalSection.dart';
import 'package:connectia/Features/Search/data/SearchHomeCubit.dart';
import 'package:connectia/Features/Search/widgets/SearchSiverAppBAr.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';

class Searchview extends StatefulWidget {
  const Searchview({super.key});

  @override
  State<Searchview> createState() => _SearchviewState();
}

class _SearchviewState extends State<Searchview> {
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => CategoryCubit(repo: locator())..fetchCategories(),
        ),
        BlocProvider(
          create: (_) => SearchHomeCubit(repo: locator())..fetchRecommendations(),
        ),
      ],
      child: const _SearchBody(),
    );
  }
}

class _SearchBody extends StatefulWidget {
  const _SearchBody();

  @override
  State<_SearchBody> createState() => _SearchBodyState();
}

class _SearchBodyState extends State<_SearchBody> {
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
          context.read<SearchHomeCubit>().fetchRecommendations(categoryId: catId);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.softBg(context),
        body: CustomScrollView(
          slivers: [
            Searchsiverappbar(),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

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
            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // ── Recommendations from API ──
            BlocBuilder<SearchHomeCubit, SearchHomeState>(
              builder: (context, state) {
                if (state is SearchHomeLoading) {
                  return _buildShimmer();
                }
                if (state is SearchHomeError) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          state.message,
                          style: TextStyle(
                            color: AppColors.secondary(context),
                          ),
                        ),
                      ),
                    ),
                  );
                }
                if (state is SearchHomeLoaded) {
                  final sections = <Widget>[];

                  int? getCategoryId() {
                    final catState = context.read<CategoryCubit>().state;
                    if (catState is CategoryLoaded &&
                        catState.selectedCategoryId != -1) {
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
                        onSeeAllTap: () =>
                            CustomNavigator.navigateProductLoadMorePage(
                          endpoint,
                          categoryId: getCategoryId(),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ]);
                  }

                  addSection(
                    "D'après ton activité",
                    state.lastSearched,
                    LoadMoreEndpoint.lastActivity,
                  );
                  addSection(
                    'Nouveautés',
                    state.newestProducts,
                    LoadMoreEndpoint.newest,
                  );

                  if (sections.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: SizedBox.shrink(),
                    );
                  }

                  return SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: sections,
                    ),
                  );
                }
                return const SliverToBoxAdapter(child: SizedBox.shrink());
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
    );
  }

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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: 5,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, __) => Container(
                  width: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(2, (section) {
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
                    height: 200,
                    child: Shimmer.fromColors(
                      baseColor: Colors.grey.shade300,
                      highlightColor: Colors.grey.shade100,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: 4,
                        separatorBuilder: (_, index) =>
                            const SizedBox(width: 12),
                        itemBuilder: (ctx, index) => Container(
                          width: 150,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
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
}
