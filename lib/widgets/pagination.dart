import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Pagination extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageChanged;

  const Pagination({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
  });

  static const _green = Color(0xFF4EA771);
  static const _greenSoft = Color(0xFFEAF6EF);
  static const _textDark = Color(0xFF013236);
  static const _textMuted = Color(0xFFADC5B5);
  static const _border = Color(0xFFDDEDE5);

  List<_PageItem> _buildItems() {
    final items = <_PageItem>[];
    if (totalPages <= 7) {
      for (int i = 1; i <= totalPages; i++) {
        items.add(_PageItem.page(i));
      }
      return items;
    }

    items.add(_PageItem.page(1));

    if (currentPage > 3) items.add(_PageItem.ellipsis());

    final start = (currentPage - 1).clamp(2, totalPages - 1);
    final end = (currentPage + 1).clamp(2, totalPages - 1);
    for (int i = start; i <= end; i++) {
      items.add(_PageItem.page(i));
    }

    if (currentPage < totalPages - 2) items.add(_PageItem.ellipsis());

    items.add(_PageItem.page(totalPages));

    return items;
  }

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1) return const SizedBox.shrink();

    final items = _buildItems();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _NavButton(
          icon: Icons.chevron_left_rounded,
          enabled: currentPage > 1,
          onTap: () {
            HapticFeedback.selectionClick();
            onPageChanged(currentPage - 1);
          },
        ),
        const SizedBox(width: 6),
        ...items.map((item) {
          if (item.isEllipsis) {
            return const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                '···',
                style: TextStyle(
                  fontSize: 12,
                  color: _textMuted,
                  letterSpacing: 1,
                ),
              ),
            );
          }
          final isActive = item.page == currentPage;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: GestureDetector(
              onTap: isActive
                  ? null
                  : () {
                      HapticFeedback.selectionClick();
                      onPageChanged(item.page!);
                    },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: isActive ? _green : _greenSoft,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isActive ? _green : _border,
                    width: 1,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${item.page}',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isActive ? Colors.white : _textDark,
                  ),
                ),
              ),
            ),
          );
        }),
        const SizedBox(width: 6),
        _NavButton(
          icon: Icons.chevron_right_rounded,
          enabled: currentPage < totalPages,
          onTap: () {
            HapticFeedback.selectionClick();
            onPageChanged(currentPage + 1);
          },
        ),
      ],
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _NavButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: enabled ? const Color(0xFFEAF6EF) : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: enabled ? const Color(0xFFDDEDE5) : const Color(0xFFEEEEEE),
            width: 1,
          ),
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 18,
          color: enabled ? const Color(0xFF4EA771) : const Color(0xFFCCCCCC),
        ),
      ),
    );
  }
}

class _PageItem {
  final int? page;
  final bool isEllipsis;

  const _PageItem._({this.page, this.isEllipsis = false});

  factory _PageItem.page(int p) => _PageItem._(page: p);
  factory _PageItem.ellipsis() => _PageItem._(isEllipsis: true);
}
