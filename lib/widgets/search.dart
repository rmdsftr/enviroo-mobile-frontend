import 'package:flutter/material.dart';

class CustomSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;
  final String searchQuery;
  final VoidCallback onClear;
  final Color? fillColor;
  final double borderRadius;
  final EdgeInsetsGeometry padding;

  const CustomSearchBar({
    Key? key,
    required this.controller,
    required this.hintText,
    required this.onChanged,
    required this.searchQuery,
    required this.onClear,
    this.fillColor,
    this.borderRadius = 50.0,
    this.padding = EdgeInsets.zero,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Container(
        decoration: BoxDecoration(
          color: fillColor ?? Colors.white.withOpacity(0.5),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            color: Color(0xFF013236),
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: const Color(0xFF013236).withOpacity(0.3),
            ),
            prefixIcon: const Padding(
              padding: EdgeInsets.only(left: 16, right: 10),
              child: Icon(Icons.search_rounded, color: Color(0xFF4EA771), size: 20),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 0),
            suffixIcon: searchQuery.isNotEmpty
                ? GestureDetector(
                    onTap: onClear,
                    child: const Padding(
                      padding: EdgeInsets.only(right: 14),
                      child: Icon(Icons.cancel_rounded, size: 17, color: Color(0xFF4EA771)),
                    ),
                  )
                : null,
            suffixIconConstraints: const BoxConstraints(minWidth: 0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius == 50.0 ? 22 : borderRadius),
              borderSide: BorderSide(
                color: const Color(0xFF013236).withOpacity(0.1),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: const BorderSide(
                color: Color(0xFF4EA771),
                width: 1,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
    );
  }
}
