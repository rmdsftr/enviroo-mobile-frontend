import 'package:enviroo/screens/katalog_screen.dart';
import 'package:enviroo/screens/penarikan_screen.dart';
import 'package:enviroo/screens/setoran_screen.dart';
import 'package:flutter/material.dart';

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
              ),
            ),
          ),
          SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMenuItem(
                context: context,
                label: "Setoran",
                icon: Icons.account_balance_wallet_rounded,
                color: Color(0xFF4EA771), // Medium green
                iconColor: Colors.white,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SetoranScreen()),
                ),
              ),
              _buildMenuItem(
                context: context,
                label: "Penarikan",
                icon: Icons.north_rounded,
                color: Color(0xFF06C0C9), // Teal/Turquoise
                iconColor: Colors.white,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PenarikanScreen()),
                ),
              ),
              _buildMenuItem(
                context: context,
                label: "Katalog",
                icon: Icons.grid_view_rounded,
                color: Color(0xFF8BC34A), // Light green
                iconColor: Color(0xFF013236),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => KatalogScreen()),
                ),
              ),
              _buildMenuItem(
                context: context,
                label: "Info BSU",
                icon: Icons.location_on_rounded,
                color: Color(0xFFFAA324), // Soft orange accent
                iconColor: Color(0xFF013236),
                onTap: () {
                  // Add navigation when ready
                },
              ),
            ],
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
          Container(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
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
          )
        ],
      ),
    );
  }
}