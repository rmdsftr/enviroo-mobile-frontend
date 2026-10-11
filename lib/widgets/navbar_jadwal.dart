import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:enviroo/core/theme/app_colors.dart';
import 'package:enviroo/core/theme/app_text.dart';

class NavbarJadwal extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabChanged;

  const NavbarJadwal({
    Key? key,
    required this.selectedIndex,
    required this.onTabChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: AppColors.dark.withAlpha(12)),
          boxShadow: [
            BoxShadow(
              color: AppColors.dark.withAlpha(12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            _buildTab(0, 'Penimbangan'),
            const SizedBox(width: 4),
            _buildTab(1, 'Pengangkutan'),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(int index, String label) {
    final isSelected = selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTabChanged(index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.neon : Colors.transparent,
            borderRadius: BorderRadius.circular(50),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.neon.withAlpha(50),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: AppText.w600(13, isSelected
                    ? AppColors.dark
                    : AppColors.dark),
              child: Text(label),
            ),
          ),
        ),
      ),
    );
  }
}
