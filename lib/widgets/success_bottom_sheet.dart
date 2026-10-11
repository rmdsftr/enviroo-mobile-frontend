import 'package:flutter/material.dart';
import 'package:enviroo/core/theme/app_colors.dart';
import 'package:enviroo/core/theme/app_text.dart';

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
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: 28),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.green.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 36,
              color: AppColors.green,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppText.w700(17, AppColors.dark),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppText.p(12, color: AppColors.dark.withValues(alpha: 0.5), height: 1.6),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                onDismiss?.call();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
              child: Text(
                buttonLabel,
                style: AppText.w600(14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
