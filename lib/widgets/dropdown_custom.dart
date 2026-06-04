import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';

class CustomDropdownItem<T> {
  final T value;
  final String label;
  final IconData? icon;

  const CustomDropdownItem({
    required this.value,
    required this.label,
    this.icon,
  });
}

class CustomDropdown<T> extends StatelessWidget {
  static const _accent = Color(0xFF4EA771);
  static const _dark   = Color(0xFF013236);

  final T? value;
  final List<CustomDropdownItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String hintText;
  final IconData? prefixIcon;
  final Color? fillColor;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final double? menuMaxHeight;
  final bool enabled;

  const CustomDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.hintText,
    this.prefixIcon,
    this.fillColor,
    this.borderRadius = 22.0,
    this.padding = EdgeInsets.zero,
    this.menuMaxHeight,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: DropdownButtonHideUnderline(
        child: DropdownButton2<T>(
          isExpanded: true,
          value: value,
          hint: _buildLabelRow(hintText, isHint: true),
          items: items.map((it) {
            final selected = it.value == value;
            return DropdownMenuItem<T>(
              value: it.value,
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 2),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: selected ? _accent.withValues(alpha: 0.10) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    if (it.icon != null) ...[
                      Icon(it.icon, size: 16, color: _accent),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: Text(
                        it.label,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          color: _dark,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (selected)
                      const Icon(Icons.check_rounded, size: 16, color: _accent),
                  ],
                ),
              ),
            );
          }).toList(),
          selectedItemBuilder: (context) => items
              .map((it) => _buildLabelRow(it.label, leadingIcon: prefixIcon ?? it.icon))
              .toList(),
          onChanged: enabled ? onChanged : null,
          buttonStyleData: ButtonStyleData(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: fillColor ?? Colors.white.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: _dark.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
          ),
          iconStyleData: const IconStyleData(
            icon: Icon(Icons.keyboard_arrow_down_rounded),
            openMenuIcon: Icon(Icons.keyboard_arrow_up_rounded),
            iconSize: 22,
            iconEnabledColor: _accent,
            iconDisabledColor: _accent,
          ),
          dropdownStyleData: DropdownStyleData(
            maxHeight: menuMaxHeight ?? 280,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _dark.withValues(alpha: 0.08)),
              boxShadow: [
                BoxShadow(
                  color: _dark.withValues(alpha: 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            offset: const Offset(0, -4),
            elevation: 0,
            scrollbarTheme: ScrollbarThemeData(
              radius: const Radius.circular(40),
              thickness: WidgetStateProperty.all(4),
              thumbVisibility: WidgetStateProperty.all(true),
              thumbColor: WidgetStateProperty.all(_accent.withValues(alpha: 0.4)),
            ),
          ),
          menuItemStyleData: const MenuItemStyleData(
            height: 44,
            padding: EdgeInsets.zero,
          ),
        ),
      ),
    );
  }

  Widget _buildLabelRow(String text, {bool isHint = false, IconData? leadingIcon}) {
    final iconData = leadingIcon ?? prefixIcon;
    return Row(
      children: [
        if (iconData != null) ...[
          Icon(iconData, size: 18, color: _accent),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: isHint ? FontWeight.normal : FontWeight.w500,
              color: isHint ? _dark.withValues(alpha: 0.3) : _dark,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
