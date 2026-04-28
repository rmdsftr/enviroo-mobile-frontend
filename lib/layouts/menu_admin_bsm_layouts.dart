import 'package:enviroo/screens/admin_bsu/harga_screen.dart';
import 'package:enviroo/screens/admin_bsu/jadwal_screen.dart';
import 'package:enviroo/screens/admin_bsu/riwayat_transaksi_bsu.dart';
import 'package:enviroo/screens/penjualan_eksternal/riwayat_penjualan_screen.dart';
import 'package:enviroo/screens/petugas/penimbangan_screen.dart';
import 'package:enviroo/screens/kelola_nasabah_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:enviroo/providers/auth_provider.dart';

class MenuAdminBSM extends StatefulWidget {
  @override
  State<MenuAdminBSM> createState() => _MenuAdminBSMState();
}

class _MenuAdminBSMState extends State<MenuAdminBSM> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 25),
      child: Column(
        children: [
          Padding(
              padding: EdgeInsets.only(left: 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Menu Admin BSM",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          SizedBox(height: 15),
          LayoutBuilder(
              builder: (context, constraints){
                double itemWidth = (constraints.maxWidth - 30) / 4;

                return Wrap(
                  spacing: 10,
                  runSpacing: 16,
                  children: [
                    SizedBox(
                      width: itemWidth,
                      child: _buildMenuItem(
                        context: context,
                        label: "Nasabah",
                        icon: Icons.people_alt_rounded,
                        color: Color(0xFF8BC34A),
                        iconColor: Color(0xFF013236),
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => KelolaNasabahScreen()));
                        },
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: _buildMenuItem(
                        context: context,
                        label: "Timbang",
                        icon: Icons.document_scanner_rounded,
                        color: Color(0xFFFAA324),
                        iconColor: Color(0xFF013236),
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => PenimbanganScreen()));
                        },
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: _buildMenuItem(
                        context: context,
                        label: "Harga",
                        icon: Icons.price_change_rounded,
                        color: Color(0xFF4EA771),
                        iconColor: Color(0xFF013236),
                        onTap: () {
                          final authRole = Provider.of<AuthProvider>(context, listen: false).role;
                          Navigator.push(context, MaterialPageRoute(builder: (context) => PerubahanHargaScreen(role: authRole)));
                        },
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: _buildMenuItem(
                        context: context,
                        label: "Reward",
                        icon: Icons.emoji_events,
                        color: Color(0xFF06C0C9),
                        iconColor: Color(0xFF013236),
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => RiwayatTransaksiBsuScreen()));
                        },
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: _buildMenuItem(
                        context: context,
                        label: "Jadwal",
                        icon: Icons.calendar_month,
                        color: Color(0xFF8BC34A),
                        iconColor: Color(0xFF013236),
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => JadwalScreen()));
                        },
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: _buildMenuItem(
                        context: context,
                        label: "Penjualan",
                        icon: Icons.monetization_on,
                        color: Color(0xFF8BC34A),
                        iconColor: Color(0xFF013236),
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const RiwayatPenjualanScreen()));
                        },
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
    final screenWidth = MediaQuery.of(context).size.width;
    final menuWidth = (screenWidth - 60 - 36) / 4; 

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: menuWidth,
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(15),
              ),
              padding: EdgeInsets.all(15),
              child: Icon(
                icon,
                size: 35,
                color: iconColor,
              ),
            ),
            SizedBox(height: 7),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            )
          ],
        ),
      ),
    );
  }
}
