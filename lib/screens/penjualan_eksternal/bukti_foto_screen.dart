import 'dart:io';
import 'package:enviroo/widgets/success_bottom_sheet.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/katalog_provider.dart';
import '../../providers/penjualan_provider.dart';
import '../../widgets/topbar_back.dart';
import '../admin_bsu/inapp_camera_screen.dart';

class _C {
  static const dark = Color(0xFF013236);
  static const green = Color(0xFF4EA771);
  static const accent = Color(0xFF94DF0C);
  static const cardBg = Color(0xFFF7FBF5);
  static const muted = Color(0xFF8A9A92);
  static const danger = Color(0xFFD94848);
  static const border = Color(0xFFE6EDE9);
}

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: _C.danger,
          content: Text('Bukti foto wajib diambil',
              style: TextStyle(fontFamily: 'Poppins')),
        ),
      );
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
      // Refresh riwayat lalu kembali ke Screen 1
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: _C.danger,
          content: Text(
            prov.submitError ?? 'Gagal menyimpan penjualan',
            style: const TextStyle(fontFamily: 'Poppins'),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<PenjualanProvider>();
    final fmt = NumberFormat('#,##0.##########', 'id_ID');

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
                        const Text(
                          'Bukti Serah Terima',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _C.dark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Ambil foto fisik serah terima sampah dengan pihak eksternal sebagai bukti.',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11.5,
                            color: _C.muted,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // ── Photo card ───────────────────────────────
                        GestureDetector(
                          onTap: _ambilFoto,
                          child: Container(
                            height: 220,
                            decoration: BoxDecoration(
                              color: _C.cardBg,
                              borderRadius:
                                  BorderRadius.circular(16),
                              border: Border.all(
                                  color: prov.buktiFoto == null
                                      ? _C.border
                                      : _C.green,
                                  width: 1.5),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: prov.buktiFoto == null
                                ? const Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                          Icons
                                              .photo_camera_rounded,
                                          color: _C.green,
                                          size: 38),
                                      SizedBox(height: 8),
                                      Text(
                                        'Ketuk untuk ambil foto',
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 13,
                                          fontWeight:
                                              FontWeight.w600,
                                          color: _C.dark,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        'Kamera in-app akan terbuka',
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 11,
                                          color: _C.muted,
                                        ),
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
                                              const EdgeInsets
                                                  .all(6),
                                          decoration:
                                              BoxDecoration(
                                            color: Colors.black
                                                .withOpacity(
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

                        // ── Ringkasan ────────────────────────────────
                        const Text(
                          'Ringkasan Transaksi',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _C.dark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.circular(14),
                            border:
                                Border.all(color: _C.border),
                          ),
                          child: Column(
                            children: [
                              _kv('Pembeli', prov.identitasPembeli),
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
                                  const Text(
                                    'Total Penjualan',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: _C.dark,
                                    ),
                                  ),
                                  Builder(builder: (context) {
                                    final satuan =
                                        prov.selectedReward?.satuan ?? '';
                                    final isRp = satuan.toLowerCase() ==
                                            'rupiah' ||
                                        satuan.toLowerCase() == 'rp';

                                    return Text(
                                      isRp
                                          ? 'Rp ${fmt.format(totalHarga)}'
                                          : '${fmt.format(totalHarga)} $satuan',
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: _C.green,
                                      ),
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
                color: Colors.black.withOpacity(0.35),
                child: const Center(
                  child: CircularProgressIndicator(color: _C.accent),
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
                  style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11.5,
                      color: _C.muted)),
            ),
            const Text(': ',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    color: _C.muted,
                    fontSize: 11.5)),
            Expanded(
              child: Text(
                v,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _C.dark,
                ),
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
        border: Border(top: BorderSide(color: _C.border)),
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
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 13.5,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _C.dark,
            foregroundColor: Colors.white,
            disabledBackgroundColor: _C.muted.withOpacity(0.5),
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
              color: isActive ? _C.green : _C.border,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      }),
    );
  }
}
