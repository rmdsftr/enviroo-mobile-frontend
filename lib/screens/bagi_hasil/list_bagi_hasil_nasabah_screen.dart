import 'package:enviroo/models/bagi_hasil_nasabah_model.dart';
import 'package:enviroo/providers/auth_provider.dart';
import 'package:enviroo/providers/bagi_hasil_provider.dart';
import 'package:enviroo/providers/penjualan_provider.dart' show FetchStatus;
import 'package:enviroo/screens/bagi_hasil/struk_bagi_hasil_nasabah.dart';
import 'package:enviroo/widgets/filter_month_year.dart';
import 'package:enviroo/widgets/navbar.dart';
import 'package:enviroo/widgets/topbar_back.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

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

  /// Label tab — ini yang dibaca nasabah. Konteksnya SALDO, jadi dilabeli
  /// saldo, seragam dengan kartu bagi hasil di beranda dan chip filter di
  /// layar setoran.
  static const _tabs = ['Saldo Rupiah', 'Saldo Poin'];

  /// Kunci penyaring, SENGAJA dipisah dari [_tabs].
  ///
  /// Backend masih memakai istilah insentif ("Uang"/"Barang") di `reward`.
  /// Dulu label tab dipakai langsung sebagai kunci pencocokan, jadi label dan
  /// penyaring terikat diam-diam: begitu labelnya diganti, kedua tab langsung
  /// kosong tanpa error apa pun.
  static const _tabKeys = ['uang', 'barang'];
  static const _tabIcons = [
    Icons.account_balance_wallet_rounded,
    Icons.shopping_basket_rounded,
  ];
  static const _tabColors = [
    Color(0xFF4EA771),
    Color(0xFF79B60B),
  ];

  int _selectedTab = 0;

  late DateTime _filterStart;
  late DateTime _filterEnd;

  List<BagiHasilNasabahItem> _allItems = [];
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

    final fmt = DateFormat('yyyy-MM-dd');
    final start = DateTime(_filterStart.year, _filterStart.month, 1);
    final end = DateTime(_filterEnd.year, _filterEnd.month + 1, 0);

    final prov = context.read<BagiHasilProvider>();
    await prov.fetchListNasabah(
      nasabahId,
      startDate: fmt.format(start),
      endDate: fmt.format(end),
    );
    if (!mounted) return;
    if (prov.nasabahListStatus == FetchStatus.success) {
      setState(() {
        _allItems = prov.nasabahList;
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = prov.nasabahListError ?? 'Gagal memuat data bagi hasil';
        _isLoading = false;
      });
    }
  }

  List<BagiHasilNasabahItem> get _filtered {
    final tabKey = _tabKeys[_selectedTab];
    return _allItems.where((item) {
      return item.reward.toLowerCase().contains(tabKey) ||
          item.satuanDiterima.toLowerCase().contains(tabKey);
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
            image: AssetImage('assets/images/bg_struk2.webp'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const TopBarBack(title: 'Bagi Hasil'),
              Expanded(
                child: RefreshIndicator(
                  color: _green,
                  onRefresh: _fetchData,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      // Deskripsi + tab navbar — scroll away normally
                      SliverToBoxAdapter(
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
                          ],
                        ),
                      ),
                      // Sticky: "Riwayat Bagi Hasil" + filter bulan
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _StickyHeaderDelegate(
                          height: 108,
                          child: Container(
                            color: Colors.white,
                            padding: const EdgeInsets.only(top: 10, bottom: 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                                  child : Text(
                                      'Riwayat Bagi Hasil',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: _teal,
                                      ),
                                  )
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  child: MonthYearFilterRow(
                                    filterStart: _filterStart,
                                    filterEnd: _filterEnd,
                                    onChanged: (s, e) {
                                      setState(() {
                                        _filterStart = s;
                                        _filterEnd = e;
                                      });
                                      _fetchData();
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // List / Empty — cuma ini yang scroll di bawah sticky header
                      SliverToBoxAdapter(
                        child: Container(
                          width: double.infinity,
                          constraints: BoxConstraints(
                            minHeight: MediaQuery.of(context).size.height,
                          ),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                          ),
                          padding: const EdgeInsets.only(bottom: 40),
                          child: _isLoading
                              ? const Padding(
                                  padding: EdgeInsets.only(top: 40),
                                  child: Center(
                                      child: CircularProgressIndicator(color: _green)),
                                )
                              : _error != null
                                  ? _buildError()
                                  : _buildList(),
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

  Widget _buildCard(BagiHasilNasabahItem item) {
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
                color: Color(0xFF013236).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Color(0xFF013236), size: 22),
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
                      fontSize: 13,
                      color: _teal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.bagiHasilId,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10,
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
                    color: Color(0xFF4EA771),
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

// ── Sticky header delegate ───────────────────────────────────────────────────
// Bikin "Riwayat Bagi Hasil" + filter bulan nempel (pinned) di bawah
// TopBarBack saat di-scroll, sementara cuma ListView card yang ikut bergerak.
class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  _StickyHeaderDelegate({required this.child, required this.height});

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(covariant _StickyHeaderDelegate oldDelegate) {
    return oldDelegate.child != child || oldDelegate.height != height;
  }
}
