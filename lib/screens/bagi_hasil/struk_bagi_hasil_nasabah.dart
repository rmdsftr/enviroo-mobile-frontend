import 'package:enviroo/models/bagi_hasil_nasabah_model.dart';
import 'package:enviroo/providers/bagi_hasil_provider.dart';
import 'package:enviroo/providers/penjualan_provider.dart' show FetchStatus;
import 'package:provider/provider.dart';
import 'package:enviroo/widgets/topbar_back.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ── Screen ────────────────────────────────────────────────────────────────────

class StrukBagiHasilNasabah extends StatefulWidget {
  final String penerimaId;
  const StrukBagiHasilNasabah({super.key, required this.penerimaId});

  @override
  State<StrukBagiHasilNasabah> createState() => _StrukBagiHasilNasabahState();
}

class _StrukBagiHasilNasabahState extends State<StrukBagiHasilNasabah> {
  static const _teal = Color(0xFF013236);
  static const _green = Color(0xFF4EA771);

  BagiHasilNasabahDetail? _detail;
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

    final prov = context.read<BagiHasilProvider>();
    await prov.fetchDetailNasabah(widget.penerimaId);
    if (!mounted) return;
    if (prov.nasabahDetailStatus == FetchStatus.success) {
      setState(() {
        _detail = prov.nasabahDetail;
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = prov.nasabahDetailError ?? 'Gagal memuat detail bagi hasil';
        _isLoading = false;
      });
    }
  }

  String _formatAmount(double amount, String satuan) {
    final s = satuan.toLowerCase();
    if (s.contains('rp') || s.contains('uang') || s.contains('idr')) {
      return NumberFormat.currency(
              locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
          .format(amount);
    }
    return '${NumberFormat('#,##0.##', 'id_ID').format(amount)} $satuan';
  }

  String _fmtNum(double v) {
    if (v == v.truncateToDouble()) return v.toInt().toString();
    return NumberFormat('#,##0.##', 'id_ID').format(v);
  }

  String _fmtCurrency(double v) =>
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
          .format(v);

  bool _isRupiah(String satuan) {
    final s = satuan.toLowerCase();
    return s.contains('rp') || s.contains('uang') || s.contains('idr');
  }

  String _fmtValue(double v, String satuan) {
    if (_isRupiah(satuan)) return _fmtCurrency(v);
    return '${NumberFormat('#,##0.##', 'id_ID').format(v)} $satuan';
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
              const TopBarBack(title: 'Detail Bagi Hasil Nasabah'),
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
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
      child: Column(
        children: [
          // ── Hero Header ──────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                width: 1,
                color: const Color(0xFF013236).withOpacity(0.1),
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _green.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.volunteer_activism_rounded,
                    color: _green,
                    size: 26,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _formatAmount(d.totalDiterima, d.satuanDiterima),
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: _green,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Total Bagi Hasil Diterima',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    color: _teal.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: _teal.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    DateFormat('EEEE, dd MMMM yyyy · HH:mm', 'id_ID')
                        .format(d.tanggal),
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
          ),

          const SizedBox(height: 14),

          // ── Info Card ────────────────────────────────────────────────────
          _buildInfoCard(d),

          const SizedBox(height: 14),

          // ── Items Card ───────────────────────────────────────────────────
          if (d.items.isNotEmpty) _buildItemsCard(d, d.satuanDiterima),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BagiHasilNasabahDetail d) {
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
          _sectionTitle('Informasi Penerima'),
          const SizedBox(height: 10),
          _infoRow(Icons.person_rounded, 'Nasabah', d.namaNasabah),
          _divider(),
          _infoRow(Icons.card_giftcard_rounded, 'Reward', d.reward),
          _divider(),
          _infoRow(
            Icons.receipt_long_rounded,
            'ID Transaksi',
            d.penerimaId,
            small: true,
          ),
        ],
      ),
    );
  }

  Widget _buildItemsCard(BagiHasilNasabahDetail d, String satuan) {
    final totalSubtotal =
        d.items.fold(0.0, (sum, item) => sum + item.subtotalHarga);

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
          _sectionTitle('Rincian Sampah'),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Expanded(
                    flex: 4,
                    child: Text('Item', style: _headerStyle)),
                Expanded(
                    flex: 2,
                    child: Text('Qty',
                        textAlign: TextAlign.center,
                        style: _headerStyle)),
                Expanded(
                    flex: 3,
                    child: Text('Harga',
                        textAlign: TextAlign.right,
                        style: _headerStyle)),
                Expanded(
                    flex: 3,
                    child: Text('Subtotal',
                        textAlign: TextAlign.right,
                        style: _headerStyle)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _dashedDivider(),
          const SizedBox(height: 8),
          ...d.items.map((item) => _buildItemRow(item, satuan)),
          const SizedBox(height: 8),
          _dashedDivider(),
          const SizedBox(height: 10),
          Row(
            children: [
              const Expanded(
                flex: 6,
                child: Text(
                  'Total Nilai Sampah',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: _teal,
                  ),
                ),
              ),
              Expanded(
                flex: 6,
                child: Text(
                  _fmtValue(totalSubtotal, satuan),
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: _green,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(BagiHasilNasabahDetailItem item, String satuan) {
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
                fontFamily: 'Poppins',
                fontSize: 11,
                color: _teal,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _fmtNum(item.qty),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                color: _teal.withValues(alpha: 0.7),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              _fmtValue(item.hargaItem, satuan),
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                color: _teal.withValues(alpha: 0.7),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              _fmtValue(item.subtotalHarga, satuan),
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                fontSize: 11,
                color: _teal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String label) {
    return Row(
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
    );
  }

  Widget _infoRow(IconData icon, String label, String value,
      {bool small = false}) {
    return Padding(
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
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    color: _teal.withValues(alpha: 0.45),
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: small ? 10.5 : 12,
                    color: _teal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Divider(color: _teal.withValues(alpha: 0.06), height: 1);

  Widget _dashedDivider() {
    return LayoutBuilder(
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
              color: _teal.withValues(alpha: 0.12),
            ),
          ),
        );
      },
    );
  }

  TextStyle get _headerStyle => TextStyle(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w600,
        fontSize: 10,
        color: _teal.withValues(alpha: 0.45),
      );

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded,
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
}
