import 'dart:io';
import 'package:enviroo/widgets/success_bottom_sheet.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/format/app_number.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/katalog_provider.dart';
import '../../providers/penjualan_provider.dart';
import '../../widgets/custom_snackbar.dart';
import '../../widgets/topbar_back.dart';
import '../petugas/inapp_camera_screen.dart';
import 'package:enviroo/core/theme/app_colors.dart';
import 'package:enviroo/core/theme/app_text.dart';


class BuktiFotoScreen extends StatefulWidget {
  const BuktiFotoScreen({super.key});

  @override
  State<BuktiFotoScreen> createState() => _BuktiFotoScreenState();
}

class _BuktiFotoScreenState extends State<BuktiFotoScreen> {
  Future<void> _ambilFoto() async {
    final File? result = await Navigator.push<File?>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const InAppCameraScreen(),
      ),
    );
    if (!mounted) return;
    if (result != null) {
      context.read<PenjualanProvider>().setBuktiFoto(result);
    }
  }

  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();
    final prov = context.read<PenjualanProvider>();

    if (prov.buktiFoto == null) {
      showCustomSnackBar(context, 'Bukti foto wajib diambil');
      return;
    }

    HapticFeedback.mediumImpact();
    final ok = await prov.submitPenjualan(
      bankId: auth.bankId ?? '',
      adminId: auth.identityId ?? '',
    );

    if (!mounted) return;

    if (ok) {
      final katalog = context.read<KatalogProvider>();
      final dashboard = context.read<DashboardProvider>();
      await prov.fetchRiwayat(auth.bankId ?? '');
      katalog.silentRefresh(auth.bankId ?? '');
      dashboard.requestSaldoRefresh();
      prov.resetForm();

      if (!mounted) return;

      await showSuccessBottomSheet(
        context,
        title: 'Berhasil!',
        message: 'Penjualan eksternal berhasil dicatat dan stok sampah sudah diperbarui.',
        buttonLabel: 'Selesai',
        onDismiss: () => Navigator.of(context).popUntil((r) => r.isFirst),
      );
    } else {
      showCustomSnackBar(
          context, prov.submitError ?? 'Gagal menyimpan penjualan');
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<PenjualanProvider>();
    final totalHarga = prov.totalHarga;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                const TopBarBack(title: 'Bukti Foto & Submit'),
                Expanded(
                  child: SingleChildScrollView(
                    padding:
                        const EdgeInsets.fromLTRB(20, 4, 20, 30),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const _StepIndicator(currentStep: 3),
                        const SizedBox(height: 16),
                        Text(
                          'Bukti Serah Terima',
                          style: AppText.w700(16, AppColors.dark),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Ambil foto fisik serah terima sampah dengan pihak eksternal sebagai bukti.',
                          style: AppText.r(11.5, AppColors.muted),
                        ),
                        const SizedBox(height: 16),

                        GestureDetector(
                          onTap: _ambilFoto,
                          child: Container(
                            height: 220,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceMint,
                              borderRadius:
                                  BorderRadius.circular(16),
                              border: Border.all(
                                  color: prov.buktiFoto == null
                                      ? AppColors.border
                                      : AppColors.green,
                                  width: 1.5),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: prov.buktiFoto == null
                                ? Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                          Icons
                                              .photo_camera_rounded,
                                          color: AppColors.green,
                                          size: 38),
                                      SizedBox(height: 8),
                                      Text(
                                        'Ketuk untuk ambil foto',
                                        style: AppText.w600(13, AppColors.dark),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        'Kamera in-app akan terbuka',
                                        style: AppText.r(11, AppColors.muted),
                                      ),
                                    ],
                                  )
                                : Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Image.file(prov.buktiFoto!,
                                          fit: BoxFit.cover),
                                      Positioned(
                                        right: 10,
                                        top: 10,
                                        child: Container(
                                          padding:
                                              EdgeInsets
                                                  .all(6),
                                          decoration:
                                              BoxDecoration(
                                            color: Colors.black
                                                .withValues(alpha: 
                                                    0.55),
                                            shape:
                                                BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.refresh_rounded,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        Text(
                          'Ringkasan Transaksi',
                          style: AppText.w700(13, AppColors.dark),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.circular(14),
                            border:
                                Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            children: [
                              _kv('Pembeli', prov.namaMitra),
                              _kv(
                                  'Reward',
                                  prov.selectedReward
                                          ?.namaReward ??
                                      '-'),
                              _kv('Jumlah Sampah',
                                  '${prov.itemsSampah.length} item'),
                              const Divider(height: 18),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Total Penjualan',
                                    style: AppText.w600(12.5, AppColors.dark),
                                  ),
                                  Builder(builder: (context) {
                                    final satuan =
                                        prov.selectedReward?.satuan ?? '';
                                    return Text(
                                      AppNumber.nominalSatuan(
                                          totalHarga, satuan),
                                      style: AppText.w700(16, AppColors.green),
                                    );
                                  }),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
                _BottomBar(
                  enabled: prov.buktiFoto != null && !prov.submitting,
                  loading: prov.submitting,
                  onSubmit: _submit,
                ),
              ],
            ),
            if (prov.submitting)
              Container(
                color: Colors.black.withValues(alpha: 0.35),
                child: const Center(
                  child: CircularProgressIndicator(color: AppColors.neon),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 110,
              child: Text(k,
                  style: AppText.r(11.5, AppColors.muted)),
            ),
            Text(': ',
                style: AppText.r(11.5, AppColors.muted)),
            Expanded(
              child: Text(
                v,
                style: AppText.w600(12, AppColors.dark),
              ),
            ),
          ],
        ),
      );
}


class _BottomBar extends StatelessWidget {
  final bool enabled;
  final bool loading;
  final VoidCallback onSubmit;
  const _BottomBar({
    required this.enabled,
    required this.loading,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton.icon(
          onPressed: enabled ? onSubmit : null,
          icon: loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                )
              : const Icon(Icons.check_rounded, size: 20),
          label: Text(
            loading ? 'Mengirim…' : 'Submit Transaksi',
            style: AppText.w600(13.5),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.dark,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.muted.withValues(alpha: 0.5),
            disabledForegroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int currentStep;
  const _StepIndicator({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    const total = 3;
    return Row(
      children: List.generate(total, (i) {
        final isActive = i + 1 <= currentStep;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i == total - 1 ? 0 : 6),
            height: 5,
            decoration: BoxDecoration(
              color: isActive ? AppColors.green : AppColors.border,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      }),
    );
  }
}
