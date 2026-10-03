import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CustomDateTimePicker extends StatefulWidget {
  const CustomDateTimePicker({super.key, this.onDateSelected, this.label});

  final Function(DateTime)? onDateSelected;
  final String? label;

  @override
  State<CustomDateTimePicker> createState() => _CustomDateTimePickerState();
}

class _CustomDateTimePickerState extends State<CustomDateTimePicker> {
  DateTime? selectedDate;

  DateTime get _minDate {
    final now = DateTime.now();
    return DateTime(now.year - 99, now.month, now.day);
  }

  DateTime get _maxDate {
    final now = DateTime.now();
    return DateTime(now.year - 18, now.month, now.day);
  }

  void _showCupertinoDatePicker(BuildContext context) {
    final DateTime minDate = _minDate;
    final DateTime maxDate = _maxDate;

    DateTime tempDate;

    if (selectedDate != null &&
        !selectedDate!.isBefore(minDate) &&
        !selectedDate!.isAfter(maxDate)) {
      tempDate = selectedDate!;
    } else {
      tempDate = maxDate;
    }

    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 320,
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Terminé',
                  style: TextStyle(color: AppColors.primary(context)),
                ),
                onPressed: () {
                  setState(() {
                    selectedDate = tempDate;
                  });

                  widget.onDateSelected?.call(tempDate);

                  Navigator.of(context).pop();
                },
              ),
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: tempDate,
                minimumDate: minDate,
                maximumDate: maxDate,
                onDateTimeChanged: (DateTime newDate) {
                  tempDate = newDate;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final labelColor = AppColors.primary(context);
    final borderColor = AppColors.secondary(context);
    final backgroundColor = AppColors.surface(context);
    final hintColor = AppColors.secondary(context);
    final iconColor = AppColors.secondary(context);

    final formattedDate = selectedDate != null
        ? DateFormat('dd/MM/yyyy').format(selectedDate!)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null)
          Text(
            widget.label!,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: labelColor,
            ),
          ),
        if (widget.label != null) const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _showCupertinoDatePicker(context),
          child: InputDecorator(
            decoration: InputDecoration(
              hintText: 'jj/mm/aaaa',
              hintStyle: TextStyle(color: hintColor, fontSize: 15),
              filled: true,
              fillColor: backgroundColor,
              prefixIcon: Icon(
                Icons.calendar_today_outlined,
                color: iconColor,
                size: 20,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: borderColor, width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: borderColor, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: AppColors.primary(context),
                  width: 1.5,
                ),
              ),
            ),
            child: Text(
              formattedDate ?? '',
              style: TextStyle(
                fontSize: 15,
                color: AppColors.primaryText(context),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
