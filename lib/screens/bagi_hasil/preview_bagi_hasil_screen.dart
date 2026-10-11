import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format/app_number.dart';
import '../../models/bagi_hasil_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/bagi_hasil_provider.dart';
import '../../providers/penjualan_provider.dart' show FetchStatus;
import '../../widgets/custom_snackbar.dart';
import '../../widgets/topbar_back.dart';
import 'struk_detail_bagi_hasil_screen.dart';
import 'package:enviroo/core/theme/app_colors.dart';
import 'package:enviroo/core/theme/app_text.dart';
import 'package:enviroo/widgets/state_message.dart';


class PreviewBagiHasilScreen extends StatefulWidget {
  final String penjualanId;
  final String bankId;

  const PreviewBagiHasilScreen({
    super.key,
    required this.penjualanId,
    required this.bankId,
  });

  @override
  State<PreviewBagiHasilScreen> createState() =>
      _PreviewBagiHasilScreenState();
}

class _PreviewBagiHasilScreenState extends State<PreviewBagiHasilScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    await context
        .read<BagiHasilProvider>()
        .fetchPreview(widget.penjualanId, widget.bankId);
  }

  Future<void> _onConfirm() async {
    final auth = context.read<AuthProvider>();
    final adminId = auth.identityId ?? '';
    final prov = context.read<BagiHasilProvider>();

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36, height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.dark.withValues(alpha: 0.07),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.currency_exchange_rounded,
                  size: 28, color: AppColors.dark),
            ),
            const SizedBox(height: 16),
            Text(
              'Konfirmasi Bagi Hasil',
              style: AppText.w700(15, AppColors.dark),
            ),
            const SizedBox(height: 8),
            Text(
              'Pastikan data preview sudah benar.\nProses bagi hasil tidak dapat dibatalkan.',
              textAlign: TextAlign.center,
              style: AppText.p(12, color: AppColors.dark.withValues(alpha: 0.5), height: 1.6),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.dark,
                      side: BorderSide(color: AppColors.dark.withValues(alpha: 0.25)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50)),
                    ),
                    child: Text('Batal',
                        style: AppText.w600(13)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.dark,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50)),
                    ),
                    child: Text('Ya, Lanjutkan',
                        style: AppText.w600(13)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    final ok = await prov.submitBagiHasil(
        widget.penjualanId, widget.bankId, adminId);

    if (!mounted) return;

    if (!ok) {
      showCustomSnackBar(context, prov.submitError ?? 'Bagi hasil gagal');
      return;
    }

    await prov.fetchDetail(widget.penjualanId);

    if (!mounted) return;

    if (prov.detailStatus == FetchStatus.error || prov.detail == null) {
      showCustomSnackBar(context, prov.detailError ?? 'Gagal mengambil struk bagi hasil');
      return;
    }

    showCustomSnackBar(context, 'Bagi hasil berhasil dilakukan',
        type: SnackBarType.success);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            StrukDetailBagiHasilScreen(detail: prov.detail!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
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
              const TopBarBack(title: 'Preview Bagi Hasil'),
              Expanded(
                child: Consumer<BagiHasilProvider>(
                  builder: (_, prov, __) {
                    if (prov.previewStatus == FetchStatus.loading) {
                      return const Center(
                          child: CircularProgressIndicator(color: AppColors.green));
                    }
                    if (prov.previewStatus == FetchStatus.error ||
                        prov.preview == null) {
                      return _buildError(
                          prov.previewError ?? 'Gagal memuat preview');
                    }
                    return _buildContent(prov.preview!, prov.submitting);
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

  Widget _buildContent(PreviewBagiHasilModel preview, bool submitting) {
    final isBarang = preview.reward.toLowerCase() == 'barang';

    String fmtNilai(double val) =>
        AppNumber.nominalSatuan(val, 'poin', isUang: !isBarang);

    return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 30),
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
                      child: const Icon(Icons.calculate_rounded,
                          color: AppColors.green, size: 36),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Preview Bagi Hasil',
                      style: AppText.w700(17, AppColors.green),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.green.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Text(
                        preview.reward,
                        style: AppText.w500(11, AppColors.dark.withValues(alpha: 0.6)),
                      ),
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
                    Row(
                      children: [
                        Text(
                          'Ringkasan Bagi Hasil',
                          style: AppText.w700(13, AppColors.dark),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _kvRow('Gross Penjualan',
                        fmtNilai(preview.summary.grossBank),
                        isHighlight: true),
                    _divider(),
                    _kvRow('Ke Nasabah',
                        fmtNilai(preview.summary.totalDistribusiNasabah)),
                    _divider(),
                    _kvRow('Sisa Bagi Hasil',
                        fmtNilai(preview.summary.sisaBagiHasil)),
                  ],
                ),
              ),

              if (preview.penerima.isNotEmpty) ...[
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
                      Row(
                        children: [
                          Text(
                            'Penerima Nasabah',
                            style: AppText.w700(13, AppColors.dark),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      ...preview.penerima.map((bank) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            margin: const EdgeInsets.only(top:10),
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
                            final isLastNasabah = e.key == bank.nasabahPenerima.length - 1;
                            final n = e.value;
                            return Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 9),
                                  child: Row(
                                    children: [
                                      const SizedBox(width: 4),
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: AppColors.green.withValues(alpha: 0.08),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(Icons.person_rounded,
                                            size: 13, color: AppColors.green),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          n.namaNasabah.isNotEmpty ? n.namaNasabah : n.nasabahId,
                                          style: AppText.w500(12, AppColors.dark),
                                        ),
                                      ),
                                      Text(
                                        fmtNilai(n.totalDiterima),
                                        style: AppText.w700(12, AppColors.green),
                                      ),
                                    ],
                                  ),
                                ),
                                if (!isLastNasabah) _divider(),
                              ],
                            );
                          }),
                        ],
                      )),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: submitting ? null : _onConfirm,
                icon: submitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.check_circle_rounded, size: 18),
                label: Text(
                  submitting ? 'Memproses...' : 'Konfirmasi Bagi Hasil',
                  style: AppText.w600(13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.dark,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.dark.withValues(alpha: 0.4),
                  minimumSize: const Size(double.infinity, 50),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50)),
                  elevation: 0,
                ),
              ),
            ],
          ),
        );
  }
}

Widget _kvRow(String label, String value, {bool isHighlight = false}) =>
    Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppText.p(12, weight: isHighlight ? FontWeight.w600 : FontWeight.normal, color: AppColors.dark.withValues(alpha: isHighlight ? 0.85 : 0.55)),
          ),
          Text(
            value,
            style: AppText.w700(isHighlight ? 13 : 12, isHighlight ? AppColors.dark : AppColors.green),
          ),
        ],
      ),
    );

Widget _divider() =>
    Divider(color: AppColors.dark.withValues(alpha: 0.06), height: 1);
