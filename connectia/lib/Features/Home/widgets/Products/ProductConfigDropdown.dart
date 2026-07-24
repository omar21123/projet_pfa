import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:connectia/Features/Home/data/Models/ProductConfigsOptions.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProductConfigDropdown extends StatelessWidget {
  final String label;
  final int value;
  final List<OptionModel> options;
  final ValueChanged<int> onChanged;

  const ProductConfigDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
            color: AppColors.primaryText(context),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.background(context),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: AppColors.secondary(context).withValues(alpha: 0.2),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: value,
              isExpanded: true,
              icon: Icon(
                Icons.keyboard_double_arrow_down_rounded,
                size: 20,
                color: AppColors.primaryText(context),
              ),
              borderRadius: BorderRadius.circular(16),
              dropdownColor: AppColors.background(context),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.primaryText(context),
              ),
              items: options
                  .map(
                    (option) => DropdownMenuItem<int>(
                      value: option.id,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Text(option.name),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (newValue) {
                if (newValue != null) onChanged(newValue);
              },
            ),
          ),
        ),
      ],
    );
  }
}