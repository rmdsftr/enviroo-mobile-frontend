import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/redeem_models.dart';

class RedeemStatusStyle {
  final Color bg;
  final Color fg;
  final Color cardBg;
  final Color border;
  final IconData icon;
  final String label;

  const RedeemStatusStyle({
    required this.bg,
    required this.fg,
    required this.cardBg,
    required this.border,
    required this.icon,
    required this.label,
  });

  static RedeemStatusStyle of(RedeemStatus status) {
    switch (status) {
      case RedeemStatus.waiting:
        return const RedeemStatusStyle(
          bg: Color(0xFFFFF4D6),
          fg: Color(0xFFB07906),
          cardBg: Color(0xFFFFFBF1),
          border: Color(0xFFFAA324),
          icon: Icons.access_time_rounded,
          label: 'Menunggu',
        );
      case RedeemStatus.approved:
        return const RedeemStatusStyle(
          bg: Color(0xFFD9F2DD),
          fg: Color(0xFF1F6F3A),
          cardBg: Color(0xFFEFFBF0),
          border: Color(0xFF4EA771),
          icon: Icons.qr_code_2_rounded,
          label: 'Disetujui',
        );
      case RedeemStatus.success:
        return const RedeemStatusStyle(
          bg: Color(0xFFD6EAFE),
          fg: Color(0xFF0E5BC1),
          cardBg: Color(0xFFF1F7FF),
          border: Color(0xFF1E88E5),
          icon: Icons.check_circle_rounded,
          label: 'Selesai',
        );
      case RedeemStatus.rejected:
        return const RedeemStatusStyle(
          bg: Color(0xFFFADADA),
          fg: Color(0xFFB52121),
          cardBg: Color(0xFFFFF5F5),
          border: Color(0xFFE57373),
          icon: Icons.close_rounded,
          label: 'Ditolak',
        );
      case RedeemStatus.canceled:
        return const RedeemStatusStyle(
          bg: Color(0xFFE5E7EB),
          fg: Color(0xFF4B5563),
          cardBg: Color(0xFFF7F8FA),
          border: Color(0xFFB0B7C3),
          icon: Icons.do_disturb_alt_rounded,
          label: 'Dibatalkan',
        );
      case RedeemStatus.failed:
        return const RedeemStatusStyle(
          bg: Color(0xFFFADADA),
          fg: Color(0xFFB52121),
          cardBg: Color(0xFFFFF5F5),
          border: Color(0xFFE57373),
          icon: Icons.error_rounded,
          label: 'Gagal',
        );
      case RedeemStatus.unknown:
        return const RedeemStatusStyle(
          bg: Color(0xFFE5E7EB),
          fg: Color(0xFF4B5563),
          cardBg: Colors.white,
          border: Color(0xFFB0B7C3),
          icon: Icons.help_outline_rounded,
          label: '-',
        );
    }
  }
}

class RedeemCard extends StatelessWidget {
  final RedeemTransaksi data;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool hideId;
  final bool showNasabah;

  const RedeemCard({
    super.key,
    required this.data,
    this.onTap,
    this.trailing,
    this.hideId = false,
    this.showNasabah = false,
  });

  String _formatDate(DateTime? d) {
    if (d == null) return '-';
    return DateFormat('dd MMM yyyy • HH:mm', 'id_ID').format(d.toLocal());
  }

  String _formatNumber(num n) {
    final format = NumberFormat.decimalPattern('id_ID');
    format.maximumFractionDigits = 4;
    format.minimumFractionDigits = 0;
    return format.format(n);
  }

  @override
  Widget build(BuildContext context) {
    final style = RedeemStatusStyle.of(data.status);
    final reward = data.reward?.namaReward ?? '-';
    final rewardDisplay = reward.isEmpty
        ? '-'
        : '${reward[0].toUpperCase()}${reward.substring(1).toLowerCase()}';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: style.cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: style.border.withOpacity(0.4), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: style.border.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(style.icon, color: style.fg, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Redeem $rewardDisplay',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF013236),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hideId ? '***' : data.transaksiId,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: Colors.black.withOpacity(0.55),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: style.bg,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Text(
                    style.label,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: style.fg,
                    ),
                  ),
                ),
              ],
            ),
            // ── Nasabah identity row (hanya tampil jika showNasabah = true) ──
            if (showNasabah && (data.nasabahName?.isNotEmpty == true || data.nasabahId?.isNotEmpty == true)) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF013236).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person_rounded, size: 14, color: Color(0xFF013236)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        data.nasabahName ?? '-',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF013236),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (data.nasabahId?.isNotEmpty == true)
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF013236).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          data.nasabahId!,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF013236),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _infoTile(
                    label: 'Poin',
                    value: _formatNumber(data.poin),
                  ),
                ),
                Expanded(
                  child: _infoTile(
                    label: data.isSembako ? 'Item' : 'Nominal',
                    value: data.isSembako
                        ? '${data.details.length} item'
                        : data.isEmas
                            ? '${_formatNumber(data.nominal)} gram'
                            : 'Rp ${_formatNumber(data.nominal)}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.schedule_rounded,
                    size: 13, color: Colors.black.withOpacity(0.45)),
                const SizedBox(width: 4),
                Text(
                  _formatDate(data.createdAt),
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: Colors.black.withOpacity(0.55),
                  ),
                ),
                const Spacer(),
                if (trailing != null) trailing!,
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoTile({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11,
            color: Colors.black.withOpacity(0.5),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF013236),
          ),
        ),
      ],
    );
  }
}
