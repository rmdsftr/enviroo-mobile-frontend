import 'package:enviroo/providers/auth_provider.dart';
import 'package:enviroo/services/bagi_hasil_service.dart';
import 'package:enviroo/screens/admin_bsu/struk_bagi_hasil_bsu_screen.dart';
import 'package:enviroo/widgets/filter_month_year.dart';
import 'package:enviroo/widgets/topbar_back.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

// ── Model ─────────────────────────────────────────────────────────────────────

class _DistribusiSisaItem {
  final String penerimaSisaId;
  final String distribusiId;
  final String bagiHasilId;
  final double nominalDiterima;
  final String satuanNominal;
  final String diantarOleh;
  final DateTime tanggalDistribusi;

  _DistribusiSisaItem({
    required this.penerimaSisaId,
    required this.distribusiId,
    required this.bagiHasilId,
    required this.nominalDiterima,
    required this.satuanNominal,
    required this.diantarOleh,
    required this.tanggalDistribusi,
  });

  factory _DistribusiSisaItem.fromJson(Map<String, dynamic> j) =>
      _DistribusiSisaItem(
        penerimaSisaId: j['penerima_sisa_id'] ?? '',
        distribusiId: j['distribusi_id'] ?? '',
        bagiHasilId: j['bagi_hasil_id'] ?? '',
        nominalDiterima: (j['nominal_diterima'] as num?)?.toDouble() ?? 0.0,
        satuanNominal: j['satuan_nominal'] ?? '',
        diantarOleh: j['diantar_oleh'] ?? '',
        tanggalDistribusi:
            DateTime.tryParse(j['tanggal_distribusi'] ?? '') ?? DateTime.now(),
      );
}

// ── Screen ────────────────────────────────────────────────────────────────────

class ListBagiHasilBsuScreen extends StatefulWidget {
  const ListBagiHasilBsuScreen({super.key});

  @override
  State<ListBagiHasilBsuScreen> createState() =>
      _ListBagiHasilBsuScreenState();
}

class _ListBagiHasilBsuScreenState extends State<ListBagiHasilBsuScreen> {
  static const _teal = Color(0xFF013236);
  static const _green = Color(0xFF4EA771);

  late DateTime _filterStart;
  late DateTime _filterEnd;

  List<_DistribusiSisaItem> _allItems = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _filterEnd = DateTime(now.year, now.month);
    final startRaw = DateTime(now.year, now.month - 2);
    _filterStart = DateTime(startRaw.year, startRaw.month);
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchData());
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final bsuId = auth.bankId ?? '';

    final res = await BagiHasilService.getListDistribusiSisaBsu(bsuId);
    if (!mounted) return;
    if (res['success'] == true) {
      final body = res['data'] as Map<String, dynamic>? ?? {};
      final list = (body['riwayat'] as List? ?? [])
          .map((e) => _DistribusiSisaItem.fromJson(e as Map<String, dynamic>))
          .toList();
      setState(() {
        _allItems = list;
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = res['message'] ?? 'Gagal memuat data distribusi sisa';
        _isLoading = false;
      });
    }
  }

  List<_DistribusiSisaItem> get _filtered {
    return _allItems.where((item) {
      final itemMonth = DateTime(
          item.tanggalDistribusi.year, item.tanggalDistribusi.month);
      final start = DateTime(_filterStart.year, _filterStart.month);
      final end = DateTime(_filterEnd.year, _filterEnd.month);
      return !itemMonth.isBefore(start) && !itemMonth.isAfter(end);
    }).toList();
  }

  String _fmtNominal(double val, String satuan) {
    final s = satuan.toLowerCase();
    if (s == 'rp') return 'Rp ${NumberFormat('#,##0', 'id_ID').format(val)}';
    return '${NumberFormat('#,##0.##', 'id_ID').format(val)} $satuan';
  }

  // Warna & ikon berdasarkan satuan
  Color _cardColor(String satuan) {
    final s = satuan.toLowerCase();
    if (s == 'rp') return _green;
    if (s == 'poin') return const Color(0xFF2D9CDB);
    return const Color(0xFFF2C94C);
  }

  IconData _cardIcon(String satuan) {
    final s = satuan.toLowerCase();
    if (s == 'rp') return Icons.account_balance_wallet_rounded;
    if (s == 'poin') return Icons.shopping_basket_rounded;
    return Icons.diamond_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg_struk.webp',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const TopBarBack(title: 'Riwayat Distribusi Sisa BSU'),
                // Deskripsi & filter — tampil di atas background
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Riwayat distribusi sisa bagi hasil yang telah diterima oleh BSU ini.',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: _teal.withValues(alpha: 0.7),
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: MonthYearFilterRow(
                    filterStart: _filterStart,
                    filterEnd: _filterEnd,
                    onChanged: (s, e) => setState(() {
                      _filterStart = s;
                      _filterEnd = e;
                    }),
                  ),
                ),
                const SizedBox(height: 16),
                // White container — menutupi background hingga paling bawah
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.only(top: 15),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                      child: _isLoading
                          ? const Center(
                              child: CircularProgressIndicator(color: _green))
                          : _error != null
                              ? _buildError()
                              : _buildList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    final items = _filtered;
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_rounded,
                size: 56, color: _teal.withValues(alpha: 0.18)),
            const SizedBox(height: 12),
            Text(
              'Belum ada distribusi sisa\nuntuk periode ini',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: _teal.withValues(alpha: 0.45),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: _green,
      onRefresh: _fetchData,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        physics: const BouncingScrollPhysics(),
        itemCount: items.length,
        itemBuilder: (_, i) => _buildCard(items[i]),
      ),
    );
  }

  Widget _buildCard(_DistribusiSisaItem item) {
    final color = _cardColor(item.satuanNominal);
    final icon = _cardIcon(item.satuanNominal);
    final dateStr = DateFormat('dd MMM yyyy, HH:mm', 'id_ID')
        .format(item.tanggalDistribusi);
    final nominalStr = _fmtNominal(item.nominalDiterima, item.satuanNominal);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StrukBagiHasilBsuScreen(
              penerimaSisaId: item.penerimaSisaId),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              width: 1,
              color: Color(0xFF013236).withOpacity(0.1)
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dateStr,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: _teal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'ID: ${item.penerimaSisaId}',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      color: _teal.withValues(alpha: 0.45),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Row(
              children: [
                Text(
                  nominalStr,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

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
            onTap: _fetchData,
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
