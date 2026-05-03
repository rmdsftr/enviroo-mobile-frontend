import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/redeem_models.dart';
import '../../providers/redeem_nasabah_provider.dart';
import '../../widgets/redeem_card.dart';
import '../../widgets/topbar_back.dart';
import 'qr_penarikan_screen.dart';

class DetailPenarikanScreen extends StatelessWidget {
  final RedeemTransaksi item;

  const DetailPenarikanScreen({super.key, required this.item});

  static const Color primary = Color(0xFF4EA771);
  static const Color dark = Color(0xFF013236);

  String _formatNumber(num n) {
    final f = NumberFormat.decimalPattern('id_ID');
    f.maximumFractionDigits = 4;
    f.minimumFractionDigits = 0;
    return f.format(n);
  }

  String _formatDate(DateTime? d) {
    if (d == null) return '-';
    return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(d.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final style = RedeemStatusStyle.of(item.status);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      body: SafeArea(
        child: Column(
          children: [
            const TopBarBack(title: 'Detail Penarikan'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Status Header Card ──────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: style.cardBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: style.border.withOpacity(0.4),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: style.border.withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(style.icon, color: style.fg, size: 26),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Penarikan ${item.reward?.namaReward ?? ''}',
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: dark,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      item.transaksiId,
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 11,
                                        color: Colors.black.withOpacity(0.5),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: style.bg,
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child: Text(
                                  style.label,
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: style.fg,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (item.status == RedeemStatus.success) ...[
                            const SizedBox(height: 14),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E88E5).withOpacity(0.08),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.check_circle_rounded,
                                      size: 18, color: Color(0xFF1E88E5)),
                                  SizedBox(width: 8),
                                  Text(
                                    'Penarikan telah berhasil diproses',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1E88E5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Info Section ────────────────────────────────────
                    _SectionCard(
                      title: 'Informasi Penarikan',
                      children: [
                        _InfoRow(label: 'Jenis Reward',
                            value: item.reward?.namaReward.toUpperCase() ?? '-'),
                        _InfoRow(label: 'Poin Digunakan',
                            value: '${_formatNumber(item.poin)} pts'),
                        if (!item.isSembako)
                          _InfoRow(
                            label: 'Nominal',
                            value: item.isEmas
                                ? '${_formatNumber(item.nominal)} gram'
                                : 'Rp ${_formatNumber(item.nominal)}',
                          ),
                        _InfoRow(
                          label: 'Tanggal Diajukan',
                          value: _formatDate(item.createdAt),
                        ),
                        if (item.status == RedeemStatus.success)
                          _InfoRow(
                            label: 'Tanggal Selesai',
                            value: _formatDate(item.updatedAt),
                          ),
                        if (item.catatan != null && item.catatan!.isNotEmpty)
                          _InfoRow(label: 'Catatan', value: item.catatan!),
                        if (item.namaPetugas != null &&
                            item.namaPetugas!.isNotEmpty)
                          _InfoRow(label: 'Diproses oleh',
                              value: item.namaPetugas!),
                      ],
                    ),

                    // ── Sembako Detail ──────────────────────────────────
                    if (item.isSembako && item.details.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _SectionCard(
                        title: 'Detail Sembako',
                        children: item.details.map((d) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FAF3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.shopping_basket_rounded,
                                    size: 18, color: primary),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    d.namaSembako ?? d.sembakoId,
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: dark,
                                    ),
                                  ),
                                ),
                                Text(
                                  'x${_formatNumber(d.qty)}',
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: primary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  '${_formatNumber(d.subtotalPoin)} pts',
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: dark,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],

                    const SizedBox(height: 28),

                    // ── Action Buttons ──────────────────────────────────
                    if (item.status == RedeemStatus.approved) ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            foregroundColor: Colors.white,
                            padding:
                                const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50)),
                            elevation: 0,
                          ),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => QrPenarikanScreen(
                                  transaksiId: item.transaksiId),
                            ),
                          ),
                          icon: const Icon(Icons.qr_code_2_rounded),
                          label: const Text(
                            'Tampilkan QR',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    if (item.status == RedeemStatus.waiting) ...[
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding:
                                const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50)),
                          ),
                          onPressed: () async {
                            final ok = await context
                                .read<RedeemNasabahProvider>()
                                .cancelRedeem(item.transaksiId);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                behavior: SnackBarBehavior.floating,
                                content: Text(ok
                                    ? 'Pengajuan berhasil dibatalkan'
                                    : 'Gagal membatalkan pengajuan'),
                                backgroundColor: ok ? primary : Colors.red,
                              ),
                            );
                            if (ok && context.mounted) {
                              Navigator.pop(context);
                            }
                          },
                          icon: const Icon(Icons.cancel_outlined, size: 18),
                          label: const Text(
                            'Batalkan Pengajuan',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helper Widgets ────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF013236),
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: Colors.black.withOpacity(0.5),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF013236),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
