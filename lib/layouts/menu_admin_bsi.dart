import 'package:enviroo/screens/admin_bsi/list_bsu_screen.dart';
import 'package:enviroo/screens/admin_bsi/pengangkutan_bsi_screen.dart';
import 'package:enviroo/screens/admin_bsu/harga_screen.dart';
import 'package:enviroo/screens/admin_bsu/jadwal_screen.dart';
import 'package:enviroo/screens/admin_bsu/riwayat_transaksi_bsu.dart';
import 'package:enviroo/screens/penjualan_eksternal/riwayat_penjualan_screen.dart';
import 'package:enviroo/screens/petugas/penimbangan_screen.dart';
import 'package:enviroo/screens/info_bank_sampah_screen.dart';
import 'package:enviroo/screens/katalog_screen.dart';
import 'package:enviroo/screens/kelola_nasabah_screen.dart';
import 'package:enviroo/screens/penarikan/penarikan_petugas_screen.dart';
import 'package:enviroo/screens/setoran_screen.dart';
import 'package:flutter/material.dart';
import 'package:enviroo/screens/redeem/redeem_bsi_screen.dart';

class MenuAdminBSI extends StatefulWidget {
  @override
  State<MenuAdminBSI> createState() => _MenuAdminBSIState();
}

class _MenuAdminBSIState extends State<MenuAdminBSI> {
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
                "Menu Admin BSU",
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
                        label: "BSU",
                        icon: Icons.house_rounded,
                        color: Color(0xFF8BC34A),
                        iconColor: Color(0xFF013236),
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => ListBsuScreen()));
                        },
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: _buildMenuItem(
                        context: context,
                        label: "Nasabah",
                        icon: Icons.person_rounded,
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
                        label: "Angkut",
                        icon: Icons.fire_truck_rounded,
                        color: Color(0xFF06C0C9),
                        iconColor: Color(0xFF013236),
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const PengangkutanBsiScreen()));
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
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const PerubahanHargaScreen(role: 'petugas_bsi')));
                        },
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: _buildMenuItem(
                        context: context,
                        label: "Penjualan",
                        icon: Icons.monetization_on,
                        color: Color(0xFF06C0C9),
                        iconColor: Color(0xFF013236),
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const RiwayatPenjualanScreen()));
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
                        label: "Redeem",
                        icon: Icons.card_giftcard_rounded,
                        color: Color(0xFFFAA324),
                        iconColor: Color(0xFF013236),
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const RedeemBsiScreen()));
                        },
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: _buildMenuItem(
                        context: context,
                        label: "Penarikan",
                        icon: Icons.account_balance_wallet_rounded,
                        color: Color(0xFF9B51E0),
                        iconColor: Color(0xFF013236),
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const PenarikanPetugasScreen()));
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
    // Hitung lebar agar pas 4 per baris
    final screenWidth = MediaQuery.of(context).size.width;
    final menuWidth = (screenWidth - 60 - 36) / 4; // 60 padding, 36 spacing (12*3)

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: menuWidth, // Fixed width agar konsisten 4 per row
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
