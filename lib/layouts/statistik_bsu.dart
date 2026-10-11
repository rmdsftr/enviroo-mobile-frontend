import 'package:enviroo/screens/kelola_nasabah_screen.dart';
import 'package:flutter/material.dart';
import 'package:enviroo/core/theme/app_colors.dart';
import 'package:enviroo/core/theme/app_text.dart';

class StatistikBsuScreen extends StatefulWidget {
  final int jumlahNasabah;
  final int jumlahStaff;

  const StatistikBsuScreen({
    super.key,
    required this.jumlahNasabah,
    required this.jumlahStaff,
  });

  @override
  State<StatistikBsuScreen> createState() => _StatistikBsuScreenState();
}

class _StatistikBsuScreenState extends State<StatistikBsuScreen> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Row(
        children: [
          Expanded(
            child: _buildCard(
              icon: Icons.admin_panel_settings_rounded,
              count: widget.jumlahStaff.toString(),
              label: "Staff",
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildCard(
              icon: Icons.people_rounded,
              count: widget.jumlahNasabah.toString(),
              label: "Nasabah",
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => KelolaNasabahScreen()
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required IconData icon,
    required String count,
    required String label,
    void Function()? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child : Container(
        height: 65,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.dark.withValues(alpha: 0.1),
              width: 1,
            )
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.green.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: AppColors.green),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  count,
                  style: AppText.p(18, weight: FontWeight.w700, color: AppColors.dark, height: 1.0),
                ),
                Text(
                  label,
                  style: AppText.w400(11, Color(0xFF7A9E8A)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
