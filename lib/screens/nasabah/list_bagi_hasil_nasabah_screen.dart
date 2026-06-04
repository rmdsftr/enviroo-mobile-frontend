import 'package:enviroo/providers/auth_provider.dart';
import 'package:enviroo/services/bagi_hasil_service.dart';
import 'package:enviroo/screens/nasabah/struk_bagi_hasil_nasabah.dart';
import 'package:enviroo/widgets/filter_month_year.dart';
import 'package:enviroo/widgets/navbar.dart';
import 'package:enviroo/widgets/topbar_back.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

// ── Model ─────────────────────────────────────────────────────────────────────

class _BagiHasilItem {
  final String penerimaId;
  final String bagiHasilId;
  final String reward;
  final DateTime tanggal;
  final double totalDiterima;
  final String satuanDiterima;

  _BagiHasilItem({
    required this.penerimaId,
    required this.bagiHasilId,
    required this.reward,
    required this.tanggal,
    required this.totalDiterima,
    required this.satuanDiterima,
  });

  factory _BagiHasilItem.fromJson(Map<String, dynamic> j) => _BagiHasilItem(
        penerimaId: j['penerima_id'] ?? '',
        bagiHasilId: j['bagi_hasil_id'] ?? '',
        reward: j['reward'] ?? '',
        tanggal: DateTime.tryParse(j['tanggal'] ?? '') ?? DateTime.now(),
        totalDiterima: (j['total_diterima'] as num?)?.toDouble() ?? 0.0,
        satuanDiterima: j['satuan_diterima'] ?? '',
      );
}

// ── Screen ────────────────────────────────────────────────────────────────────

class ListBagiHasilNasabahScreen extends StatefulWidget {
  final int initialTab;
  const ListBagiHasilNasabahScreen({super.key, this.initialTab = 0});

  @override
  State<ListBagiHasilNasabahScreen> createState() =>
      _ListBagiHasilNasabahScreenState();
}

class _ListBagiHasilNasabahScreenState
    extends State<ListBagiHasilNasabahScreen> {
  static const _teal = Color(0xFF013236);
  static const _green = Color(0xFF4EA771);

  static const _tabs = ['Uang', 'Sembako'];
  static const _tabIcons = [
    Icons.account_balance_wallet_rounded,
    Icons.shopping_basket_rounded,
  ];
  static const _tabColors = [
    Color(0xFF4EA771),
    Color(0xFF2D9CDB),
  ];

  int _selectedTab = 0;

  late DateTime _filterStart;
  late DateTime _filterEnd;

  List<_BagiHasilItem> _allItems = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
    final now = DateTime.now();
    _filterEnd = DateTime(now.year, now.month);
    // default 3 bulan terakhir (bulan ini dan 2 bulan sebelumnya)
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
    final nasabahId = auth.identityId ?? '';

    final res = await BagiHasilService.getListBagiHasilNasabah(nasabahId);
    if (!mounted) return;
    if (res['success'] == true) {
      final body = res['data'] as Map<String, dynamic>? ?? {};
      final list = (body['riwayat_bagi_hasil'] as List? ?? [])
          .map((e) => _BagiHasilItem.fromJson(e as Map<String, dynamic>))
          .toList();
      setState(() {
        _allItems = list;
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = res['message'] ?? 'Gagal memuat data bagi hasil';
        _isLoading = false;
      });
    }
  }

  List<_BagiHasilItem> get _filtered {
    final tabLabel = _tabs[_selectedTab].toLowerCase();
    return _allItems.where((item) {
      final matchesTab = item.reward.toLowerCase().contains(tabLabel) ||
          item.satuanDiterima.toLowerCase().contains(tabLabel);
      if (!matchesTab) return false;

      final itemMonth = DateTime(item.tanggal.year, item.tanggal.month);
      final start = DateTime(_filterStart.year, _filterStart.month);
      final end = DateTime(_filterEnd.year, _filterEnd.month);
      return !itemMonth.isBefore(start) && !itemMonth.isAfter(end);
    }).toList();
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
              const TopBarBack(title: 'Riwayat Bagi Hasil'),
              Expanded(
                child: RefreshIndicator(
                  color: _green,
                  onRefresh: _fetchData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            'Pada menu ini kamu bisa melihat semua detail bagi hasil yang sudah masuk ke saldo rekeningmu',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color: _teal.withValues(alpha: 0.65),
                              height: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        MainNavbar(
                          selectedIndex: _selectedTab,
                          onTabChanged: (i) => setState(() => _selectedTab = i),
                          tabs: _tabs,
                          backgroundColor: Colors.white.withOpacity(0.6),
                          border: Border.all(
                            color: const Color(0xFF013236).withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                        const SizedBox(height: 12),
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
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          constraints: BoxConstraints(
                            minHeight: MediaQuery.of(context).size.height,
                          ),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                          ),
                          padding: const EdgeInsets.only(top: 10, bottom: 40),
                          child: _isLoading
                              ? const Center(
                                  child: CircularProgressIndicator(color: _green))
                              : _error != null
                                  ? _buildError()
                                  : _buildList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
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
              'Belum ada bagi hasil\nuntuk periode ini',
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

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (_, i) => _buildCard(items[i]),
    );
  }

  Widget _buildCard(_BagiHasilItem item) {
    final color = _tabColors[_selectedTab];
    final icon = _tabIcons[_selectedTab];
    final dateStr =
        DateFormat('dd MMM yyyy', 'id_ID').format(item.tanggal);
    final amountStr = _formatAmount(item.totalDiterima, item.satuanDiterima);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              StrukBagiHasilNasabah(penerimaId: item.penerimaId),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.5),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            width: 1,
            color: const Color(0xFF013236).withOpacity(0.1), // Brand color dengan opacity cuma 10%
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
                    item.reward,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: _teal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dateStr,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: _teal.withValues(alpha: 0.45),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  amountStr,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Icon(Icons.chevron_right_rounded,
                    size: 16, color: _teal.withValues(alpha: 0.3)),
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
