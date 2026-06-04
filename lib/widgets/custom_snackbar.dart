import 'package:flutter/material.dart';

enum SnackBarType { error, success }

void showCustomSnackBar(
  BuildContext context,
  String message, {
  SnackBarType type = SnackBarType.error,
}) {
  final bool isError = type == SnackBarType.error;

  final Color borderColor  = isError ? const Color(0xFFFFD6D6) : const Color(0xFFB8E6C8);
  final Color iconBgColor  = isError ? const Color(0xFFFFEBEE) : const Color(0xFFEBF7F0);
  final Color iconColor    = isError ? const Color(0xFFB61E20) : const Color(0xFF2E7D4F);
  final IconData icon      = isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      elevation: 0,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor),
      ),
      content: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: Color(0xFF222222),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
