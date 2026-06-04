import 'package:flutter/material.dart';

/// Model untuk merepresentasikan satu item pada [BottomBarCustom].
class BottomBarItem {
  final IconData icon;
  final String label;

  const BottomBarItem({
    required this.icon,
    required this.label,
  });
}


class BottomBarCustom extends StatelessWidget {
  /// Daftar item yang ditampilkan pada bottom bar.
  final List<BottomBarItem> items;

  /// Index item yang sedang aktif.
  final int currentIndex;

  /// Callback saat user menekan salah satu item.
  final ValueChanged<int> onTap;

  /// Warna utama untuk icon, label, dan highlight.
  final Color primaryColor;

  /// Warna background bar.
  final Color backgroundColor;

  /// Margin dari tepi layar (untuk efek floating).
  final EdgeInsetsGeometry margin;

  /// Tinggi konten di dalam bar.
  final double height;

  /// Ukuran icon.
  final double iconSize;

  const BottomBarCustom({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.primaryColor = const Color(0xFF013236),
    this.backgroundColor = Colors.white,
    this.margin = const EdgeInsets.fromLTRB(15, 0, 15, 15),
    this.height = 68,
    this.iconSize = 23,
  })  : assert(items.length >= 2, 'Minimal harus ada 2 item'),
        assert(currentIndex >= 0, 'currentIndex tidak valid');

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: margin,
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(height / 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(items.length, (index) {
                final isActive = index == currentIndex;
                return Expanded(
                  child: _BottomBarItemWidget(
                    item: items[index],
                    isActive: isActive,
                    color: primaryColor,
                    iconSize: iconSize,
                    onTap: () => onTap(index),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomBarItemWidget extends StatelessWidget {
  final BottomBarItem item;
  final bool isActive;
  final Color color;
  final double iconSize;
  final VoidCallback onTap;

  const _BottomBarItemWidget({
    required this.item,
    required this.isActive,
    required this.color,
    required this.iconSize,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Background highlight untuk item aktif.
    final Color activeBg = color.withOpacity(0.08);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(40),
        splashColor: color.withOpacity(0.08),
        highlightColor: color.withOpacity(0.04),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: isActive ? activeBg : Colors.transparent,
            borderRadius: BorderRadius.circular(40),
          ),
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                item.icon,
                size: iconSize,
                color: color,
              ),
              const SizedBox(height: 2),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  height: 1.0,
                  fontFamily: 'Poppins',
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}