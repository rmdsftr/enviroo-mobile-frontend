import 'package:flutter/material.dart';

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
  }) {
    return Container(
      height: 65,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF4EA771).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: const Color(0xFF4EA771)),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                count,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF013236),
                  height: 1.0,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF7A9E8A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
