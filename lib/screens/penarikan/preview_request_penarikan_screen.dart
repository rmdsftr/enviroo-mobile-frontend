import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/penarikan_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/penarikan_nasabah_provider.dart';
import '../../widgets/topbar_back.dart';
import 'detail_penarikan_screen.dart';

class PreviewRequestPenarikanScreen extends StatefulWidget {
  final PenarikanFormData formData;

  const PreviewRequestPenarikanScreen({
    super.key,
    required this.formData,
  });

  @override
  State<PreviewRequestPenarikanScreen> createState() =>
      _PreviewRequestPenarikanScreenState();
}

class _PreviewRequestPenarikanScreenState
    extends State<PreviewRequestPenarikanScreen> {
  static const Color primary = Color(0xFF4EA771);
  static const Color dark = Color(0xFF013236);

  bool _loadingPreview = true;
  bool _submitting = false;
  PenarikanPreviewData? _preview;
  String? _errorPreview;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPreview());
  }

  Future<void> _loadPreview() async {
    setState(() {
      _loadingPreview = true;
      _errorPreview = null;
    });

    final auth = context.read<AuthProvider>();
    final prov = context.read<PenarikanNasabahProvider>();
    prov.bind(auth);

    final res = await prov.callPreview(
      rewardId: widget.formData.rewardId,
      nominalPenarikan: widget.formData.nominalPenarikan,
      itemSembako: widget.formData.itemSembako,
    );

    if (!mounted) return;

    if (res['success'] == true && res['data'] != null) {
      setState(() {
        _preview = PenarikanPreviewData.fromJson(
          res['data'] as Map<String, dynamic>,
          rewardId: widget.formData.rewardId,
          nominalRequest: widget.formData.nominalPenarikan,
          itemSembakoRequest: widget.formData.itemSembako,
        );
        _loadingPreview = false;
      });
    } else {
      setState(() {
        _errorPreview = res['message']?.toString() ?? 'Gagal memuat preview';
        _loadingPreview = false;
      });
    }
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    final preview = _preview;
    if (preview == null) return;

    HapticFeedback.mediumImpact();
    setState(() => _submitting = true);

    final prov = context.read<PenarikanNasabahProvider>();
    final res = await prov.callAjukan(
      rewardId: preview.rewardId,
      nominalPenarikan: preview.nominalRequest,
      itemSembako: preview.itemSembakoRequest,
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (res['success'] == true) {
      HapticFeedback.lightImpact();
      final data = res['data'];
      final penarikanId = (data is Map ? data['penarikan_id'] : null) as String?;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => DetailPenarikanScreen(
            penarikanId: penarikanId ?? '',
          ),
        ),
        (route) => route.isFirst,
      );
    } else {
      _showSnack(
          res['message']?.toString() ?? 'Pengajuan gagal',
          error: true);
    }
  }

  void _showSnack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      content: Text(msg, style: const TextStyle(fontFamily: 'Poppins')),
      backgroundColor: error ? Colors.redAccent : primary,
    ));
  }

  // ── Formatters ────────────────────────────────────────────────────────────

  String _fmtNominal(double v, String satuan) {
    final f = NumberFormat.decimalPattern('id_ID');
    f.maximumFractionDigits = 4;
    f.minimumFractionDigits = 0;
    final lower = satuan.toLowerCase();
    if (lower.contains('rupiah') || lower.contains('uang')) {
      return 'Rp ${f.format(v)}';
    }
    return '${f.format(v)} ${satuan.isEmpty ? 'poin' : satuan}';
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bg_struk.webp'),
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  const TopBarBack(title: 'Konfirmasi Penarikan'),
                  Expanded(
                    child: _loadingPreview
                        ? const Center(
                            child: CircularProgressIndicator(color: primary))
                        : _errorPreview != null
                            ? _buildError()
                            : _buildContent(),
                  ),
                  // ── Bottom bar button ──────────────────────────────────────
                  if (!_loadingPreview && _errorPreview == null)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 16,
                            offset: const Offset(0, -4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                      child: _buildCTA(),
                    ),
                ],
              ),
              // Submit loading overlay
              if (_submitting)
                Container(
                  color: Colors.black.withValues(alpha: 0.35),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(height: 16),
                        Text(
                          'Memproses pengajuan...',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            color: Colors.white,
                            fontSize: 14,
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

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: Colors.redAccent, size: 56),
            const SizedBox(height: 16),
            Text(
              _errorPreview!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontFamily: 'Poppins', fontSize: 14),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 32, vertical: 14),
              ),
              onPressed: _loadPreview,
              child: const Text('Coba Lagi',
                  style: TextStyle(fontFamily: 'Poppins')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final p = _preview!;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Card
          _buildSummaryCard(p),
          const SizedBox(height: 16),
          // Sembako breakdown
          if (p.isSembako && p.itemSembako.isNotEmpty)
            _buildSembakoBreakdown(p),
          if (p.isSembako && p.itemSembako.isNotEmpty)
            const SizedBox(height: 16),
          // Saldo info card
          _buildSaldoCard(p),
          const SizedBox(height: 16),
          // Disclaimer
          _buildDisclaimer(),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(PenarikanPreviewData p) {
    final f = NumberFormat.decimalPattern('id_ID');
    f.maximumFractionDigits = 4;
    f.minimumFractionDigits = 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          width: 1,
          color: const Color(0xFF013236).withOpacity(0.1), // Brand color dengan opacity cuma 10%
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  p.isUang
                      ? Icons.payments_rounded
                      : Icons.shopping_basket_rounded,
                  color: primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Penarikan ${_capitalize(p.namaReward)}',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: dark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: const Text(
                        'Pending',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFF59E0B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          const SizedBox(height: 16),
          _InfoRow(
            label: 'Jenis Reward',
            value: _capitalize(p.namaReward),
          ),
          if (!p.isSembako)
            _InfoRow(
              label: 'Nominal',
              value: _fmtNominal(p.nominalPenarikan, p.satuan),
              highlight: true,
            ),
          if (p.isSembako)
            _InfoRow(
              label: 'Total Poin',
              value: '${f.format(p.nominalPenarikan)} poin',
              highlight: true,
            ),
          _InfoRow(
            label: 'Est. Konfirmasi',
            value: 'Dalam 2 jam',
          ),
        ],
      ),
    );
  }

  Widget _buildSembakoBreakdown(PenarikanPreviewData p) {
    final f = NumberFormat.decimalPattern('id_ID');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          width: 1,
          color: const Color(0xFF013236).withOpacity(0.1), // Brand color dengan opacity cuma 10%
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Detail Sembako',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: dark,
            ),
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          const SizedBox(height: 10),
          ...p.itemSembako.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.shopping_basket_rounded,
                        size: 16, color: primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.namaSembako,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: dark,
                        ),
                      ),
                    ),
                    Text(
                      'x${f.format(item.qty)}',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: Colors.black.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${f.format(item.subtotalPoin)} poin',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: dark,
                      ),
                    ),
                  ],
                ),
              )),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: dark,
                ),
              ),
              const Spacer(),
              Text(
                '${f.format(p.nominalPenarikan)} poin',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSaldoCard(PenarikanPreviewData p) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          width: 1,
          color: const Color(0xFF013236).withOpacity(0.1), // Brand color dengan opacity cuma 10%
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informasi Saldo',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: dark,
            ),
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          const SizedBox(height: 10),
          _InfoRow(
            label: 'Saldo Sekarang',
            value: _fmtNominal(p.saldoSekarang, p.satuanSaldo),
          ),
          _InfoRow(
            label: 'Penarikan',
            value: '- ${_fmtNominal(p.nominalPenarikan, p.satuan)}',
          ),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          const SizedBox(height: 10),
          _InfoRow(
            label: 'Estimasi Sisa',
            value: _fmtNominal(p.saldoSetelah, p.satuanSaldo),
            highlight: true,
          ),
          if (!p.saldoCukup) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: Colors.red, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Saldo tidak mencukupi untuk penarikan ini',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDisclaimer() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded,
              color: Color(0xFFF59E0B), size: 18),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Jika dalam 2 jam pengajuan penarikan belum dikonfirmasi petugas bank sampah, pengajuan otomatis akan dibatalkan dan saldo dikembalikan ke rekeningmu.',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: Color(0xFF92400E),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCTA() {
    final preview = _preview;
    final disabled =
        _submitting || preview == null || !preview.saldoCukup;

    return Container(
      decoration: BoxDecoration(
        color: disabled ? Colors.grey.shade400 : Color(0xFF013236),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: disabled ? null : _submit,
          borderRadius: BorderRadius.circular(50),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: _submitting
                  ? const SizedBox(
                      width: 22,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5),
                    )
                  : const Text(
                      'Lanjutkan Penarikan',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1).toLowerCase()}';
}

// ── Info Row ──────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _InfoRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: Colors.black.withValues(alpha: 0.5),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight:
                    highlight ? FontWeight.w700 : FontWeight.w600,
                color: highlight
                    ? const Color(0xFF4EA771)
                    : const Color(0xFF013236),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
