import 'package:flutter/material.dart';

import '../ui/app_theme.dart';

class CustomDatePicker {
  static Future<DateTime?> show(
    BuildContext context, {
    DateTime? initialDate,
    DateTime? minDate,
    DateTime? maxDate,
    String title = '选择日期',
    String confirmText = '确定',
    String cancelText = '取消',
  }) async {
    final now = DateTime.now();
    final normalizedMin = _normalizeDate(minDate ?? DateTime(1970, 1, 1));
    final normalizedMax = _normalizeDate(
      maxDate ?? DateTime(now.year + 10, 12, 31),
    );
    final fallback = _normalizeDate(initialDate ?? now);
    final selected = _clampDate(fallback, normalizedMin, normalizedMax);

    return showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _DatePickerSheet(
        initialDate: selected,
        minDate: normalizedMin,
        maxDate: normalizedMax,
        title: title,
        confirmText: confirmText,
        cancelText: cancelText,
      ),
    );
  }

  static DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static DateTime _clampDate(DateTime date, DateTime min, DateTime max) {
    if (date.isBefore(min)) return min;
    if (date.isAfter(max)) return max;
    return date;
  }
}

class _DatePickerSheet extends StatefulWidget {
  const _DatePickerSheet({
    required this.initialDate,
    required this.minDate,
    required this.maxDate,
    required this.title,
    required this.confirmText,
    required this.cancelText,
  });

  final DateTime initialDate;
  final DateTime minDate;
  final DateTime maxDate;
  final String title;
  final String confirmText;
  final String cancelText;

  @override
  State<_DatePickerSheet> createState() => _DatePickerSheetState();
}

class _DatePickerSheetState extends State<_DatePickerSheet> {
  late int selectedYear;
  late int selectedMonth;
  late int selectedDay;

  @override
  void initState() {
    super.initState();
    selectedYear = widget.initialDate.year;
    selectedMonth = widget.initialDate.month;
    selectedDay = widget.initialDate.day;
  }

  List<int> get years => List.generate(
    widget.maxDate.year - widget.minDate.year + 1,
    (i) => widget.maxDate.year - i,
  );

  List<int> get months {
    final minMonth = selectedYear == widget.minDate.year
        ? widget.minDate.month
        : 1;
    final maxMonth = selectedYear == widget.maxDate.year
        ? widget.maxDate.month
        : 12;
    return List.generate(maxMonth - minMonth + 1, (i) => minMonth + i);
  }

  List<int> get days {
    final monthStart = DateTime(selectedYear, selectedMonth, 1);
    final monthEnd = DateTime(selectedYear, selectedMonth + 1, 0);
    final minDay =
        (selectedYear == widget.minDate.year &&
            selectedMonth == widget.minDate.month)
        ? widget.minDate.day
        : 1;
    final maxDay =
        (selectedYear == widget.maxDate.year &&
            selectedMonth == widget.maxDate.month)
        ? widget.maxDate.day
        : monthEnd.day;
    final safeMinDay = minDay.clamp(1, monthEnd.day).toInt();
    final safeMaxDay = maxDay.clamp(safeMinDay, monthEnd.day).toInt();
    if (monthStart.isAfter(widget.maxDate) ||
        monthEnd.isBefore(widget.minDate)) {
      return [];
    }
    return List.generate(safeMaxDay - safeMinDay + 1, (i) => safeMinDay + i);
  }

  void _syncDateSelection() {
    final allowedMonths = months;
    if (allowedMonths.isEmpty) return;
    if (!allowedMonths.contains(selectedMonth)) {
      selectedMonth = allowedMonths.first;
    }
    final allowedDays = days;
    if (allowedDays.isEmpty) return;
    if (!allowedDays.contains(selectedDay)) {
      selectedDay = allowedDays.last;
    }
  }

  DateTime _selectedDate() {
    return DateTime(selectedYear, selectedMonth, selectedDay);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.5,
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildPicker()),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceMuted,
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              widget.cancelText,
              style: const TextStyle(color: AppTheme.textMuted),
            ),
          ),
          Text(
            widget.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.ink,
            ),
          ),
          TextButton(
            onPressed: () {
              final selected = _selectedDate();
              if (selected.isBefore(widget.minDate)) {
                Navigator.pop(context, widget.minDate);
                return;
              }
              if (selected.isAfter(widget.maxDate)) {
                Navigator.pop(context, widget.maxDate);
                return;
              }
              Navigator.pop(context, selected);
            },
            child: Text(
              widget.confirmText,
              style: const TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPicker() {
    return Row(
      children: [
        Expanded(
          child: _buildColumn(
            years,
            selectedYear,
            (v) => setState(() {
              selectedYear = v;
              _syncDateSelection();
            }),
            suffix: '年',
          ),
        ),
        Expanded(
          child: _buildColumn(
            months,
            selectedMonth,
            (v) => setState(() {
              selectedMonth = v;
              _syncDateSelection();
            }),
            suffix: '月',
          ),
        ),
        Expanded(
          child: _buildColumn(
            days,
            selectedDay,
            (v) => setState(() => selectedDay = v),
            suffix: '日',
          ),
        ),
      ],
    );
  }

  Widget _buildColumn(
    List<int> items,
    int selected,
    ValueChanged<int> onChanged, {
    required String suffix,
  }) {
    return ListView.builder(
      key: ValueKey('$suffix-$selectedYear-$selectedMonth'),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isSelected = item == selected;
        return GestureDetector(
          onTap: () => onChanged(item),
          child: Container(
            height: 50,
            alignment: Alignment.center,
            color: isSelected ? AppTheme.surfaceMuted : Colors.transparent,
            child: Text(
              '$item$suffix',
              style: TextStyle(
                fontSize: isSelected ? 18 : 16,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppTheme.primary : AppTheme.textMuted,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFooter() {
    return const SizedBox(height: 8);
  }
}
