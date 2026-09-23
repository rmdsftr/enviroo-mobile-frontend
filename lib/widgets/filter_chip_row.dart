import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Warna aksen buat chip yang lagi terpilih. Tinggal tambah case baru
/// di [_accentColor] kalau butuh mode warna lain.
enum FilterChipColorMode { defaultMode, dark, lime }

Color _accentColor(FilterChipColorMode mode) {
  switch (mode) {
    case FilterChipColorMode.dark:
      return const Color(0xFF013236);
    case FilterChipColorMode.lime:
      return const Color(0xFF94DF0C);
    case FilterChipColorMode.defaultMode:
      return const Color(0xFF4EA771);
  }
}

/// Generic reusable horizontal filter chip row.
/// [T] adalah tipe value untuk setiap chip (bisa String, int, dll).
class FilterChipRow<T> extends StatelessWidget {
  final List<FilterChipItem<T>> items;
  final T selectedValue;
  final ValueChanged<T> onSelected;
  final EdgeInsetsGeometry padding;
  final FilterChipColorMode colorMode;

  const FilterChipRow({
    super.key,
    required this.items,
    required this.selectedValue,
    required this.onSelected,
    this.padding = const EdgeInsets.symmetric(horizontal: 20),
    this.colorMode = FilterChipColorMode.defaultMode,
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
                  accent: _accentColor(colorMode),
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
  static const _dark = Color(0xFF013236);

  final FilterChipItem<T> item;
  final bool isSelected;
  final Color accent;
  final VoidCallback onTap;

  const _FilterChipWidget({
    required this.item,
    required this.isSelected,
    required this.accent,
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
            color: isSelected ? accent.withValues(alpha: 0.075) : Colors.white,
            borderRadius: BorderRadius.circular(50),
            border: Border.all(
              color: isSelected ? accent : const Color(0xFFE5E5E5),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelected) ...[
                Icon(Icons.check, size: 14, color: accent),
                const SizedBox(width: 4),
              ],
              Text(
                item.label,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? accent : _dark.withValues(alpha: 0.5),
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
