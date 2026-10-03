import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:connectia/Core/DI/locator.dart';
import 'package:connectia/Core/Navigations/CustomNavigator.dart';
import 'package:connectia/Core/widgets/Texts/TextSearchBar.dart';
import 'package:connectia/Features/Search/data/SearchRepo.dart';
import 'package:connectia/Features/Search/data/search_cubit.dart';
import 'package:connectia/Features/Search/widgets/SuggestionCard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';

class Searchtypingsuggestions extends StatelessWidget {
  const Searchtypingsuggestions({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SearchCubit(repo: locator<SearchRepo>()),
      child: const _SearchView(),
    );
  }
}

class _SearchView extends StatefulWidget {
  const _SearchView();

  @override
  State<_SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<_SearchView> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    context.read<SearchCubit>().fetchHistory();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        backgroundColor: AppColors.background(context),
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.primaryText(context)),
        titleSpacing: 0,
        title: Textsearchbar(
          controller: _controller,
          focusNode: _focusNode,
          autofocus: true,
          onChanged: (q) => context.read<SearchCubit>().onQueryChanged(q),
          onClear: () {
            _controller.clear();
            context.read<SearchCubit>().onQueryChanged('');
          },
        ),
      ),
      body: BlocBuilder<SearchCubit, SearchState>(
        builder: (context, state) {
          if (state is SearchLoading) {
            return _buildShimmer(context);
          }

          if (state is SearchError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, size: 40, color: AppColors.secondary(context)),
                    const SizedBox(height: 12),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.secondary(context)),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is SearchEmpty) {
            return Center(
              child: Text(
                'Aucun résultat pour "${state.query}"',
                style: TextStyle(color: AppColors.secondary(context)),
              ),
            );
          }

          if (state is SearchSuggestionsLoaded) {
            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: state.suggestions.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                indent: 20,
                endIndent: 20,
                color: AppColors.secondary(context).withValues(alpha: 0.15),
              ),
              itemBuilder: (context, index) {
                final suggestion = state.suggestions[index];
                return SuggestionCard(
                  isHistory: false,
                  text: suggestion.text,
                  onTap: () {
                    _controller.text = suggestion.text;
                    CustomNavigator.navigateSearchResultsPage(suggestion.text);
                  },
                );
              },
            );
          }

          if (state is SearchHistoryLoaded) {
            return _buildHistory(state, context);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildShimmer(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.softBg(context),
      highlightColor: AppColors.surface(context),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: 6,
        separatorBuilder: (_, __) => const SizedBox(height: 0),
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistory(SearchHistoryLoaded state, BuildContext context) {
    final history = state.history;
    final hasLatest = history.latest.isNotEmpty;
    final hasFamous = history.famous.isNotEmpty;

    if (!hasLatest && !hasFamous) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded,
                size: 40, color: AppColors.secondary(context)),
            const SizedBox(height: 12),
            Text(
              'Aucun historique de recherche',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.secondary(context),
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        if (hasLatest) ...[
          _buildSectionHeader(context, 'Recherches récentes'),
          ...history.latest.map((item) => SuggestionCard(
                isHistory: true,
                text: item.text,
                onTap: () {
                  _controller.text = item.text;
                  CustomNavigator.navigateSearchResultsPage(item.text);
                },
              )),
        ],
        if (hasFamous) ...[
          if (hasLatest) const SizedBox(height: 8),
          _buildSectionHeader(context, 'Recherches populaires'),
          ...history.famous.map((item) => SuggestionCard(
                isHistory: true,
                text: item.text,
                onTap: () {
                  _controller.text = item.text;
                  CustomNavigator.navigateSearchResultsPage(item.text);
                },
              )),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.secondary(context),
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
