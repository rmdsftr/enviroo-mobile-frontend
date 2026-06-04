import 'package:enviroo/screens/nasabah/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:enviroo/providers/auth_provider.dart';

class ProfilBsuScreen extends StatefulWidget {
  final String namaBank;
  final String alamatBank;
  final String? namaInduk;
  final String? photoBank;

  const ProfilBsuScreen({
    super.key,
    required this.namaBank,
    required this.alamatBank,
    this.namaInduk,
    this.photoBank,
  });

  @override
  State<ProfilBsuScreen> createState() => _ProfilBsuScreenState();
}

class _ProfilBsuScreenState extends State<ProfilBsuScreen> {
  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    
    String roleText = 'Petugas BSU';
    if (auth.role == 'admin_bsu') {
      roleText = 'Admin BSU';
    } else if (auth.role == 'petugas_bsm') {
      roleText = 'Petugas BSM';
    } else if (auth.role == 'admin_bsm') {
      roleText = 'Admin BSM';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF94DF0C), // Green border
                width: 2.5,
              ),
              color: Colors.white,
            ),
            child: ClipOval(
              child: Image.network(
                widget.photoBank != null && widget.photoBank!.isNotEmpty
                    ? widget.photoBank!
                    : "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQcsLMxl59B-uLQ0g27IEy0JRCIkqGJY8oKbw&s",
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Image.asset(
                  "assets/images/profile.png",
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.namaBank,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF013236),
                    height: 1.2,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  roleText,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF057642),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
