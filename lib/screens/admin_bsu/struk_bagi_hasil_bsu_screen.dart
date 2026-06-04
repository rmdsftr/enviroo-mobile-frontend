import 'package:enviroo/services/bagi_hasil_service.dart';
import 'package:enviroo/widgets/topbar_back.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ── Models ────────────────────────────────────────────────────────────────────

class _PerhitunganSisaItem {
  final String tabunganId;
  final String namaSampah;
  final double qtyDipakai;
  final String satuan;

  _PerhitunganSisaItem({
    required this.tabunganId,
    required this.namaSampah,
    required this.qtyDipakai,
    required this.satuan,
  });

  factory _PerhitunganSisaItem.fromJson(Map<String, dynamic> j) =>
      _PerhitunganSisaItem(
        tabunganId: j['tabungan_id'] ?? '',
        namaSampah: j['nama_sampah'] ?? '',
        qtyDipakai: (j['qty_dipakai'] as num?)?.toDouble() ?? 0.0,
        satuan: j['satuan'] ?? '',
      );
}

class _DistribusiSisaBsuDetail {
  final String penerimaSisaId;
  final String distribusiId;
  final String bagiHasilId;
  final String bankId;
  final String namaBank;
  final double nominalDiterima;
  final double porsi;
  final double transportasi;
  final String satuanNominal;
  final String diantarOleh;
  final DateTime tanggalDistribusi;
  final List<_PerhitunganSisaItem> perhitunganSisa;

  _DistribusiSisaBsuDetail({
    required this.penerimaSisaId,
    required this.distribusiId,
    required this.bagiHasilId,
    required this.bankId,
    required this.namaBank,
    required this.nominalDiterima,
    required this.porsi,
    required this.transportasi,
    required this.satuanNominal,
    required this.diantarOleh,
    required this.tanggalDistribusi,
    required this.perhitunganSisa,
  });

  factory _DistribusiSisaBsuDetail.fromJson(Map<String, dynamic> j) =>
      _DistribusiSisaBsuDetail(
        penerimaSisaId: j['penerima_sisa_id'] ?? '',
        distribusiId: j['distribusi_id'] ?? '',
        bagiHasilId: j['bagi_hasil_id'] ?? '',
        bankId: j['bank_id'] ?? '',
        namaBank: j['nama_bank'] ?? '',
        nominalDiterima: (j['nominal_diterima'] as num?)?.toDouble() ?? 0.0,
        porsi: (j['porsi'] as num?)?.toDouble() ?? 0.0,
        transportasi: (j['transportasi'] as num?)?.toDouble() ?? 0.0,
        satuanNominal: j['satuan_nominal'] ?? '',
        diantarOleh: j['diantar_oleh'] ?? '',
        tanggalDistribusi:
            DateTime.tryParse(j['tanggal_distribusi'] ?? '') ?? DateTime.now(),
        perhitunganSisa: (j['perhitungan_sisa'] as List? ?? [])
            .map((e) =>
                _PerhitunganSisaItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

// ── Screen ────────────────────────────────────────────────────────────────────

class StrukBagiHasilBsuScreen extends StatefulWidget {
  final String penerimaSisaId;
  const StrukBagiHasilBsuScreen({super.key, required this.penerimaSisaId});

  @override
  State<StrukBagiHasilBsuScreen> createState() =>
      _StrukBagiHasilBsuScreenState();
}

class _StrukBagiHasilBsuScreenState extends State<StrukBagiHasilBsuScreen> {
  static const _teal = Color(0xFF013236);
  static const _green = Color(0xFF4EA771);

  _DistribusiSisaBsuDetail? _detail;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchDetail());
  }

  Future<void> _fetchDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final res = await BagiHasilService.getDetailDistribusiSisaBsu(widget.penerimaSisaId);
    if (!mounted) return;
    if (res['success'] == true) {
      setState(() {
        _detail = _DistribusiSisaBsuDetail.fromJson(res['data'] as Map<String, dynamic>);
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = res['message'] ?? 'Gagal memuat detail distribusi sisa';
        _isLoading = false;
      });
    }
  }

  String _fmtNominal(double val, String satuan) {
    final s = satuan.toLowerCase();
    if (s == 'rp') return 'Rp ${NumberFormat('#,##0', 'id_ID').format(val)}';
    return '${NumberFormat('#,##0.##', 'id_ID').format(val)} $satuan';
  }

  String _fmtNum(double v) => NumberFormat('#,##0.##', 'id_ID').format(v);

