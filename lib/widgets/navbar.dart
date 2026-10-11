import 'package:flutter/material.dart';
import 'package:enviroo/core/theme/app_colors.dart';
import 'package:enviroo/core/theme/app_text.dart';

class MainNavbar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTabChanged;
  final List<String> tabs;
  final List<int?>? badges;
  final Color? backgroundColor;
  final BoxBorder? border;

  const MainNavbar({
    Key? key,
    required this.selectedIndex,
    required this.onTabChanged,
    this.tabs = const ['Beranda', 'Transaksi', 'Reward'],
    this.badges,
    this.backgroundColor,
    this.border,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.white,
          border: border,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Row(
          children: List.generate(
            tabs.length,
            (i) => _buildTab(i, tabs[i], badges != null && i < badges!.length ? badges![i] : null),
          ),
        ),
      ),
    );
  }

  Widget _buildTab(int index, String label, int? badge) {
    final isSelected = selectedIndex == index;
    final showBadge = badge != null && badge > 0;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTabChanged(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.neon.withValues(alpha: 0.75) : Colors.transparent,
            borderRadius: BorderRadius.circular(50),
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: AppText.p(13, weight: isSelected ? FontWeight.w600 : FontWeight.w500, color: isSelected
                        ? AppColors.dark
                        : AppColors.dark.withValues(alpha: 0.5)),
                ),
                if (showBadge) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.dark,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$badge',
                      style: AppText.w700(10, Colors.white),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
