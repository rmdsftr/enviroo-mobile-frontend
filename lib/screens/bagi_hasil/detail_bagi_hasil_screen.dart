import 'package:flutter/material.dart';
import '../../core/format/app_date.dart';
import '../../core/format/app_number.dart';
import 'package:provider/provider.dart';

import '../../models/bagi_hasil_bank_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/bagi_hasil_bank_provider.dart';
import '../../widgets/topbar_back.dart';
import '../bagi_hasil/detail_distribusi_sisa_screen.dart';
import 'struk_bagi_hasil_nasabah.dart';
import 'package:enviroo/core/theme/app_colors.dart';
import 'package:enviroo/core/theme/app_text.dart';
import 'package:enviroo/widgets/state_message.dart';


class DetailBagiHasilScreen extends StatefulWidget {
  final String bagiHasilId;
  const DetailBagiHasilScreen({super.key, required this.bagiHasilId});

  @override
  State<DetailBagiHasilScreen> createState() => _DetailBagiHasilScreenState();
}

class _DetailBagiHasilScreenState extends State<DetailBagiHasilScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    context.read<BagiHasilBankProvider>().fetchDetail(widget.bagiHasilId);
  }

  @override
  Widget build(BuildContext context) {
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
              const TopBarBack(title: 'Detail Bagi Hasil'),
              Expanded(
                child: Consumer<BagiHasilBankProvider>(
                  builder: (_, prov, __) {
                    if (prov.detailStatus == BhBankStatus.loading) {
                      return const Center(
                          child: CircularProgressIndicator(color: AppColors.green));
                    }
                    if (prov.detailStatus == BhBankStatus.error ||
                        prov.detail == null) {
                      return _buildError(prov.detailError ?? 'Gagal memuat detail');
                    }
                    return _buildContent(prov.detail!);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError(String msg) => StateMessage(
        illustration: StateArt.error,
        message: msg,
        action: StateRetryButton(onPressed: _load),
      );

  Widget _buildContent(BagiHasilBankDetail d) {
    final role = context.read<AuthProvider>().role;
    final isBsm = role == 'petugas_bsm';

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      child: Column(
        children: [
          _buildHero(d),
          const SizedBox(height: 16),
          _buildRingkasan(d),
          if (isBsm) ...[
            Builder(builder: (_) {
              final List<BhNasabahPenerima> nasabah = [
                if (d.nasabahBsi != null) ...d.nasabahBsi!,
                for (final p in d.penerima) ...p.nasabahPenerima,
              ];
              if (nasabah.isEmpty) return const SizedBox.shrink();
              return Column(children: [
                const SizedBox(height: 16),
                _buildPenerimaBsmSection(nasabah),
              ]);
            }),
          ] else ...[
            if (d.penerima.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildPenerimaSection(d),
            ],
            if (d.nasabahBsi != null && d.nasabahBsi!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildNasabahBsiCard(d),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildHero(BagiHasilBankDetail d) {
    final color = _rewardColor(d.rewardId);
    final icon = _rewardIcon(d.rewardId);
    final tanggal =
        AppDate.tanggalPenuhJam(d.tanggal);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 36),
          ),
          const SizedBox(height: 12),
          Text(
            'Bagi Hasil Berhasil',
            style: AppText.w700(16, color),
          ),
          const SizedBox(height: 3),
          Text(
            'ID : ${d.bagiHasilId}',
            style: AppText.w500(10, AppColors.dark.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.dark.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              tanggal,
              style: AppText.w500(10, AppColors.dark.withValues(alpha: 0.6)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRingkasan(BagiHasilBankDetail d) {
    String satuan = 'rp';
    final firstNasabah = d.penerima.isNotEmpty
        ? d.penerima.first.nasabahPenerima.isNotEmpty
            ? d.penerima.first.nasabahPenerima.first
            : null
        : null;
    if (firstNasabah != null) {
      satuan = firstNasabah.satuanDiterima;
    } else if (d.nasabahBsi != null && d.nasabahBsi!.isNotEmpty) {
      satuan = d.nasabahBsi!.first.satuanDiterima;
    }

    final lihatDistribusiBtn = d.distribusiId != null
        ? GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DetailDistribusiSisaScreen(
                    distribusiId: d.distribusiId!),
              ),
            ),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Lihat Distribusi',
                style: AppText.w600(10, AppColors.green),
              ),
            ),
          )
        : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader('Ringkasan'),
          _infoRow(Icons.payments_rounded, 'Gross Bagi Hasil',
              _fmtBySatuan(d.grossBsi, satuan)),
          _divider(),
          _infoRow(Icons.group_rounded, 'Total ke Nasabah',
              _fmtBySatuan(d.totalDistribusiNasabah, satuan)),
          _divider(),
          _infoRow(Icons.savings_rounded, 'Sisa Bagi Hasil',
              _fmtBySatuan(d.sisaBagiHasil, satuan),
              trailing: lihatDistribusiBtn),
        ],
      ),
    );
  }

  Widget _buildPenerimaSection(BagiHasilBankDetail d) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader('Penerima (${d.penerima.length} BSU)'),
          ...d.penerima.asMap().entries.map((entry) {
            final isLast = entry.key == d.penerima.length - 1;
            return Column(
              children: [
                _buildBsuBlock(entry.value, d.rewardId),
                if (!isLast) _divider(),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBsuBlock(BhPenerimaItem bsu, int rewardId) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
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
              bsu.namaBank,
              style: AppText.w600(11, AppColors.dark.withValues(alpha: 0.6)),
            ),
          ),
          if (bsu.nasabahPenerima.isNotEmpty)
            ...bsu.nasabahPenerima.map((n) => _buildNasabahRow(n)),
        ],
      ),
    );
  }

  Widget _buildNasabahBsiCard(BagiHasilBankDetail d) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader('Nasabah Penerima (${d.nasabahBsi!.length})'),
          ...d.nasabahBsi!.map((n) => _buildNasabahRow(n)),
        ],
      ),
    );
  }

  Widget _buildPenerimaBsmSection(List<BhNasabahPenerima> nasabah) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader('Penerima (${nasabah.length} nasabah)'),
          ...nasabah.map((n) => _buildNasabahRow(n)),
        ],
      ),
    );
  }

  Widget _buildNasabahRow(BhNasabahPenerima n) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StrukBagiHasilNasabah(penerimaId: n.penerimaId),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.green.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.person_rounded, size: 13, color: AppColors.green),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                n.namaNasabah,
                style: AppText.w600(12, AppColors.dark),
              ),
            ),
            const SizedBox(width: 8),
            Row(
              children: [
                Text(
                  _fmtBySatuan(n.totalDiterima, n.satuanDiterima),
                  style: AppText.w700(12, AppColors.green),
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right_rounded,
                    size: 14, color: AppColors.dark.withValues(alpha: 0.3)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Color _rewardColor(int rewardId) {
  if (rewardId == 2) return const Color(0xFFF2C94C);
  if (rewardId == 3) return const Color(0xFF9B51E0);
  return AppColors.green;
}

IconData _rewardIcon(int rewardId) {
  if (rewardId == 2) return Icons.diamond_rounded;
  if (rewardId == 3) return Icons.toll_rounded;
  return Icons.payments_rounded;
}

String _fmtBySatuan(double val, String satuan) =>
    AppNumber.tampakRupiah(satuan)
        ? AppNumber.rupiah(val,
            maksDesimal: AppNumber.presisiSistem)
        : AppNumber.denganSatuan(val, satuan);

Widget _cardHeader(String title) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: AppText.w700(13, AppColors.dark),
      ),
    );

Widget _infoRow(IconData icon, String label, String value,
        {bool small = false, Widget? trailing}) =>
    Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
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
          if (trailing != null) trailing,
        ],
      ),
    );

Widget _divider() => Divider(color: AppColors.dark.withValues(alpha: 0.06), height: 1);
