import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

class CustomDateTimePicker extends StatefulWidget {
  const CustomDateTimePicker({
    super.key,
    this.onDateSelected,
    this.label,
  });

  final Function(DateTime)? onDateSelected;
  final String? label;

  @override
  State<CustomDateTimePicker> createState() => _CustomDateTimePickerState();
}

class _CustomDateTimePickerState extends State<CustomDateTimePicker> {
  DateTime? selectedDate;

  // ✅ Strip time — only keep year/month/day to avoid millisecond mismatch
  DateTime get _minDate {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  void _showCupertinoDatePicker(BuildContext context) {
    final DateTime minDate = _minDate;

    DateTime tempDate = selectedDate != null && selectedDate!.isAfter(minDate)
        ? selectedDate!
        : minDate;

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
                  widget.onDateSelected?.call(selectedDate!);
                  Navigator.of(context).pop();
                },
              ),
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: tempDate,
                minimumDate: minDate,
                maximumDate: DateTime(2100),
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

  String _getFormattedDate() {
    if (selectedDate == null) {
      return 'jj/mm/aaaa';
    }
    // ✅ Force French date format regardless of device/app locale
    return DateFormat('EEE, d MMM', 'fr_FR').format(selectedDate!);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
        ],
        SizedBox(
          width: double.infinity,
          child: GestureDetector(
            onTap: () => _showCupertinoDatePicker(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(
                  width: 1,
                  color: CupertinoColors.systemGrey3,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(
                    CupertinoIcons.calendar,
                    color: CupertinoColors.systemGrey,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _getFormattedDate(),
                    style: TextStyle(
                      color: selectedDate == null
                          ? CupertinoColors.systemGrey
                          : CupertinoColors.label.resolveFrom(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}