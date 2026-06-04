import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Row of two tappable month-year chips (Dari / Sampai).
/// Parent owns [filterStart] and [filterEnd]; [onChanged] receives the updated
/// pair after the picker closes. Auto-clamps: if start > end or end < start,
/// the other bound is adjusted to match.
class MonthYearFilterRow extends StatelessWidget {
  final DateTime filterStart;
  final DateTime filterEnd;
  final void Function(DateTime start, DateTime end) onChanged;

  const MonthYearFilterRow({
    super.key,
    required this.filterStart,
    required this.filterEnd,
    required this.onChanged,
  });

  Future<void> _pick(BuildContext context, {required bool isStart}) async {
    final current = isStart ? filterStart : filterEnd;
    final result = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => MonthYearPickerSheet(
        initialYear: current.year,
        initialMonth: current.month,
      ),
    );
    if (result == null) return;

    DateTime newStart = filterStart;
    DateTime newEnd = filterEnd;
    if (isStart) {
      newStart = result;
      if (newStart.isAfter(newEnd)) newEnd = newStart;
    } else {
      newEnd = result;
      if (newEnd.isBefore(newStart)) newStart = newEnd;
    }
    onChanged(newStart, newEnd);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _FilterChip(
            label: 'Dari',
            value: filterStart,
            onTap: () => _pick(context, isStart: true),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _FilterChip(
            label: 'Sampai',
            value: filterEnd,
            onTap: () => _pick(context, isStart: false),
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final DateTime value;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: const Color(0xFF013236).withOpacity(0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('MMMM yyyy', 'id_ID').format(value),
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF013236),
                  ),
                ),
              ],
            ),
            const Icon(Icons.expand_more_rounded,
                size: 18, color: Color(0xFF4EA771)),
          ],
        ),
      ),
    );
  }
}

/// Bottom-sheet month-year picker. Pops with the selected [DateTime] on tap.
class MonthYearPickerSheet extends StatefulWidget {
  final int initialYear;
  final int initialMonth;

  const MonthYearPickerSheet({
    super.key,
    required this.initialYear,
    required this.initialMonth,
  });

  @override
  State<MonthYearPickerSheet> createState() => _MonthYearPickerSheetState();
}

class _MonthYearPickerSheetState extends State<MonthYearPickerSheet> {
  late int _year;

  static const _monthLabels = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];

  @override
  void initState() {
    super.initState();
    _year = widget.initialYear;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded,
                    color: Color(0xFF013236)),
                onPressed: () => setState(() => _year--),
              ),
              Text(
                '$_year',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF013236),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.chevron_right_rounded,
                  color: _year >= now.year
                      ? Colors.grey[300]
                      : const Color(0xFF013236),
                ),
                onPressed:
                    _year >= now.year ? null : () => setState(() => _year++),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 2.2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: 12,
            itemBuilder: (_, i) {
              final month = i + 1;
              final isFuture = _year == now.year && month > now.month;
              final isSelected =
                  month == widget.initialMonth && _year == widget.initialYear;
              return GestureDetector(
                onTap: isFuture
                    ? null
                    : () => Navigator.pop(context, DateTime(_year, month)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF4EA771)
                        : isFuture
                            ? Colors.grey[100]
                            : const Color(0xFFF0F9F4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _monthLabels[i],
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : isFuture
                              ? Colors.grey[400]
                              : const Color(0xFF013236),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
