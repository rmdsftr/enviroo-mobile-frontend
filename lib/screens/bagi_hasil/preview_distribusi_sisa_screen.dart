import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/distribusi_sisa_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/distribusi_sisa_provider.dart';
import '../../providers/penjualan_provider.dart' show FetchStatus;
import '../../widgets/confirm_bottom_sheet.dart';
import '../../widgets/topbar_back.dart';
import 'detail_distribusi_sisa_screen.dart';

class _C {
  static const dark = Color(0xFF013236);
  static const green = Color(0xFF4EA771);
  static const muted = Color(0xFF8A9A92);
  static const danger = Color(0xFFD94848);
}

class PreviewDistribusiSisaScreen extends StatefulWidget {
  final String bagiHasilId;

  const PreviewDistribusiSisaScreen({super.key, required this.bagiHasilId});

  @override
  State<PreviewDistribusiSisaScreen> createState() =>
      _PreviewDistribusiSisaScreenState();
}

class _PreviewDistribusiSisaScreenState
    extends State<PreviewDistribusiSisaScreen> {
  // bankId → true berarti dicentang (antar mandiri / diantar_oleh = "bsu")
  final Map<String, bool> _antarMandiri = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final prov = context.read<DistribusiSisaProvider>();
    await prov.fetchPreview(widget.bagiHasilId);

    if (!mounted) return;

    // Jika sudah pernah didistribusikan, langsung ke halaman detail
    if (prov.alreadyDistributed && prov.existingDistribusiId != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DetailDistribusiSisaScreen(
            distribusiId: prov.existingDistribusiId!,
          ),
        ),
      );
      return;
    }

    // Inisialisasi state checkbox dari data preview
    if (prov.preview != null) {
      setState(() {
        for (final bsu in prov.preview!.bsuTerlibat) {
          _antarMandiri.putIfAbsent(bsu.bankId, () => false);
        }
      });
    }
  }

  Future<void> _onSubmit() async {
    final auth = context.read<AuthProvider>();
    final prov = context.read<DistribusiSisaProvider>();
    final adminId = auth.identityId ?? '';

    final confirmed = await showConfirmBottomSheet(
      context,
      icon: Icons.swap_horiz_rounded,
      title: 'Konfirmasi Distribusi Sisa',
      message: 'Pastikan pilihan pengiriman sudah benar. Proses ini tidak dapat dibatalkan.',
      cancelLabel: 'Batal',
      confirmLabel: 'Ya, Lanjutkan',
      isDanger: true,
    );

    if (!confirmed || !mounted) return;

    final pengirimanBsu = _antarMandiri.entries
        .map((e) => {
              'bank_id': e.key,
              'diantar_oleh': e.value ? 'bsu' : 'bsi',
            })
        .toList();

    final ok = await prov.submitDistribusiSisa(
        widget.bagiHasilId, adminId, pengirimanBsu);

    if (!mounted) return;

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(prov.submitError ?? 'Submit distribusi sisa gagal',
            style: const TextStyle(fontFamily: 'Poppins')),
        backgroundColor: _C.danger,
      ));
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => DetailDistribusiSisaScreen(
          distribusiId: prov.newDistribusiId!,
        ),
      ),
    );
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
              const TopBarBack(title: 'Distribusi Sisa Bagi Hasil'),
              Expanded(
                child: Consumer<DistribusiSisaProvider>(
                  builder: (_, prov, __) {
                    if (prov.previewStatus == FetchStatus.loading) {
                      return const Center(
                          child:
                              CircularProgressIndicator(color: _C.green));
                    }
                    if (prov.previewStatus == FetchStatus.error &&
                        !prov.alreadyDistributed) {
                      return _buildError(
                          prov.previewError ?? 'Gagal memuat preview');
                    }
                    if (prov.previewStatus == FetchStatus.error &&
                        prov.alreadyDistributed) {
                      // Sedang redirect, tampilkan loading
                      return const Center(
                          child:
                              CircularProgressIndicator(color: _C.green));
                    }
                    if (prov.preview == null) {
                      return const SizedBox.shrink();
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

  Widget _buildContent(
      PreviewDistribusiSisaModel preview, bool submitting) {
    final fmtRp = NumberFormat('#,##0', 'id_ID');
    final fmtNum = NumberFormat('#,##0.##########', 'id_ID');
    final isRp = preview.satuan.toLowerCase() == 'rp';

    String fmtSisa(double val) =>
        isRp ? 'Rp ${fmtRp.format(val)}' : '${fmtNum.format(val)} ${preview.satuan}';

    return Stack(
      children: [
        SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
          child: Column(
            children: [
              // ── Hero ──────────────────────────────────────────────────
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
                      child: const Icon(Icons.account_balance_wallet_rounded,
                          color: _C.green, size: 36),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Preview Distribusi Sisa',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                        color: _C.green,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID: ${preview.bagiHasilId}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: _C.dark.withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Ringkasan Sisa ─────────────────────────────────────────
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
                    _cardHeader(Icons.pie_chart_rounded, 'Ringkasan Sisa'),
                    _kvRow('Total Sisa', fmtSisa(preview.totalSisa),
                        highlight: true),
                    _divider(),
                    _kvRow('Porsi BSI', '${fmtNum.format(preview.porsiBsi)}%'),
                    _divider(),
                    _kvRow('Porsi BSU', '${fmtNum.format(preview.porsiBsu)}%'),
                    _divider(),
                    _kvRow('Porsi Transport',
                        '${fmtNum.format(preview.porsiTransport)}%'),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Tabel BSU ──────────────────────────────────────────────
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
                    _cardHeader(
                        Icons.account_balance_rounded, 'Bank Unit Penerima'),
                    const SizedBox(height: 4),
                    if (preview.bsuTerlibat.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'Tidak ada BSU yang terlibat dalam bagi hasil ini.',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: _C.dark.withValues(alpha: 0.45),
                          ),
                        ),
                      )
                    else ...[
                      // Header tabel
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Nama Bank Unit',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _C.dark.withValues(alpha: 0.55),
                                ),
                              ),
                            ),
                            Text(
                              'Antar Mandiri',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _C.dark.withValues(alpha: 0.55),
                              ),
                            ),
                          ],
                        ),
                      ),
                      _divider(),
                      ...preview.bsuTerlibat.asMap().entries.map((entry) {
                        final bsu = entry.value;
                        final isLast =
                            entry.key == preview.bsuTerlibat.length - 1;
                        return Column(
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
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
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          bsu.namaBank,
                                          style: const TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: _C.dark,
                                          ),
                                        ),
                                        Text(
                                          '${fmtNum.format(bsu.kontribusiPersen)}% kontribusi',
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 10,
                                            color: _C.dark
                                                .withValues(alpha: 0.45),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Checkbox(
                                    value:
                                        _antarMandiri[bsu.bankId] ?? false,
                                    activeColor: _C.dark,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(4)),
                                    onChanged: (val) => setState(() {
                                      _antarMandiri[bsu.bankId] =
                                          val ?? false;
                                    }),
                                  ),
                                ],
                              ),
                            ),
                            if (!isLast) _divider(),
                          ],
                        );
                      }),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _C.dark.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline_rounded,
                                size: 14,
                                color: _C.dark.withValues(alpha: 0.45)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Centang "Antar Mandiri" jika BSU mengantarkan sampah mereka sendiri. '
                                'Tidak perlu dicentang jika BSI yang mengangkuat sampah ke BSU.',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 10,
                                  color: _C.dark.withValues(alpha: 0.5),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── Submit Button ─────────────────────────────────────────────────
        if (preview.bsuTerlibat.isNotEmpty)
          Positioned(
            left: 20,
            right: 20,
            bottom: 24,
            child: ElevatedButton.icon(
              onPressed: submitting ? null : _onSubmit,
              icon: submitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded, size: 18),
              label: Text(
                submitting ? 'Memproses...' : 'Submit Sisa Distribusi',
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
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50)),
                elevation: 0,
              ),
            ),
          ),
      ],
    );
  }
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

Widget _kvRow(String label, String value, {bool highlight = false}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: highlight ? 12 : 11.5,
              color: _C.dark.withValues(alpha: highlight ? 0.85 : 0.55),
              fontWeight:
                  highlight ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: highlight ? 13 : 12,
              fontWeight: FontWeight.w700,
              color: highlight ? _C.dark : _C.green,
            ),
          ),
        ],
      ),
    );

Widget _divider() =>
    Divider(color: _C.dark.withValues(alpha: 0.06), height: 1);
