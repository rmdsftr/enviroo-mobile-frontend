import 'package:flutter/material.dart';

import '../core/format/app_date.dart';
import '../models/penarikan_model.dart';
import 'package:enviroo/core/theme/app_colors.dart';
import 'package:enviroo/core/theme/app_text.dart';

class PenarikanPetugasCard extends StatelessWidget {
  final PenarikanItem item;
  final VoidCallback onTap;

  const PenarikanPetugasCard({super.key, required this.item, required this.onTap});

  static const Color dark = AppColors.dark;

  Color get _statusColor => item.status.color;

  String get _statusLabel => item.status.label;

  @override
  Widget build(BuildContext context) {
    final dateStr = AppDate.tanggalSingkatJam(item.createdAt);
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
                        style: AppText.w600(13, dark),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.namaReward.isEmpty
                            ? '-'
                            : _capitalize(item.namaReward),
                        style: AppText.r(11, Colors.black.withValues(alpha: 0.5)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dateStr,
                        style: AppText.r(11, Colors.black.withValues(alpha: 0.4)),
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
                    style: AppText.w700(10, _statusColor),
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
