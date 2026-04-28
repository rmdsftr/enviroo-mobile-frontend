import 'package:enviroo/screens/notifikasi_screen.dart';
import 'package:enviroo/widgets/profile_corner.dart';
import 'package:flutter/material.dart';

class TopBarCustom extends StatelessWidget implements PreferredSizeWidget {
  final Color backgroundColor;
  final String? logo;
  final Color borderFoto;
  final Color bgFoto;

  const TopBarCustom({
    super.key,
    this.backgroundColor = const Color(0xFFEAF8E7),
    this.logo = "assets/images/logo-fix.png",
    this.borderFoto = const Color(0xFF94DF0C),
    this.bgFoto = const Color(0xFF013236),
  });

  @override
  Size get preferredSize => const Size.fromHeight(120);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Image.asset(
            logo ?? "assets/images/logo-fix.png",
            height: 22,
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => NotifikasiScreen()));
                },
                child: const Icon(
                  Icons.circle_notifications_rounded,
                  size: 40,
                  color: Color(0xFF013236),
                ),
              ),
              const SizedBox(width: 12),
              ProfileCorner(
                borderPhoto: borderFoto,
                bgPhoto: bgFoto,
              ),
            ],
          )
        ],
      ),
    );
  }
}
