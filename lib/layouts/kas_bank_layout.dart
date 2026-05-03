import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Menampilkan kas bank berupa total uang dan emas
/// Dipasang di home screen petugas BSU / BSM / BSI
class KasBankSection extends StatelessWidget {
  final double kasUang;
  final double kasEmas;

  const KasBankSection({
    super.key,
    required this.kasUang,
    required this.kasEmas,
  });

  String _formatRupiah(double v) {
    final f = NumberFormat.decimalPattern('id_ID');
    f.maximumFractionDigits = 0;
    f.minimumFractionDigits = 0;
    return 'Rp ${f.format(v)}';
  }

  String _formatEmas(double v) {
    if (v == v.truncateToDouble()) {
      return '${v.toInt()} gram';
    }
    return '${v.toStringAsFixed(4).replaceAll(RegExp(r'0*$'), '').replaceAll(RegExp(r'\.$'), '')} gram';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(25, 0, 25, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section label
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              'Kas Bank',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF013236).withOpacity(0.7),
                letterSpacing: 0.3,
              ),
            ),
          ),
          // ── Cards row
          Row(
            children: [
              Expanded(child: _buildKasCard(
                label: 'Kas Uang',
                value: _formatRupiah(kasUang),
                icon: Icons.account_balance_wallet_rounded,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF024A4F), Color(0xFF013236)],
                ),
                accentColor: const Color(0xFF4EA771),
              )),
              const SizedBox(width: 12),
              Expanded(child: _buildKasCard(
                label: 'Kas Emas',
                value: _formatEmas(kasEmas),
                icon: Icons.auto_awesome_rounded,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF6B4F12), Color(0xFF3D2C05)],
                ),
                accentColor: const Color(0xFFD4A017),
              )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKasCard({
    required String label,
    required String value,
    required IconData icon,
    required Gradient gradient,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accentColor, size: 20),
          ),
          const SizedBox(height: 12),
          // Label
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.6),
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 4),
          // Value
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
