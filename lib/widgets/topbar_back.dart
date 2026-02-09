import 'package:flutter/material.dart';

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
              color: const Color(0xFF013236),
            ),
          ),
          const SizedBox(width: 5),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              color: Color(0xFF013236),
            ),
          ),
        ],
      ),
    );
  }
}
