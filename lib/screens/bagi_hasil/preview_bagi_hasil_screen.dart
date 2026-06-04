import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/bagi_hasil_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/bagi_hasil_provider.dart';
import '../../providers/penjualan_provider.dart' show FetchStatus;
import '../../widgets/custom_snackbar.dart';
import '../../widgets/topbar_back.dart';
import 'struk_detail_bagi_hasil_screen.dart';

class _C {
  static const dark = Color(0xFF013236);
  static const green = Color(0xFF4EA771);
  static const danger = Color(0xFFD94848);
}

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
                color: const Color(0xFF013236).withValues(alpha: 0.07),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.currency_exchange_rounded,
                  size: 28, color: _C.dark),
            ),
            const SizedBox(height: 16),
            const Text(
              'Konfirmasi Bagi Hasil',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: _C.dark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pastikan data preview sudah benar.\nProses bagi hasil tidak dapat dibatalkan.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                height: 1.6,
                color: _C.dark.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _C.dark,
                      side: BorderSide(color: _C.dark.withValues(alpha: 0.25)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50)),
                    ),
                    child: const Text('Batal',
                        style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _C.dark,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50)),
                    ),
                    child: const Text('Ya, Lanjutkan',
                        style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
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
      backgroundColor: const Color(0xFFF5F7F5),
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
                          child: CircularProgressIndicator(color: _C.green));
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

  Widget _buildError(String msg) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off_rounded,
                  size: 40, color: _C.danger.withValues(alpha: 0.5)),
              const SizedBox(height: 12),
              Text(
                msg,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: _C.dark.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _load,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _C.dark,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Coba Lagi',
                    style: TextStyle(fontFamily: 'Poppins')),
              ),
            ],
          ),
        ),
      );

  Widget _buildContent(PreviewBagiHasilModel preview, bool submitting) {
    final fmtRp = NumberFormat('#,##0', 'id_ID');

    String fmtNilai(double val) => preview.reward.toLowerCase() == 'sembako'
        ? '${fmtRp.format(val)} poin'
        : 'Rp ${fmtRp.format(val)}';

    return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 30),
          child: Column(
            children: [
              // ── Hero Card ─────────────────────────────────────────────
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
                        color: _C.green.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.calculate_rounded,
                          color: _C.green, size: 36),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Preview Bagi Hasil',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                        color: _C.green,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 6),
                      decoration: BoxDecoration(
                        color: _C.green.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Text(
                        preview.reward,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: _C.dark.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Ringkasan Card ────────────────────────────────────────
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
                      children: const [
                        Text(
                          'Ringkasan Bagi Hasil',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: _C.dark,
                          ),
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

              // ── Penerima Nasabah Card (dikelompokkan per bank) ────────
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
                        children: const [
                          Text(
                            'Penerima Nasabah',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: _C.dark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      ...preview.penerima.asMap().entries.map((bankEntry) {
                        final isLastBank =
                            bankEntry.key == preview.penerima.length - 1;
                        final bank = bankEntry.value;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Bank sub-header
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: _C.dark.withValues(alpha: 0.06),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                      Icons.account_balance_rounded,
                                      size: 13,
                                      color: _C.dark),
                                ),
                                const SizedBox(width: 8),
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
                            const SizedBox(height: 8),
                            // Nasabah rows
                            ...bank.nasabahPenerima.asMap().entries.map((e) {
                              final isLastNasabah = e.key ==
                                  bank.nasabahPenerima.length - 1;
                              final n = e.value;
                              return Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 9),
                                    child: Row(
                                      children: [
                                        const SizedBox(width: 4),
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: _C.green
                                                .withValues(alpha: 0.08),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: const Icon(
                                              Icons.person_rounded,
                                              size: 13,
                                              color: _C.green),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            n.namaNasabah.isNotEmpty
                                                ? n.namaNasabah
                                                : n.nasabahId,
                                            style: const TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: _C.dark,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          fmtNilai(n.totalDiterima),
                                          style: const TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: _C.green,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (!isLastNasabah) _divider(),
                                ],
                              );
                            }),
                            if (!isLastBank) ...[
                              const SizedBox(height: 4),
                              Divider(
                                  color:
                                      _C.dark.withValues(alpha: 0.12),
                                  height: 16),
                            ],
                          ],
                        );
                      }),
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
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _C.dark,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: _C.dark.withValues(alpha: 0.4),
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
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: _C.dark.withValues(alpha: isHighlight ? 0.85 : 0.55),
              fontWeight:
                  isHighlight ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: isHighlight ? 13 : 12,
              fontWeight: FontWeight.w700,
              color: isHighlight ? _C.dark : _C.green,
            ),
          ),
        ],
      ),
    );

Widget _divider() =>
    Divider(color: const Color(0xFF013236).withValues(alpha: 0.06), height: 1);
