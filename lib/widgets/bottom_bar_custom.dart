import 'package:flutter/material.dart';
import 'package:enviroo/core/theme/app_colors.dart';
import 'package:enviroo/core/theme/app_text.dart';

const double _lebarItemIdeal = 100;

const double _kTinggiBar = 66;
const double _kMarginBawahBar = 15;

const double kRuangBottomBar = _kTinggiBar + _kMarginBawahBar;

class BottomBarItem {
  final IconData icon;
  final String label;

  const BottomBarItem({
    required this.icon,
    required this.label,
  });
}


class BottomBarCustom extends StatelessWidget {
  final List<BottomBarItem> items;

  final int currentIndex;

  final ValueChanged<int> onTap;

  final Color primaryColor;

  final Color backgroundColor;

  final EdgeInsetsGeometry margin;

  final double height;

  final double iconSize;

  const BottomBarCustom({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.primaryColor = AppColors.dark,
    this.backgroundColor = Colors.white,
    this.margin = const EdgeInsets.fromLTRB(15, 0, 15, _kMarginBawahBar),
    this.height = _kTinggiBar,
    this.iconSize = 23,
  })  : assert(items.length >= 2, 'Minimal harus ada 2 item'),
        assert(currentIndex >= 0, 'currentIndex tidak valid');

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: margin,
        child: Center(
          child: Container(
            height: height,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(height / 2),
              border : Border.all(
                color: AppColors.dark.withValues(alpha: 0.1),
                width: 1,
              )
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final muat = constraints.maxWidth / items.length;
                  final lebarItem =
                      _lebarItemIdeal < muat ? _lebarItemIdeal : muat;

                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(items.length, (index) {
                      final isActive = index == currentIndex;
                      return SizedBox(
                        width: lebarItem,
                        child: _BottomBarItemWidget(
                          item: items[index],
                          isActive: isActive,
                          color: primaryColor,
                          iconSize: iconSize,
                          onTap: () => onTap(index),
                        ),
                      );
                    }),
                  );
                },
              ),
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
    final Color activeBg = color.withValues(alpha: 0.08);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(40),
        splashColor: color.withValues(alpha: 0.08),
        highlightColor: color.withValues(alpha: 0.04),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: isActive ? activeBg : Colors.transparent,
            borderRadius: BorderRadius.circular(40),
          ),
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                item.icon,
                size: iconSize,
                color: color,
              ),
              const SizedBox(height: 1),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.p(10, weight: isActive ? FontWeight.w600 : FontWeight.w400, color: color, height: 1.0),
              ),
            ],
          ),
        ),
      ),
    );
  }
}