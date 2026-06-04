import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/penjualan_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/katalog_provider.dart';
import '../../providers/penjualan_provider.dart';
import '../../widgets/custom_snackbar.dart';
import '../../widgets/topbar_back.dart';
import '../admin_bsu/inapp_camera_screen.dart';
import 'detail_penjualan_screen.dart';

class _C {
  static const dark = Color(0xFF013236);
  static const green = Color(0xFF4EA771);
  static const accent = Color(0xFF94DF0C);
  static const cardBg = Color(0xFFF7FBF5);
  static const muted = Color(0xFF8A9A92);
  static const border = Color(0xFFE6EDE9);
}

class HitungPenjualanScreen extends StatefulWidget {
  const HitungPenjualanScreen({super.key});

  @override
  State<HitungPenjualanScreen> createState() => _HitungPenjualanScreenState();
}

class _HitungPenjualanScreenState extends State<HitungPenjualanScreen> {
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
    final prov = context.read<PenjualanProvider>();

    if (prov.buktiFoto == null) {
      _showSnack('Bukti foto serah terima wajib diambil');
      return;
    }

    final auth = context.read<AuthProvider>();
    HapticFeedback.mediumImpact();

    final ok = await prov.submitPenjualan(
      bankId: auth.bankId ?? '',
      adminId: auth.identityId ?? '',
    );

    if (!mounted) return;

    if (ok) {
      final penjualanId = prov.lastPenjualanId ?? '';
      prov.fetchRiwayat(auth.bankId ?? '');
      context.read<KatalogProvider>().silentRefresh(auth.bankId ?? '');
      context.read<DashboardProvider>().requestSaldoRefresh();
      prov.resetForm();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
            builder: (_) => DetailPenjualanScreen(penjualanId: penjualanId)),
        (route) => route.isFirst,
      );
    } else {
      _showSnack(prov.submitError ?? 'Gagal menyimpan penjualan');
    }
  }

  void _showSnack(String msg) => showCustomSnackBar(context, msg);

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<PenjualanProvider>();
    final preview = prov.preview;

    if (preview == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: _C.green)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                const TopBarBack(title: 'Hitung Penjualan'),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _StepIndicator(currentStep: 3),
                        const SizedBox(height: 16),
                        _KalkulasiCard(preview: preview),
                        const SizedBox(height: 16),
                        _sectionTitle('Detail Item Sampah'),
                        const SizedBox(height: 8),
                        ...preview.detailItems.map((e) => _DetailItemRow(item: e, satuan: preview.satuan)),
                        const SizedBox(height: 16),
                        _sectionTitle('Bukti Serah Terima'),
                        const SizedBox(height: 4),
                        const Text(
                          'Ambil foto fisik serah terima sampah dengan pihak eksternal.',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11.5,
                            color: _C.muted,
                          ),
                        ),
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: _ambilFoto,
                          child: Container(
                            width: double.infinity,
                            height: 200,
                            decoration: BoxDecoration(
                              color: _C.cardBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: prov.buktiFoto == null
                                    ? _C.border
                                    : _C.green,
                                width: 1.5,
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: prov.buktiFoto == null
                                ? const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.photo_camera_rounded,
                                          color: _C.green, size: 38),
                                      SizedBox(height: 8),
                                      Text(
                                        'Ketuk untuk ambil foto',
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
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
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.black.withValues(alpha:0.55),
                                            shape: BoxShape.circle,
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
                        const SizedBox(height: 16),
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
                color: Colors.black.withValues(alpha:0.35),
                child: const Center(
                  child: CircularProgressIndicator(color: _C.accent),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) => Text(
        title,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: _C.dark,
        ),
      );
}

// ─── Kalkulasi Card ──────────────────────────────────────────────────────────
class _KalkulasiCard extends StatelessWidget {
  final PreviewPenjualanModel preview;
  const _KalkulasiCard({required this.preview});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.##', 'id_ID');
    final isRp = preview.satuan.toLowerCase() == 'rupiah' ||
        preview.satuan.toLowerCase() == 'rp';
    final totalLabel = isRp
        ? 'Rp ${NumberFormat('#,##0', 'id_ID').format(preview.totalPenjualan)}'
        : '${fmt.format(preview.totalPenjualan)} ${preview.satuan}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.dark.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _C.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Icon(Icons.calculate_rounded,
                    color: _C.green, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Hasil Kalkulasi Penjualan',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: _C.dark.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            totalLabel,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 24,
              color: _C.dark,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Divider(color: _C.dark.withValues(alpha: 0.08), height: 1),
          const SizedBox(height: 10),
          _Chip(label: 'Nasabah', value: '${fmt.format(preview.persenNasabah)}%'),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final String value;
  const _Chip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _C.green.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$label $value',
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 11,
          color: _C.green,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─── Detail Item Row ─────────────────────────────────────────────────────────
class _DetailItemRow extends StatelessWidget {
  final DetailKalkulasiItem item;
  final String satuan;
  const _DetailItemRow({required this.item, required this.satuan});

  String _fmt(double v) {
    final s = satuan.toLowerCase().trim();
    if (s == 'poin') {
      return '${NumberFormat('#,##0.##', 'id_ID').format(v)} poin';
    } else {
      return 'Rp ${NumberFormat('#,##0', 'id_ID').format(v)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmtQty = NumberFormat('#,##0.##', 'id_ID');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: _C.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.namaSampah,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: _C.dark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${fmtQty.format(item.qty)} × ${_fmt(item.hargaJual)}',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: _C.muted,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _fmt(item.subtotal),
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _C.green,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Bottom Bar ──────────────────────────────────────────────────────────────
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
              : const Icon(Icons.save_rounded, size: 20),
          label: Text(
            loading ? 'Menyimpan…' : 'Simpan Transaksi Penjualan',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 13.5,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _C.dark,
            foregroundColor: Colors.white,
            disabledBackgroundColor: _C.muted.withValues(alpha:0.5),
            disabledForegroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50)),
          ),
        ),
      ),
    );
  }
}

// ─── Step Indicator ──────────────────────────────────────────────────────────
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
              color: isActive ? _C.accent : _C.border,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      }),
    );
  }
}
