import 'package:enviroo/widgets/profile_corner.dart';
import 'package:flutter/material.dart';

class TopBarCustom extends StatelessWidget
    implements PreferredSizeWidget {

  @override
  Size get preferredSize => const Size.fromHeight(120);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFC1E6BA),
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Image.asset(
            "assets/images/logo-enviroo.png",
            height: 22,
          ),
          Row(
            children: [
              const Icon(
                Icons.circle_notifications_rounded,
                size: 40,
                color: Colors.black,
              ),
              const SizedBox(width: 12),
              ProfileCorner(),
            ],
          )
        ],
      ),
    );
  }
}
