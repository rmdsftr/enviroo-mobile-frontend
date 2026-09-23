import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/penarikan_model.dart';

/// Card item penarikan buat sisi petugas — nampilin nama nasabah, reward,
/// tanggal, dan status pill. Dipakai di [PenarikanPetugasScreen] (riwayat
/// selesai) dan [PenarikanWaitingScreen] (pengajuan & siap dijemput).
class PenarikanPetugasCard extends StatelessWidget {
  final PenarikanItem item;
  final VoidCallback onTap;

  const PenarikanPetugasCard({super.key, required this.item, required this.onTap});

  static const Color dark = Color(0xFF013236);

  Color get _statusColor => item.status.color;

  String get _statusLabel => item.status.label;

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd MMM yyyy, HH:mm', 'id_ID')
        .format(item.createdAt);
    final nasabah = item.namaNasabah?.isNotEmpty == true
        ? item.namaNasabah!
        : item.nasabahId ?? '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          width: 1,
          color: dark.withValues(alpha: 0.1),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nasabah,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: dark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.namaReward.isEmpty
                            ? '-'
                            : _capitalize(item.namaReward),
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: Colors.black.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dateStr,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: Colors.black.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Text(
                    _statusLabel,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1).toLowerCase()}';
}
