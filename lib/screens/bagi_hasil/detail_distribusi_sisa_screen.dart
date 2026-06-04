import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/distribusi_sisa_model.dart';
import '../../providers/distribusi_sisa_provider.dart';
import '../../providers/penjualan_provider.dart' show FetchStatus;
import '../../widgets/topbar_back.dart';
import '../admin_bsu/struk_bagi_hasil_bsu_screen.dart';

class _C {
  static const dark = Color(0xFF013236);
  static const green = Color(0xFF4EA771);
  static const danger = Color(0xFFD94848);
}

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
                          child: CircularProgressIndicator(color: _C.green));
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

  Widget _buildContent(DetailDistribusiSisaModel detail) {
    final fmtRp = NumberFormat('#,##0', 'id_ID');
    final fmtNum = NumberFormat('#,##0.##########', 'id_ID');
    final isRp = detail.satuan.toLowerCase() == 'rp';

    String fmtNominal(double val, String satuan) {
      final s = satuan.toLowerCase();
      if (s == 'rp') return 'Rp ${fmtRp.format(val)}';
      return '${fmtNum.format(val)} $satuan';
    }

    String fmtSisa(double val) =>
        isRp ? 'Rp ${fmtRp.format(val)}' : '${fmtNum.format(val)} ${detail.satuan}';

    String tanggalFmt() {
      try {
        final dt = DateTime.parse(detail.createdAt);
        return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(dt);
      } catch (_) {
        return detail.createdAt;
      }
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      child: Column(
        children: [
          // ── Hero ────────────────────────────────────────────────────────
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
                  child: const Icon(Icons.check_circle_rounded,
                      color: _C.green, size: 36),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Distribusi Sisa Selesai',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    color: _C.green,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ID: ${detail.distribusiId}',
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

          // ── Info ─────────────────────────────────────────────────────────
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

          // ── Penerima BSI ─────────────────────────────────────────────────
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
                    iconColor: _C.green,
                    iconBg: _C.green.withValues(alpha: 0.08),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // ── Penerima BSU ─────────────────────────────────────────────────
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
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: _C.dark.withValues(alpha: 0.45),
                      ),
                    ),
                  )
                else
                  ...detail.penerimaBsu.asMap().entries.map((entry) {
                    final isLast =
                        entry.key == detail.penerimaBsu.length - 1;
                    return Column(
                      children: [
                        _penerimaRow(
                          p: entry.value,
                          fmtNominal: fmtNominal,
                          iconColor: _C.dark,
                          iconBg: _C.dark.withValues(alpha: 0.06),
                          showAntar: true,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => StrukBagiHasilBsuScreen(
                                  penerimaSisaId: entry.value.penerimaSisaId),
                            ),
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
    final antarLabel = p.diantarOleh == 'bsu' ? 'Antar Mandiri' : 'Diantar BSI';
    final antarColor =
        p.diantarOleh == 'bsu' ? _C.green : _C.dark.withValues(alpha: 0.55);

    return GestureDetector(
      onTap: onTap,
      child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.account_balance_rounded,
                size: 15, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.namaBank,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: _C.dark,
                  ),
                ),
                // if (showAntar && p.diantarOleh != null)
                //   Text(
                //     antarLabel,
                //     style: TextStyle(
                //       fontFamily: 'Poppins',
                //       fontSize: 10,
                //       color: antarColor,
                //       fontWeight: FontWeight.w500,
                //     ),
                //   ),
                // const SizedBox(height: 3),
                Text(
                  'Porsi: ${fmtNominal(p.porsi, p.satuanNominal)}  ·  '
                  'Transport: ${fmtNominal(p.transportasi, p.satuanNominal)}',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    color: _C.dark.withValues(alpha: 0.45),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            children: [
              Text(
                fmtNominal(p.nominalDiterima, p.satuanNominal),
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _C.green,
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 2),
                Icon(Icons.chevron_right_rounded,
                    size: 14, color: _C.dark.withValues(alpha: 0.3)),
              ],
            ],
          ),
        ],
      ),
    ),
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────

Widget _cardHeader(String title) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
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

Widget _infoRow(IconData icon, String label, String value,
        {bool small = false}) =>
    Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: _C.green.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 15, color: _C.green),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    color: _C.dark.withValues(alpha: 0.45),
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: small ? 10.5 : 12,
                    color: _C.dark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

Widget _divider() =>
    Divider(color: _C.dark.withValues(alpha: 0.06), height: 1);
