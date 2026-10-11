import 'package:flutter/material.dart';
import '../core/format/app_date.dart';
import '../core/format/app_number.dart';

import '../models/penarikan_model.dart';
import 'package:enviroo/core/theme/app_colors.dart';
import 'package:enviroo/core/theme/app_text.dart';


class PenarikanDetailHeader extends StatelessWidget {
  final double nominal;
  final String satuan;
  final bool isUang;
  final StatusPenarikan status;
  final String penarikanId;

  const PenarikanDetailHeader({
    super.key,
    required this.nominal,
    required this.satuan,
    required this.isUang,
    required this.status,
    required this.penarikanId,
  });

  @override
  Widget build(BuildContext context) {
    final nominalText =
        AppNumber.nominal(nominal, satuan: satuan, isUang: isUang);

    return Center(
      child: Column(
        children: [
          Text(
            nominalText,
            style: AppText.p(30, weight: FontWeight.w800, color: AppColors.green, letterSpacing: -0.8),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: status.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Text(
              status.label,
              style: AppText.w700(12, status.color),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ID: $penarikanId',
            style: AppText.r(11, AppColors.dark.withValues(alpha: 0.4)),
          ),
        ],
      ),
    );
  }
}

class SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;

  const SectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(width: 1, color: AppColors.dark.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.green),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppText.w700(13, AppColors.dark),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class PenarikanInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const PenarikanInfoRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 125,
            child: Text(
              label,
              style: AppText.r(11, Colors.black.withValues(alpha: 0.5)),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppText.w600(12, AppColors.dark),
            ),
          ),
        ],
      ),
    );
  }
}

class PenarikanRiwayatCard extends StatefulWidget {
  final List<PenarikanRiwayatItem> riwayat;

  const PenarikanRiwayatCard({super.key, required this.riwayat});

  @override
  State<PenarikanRiwayatCard> createState() => _PenarikanRiwayatCardState();
}

class _PenarikanRiwayatCardState extends State<PenarikanRiwayatCard> {
  bool _expanded = false;

  String _fmtDate(DateTime d) =>
      AppDate.tanggalSingkatJam(d);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(width: 1, color: AppColors.dark.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _expanded = !_expanded),
            child: Row(
              children: [
                const Icon(Icons.history_rounded, size: 16, color: AppColors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Riwayat Penarikan',
                    style: AppText.w700(13, AppColors.dark),
                  ),
                ),
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: AppColors.dark.withValues(alpha: 0.4),
                  size: 22,
                ),
              ],
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: !_expanded
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(height: 1, color: AppColors.divider),
                        const SizedBox(height: 6),
                        for (int i = 0; i < widget.riwayat.length; i++) ...[
                          if (i > 0)
                            const Divider(height: 1, color: AppColors.divider),
                          _buildItem(widget.riwayat[i]),
                        ],
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(PenarikanRiwayatItem item) {
    final hasCatatan = item.catatan != null && item.catatan!.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  item.createdBy.isEmpty ? '-' : item.createdBy,
                  style: AppText.w600(13, AppColors.dark),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    item.status.label,
                    style: AppText.w600(12, item.status.color),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _fmtDate(item.createdAt),
                    style: AppText.r(11, Colors.black.withValues(alpha: 0.4)),
                  ),
                ],
              ),
            ],
          ),
          if (hasCatatan) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: const Border(
                  left: BorderSide(color: AppColors.green, width: 3),
                ),
              ),
              child: Text(
                item.catatan!,
                style: AppText.p(12, color: AppColors.dark.withValues(alpha: 0.7), height: 1.4, fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class DetailBarangRow extends StatelessWidget {
  final DetailBarangItem item;
  const DetailBarangRow({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.namaBarang,
                  style: AppText.w600(13, AppColors.dark),
                ),
                const SizedBox(height: 3),
                Text(
                  '${AppNumber.desimal(item.nilaiPoin)} poin',
                  style: AppText.r(11.5, Colors.black.withValues(alpha: 0.45)),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${AppNumber.desimal(item.qty)} item',
                style: AppText.w600(13, AppColors.dark),
              ),
              const SizedBox(height: 3),
              Text(
                '${AppNumber.desimal(item.subtotalPoin)} poin',
                style: AppText.r(11.5, Colors.black.withValues(alpha: 0.45)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
