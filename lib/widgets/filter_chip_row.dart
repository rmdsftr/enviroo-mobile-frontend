import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Generic reusable horizontal filter chip row.
/// [T] adalah tipe value untuk setiap chip (bisa String, int, dll).
class FilterChipRow<T> extends StatelessWidget {
  final List<FilterChipItem<T>> items;
  final T selectedValue;
  final ValueChanged<T> onSelected;
  final EdgeInsetsGeometry padding;

  const FilterChipRow({
    super.key,
    required this.items,
    required this.selectedValue,
    required this.onSelected,
    this.padding = const EdgeInsets.symmetric(horizontal: 20),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: padding,
        physics: const BouncingScrollPhysics(),
        children: items
            .map((item) => _FilterChipWidget<T>(
                  item: item,
                  isSelected: item.value == selectedValue,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onSelected(item.value);
                  },
                ))
            .toList(),
      ),
    );
  }
}

class FilterChipItem<T> {
  final T value;
  final String label;

  const FilterChipItem({required this.value, required this.label});
}

class _FilterChipWidget<T> extends StatelessWidget {
  static const _accent = Color(0xFF4EA771);
  static const _dark = Color(0xFF013236);

  final FilterChipItem<T> item;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChipWidget({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected ? _accent.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(50),
            border: Border.all(
              color: isSelected ? _accent : const Color(0xFFE5E5E5),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelected) ...[
                const Icon(Icons.check, size: 14, color: _accent),
                const SizedBox(width: 4),
              ],
              Text(
                item.label,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? _accent : _dark.withOpacity(0.5),
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
