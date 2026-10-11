import 'package:flutter/material.dart';
import '../../core/format/app_date.dart';
import '../../core/format/app_number.dart';

import 'package:provider/provider.dart';

import '../../models/bagi_hasil_model.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/topbar_back.dart';
import 'struk_bagi_hasil_nasabah.dart';
import 'preview_distribusi_sisa_screen.dart';
import 'package:enviroo/core/theme/app_colors.dart';
import 'package:enviroo/core/theme/app_text.dart';


class StrukDetailBagiHasilScreen extends StatelessWidget {
  final DetailBagiHasilModel detail;
  const StrukDetailBagiHasilScreen({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    String fmtMain(double val) =>
        AppNumber.nominalSatuan(val, detail.satuan);

    String tanggalFmt() {
      try {
        final dt = DateTime.parse(detail.tanggal).toLocal();
        return AppDate.tanggalSingkatJam(dt);
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
                      _HeroCard(bagiHasilId: detail.bagiHasilId),
                      const SizedBox(height: 16),

                      _InfoCard(
                        tanggal: tanggalFmt(),
                        penjualanId: detail.penjualanId,
                        reward: detail.reward,
                        namaPetugas: detail.namaPetugas,
                      ),
                      const SizedBox(height: 16),

                      _RingkasanCard(detail: detail, fmtMain: fmtMain),
                      const SizedBox(height: 16),

                      if (detail.hasPenerima) ...[
                        _PenerimaBankCard(detail: detail),
                        const SizedBox(height: 16),
                      ],

                      if (detail.nasabahLangsung.isNotEmpty) ...[
                        _PenerimaLangsungCard(detail: detail),
                        const SizedBox(height: 16),
                      ],

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
                          label: Text(
                            'Distribusi Sisa',
                            style: AppText.w600(13),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.dark,
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
                color: AppColors.green.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.receipt_long_rounded,
                  color: AppColors.green, size: 36),
            ),
            const SizedBox(height: 12),
            Text(
              'Struk Bagi Hasil',
              style: AppText.w700(17, AppColors.green),
            ),
            const SizedBox(height: 4),
            Text(
              'ID: $bagiHasilId',
              textAlign: TextAlign.center,
              style: AppText.r(11, AppColors.dark.withValues(alpha: 0.45)),
            ),
          ],
        ),
      );
}

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

class _PenerimaBankCard extends StatelessWidget {
  final DetailBagiHasilModel detail;

  const _PenerimaBankCard({required this.detail});

  String _fmtDiterima(NasabahBagiHasil n) => AppNumber.nominalSatuan(n.totalDiterima, n.satuanDiterima);

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
            _cardHeader(Icons.group_rounded, 'Penerima Nasabah'),
            ...detail.penerima.asMap().entries.map((bankEntry) {
              final isLastBank = bankEntry.key == detail.penerima.length - 1;
              final bank = bankEntry.value;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    margin: const EdgeInsets.only(bottom: 6),
                    decoration: BoxDecoration(
                      color: AppColors.dark.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      bank.namaBank,
                      style: AppText.w600(12, AppColors.dark.withValues(alpha: 0.6)),
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
                        color: AppColors.dark.withValues(alpha: 0.12), height: 16),
                  ],
                ],
              );
            }),
          ],
        ),
      );
}

class _PenerimaLangsungCard extends StatelessWidget {
  final DetailBagiHasilModel detail;

  const _PenerimaLangsungCard({required this.detail});

  String _fmtDiterima(NasabahBagiHasil n) => AppNumber.nominalSatuan(n.totalDiterima, n.satuanDiterima);

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
            _cardHeader(Icons.group_rounded, 'Nasabah Penerima'),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nasabah.namaNasabah,
                      style: AppText.w600(12, AppColors.dark),
                    ),
                    Text(
                      'ID: ${nasabah.nasabahId}',
                      style: AppText.r(10, AppColors.dark.withValues(alpha: 0.45)),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    diterima,
                    style: AppText.w700(12, AppColors.green),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.muted),
            ],
          ),
        ),
      );
}

Widget _cardHeader(IconData? icon, String title) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          if (icon != null) ...[Icon(icon, size: 18, color: AppColors.green), const SizedBox(width: 8)],
          Text(
            title,
            style: AppText.w700(13, AppColors.dark),
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
              color: AppColors.green.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 15, color: AppColors.green),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppText.r(10, AppColors.dark.withValues(alpha: 0.45)),
                ),
                Text(
                  value,
                  style: AppText.w600(small ? 10.5 : 12, AppColors.dark),
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
            style: AppText.r(11.5, AppColors.dark.withValues(alpha: 0.55)),
          ),
          Text(
            value,
            style: AppText.w600(12, AppColors.dark),
          ),
        ],
      ),
    );

Widget _divider() =>
    Divider(color: AppColors.dark.withValues(alpha: 0.06), height: 1);
