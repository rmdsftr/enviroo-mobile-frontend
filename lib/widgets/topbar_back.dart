import 'package:flutter/material.dart';
import 'package:enviroo/core/theme/app_colors.dart';
import 'package:enviroo/core/theme/app_text.dart';

class TopBarBack extends StatelessWidget {
  final String title;
  final VoidCallback? onBack;

  const TopBarBack({
    super.key,
    required this.title,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 12),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: onBack ?? () => Navigator.pop(context),
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 17,
              ),
              color: AppColors.dark,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            title,
            style: AppText.w600(15, AppColors.dark),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
