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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final prov = context.read<DistribusiSisaProvider>();
    await prov.fetchPreview(widget.bagiHasilId);

    if (!mounted) return;

    if (prov.alreadyDistributed && prov.existingDistribusiId != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DetailDistribusiSisaScreen(
            distribusiId: prov.existingDistribusiId!,
          ),
        ),
      );
    }
  }

  Future<void> _onSubmit() async {
    final auth = context.read<AuthProvider>();
    final prov = context.read<DistribusiSisaProvider>();

    final confirmed = await showConfirmBottomSheet(
      context,
      icon: Icons.swap_horiz_rounded,
      title: 'Konfirmasi Distribusi Sisa',
      message: 'Proses ini tidak dapat dibatalkan.',
      cancelLabel: 'Batal',
      confirmLabel: 'Ya, Lanjutkan',
      isDanger: true,
    );

    if (!confirmed || !mounted) return;

    final ok = await prov.submitDistribusiSisa(
        widget.bagiHasilId, auth.identityId ?? '');

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
                          child: CircularProgressIndicator(color: _C.green));
                    }
                    if (prov.previewStatus == FetchStatus.error &&
                        !prov.alreadyDistributed) {
                      return _buildError(
                          prov.previewError ?? 'Gagal memuat preview');
                    }
                    if (prov.previewStatus == FetchStatus.error &&
                        prov.alreadyDistributed) {
                      return const Center(
                          child: CircularProgressIndicator(color: _C.green));
                    }
                    if (prov.preview == null) return const SizedBox.shrink();
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
              Text(msg,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      color: _C.dark.withValues(alpha: 0.5))),
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

  Widget _buildContent(PreviewDistribusiSisaModel preview, bool submitting) {
    final fmtRp = NumberFormat('#,##0', 'id_ID');
    final fmtNum = NumberFormat('#,##0.##########', 'id_ID');
    final isRp = preview.satuan.toLowerCase() == 'rp';

    String fmt(double val) =>
        isRp ? 'Rp ${fmtRp.format(val)}' : '${fmtNum.format(val)} ${preview.satuan}';

    final totalBsu = preview.penerimaBsu.fold(0.0, (s, b) => s + b.nominal);

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
                    borderRadius: BorderRadius.circular(20)),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: _C.green.withValues(alpha: 0.12),
                          shape: BoxShape.circle),
                      child: const Icon(Icons.account_balance_wallet_rounded,
                          color: _C.green, size: 36),
                    ),
                    const SizedBox(height: 12),
                    const Text('Preview Distribusi Sisa',
                        style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w700,
                            fontSize: 17,
                            color: _C.green)),
                    const SizedBox(height: 4),
                    Text('ID: ${preview.bagiHasilId}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            color: _C.dark.withValues(alpha: 0.45))),
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
                    borderRadius: BorderRadius.circular(20)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _cardHeader(Icons.pie_chart_rounded, 'Ringkasan Sisa'),
                    _kvRow('Total Sisa', fmt(preview.totalSisa),
                        highlight: true),
                    _divider(),
                    _kvRow('Porsi BSI', fmt(preview.nominalBsi)),
                    _divider(),
                    _kvRow('Total ke BSU', fmt(totalBsu)),
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
                    borderRadius: BorderRadius.circular(20)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _cardHeader(
                        Icons.account_balance_rounded, 'Bank Unit Penerima'),
                    if (preview.penerimaBsu.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'Tidak ada BSU yang terlibat dalam bagi hasil ini.',
                          style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color: _C.dark.withValues(alpha: 0.45)),
                        ),
                      )
                    else
                      ...preview.penerimaBsu.asMap().entries.map((entry) {
                        final bsu = entry.value;
                        final isLast =
                            entry.key == preview.penerimaBsu.length - 1;
                        return Column(
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                        color: _C.dark.withValues(alpha: 0.06),
                                        borderRadius:
                                            BorderRadius.circular(8)),
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
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(bsu.namaBank,
                                                style: const TextStyle(
                                                    fontFamily: 'Poppins',
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: _C.dark)),
                                            Text(
                                              '${fmtNum.format(bsu.persenKontribusi)}%',
                                              style: TextStyle(
                                                  fontFamily: 'Poppins',
                                                  fontSize: 11,
                                                  color: _C.dark
                                                      .withValues(alpha: 0.5)),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        _subRow('Pokok', fmt(bsu.pokok)),
                                        if (bsu.transportasi > 0)
                                          _subRow('Transportasi',
                                              fmt(bsu.transportasi)),
                                        const SizedBox(height: 4),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text('Total',
                                                style: TextStyle(
                                                    fontFamily: 'Poppins',
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color: _C.dark
                                                        .withValues(alpha: 0.7))),
                                            Text(fmt(bsu.nominal),
                                                style: const TextStyle(
                                                    fontFamily: 'Poppins',
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w700,
                                                    color: _C.green)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!isLast) _divider(),
                          ],
                        );
                      }),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── Submit Button ─────────────────────────────────────────────────
        if (preview.penerimaBsu.isNotEmpty)
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
                    fontSize: 13),
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
          Text(title,
              style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: _C.dark)),
        ],
      ),
    );

Widget _kvRow(String label, String value, {bool highlight = false}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: highlight ? 12 : 11.5,
                  color: _C.dark.withValues(alpha: highlight ? 0.85 : 0.55),
                  fontWeight:
                      highlight ? FontWeight.w600 : FontWeight.normal)),
          Text(value,
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: highlight ? 13 : 12,
                  fontWeight: FontWeight.w700,
                  color: highlight ? _C.dark : _C.green)),
        ],
      ),
    );

Widget _subRow(String label, String value) => Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  color: _C.dark.withValues(alpha: 0.45))),
          Text(value,
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  color: _C.dark.withValues(alpha: 0.65))),
        ],
      ),
    );

Widget _divider() =>
    Divider(color: _C.dark.withValues(alpha: 0.06), height: 1);
