import 'package:enviroo/screens/admin_bsi/home_bsi_screen.dart';
import 'package:enviroo/screens/admin_bsu/home_bsu_screen.dart';
import 'package:enviroo/screens/info_bank_sampah_screen.dart';
import 'package:enviroo/screens/katalog_screen.dart';
import 'package:enviroo/screens/nasabah/riwayat_setoran_screen.dart';
import 'package:enviroo/screens/penarikan/penarikan_nasabah_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:enviroo/providers/auth_provider.dart';

class MainMenu extends StatefulWidget {
  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {
  @override
  Widget build(BuildContext context) {

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 20, horizontal: 30),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Menu Utama",
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF013236),
              ),
            ),
          ),
          SizedBox(height: 15),
          LayoutBuilder(
              builder: (context, constraints){
                double itemWidth = (constraints.maxWidth - 60) / 4;
                return Wrap(
                  spacing: 20,
                  runSpacing: 16,
                  children: [
                    SizedBox(
                      width: itemWidth,
                      child: _buildMenuItem(
                        context: context,
                        label: "Setoran",
                        icon: Icons.qr_code_rounded,
                        color: const Color(0xFF9B51E0), // Ungu
                        iconColor: Colors.white,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const RiwayatSetoranScreen()),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: _buildMenuItem(
                        context: context,
                        label: "Penarikan",
                        icon: Icons.account_balance_wallet_rounded,
                        color: const Color(0xFFF2994A), // Oren
                        iconColor: Colors.white,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const PenarikanNasabahScreen()),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: _buildMenuItem(
                        context: context,
                        label: "Katalog",
                        icon: Icons.grid_view_rounded,
                        color: const Color(0xFF2D9CDB), // Biru
                        iconColor: Colors.white,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => KatalogScreen()),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: _buildMenuItem(
                        context: context,
                        label: "Bank Sampah",
                        icon: Icons.location_on_rounded,
                        color: const Color(0xFF1ABC9C), // Toska
                        iconColor: Colors.white,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => InfoBankSampahScreen()),
                        ),
                      ),
                    ),
                  ],
                );
              }
          )
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
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  size: 37,
                  color: iconColor,
                ),
              ),
            ),
            SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                color: Color(0xFF013236),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            )
          ],
        ),
    );
  }
}
