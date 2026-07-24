import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:connectia/Features/Home/data/Models/ProductConfigsOptions.dart';
import 'package:connectia/Features/Home/widgets/Products/ProductConfigDropdown.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProductConfigsSliverList extends StatefulWidget {
  final List<ProductConfigsOptions> configs;
  final List<ChoosedOptionModel>? initialSelections;
  final ValueChanged<List<ChoosedOptionModel>> onChanged;
  final EdgeInsets padding;

  const ProductConfigsSliverList({
    super.key,
    required this.configs,
    required this.onChanged,
    this.initialSelections,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
  });

  @override
  State<ProductConfigsSliverList> createState() =>
      _ProductConfigsSliverListState();
}

class _ProductConfigsSliverListState extends State<ProductConfigsSliverList> {
  // configID -> optionID
  late final Map<int, int> _selected;

  @override
  void initState() {
    super.initState();
    _selected = {};

    for (final config in widget.configs) {
      final existing = widget.initialSelections?.firstWhere(
        (c) => c.configID == config.id,
        orElse: () => ChoosedOptionModel(configID: -1, optionID: -1),
      );

      if (existing != null && existing.configID != -1) {
        _selected[config.id] = existing.optionID;
      } else if (config.options.isNotEmpty) {
        _selected[config.id] = config.options.first.id;
      }
    }

    // Notifie l'état initial (utile si le parent veut connaître les
    // valeurs par défaut sans attendre une interaction utilisateur).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onChanged(_buildSelections());
    });
  }

  List<ChoosedOptionModel> _buildSelections() {
    return _selected.entries
        .map(
          (entry) =>
              ChoosedOptionModel(configID: entry.key, optionID: entry.value),
        )
        .toList();
  }

  void _onOptionChanged(int configId, int optionId) {
    setState(() => _selected[configId] = optionId);
    widget.onChanged(_buildSelections());
  }

  @override
  Widget build(BuildContext context) {
    if (widget.configs.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverPadding(
      padding: widget.padding,
      sliver: SliverToBoxAdapter(
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.background(context),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.accent30(context), width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Personnalisons votre produit ✨',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryText(context),
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Cette personnalisation est proposée par le vendeur. Si vous ne '
                'faites aucun choix, la configuration par défaut sera appliquée.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.secondary(context),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              ...List.generate(widget.configs.length * 2 - 1, (i) {
                if (i.isOdd) return const SizedBox(height: 16);

                final config = widget.configs[i ~/ 2];
                final selectedValue =
                    _selected[config.id] ??
                    (config.options.isNotEmpty ? config.options.first.id : 0);

                return ProductConfigDropdown(
                  label: config.name,
                  value: selectedValue,
                  options: config.options,
                  onChanged: (newOptionId) =>
                      _onOptionChanged(config.id, newOptionId),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
