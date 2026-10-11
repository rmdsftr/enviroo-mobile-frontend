import 'package:flutter/material.dart';
import 'package:enviroo/core/theme/app_colors.dart';
import 'package:enviroo/core/theme/app_text.dart';

Future<bool> showConfirmBottomSheet(
  BuildContext context, {
  required IconData icon,
  Color iconColor = AppColors.dark,
  required String title,
  required String message,
  String cancelLabel = 'Batal',
  required String confirmLabel,
  bool isDanger = false,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _ConfirmSheet(
      icon: icon,
      iconColor: iconColor,
      title: title,
      message: message,
      cancelLabel: cancelLabel,
      confirmLabel: confirmLabel,
      isDanger: isDanger,
    ),
  );
  return result ?? false;
}

class _ConfirmSheet extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final String cancelLabel;
  final String confirmLabel;
  final bool isDanger;

  const _ConfirmSheet({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    required this.cancelLabel,
    required this.confirmLabel,
    required this.isDanger,
  });

  @override
  Widget build(BuildContext context) {
    final confirmColor = isDanger ? const Color(0xFFD32F2F) : AppColors.dark;

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
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 28, color: iconColor),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppText.w700(16, AppColors.dark),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppText.p(12, color: AppColors.dark.withValues(alpha: 0.5), height: 1.6),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.dark,
                    side: BorderSide(
                      color: AppColors.dark.withValues(alpha: 0.25),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                  child: Text(
                    cancelLabel,
                    style: AppText.w600(13),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: confirmColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                  child: Text(
                    confirmLabel,
                    style: AppText.w600(13),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
