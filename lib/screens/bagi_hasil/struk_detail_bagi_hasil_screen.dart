import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:provider/provider.dart';

import '../../models/bagi_hasil_model.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/topbar_back.dart';
import '../nasabah/struk_bagi_hasil_nasabah.dart';
import 'preview_distribusi_sisa_screen.dart';

class _C {
  static const dark = Color(0xFF013236);
  static const green = Color(0xFF4EA771);
  static const muted = Color(0xFF8A9A92);
}

class StrukDetailBagiHasilScreen extends StatelessWidget {
  final DetailBagiHasilModel detail;
  const StrukDetailBagiHasilScreen({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    final fmtRp = NumberFormat('#,##0', 'id_ID');
    final fmtNum = NumberFormat('#,##0.##########', 'id_ID');

    String fmtMain(double val) {
      if (detail.satuan.toLowerCase() == 'rp') return 'Rp ${fmtRp.format(val)}';
      return '${fmtNum.format(val)} ${detail.satuan}';
    }

    String tanggalFmt() {
      try {
        final dt = DateTime.parse(detail.tanggal);
        return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(dt);
      } catch (_) {
        return detail.tanggal;
      }
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bg_struk.webp'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const TopBarBack(title: 'Struk Bagi Hasil'),
              Expanded(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                  child: Column(
                    children: [
                      // ── Hero ────────────────────────────────────────────
                      _HeroCard(bagiHasilId: detail.bagiHasilId),
                      const SizedBox(height: 16),

                      // ── Info ─────────────────────────────────────────────
                      _InfoCard(
                        tanggal: tanggalFmt(),
                        penjualanId: detail.penjualanId,
                        reward: detail.reward,
                        namaPetugas: detail.namaPetugas,
                      ),
                      const SizedBox(height: 16),

                      // ── Ringkasan ─────────────────────────────────────────
                      _RingkasanCard(detail: detail, fmtMain: fmtMain),
                      const SizedBox(height: 16),

                      // ── Penerima (dikelompokkan per bank) ─────────────────
                      if (detail.hasPenerima) ...[
                        _PenerimaBankCard(
                            detail: detail, fmtRp: fmtRp, fmtNum: fmtNum),
                        const SizedBox(height: 16),
                      ],

                      // ── Nasabah Langsung ──────────────────────────────────
                      if (detail.nasabahLangsung.isNotEmpty) ...[
                        _PenerimaLangsungCard(
                          detail: detail,
                          fmtRp: fmtRp,
                          fmtNum: fmtNum,
                        ),
                        const SizedBox(height: 16),
                      ],

                      // ── Tombol Distribusi Sisa (hanya petugas_bsi dan reward uang) ────────
                      if (context.read<AuthProvider>().role == 'petugas_bsi' &&
                          detail.reward.toLowerCase() == 'uang')
                        ElevatedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PreviewDistribusiSisaScreen(
                                bagiHasilId: detail.bagiHasilId,
                              ),
                            ),
                          ),
                          icon: const Icon(
                              Icons.account_balance_wallet_rounded,
                              size: 18),
                          label: const Text(
                            'Distribusi Sisa',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _C.dark,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 50),
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50)),
                            elevation: 0,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Hero Card ─────────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  final String bagiHasilId;
  const _HeroCard({required this.bagiHasilId});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _C.green.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.receipt_long_rounded,
                  color: _C.green, size: 36),
            ),
            const SizedBox(height: 12),
            const Text(
              'Struk Bagi Hasil',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                fontSize: 17,
                color: _C.green,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'ID: $bagiHasilId',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                color: _C.dark.withValues(alpha: 0.45),
              ),
            ),
          ],
        ),
      );
}

// ── Info Card ─────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final String tanggal;
  final String penjualanId;
  final String reward;
  final String namaPetugas;

  const _InfoCard({
    required this.tanggal,
    required this.penjualanId,
    required this.reward,
    required this.namaPetugas,
  });

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _cardHeader(Icons.info_outline_rounded, 'Informasi Transaksi'),
            _infoRow(Icons.calendar_today_rounded, 'Tanggal', tanggal),
            _divider(),
            _infoRow(Icons.tag_rounded, 'ID Penjualan', penjualanId, small: true),
            _divider(),
            _infoRow(Icons.card_giftcard_rounded, 'Jenis Reward', reward),
            _divider(),
            _infoRow(Icons.badge_rounded, 'Petugas', namaPetugas),
          ],
        ),
      );
}

// ── Ringkasan Card ────────────────────────────────────────────────────────────

