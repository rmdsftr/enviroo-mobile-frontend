import 'package:flutter/material.dart';

Future<void> showSuccessBottomSheet(
  BuildContext context, {
  required String title,
  required String message,
  String buttonLabel = 'OK',
  VoidCallback? onDismiss,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isDismissible: false,
    enableDrag: false,
    isScrollControlled: true,
    builder: (_) => _SuccessSheet(
      title: title,
      message: message,
      buttonLabel: buttonLabel,
      onDismiss: onDismiss,
    ),
  );
}

class _SuccessSheet extends StatelessWidget {
  final String title;
  final String message;
  final String buttonLabel;
  final VoidCallback? onDismiss;

  const _SuccessSheet({
    required this.title,
    required this.message,
    required this.buttonLabel,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: 28),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          // Icon
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF4EA771).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 36,
              color: Color(0xFF4EA771),
            ),
          ),
          const SizedBox(height: 20),
          // Title
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF013236),
            ),
          ),
          const SizedBox(height: 8),
          // Message
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              height: 1.6,
              color: const Color(0xFF013236).withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 28),
          // Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                onDismiss?.call();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4EA771),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
              child: Text(
                buttonLabel,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
