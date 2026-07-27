import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:flutter/material.dart';

enum OrderFilter { all, inProgress, delivered }

extension OrderFilterX on OrderFilter {
  String get label {
    switch (this) {
      case OrderFilter.all:
        return 'Tous';
      case OrderFilter.inProgress:
        return 'En cours';
      case OrderFilter.delivered:
        return 'Livrée';
    }
  }
}

class OrderFilterTabs extends StatelessWidget {
  final OrderFilter selected;
  final ValueChanged<OrderFilter> onChanged;

  const OrderFilterTabs({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: OrderFilter.values.map((filter) {
        final bool isSelected = filter == selected;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => onChanged(filter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary(context)
                    : AppColors.surface(context),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : AppColors.secondary(context).withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                filter.label,
                style: TextStyle(
                  color: isSelected
                      ? AppColors.onPrimary(context)
                      : AppColors.primaryText(context),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}