class _RingkasanCard extends StatelessWidget {
  final DetailBagiHasilModel detail;
  final String Function(double) fmtMain;
  const _RingkasanCard({required this.detail, required this.fmtMain});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _cardHeader(Icons.bar_chart_rounded, 'Ringkasan Bagi Hasil'),
            _kvRow('Gross Penjualan', fmtMain(detail.grossBank)),
            _divider(),
            _kvRow('Ke Nasabah', fmtMain(detail.totalDistribusiNasabah)),
            _divider(),
            _kvRow('Sisa Bagi Hasil', fmtMain(detail.sisaBagiHasil)),
          ],
        ),
      );
}

// ── Penerima Bank Card ────────────────────────────────────────────────────────

class _PenerimaBankCard extends StatelessWidget {
  final DetailBagiHasilModel detail;
  final NumberFormat fmtRp;
  final NumberFormat fmtNum;

  const _PenerimaBankCard({
    required this.detail,
    required this.fmtRp,
    required this.fmtNum,
  });

  String _fmtDiterima(NasabahBagiHasil n) {
    if (n.satuanDiterima.toLowerCase() == 'rp') {
      return 'Rp ${fmtRp.format(n.totalDiterima)}';
    }
    return '${fmtNum.format(n.totalDiterima)} ${n.satuanDiterima}';
  }

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _cardHeader(Icons.people_rounded, 'Penerima Nasabah'),
            ...detail.penerima.asMap().entries.map((bankEntry) {
              final isLastBank = bankEntry.key == detail.penerima.length - 1;
              final bank = bankEntry.value;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            bank.namaBank,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _C.dark.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...bank.nasabahPenerima.asMap().entries.map((e) {
                    final isLastNasabah =
                        e.key == bank.nasabahPenerima.length - 1;
                    return Column(
                      children: [
                        _NasabahTile(
                          nasabah: e.value,
                          diterima: _fmtDiterima(e.value),
                        ),
                        if (!isLastNasabah) _divider(),
                      ],
                    );
                  }),
                  if (!isLastBank) ...[
                    const SizedBox(height: 4),
                    Divider(
                        color: _C.dark.withValues(alpha: 0.12), height: 16),
                  ],
                ],
              );
            }),
          ],
        ),
      );
}

// ── Penerima Langsung ─────────────────────────────────────────────────────────

class _PenerimaLangsungCard extends StatelessWidget {
  final DetailBagiHasilModel detail;
  final NumberFormat fmtRp;
  final NumberFormat fmtNum;

  const _PenerimaLangsungCard({
    required this.detail,
    required this.fmtRp,
    required this.fmtNum,
  });

  String _fmtDiterima(NasabahBagiHasil n) {
    if (n.satuanDiterima.toLowerCase() == 'rp') {
      return 'Rp ${fmtRp.format(n.totalDiterima)}';
    }
    return '${fmtNum.format(n.totalDiterima)} ${n.satuanDiterima}';
  }

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _cardHeader(Icons.person_rounded, 'Nasabah Langsung'),
            ...detail.nasabahLangsung.asMap().entries.map((e) => Column(
                  children: [
                    if (e.key > 0) _divider(),
                    _NasabahTile(
                      nasabah: e.value,
                      diterima: _fmtDiterima(e.value),
                    ),
                  ],
                )),
          ],
        ),
      );
}

// ── Nasabah Tile ──────────────────────────────────────────────────────────────

class _NasabahTile extends StatelessWidget {
  final NasabahBagiHasil nasabah;
  final String diterima;

  const _NasabahTile({
    required this.nasabah,
    required this.diterima,
  });

  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                StrukBagiHasilNasabah(penerimaId: nasabah.penerimaId),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: _C.green.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.person_rounded,
                    size: 15, color: _C.green),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nasabah.namaNasabah,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: _C.dark,
                      ),
                    ),
                    Text(
                      'ID: ${nasabah.nasabahId}',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        color: _C.dark.withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    diterima,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _C.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, size: 18, color: _C.muted),
            ],
          ),
        ),
      );
}

// ── Shared helpers ────────────────────────────────────────────────────────────

Widget _cardHeader(IconData icon, String title) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: _C.green),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: _C.dark,
            ),
          ),
        ],
      ),
    );

Widget _infoRow(IconData icon, String label, String value,
        {bool small = false}) =>
    Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: _C.green.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 15, color: _C.green),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    color: _C.dark.withValues(alpha: 0.45),
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: small ? 10.5 : 12,
                    color: _C.dark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

Widget _kvRow(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11.5,
              color: _C.dark.withValues(alpha: 0.55),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _C.dark,
            ),
          ),
        ],
      ),
    );

Widget _divider() =>
    Divider(color: _C.dark.withValues(alpha: 0.06), height: 1);
