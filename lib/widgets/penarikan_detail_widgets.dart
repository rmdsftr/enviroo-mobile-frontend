import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/penarikan_model.dart';

/// Widget bersama untuk layar detail penarikan (nasabah & petugas) supaya
/// kartunya konsisten satu desain di kedua sisi.

const Color _primary = Color(0xFF4EA771);
const Color _dark = Color(0xFF013236);

/// Header gaya struk: nominal besar, badge status, dan ID transaksi — dipakai
/// paling atas di layar detail penarikan (nasabah & petugas).
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
    final f = NumberFormat.decimalPattern('id_ID');
    f.maximumFractionDigits = 4;
    f.minimumFractionDigits = 0;
    final nominalText = isUang
        ? 'Rp ${f.format(nominal)}'
        : '${f.format(nominal)} ${satuan.isEmpty ? 'poin' : satuan}';

    return Center(
      child: Column(
        children: [
          Text(
            nominalText,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: _primary,
              letterSpacing: -0.8,
            ),
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
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: status.color,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ID: $penarikanId',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              color: _dark.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}

/// Card generik icon + judul + divider, dipakai untuk semua section
/// (Informasi Nasabah, Informasi Penarikan, Detail Barang, Estimasi Konfirmasi, dst).
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
        border: Border.all(width: 1, color: _dark.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: _primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _dark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

/// Baris label-value, dipakai di dalam [SectionCard].
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
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                color: Colors.black.withValues(alpha: 0.5),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _dark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Card "Riwayat Penarikan" expandable — tap judul untuk buka/tutup daftar
/// log status. Dipakai di layar detail nasabah maupun petugas.
class PenarikanRiwayatCard extends StatefulWidget {
  final List<PenarikanRiwayatItem> riwayat;

  const PenarikanRiwayatCard({super.key, required this.riwayat});

  @override
  State<PenarikanRiwayatCard> createState() => _PenarikanRiwayatCardState();
}

class _PenarikanRiwayatCardState extends State<PenarikanRiwayatCard> {
  bool _expanded = false;

  String _fmtDate(DateTime d) =>
      DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(d);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(width: 1, color: _dark.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _expanded = !_expanded),
            child: Row(
              children: [
                const Icon(Icons.history_rounded, size: 16, color: _primary),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Riwayat Penarikan',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _dark,
                    ),
                  ),
                ),
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: _dark.withValues(alpha: 0.4),
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
                        const Divider(height: 1, color: Color(0xFFF0F0F0)),
                        const SizedBox(height: 6),
                        for (int i = 0; i < widget.riwayat.length; i++) ...[
                          if (i > 0)
                            const Divider(height: 1, color: Color(0xFFF0F0F0)),
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
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _dark,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    item.status.label,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: item.status.color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _fmtDate(item.createdAt),
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: Colors.black.withValues(alpha: 0.4),
                    ),
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
                color: const Color(0xFFF5F7F5),
                borderRadius: BorderRadius.circular(10),
                border: const Border(
                  left: BorderSide(color: _primary, width: 3),
                ),
              ),
              child: Text(
                item.catatan!,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: _dark.withValues(alpha: 0.7),
                  height: 1.4,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Breakdown item barang (sembako) 2-kolom: nama+nilai poin (kiri),
/// qty+subtotal poin (kanan). Dipakai di [SectionCard] "Detail Barang".
class DetailBarangRow extends StatelessWidget {
  final DetailSembakoItem item;
  const DetailBarangRow({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final f = NumberFormat.decimalPattern('id_ID');
    f.maximumFractionDigits = 2;
    f.minimumFractionDigits = 0;

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
                  item.namaSembako,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _dark,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${f.format(item.nilaiPoin)} poin',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11.5,
                    color: Colors.black.withValues(alpha: 0.45),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${f.format(item.qty)} item',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _dark,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${f.format(item.subtotalPoin)} poin',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11.5,
                  color: Colors.black.withValues(alpha: 0.45),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
