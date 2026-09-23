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

  /// Kalau true, bulan-bulan setelah bulan berjalan gak di-disable di bottom
  /// sheet — dipakai untuk fitur yang justru butuh milih jadwal mendatang
  /// (misal pembatalan jadwal), bukan riwayat yang cuma masuk akal ke masa lalu.
  final bool allowFutureMonths;

  /// Kalau false, bulan-bulan sebelum bulan berjalan di-disable — dipakai
  /// untuk fitur yang cuma masuk akal ke jadwal mendatang (misal pembatalan
  /// jadwal), bukan riwayat yang justru butuh milih bulan-bulan lalu.
  final bool allowPastMonths;

  const MonthYearFilterRow({
    super.key,
    required this.filterStart,
    required this.filterEnd,
    required this.onChanged,
    this.allowFutureMonths = false,
    this.allowPastMonths = true,
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
        allowFutureMonths: allowFutureMonths,
        allowPastMonths: allowPastMonths,
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
            value: filterStart,
            onTap: () => _pick(context, isStart: true),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _FilterChip(
            value: filterEnd,
            onTap: () => _pick(context, isStart: false),
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final DateTime value;
  final VoidCallback onTap;

  const _FilterChip({
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
          color: Color(0xFF4EA771).withOpacity(0.075),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
              color: const Color(0xFF4EA771).withOpacity(0.75),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                DateFormat('MMMM yyyy', 'id_ID').format(value),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4EA771),
                ),
              ),
            ),
            const SizedBox(width: 4),
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

  /// Kalau true, tahun & bulan setelah saat ini tetap bisa dipilih (gak ada
  /// yang di-disable). Dipakai untuk fitur yang butuh milih jadwal mendatang.
  final bool allowFutureMonths;

  /// Kalau false, tahun & bulan sebelum saat ini di-disable. Dipakai untuk
  /// fitur yang cuma masuk akal ke jadwal mendatang.
  final bool allowPastMonths;

  const MonthYearPickerSheet({
    super.key,
    required this.initialYear,
    required this.initialMonth,
    this.allowFutureMonths = false,
    this.allowPastMonths = true,
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
                icon: Icon(
                  Icons.chevron_left_rounded,
                  color: (!widget.allowPastMonths && _year <= now.year)
                      ? Colors.grey[300]
                      : const Color(0xFF013236),
                ),
                onPressed: (!widget.allowPastMonths && _year <= now.year)
                    ? null
                    : () => setState(() => _year--),
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
                  color: (!widget.allowFutureMonths && _year >= now.year)
                      ? Colors.grey[300]
                      : const Color(0xFF013236),
                ),
                onPressed: (!widget.allowFutureMonths && _year >= now.year)
                    ? null
                    : () => setState(() => _year++),
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
              final isFuture = !widget.allowFutureMonths &&
                  _year == now.year &&
                  month > now.month;
              final isPast = !widget.allowPastMonths &&
                  _year == now.year &&
                  month < now.month;
              final isDisabled = isFuture || isPast;
              final isSelected =
                  month == widget.initialMonth && _year == widget.initialYear;
              return GestureDetector(
                onTap: isDisabled
                    ? null
                    : () => Navigator.pop(context, DateTime(_year, month)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF4EA771)
                        : isDisabled
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
                          : isDisabled
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
