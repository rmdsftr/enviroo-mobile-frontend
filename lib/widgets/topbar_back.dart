import 'package:enviroo/providers/auth_provider.dart';
import 'package:enviroo/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
          Spacer(),

          if (title == 'Profil')
            GestureDetector(
              onTap: () async {
                // Konfirmasi logout
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    title: const Text('Logout', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
                    content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?', style: TextStyle(fontFamily: 'Poppins')),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Batal', style: TextStyle(color: Colors.grey, fontFamily: 'Poppins')),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Keluar', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  // Panggil fungsi logout dari AuthProvider
                  final authProvider = Provider.of<AuthProvider>(context, listen: false);
                  await authProvider.logout();

                  // Arahkan ke SplashScreen dan hapus semua stack navigasi sebelumnya
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => SplashScreen()),
                      (route) => false,
                    );
                  }
                }
              },
              child: Padding(
                padding: EdgeInsets.only(right: 30, bottom: 7),
                child: Row(
                  children: [
                    Icon(
                      Icons.logout_rounded,
                      size: 12,
                      color: Color(0xFF013236),
                    ),
                    SizedBox(width: 4),
                    Text(
                      "Logout",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF013236),
                      ),
                    )
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
