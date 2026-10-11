import 'package:flutter/material.dart';
import '../../core/format/app_date.dart';
import '../../core/format/app_number.dart';
import 'package:provider/provider.dart';

import '../../models/distribusi_sisa_model.dart';
import '../../providers/distribusi_sisa_provider.dart';
import '../../providers/penjualan_provider.dart' show FetchStatus;
import '../../widgets/topbar_back.dart';
import 'struk_bagi_hasil_bsu_screen.dart';
import 'package:enviroo/core/theme/app_colors.dart';
import 'package:enviroo/core/theme/app_text.dart';
import 'package:enviroo/widgets/state_message.dart';


class DetailDistribusiSisaScreen extends StatefulWidget {
  final String distribusiId;

  const DetailDistribusiSisaScreen({super.key, required this.distribusiId});

  @override
  State<DetailDistribusiSisaScreen> createState() =>
      _DetailDistribusiSisaScreenState();
}

class _DetailDistribusiSisaScreenState
    extends State<DetailDistribusiSisaScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    await context
        .read<DistribusiSisaProvider>()
        .fetchDetail(widget.distribusiId);
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
              const TopBarBack(title: 'Detail Distribusi Sisa'),
              Expanded(
                child: Consumer<DistribusiSisaProvider>(
                  builder: (_, prov, __) {
                    if (prov.detailStatus == FetchStatus.loading) {
                      return const Center(
                          child: CircularProgressIndicator(color: AppColors.green));
                    }
                    if (prov.detailStatus == FetchStatus.error ||
                        prov.detail == null) {
                      return _buildError(
                          prov.detailError ?? 'Gagal memuat detail');
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

  Widget _buildContent(DetailDistribusiSisaModel detail) {
    String fmtNominal(double val, String satuan) =>
        AppNumber.nominalSatuan(val, satuan);

    String fmtSisa(double val) => fmtNominal(val, detail.satuan);

    String tanggalFmt() {
      try {
        final dt = DateTime.parse(detail.createdAt).toLocal();
        return AppDate.tanggalSingkatJam(dt);
      } catch (_) {
        return detail.createdAt;
      }
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      child: Column(
        children: [
          Container(
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
                  child: const Icon(Icons.check_circle_rounded,
                      color: AppColors.green, size: 36),
                ),
                const SizedBox(height: 12),
                Text(
                  'Distribusi Sisa Selesai',
                  style: AppText.w700(17, AppColors.green),
                ),
                const SizedBox(height: 4),
                Text(
                  'ID: ${detail.distribusiId}',
                  textAlign: TextAlign.center,
                  style: AppText.r(11, AppColors.dark.withValues(alpha: 0.45)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _cardHeader('Informasi Distribusi'),
                _infoRow(Icons.calendar_today_rounded, 'Tanggal', tanggalFmt()),
                _divider(),
                _infoRow(Icons.tag_rounded, 'ID Bagi Hasil',
                    detail.bagiHasilId,
                    small: true),
                _divider(),
                _infoRow(Icons.badge_rounded, 'Dibuat Oleh', detail.createdBy),
                _divider(),
                _infoRow(Icons.savings_rounded, 'Total Sisa',
                    fmtSisa(detail.totalSisa)),
              ],
            ),
          ),

          if (detail.penerimaBsi != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _cardHeader('Penerima Bank Induk'),
                  _penerimaRow(
                    p: detail.penerimaBsi!,
                    fmtNominal: fmtNominal,
                    iconColor: AppColors.green,
                    iconBg: AppColors.green.withValues(alpha: 0.08),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _cardHeader('Penerima Bank Unit'),
                if (detail.penerimaBsu.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Tidak ada BSU penerima.',
                      style: AppText.r(12, AppColors.dark.withValues(alpha: 0.45)),
                    ),
                  )
                else
                  ...detail.penerimaBsu.map((bsu) => _penerimaRow(
                    p: bsu,
                    fmtNominal: fmtNominal,
                    iconColor: AppColors.dark,
                    iconBg: AppColors.dark.withValues(alpha: 0.06),
                    showAntar: true,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StrukBagiHasilBsuScreen(
                            penerimaSisaId: bsu.penerimaSisaId),
                      ),
                    ),
                  )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _penerimaRow({
    required PenerimaDistribusiSisaItem p,
    required String Function(double, String) fmtNominal,
    required Color iconColor,
    required Color iconBg,
    bool showAntar = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              margin: const EdgeInsets.only(bottom: 3),
              decoration: BoxDecoration(
                color: AppColors.dark.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    p.namaBank,
                    style: AppText.w600(11, AppColors.dark.withValues(alpha: 0.6)),
                  ),
                  if (onTap != null)
                    Icon(Icons.chevron_right_rounded,
                        size: 14, color: AppColors.dark.withValues(alpha: 0.3)),
                ],
              ),
            ),
            _statCell('Porsi', fmtNominal(p.porsi, p.satuanNominal)),
            _statCell('Transport', fmtNominal(p.transportasi, p.satuanNominal)),
            if (p.transportDetail.isNotEmpty) ...[
              const SizedBox(height: 2),
              ...p.transportDetail.map((t) => Padding(
                padding: const EdgeInsets.only(left: 10, bottom: 2, top: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.subdirectory_arrow_right_rounded,
                            size: 10,
                            color: AppColors.dark.withValues(alpha: 0.3)),
                        const SizedBox(width: 3),
                        Text(t.namaBsu,
                            style: AppText.r(9.5, AppColors.dark.withValues(alpha: 0.4))),
                      ],
                    ),
                    Text(fmtNominal(t.transport, p.satuanNominal),
                        style: AppText.r(9.5, AppColors.dark.withValues(alpha: 0.5))),
                  ],
                ),
              )),
              const SizedBox(height: 2),
            ],
            _statCell('Total', fmtNominal(p.nominalDiterima, p.satuanNominal), isTotal: true),
          ],
        ),
      ),
    );
  }
}

Widget _statCell(String label, String value, {bool isTotal = false}) {
  return Padding(
    padding: const EdgeInsets.only(top: 3, left: 5, right: 5, bottom: 3),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppText.r(12, AppColors.dark.withValues(alpha: 0.45)),
        ),
        Text(
          value,
          style: AppText.p(12, weight: isTotal ? FontWeight.w700 : FontWeight.w500, color: isTotal ? AppColors.green : AppColors.dark.withValues(alpha: 0.75)),
        ),
      ],
    ),
  );
}

Widget _cardHeader(String title) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
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

Widget _divider() =>
    Divider(color: AppColors.dark.withValues(alpha: 0.06), height: 1);
