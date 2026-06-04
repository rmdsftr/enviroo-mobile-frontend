import 'package:flutter/material.dart';

class MainNavbar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTabChanged;
  final List<String> tabs;
  final Color? backgroundColor;
  final BoxBorder? border;

  const MainNavbar({
    Key? key,
    required this.selectedIndex,
    required this.onTabChanged,
    this.tabs = const ['Beranda', 'Transaksi', 'Reward'],
    this.backgroundColor,
    this.border,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.white,
          border: border,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Row(
          children: List.generate(
            tabs.length,
            (i) => _buildTab(i, tabs[i]),
          ),
        ),
      ),
    );
  }

  Widget _buildTab(int index, String label) {
    final isSelected = selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTabChanged(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF94DF0C) : Colors.transparent,
            borderRadius: BorderRadius.circular(50),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? const Color(0xFF013236)
                    : const Color(0xFF013236).withOpacity(0.5),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