  // ── Build ───────────────────────────────────────────────────────────────────

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
              const TopBarBack(title: 'Detail Distribusi Sisa BSU'),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: _green))
                    : _error != null
                        ? _buildError()
                        : _buildStruk(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStruk() {
    final d = _detail!;
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      child: Column(
        children: [
          // ── Hero ────────────────────────────────────────────────────────────
          _buildHero(d),
          const SizedBox(height: 16),

          // ── Info ────────────────────────────────────────────────────────────
          _buildInfoCard(d),

          // ── Perhitungan Sisa ─────────────────────────────────────────────
          if (d.perhitunganSisa.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildPerhitunganCard(d),
          ],
        ],
      ),
    );
  }

  // ── Hero Card ───────────────────────────────────────────────────────────────

  Widget _buildHero(_DistribusiSisaBsuDetail d) {
    final antarLabel =
        d.diantarOleh == 'bsu' ? 'Antar Mandiri' : 'Diantar BSI';
    final antarColor =
        d.diantarOleh == 'bsu' ? _green : _teal.withValues(alpha: 0.55);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _green.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.account_balance_wallet_rounded,
                color: _green, size: 36),
          ),
          const SizedBox(height: 12),
          Text(
            d.namaBank,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: _teal,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _fmtNominal(d.nominalDiterima, d.satuanNominal),
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: _green,
              letterSpacing: -0.5,
            ),
          ),
          Text(
            'ID: ${d.penerimaSisaId}',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10,
              color: _teal.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 10),
          // Row(
          //   mainAxisAlignment: MainAxisAlignment.center,
          //   children: [
          //     Container(
          //       padding:
          //           const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          //       decoration: BoxDecoration(
          //         color: antarColor.withValues(alpha: 0.1),
          //         borderRadius: BorderRadius.circular(20),
          //       ),
          //       child: Text(
          //         antarLabel,
          //         style: TextStyle(
          //           fontFamily: 'Poppins',
          //           fontSize: 10,
          //           fontWeight: FontWeight.w600,
          //           color: antarColor,
          //         ),
          //       ),
          //     ),
          //   ],
          // ),
          // const SizedBox(height: 10),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: _teal.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              DateFormat('EEEE, dd MMMM yyyy · HH:mm', 'id_ID')
                  .format(d.tanggalDistribusi),
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: _teal.withValues(alpha: 0.65),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Info Card ───────────────────────────────────────────────────────────────

  Widget _buildInfoCard(_DistribusiSisaBsuDetail d) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Informasi'),
          const SizedBox(height: 10),
          _infoRow(Icons.pie_chart_rounded, 'Porsi Bagi Hasil',
              _fmtNominal(d.porsi, d.satuanNominal)),
          _divider(),
          _infoRow(Icons.local_shipping_rounded, 'Biaya Transportasi',
              _fmtNominal(d.transportasi, d.satuanNominal)),
          _divider(),
          _infoRow(Icons.account_balance_wallet_rounded, 'Nominal Diterima',
              _fmtNominal(d.nominalDiterima, d.satuanNominal)),
        ],
      ),
    );
  }

  // ── Perhitungan Sisa Card ───────────────────────────────────────────────────

  Widget _buildPerhitunganCard(_DistribusiSisaBsuDetail d) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Rincian Tabungan Sampah'),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Expanded(
                    flex: 4,
                    child: Text('Nama Sampah', style: _headerStyle)),
                Expanded(
                    flex: 3,
                    child: Text('Qty Dipakai',
                        textAlign: TextAlign.right, style: _headerStyle)),
                Expanded(
                    flex: 2,
                    child: Text('Satuan',
                        textAlign: TextAlign.right, style: _headerStyle)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _dashedDivider(),
          const SizedBox(height: 8),
          ...d.perhitunganSisa.map((item) => _buildPerhitunganRow(item)),
        ],
      ),
    );
  }

  Widget _buildPerhitunganRow(_PerhitunganSisaItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              item.namaSampah,
              style: const TextStyle(
                  fontFamily: 'Poppins', fontSize: 11, color: _teal),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              _fmtNum(item.qtyDipakai),
              textAlign: TextAlign.right,
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _teal.withValues(alpha: 0.8)),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              item.satuan,
              textAlign: TextAlign.right,
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  color: _teal.withValues(alpha: 0.5)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Error State ─────────────────────────────────────────────────────────────

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off_rounded,
              size: 48, color: _teal.withValues(alpha: 0.25)),
          const SizedBox(height: 12),
          Text(
            _error!,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: _teal.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _fetchDetail,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                color: _green,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Coba Lagi',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Shared helpers ──────────────────────────────────────────────────────────

  Widget _sectionTitle(String label) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            Container(
              width: 3,
              height: 16,
              decoration: BoxDecoration(
                color: _green,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: _teal,
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
                color: _green.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 15, color: _green),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          color: _teal.withValues(alpha: 0.45))),
                  Text(value,
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          fontSize: small ? 10.5 : 12,
                          color: _teal)),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _divider() =>
      Divider(color: _teal.withValues(alpha: 0.06), height: 1);

  Widget _dashedDivider() => LayoutBuilder(
        builder: (context, constraints) {
          const dashWidth = 6.0;
          const dashSpace = 4.0;
          final count =
              (constraints.maxWidth / (dashWidth + dashSpace)).floor();
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              count,
              (_) => Container(
                  width: dashWidth,
                  height: 1,
                  color: _teal.withValues(alpha: 0.12)),
            ),
          );
        },
      );

  TextStyle get _headerStyle => TextStyle(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w600,
        fontSize: 10,
        color: _teal.withValues(alpha: 0.45),
      );
}
