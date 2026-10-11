import 'package:enviroo/screens/bagi_hasil/riwayat_bagi_hasil_screen.dart';
import 'package:enviroo/screens/penjualan/riwayat_penjualan_screen.dart';
import 'package:enviroo/screens/penarikan/penarikan_petugas_screen.dart';
import 'package:enviroo/screens/penimbangan/penimbangan_screen.dart';
import 'package:enviroo/screens/katalog/katalog_screen.dart';
import 'package:enviroo/screens/jadwal/navigasi_jadwal_screen.dart';
import 'package:enviroo/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:enviroo/core/theme/app_colors.dart';
import 'package:enviroo/core/theme/app_text.dart';

class MenuAdminBSM extends StatefulWidget {
  @override
  State<MenuAdminBSM> createState() => _MenuAdminBSMState();
}

class _MenuAdminBSMState extends State<MenuAdminBSM> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Menu Petugas BSM",
              style: AppText.w600(15, AppColors.dark),
            ),
          ),
          const SizedBox(height: 15),
          LayoutBuilder(
            builder: (context, constraints) {
              double itemWidth = (constraints.maxWidth - 60) / 4;
              return Wrap(
                spacing: 20,
                runSpacing: 16,
                children: [
                  SizedBox(
                    width: itemWidth,
                    child: _buildMenuItem(
                      context: context,
                      label: "Timbang",
                      icon: Icons.document_scanner_rounded,
                      color: AppColors.warningAlt,
                      iconColor: Colors.white,
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => PenimbanganScreen())),
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _buildMenuItem(
                      context: context,
                      label: "Penjualan",
                      icon: Icons.monetization_on_rounded,
                      color: AppColors.green,
                      iconColor: Colors.white,
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const RiwayatPenjualanScreen())),
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _buildMenuItem(
                      context: context,
                      label: "Penarikan",
                      icon: Icons.account_balance_wallet_rounded,
                      color: const Color(0xFFEB5757),
                      iconColor: Colors.white,
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const PenarikanPetugasScreen())),
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _buildMenuItem(
                      context: context,
                      label: "Bagi Hasil",
                      icon: Icons.account_balance_rounded,
                      color: const Color(0xFF2D9CDB),
                      iconColor: Colors.white,
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const RiwayatBagiHasilScreen())),
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _buildMenuItem(
                      context: context,
                      label: "Katalog",
                      icon: Icons.collections_bookmark_rounded,
                      color: AppColors.green,
                      iconColor: Colors.white,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => KatalogScreen(
                            role: context.read<AuthProvider>().role,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _buildMenuItem(
                      context: context,
                      label: "Jadwal",
                      icon: Icons.calendar_month_rounded,
                      color:  const Color(0xFF2D9CDB),
                      iconColor: Colors.white,
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const NavigasiJadwalScreen())),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color color,
    required Color iconColor,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(
                icon,
                size: 37,
                color: iconColor,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppText.w600(11, AppColors.dark),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
