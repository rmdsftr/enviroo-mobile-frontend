import 'package:enviroo/models/katalog_model.dart';
import 'package:enviroo/providers/auth_provider.dart';
import 'package:enviroo/providers/sembako_provider.dart';
import 'package:enviroo/screens/admin_bsi/input_distribusi_sembako_screen.dart';
import 'package:enviroo/screens/admin_bsi/struk_distribusi_sembako_screen.dart';
import 'package:enviroo/screens/admin_bsu/qr_terima_sembako_screen.dart';
import 'package:enviroo/widgets/detail_sembako_sheet.dart';
import 'package:enviroo/widgets/filter_month_year.dart';
import 'package:enviroo/widgets/navbar.dart';
import 'package:enviroo/widgets/search.dart';
import 'package:enviroo/widgets/pagination.dart';
import 'package:enviroo/widgets/topbar_back.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class _C {
  static const bg     = Color(0xFFF2FAF0);
  static const dark   = Color(0xFF0D3B3E);
  static const accent = Color(0xFF4EA771);
  static const teal   = Color(0xFF013236);
}

class KatalogSembakoScreen extends StatefulWidget {
  const KatalogSembakoScreen({super.key});

  @override
  State<KatalogSembakoScreen> createState() => _KatalogSembakoScreenState();
}

class _KatalogSembakoScreenState extends State<KatalogSembakoScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _tabIndex = 0;

  late DateTime _filterStart;
  late DateTime _filterEnd;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    int startMonth = now.month - 2;
    int startYear = now.year;
    if (startMonth <= 0) { startMonth += 12; startYear--; }
    _filterStart = DateTime(startYear, startMonth);
    _filterEnd = DateTime(now.year, now.month);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitial());
  }

  void _loadInitial() {
    final auth = context.read<AuthProvider>();
    final sembako = context.read<SembakoProvider>();
    final bankId = auth.bankId ?? '';
    sembako.fetchKatalogBsi(bankId);
    if (auth.role == 'petugas_bsi' || auth.role == 'petugas_bsu') {
      sembako.fetchListDistribusi(
        bankId,
        startDate: '${_filterStart.year}-${_filterStart.month.toString().padLeft(2, '0')}-01',
        endDate: '${_filterEnd.year}-${_filterEnd.month.toString().padLeft(2, '0')}-${DateTime(_filterEnd.year, _filterEnd.month + 1, 0).day.toString().padLeft(2, '0')}',
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<KatalogSembakoModel> _filtered(SembakoProvider sembako) {
    final list = sembako.katalogBsi;
    if (_searchQuery.isEmpty) return list;
    return list
        .where((e) => e.namaSembako.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  void _openDetail(KatalogSembakoModel item, String role) {
    final sembako = context.read<SembakoProvider>();
    final bankId = context.read<AuthProvider>().bankId ?? '';

    if (role == 'petugas_bsm') {
      sembako.setDetailDirect(item);
    } else {
      sembako.fetchDetailSembako(item.sembakoId, item, bankId);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.12),
        child: DetailSembakoSheet(role: role, showRiwayat: true),
      ),
    );
  }

  Future<void> _refresh(SembakoProvider sembako) async {
    final auth = context.read<AuthProvider>();
    final bankId = auth.bankId ?? '';
    await sembako.fetchKatalogBsi(bankId, page: 1);
    if (auth.role == 'petugas_bsi' || auth.role == 'petugas_bsu') {
      await sembako.fetchListDistribusi(
        bankId,
        startDate: '${_filterStart.year}-${_filterStart.month.toString().padLeft(2, '0')}-01',
        endDate: '${_filterEnd.year}-${_filterEnd.month.toString().padLeft(2, '0')}-${DateTime(_filterEnd.year, _filterEnd.month + 1, 0).day.toString().padLeft(2, '0')}',
      );
    }
  }

  List<ListDistribusiSembakoModel> _filteredDistribusi(SembakoProvider sembako) {
    return sembako.listDistribusi.where((d) {
      final m = DateTime(d.createdAt.year, d.createdAt.month);
      final start = DateTime(_filterStart.year, _filterStart.month);
      final end = DateTime(_filterEnd.year, _filterEnd.month);
      return !m.isBefore(start) && !m.isAfter(end);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<SembakoProvider, AuthProvider>(
      builder: (context, sembako, auth, _) {
        final role = auth.role;
        final isPetugasBsi = role == 'petugas_bsi';
        final isPetugasBsu = role == 'petugas_bsu';
        final isPetugasBsm = role == 'petugas_bsm';
        final canViewDetail = isPetugasBsi || isPetugasBsu || isPetugasBsm;
        final filtered = _filtered(sembako);

        return Scaffold(
          backgroundColor: _C.bg,
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
                const TopBarBack(title: 'Katalog Barang'),

                if (isPetugasBsi || isPetugasBsu) ...[
                  const SizedBox(height: 12),
                  MainNavbar(
                    selectedIndex: _tabIndex,
                    onTabChanged: (i) => setState(() {
                      _tabIndex = i;
                      _searchController.clear();
                      _searchQuery = '';
                    }),
                    tabs: const ['Katalog', 'Distribusi'],
                    backgroundColor: Colors.white.withValues(alpha: 0.6),
                    border: Border.all(
                      color: const Color(0xFF013236).withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],

                Expanded(
                  child: RefreshIndicator(
                    color: _C.accent,
                    onRefresh: () => _refresh(sembako),
                    child: ListView(
                      padding: EdgeInsets.zero,
                      physics: const BouncingScrollPhysics(),
                      children: [
                        // Tab Distribusi (BSI)
                        if (isPetugasBsi && _tabIndex == 1) ...[
                          const SizedBox(height: 10),
                          _buildDistribusiButton(context),
                          const SizedBox(height: 16),
                          _buildRiwayatDistribusiSection(sembako, showNamaBsu: true),
                          const SizedBox(height: 30),
                        ],

                        // Tab Distribusi (BSU)
                        if (isPetugasBsu && _tabIndex == 1) ...[
                          const SizedBox(height: 10),
                          _buildTerimaDistribusiButton(context),
                          const SizedBox(height: 16),
                          _buildRiwayatDistribusiSection(sembako, showNamaBsu: false),
                          const SizedBox(height: 30),
                        ],

                        // Tab Katalog (semua role, atau BSI/BSU tab 0)
                        if ((!isPetugasBsi && !isPetugasBsu) || _tabIndex == 0) ...[

                          const SizedBox(height: 10),

                          // Search bar
                          _buildSearchBar(),
                          const SizedBox(height: 16),

                          Container(
                            width: double.infinity,
                            constraints: BoxConstraints(
                              minHeight: MediaQuery.of(context).size.height,
                            ),
                            decoration: const BoxDecoration(color: Colors.white),
                            padding: const EdgeInsets.only(top: 20, bottom: 40),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header label
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 24),
                                  child: Row(
                                    children: [
                                      const Text(
                                        'Katalog Saya',
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                          color: _C.dark,
                                        ),
                                      ),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _C.accent.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          '${filtered.length} item',
                                          style: const TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: _C.accent,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Content
                                if (sembako.isLoading)
                                  const Padding(
                                    padding: EdgeInsets.only(top: 80),
                                    child: Center(
                                      child: CircularProgressIndicator(color: _C.accent),
                                    ),
                                  )
                                else
                                  _buildGrid(filtered, canViewDetail, role),
                                if (!sembako.isLoading && sembako.katalogBsiTotalPages > 1)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 20, bottom: 8),
                                    child: Pagination(
                                      currentPage: sembako.katalogBsiPage,
                                      totalPages: sembako.katalogBsiTotalPages,
                                      onPageChanged: (p) => sembako.fetchKatalogBsi(auth.bankId ?? '', page: p),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          ),
        );
      },
    );
  }

  Widget _buildDistribusiButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          final sembako = context.read<SembakoProvider>();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const InputDistribusiSembakoScreen(),
            ),
          ).then((_) {
            if (!mounted) return;
            _refresh(sembako);
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color : Color(0xFF013236),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            children: [
              Icon(Icons.local_shipping_rounded, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Distribusikan Barang ke BSU',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Colors.white,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 14),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTerimaDistribusiButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const QrTerimaSembakoScreen(),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color : Color(0xFF013236),
            borderRadius: BorderRadius.circular(30),
          ),
          child: const Row(
            children: [
              Icon(Icons.qr_code_rounded, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Terima Distribusi Barang',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Colors.white,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 14),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return CustomSearchBar(
      controller: _searchController,
      hintText: 'Cari barang...',
      onChanged: (v) => setState(() => _searchQuery = v),
      searchQuery: _searchQuery,
      onClear: () {
        _searchController.clear();
        setState(() => _searchQuery = '');
      },
      padding: const EdgeInsets.symmetric(horizontal: 24),
    );
  }

  Widget _buildGrid(List<KatalogSembakoModel> items, bool canViewDetail, String role) {
    if (items.isEmpty) return _buildEmptyState();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.73,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) => _buildCard(items[index], canViewDetail, role),
      ),
    );
  }

  Widget _buildCard(KatalogSembakoModel item, bool canViewDetail, String role) {
    final tappable = canViewDetail;

    return GestureDetector(
      onTap: tappable ? () => _openDetail(item, role) : null,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: _C.dark.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  item.photoUrl.isNotEmpty
                      ? Image.network(
                          item.photoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _buildPlaceholder(),
                        )
                      : _buildPlaceholder(),
                  if (tappable)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.info_outline_rounded,
                          size: 14,
                          color: _C.accent,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.namaSembako,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _C.dark,
                        letterSpacing: -0.3,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    _buildStokBadge(item.stok),
                    if (item.hasNilaiPoin) ...[
                      const SizedBox(height: 3),
                      _buildPoinBadge(item.nilaiPoin),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPoinBadge(double poin) {
    final label = poin == poin.truncateToDouble()
        ? '${poin.toInt()} poin'
        : '${poin.toStringAsFixed(2)} poin';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF4EA771).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF4EA771).withValues(alpha: 0.2),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.stars_rounded, size: 9, color: Color(0xFF4EA771)),
          const SizedBox(width: 3),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4EA771),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStokBadge(double stok) {
    final hasStok = stok > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: hasStok
            ? _C.teal.withValues(alpha: 0.05)
            : Colors.orange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasStok
              ? _C.teal.withValues(alpha: 0.12)
              : Colors.orange.withValues(alpha: 0.2),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.inventory_2_rounded,
            size: 9,
            color: hasStok ? _C.teal : Colors.orange,
          ),
          const SizedBox(width: 3),
          Text(
            'Stok: ${stok.toInt()}',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: hasStok ? _C.teal : Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: const Color(0xFFF2F2F2),
      child: Center(
        child: Icon(Icons.storefront_rounded,
            size: 36, color: _C.accent.withValues(alpha: 0.5)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.search_off_rounded,
                size: 48, color: _C.dark.withValues(alpha: 0.15)),
            const SizedBox(height: 12),
            Text(
              'Tidak ada hasil',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: _C.dark.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Riwayat Distribusi ────────────────────────────────────────────────────

  Widget _buildRiwayatDistribusiSection(SembakoProvider sembako, {required bool showNamaBsu}) {
    final filtered = _filteredDistribusi(sembako);
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height),
      decoration: const BoxDecoration(color: Colors.white),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header + filter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 2),
                  child: Text(
                    'Riwayat Distribusi',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _C.dark,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                MonthYearFilterRow(
                  filterStart: _filterStart,
                  filterEnd: _filterEnd,
                  onChanged: (start, end) {
                    setState(() {
                      _filterStart = start;
                      _filterEnd = end;
                    });
                    _refresh(sembako);
                  },
                ),
              ],
            ),
          ),
          // List
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: sembako.isListDistribusiLoading
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: CircularProgressIndicator(color: _C.accent)),
                  )
                : _buildDistribusiList(filtered, showNamaBsu: showNamaBsu),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDistribusiList(List<ListDistribusiSembakoModel> items, {required bool showNamaBsu}) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 36),
          child: Column(
            children: [
              Icon(Icons.history_toggle_off_rounded,
                  size: 44, color: Colors.grey[300]),
              const SizedBox(height: 10),
              Text(
                'Belum ada riwayat distribusi',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _buildDistribusiCard(items[i], showNamaBsu: showNamaBsu),
    );
  }

  Widget _buildDistribusiCard(ListDistribusiSembakoModel d, {required bool showNamaBsu}) {
    final status = d.statusDistribusi.toLowerCase();
    final Color statusColor;
    final Color statusBg;
    final String statusLabel;

    switch (status) {
      case 'selesai':
      case 'diterima':
        statusColor = const Color(0xFF4EA771);
        statusBg = const Color(0xFFE8F5E9);
        statusLabel = status == 'diterima' ? 'Diterima' : 'Selesai';
        break;
      case 'pending':
        statusColor = const Color(0xFFF59E0B);
        statusBg = const Color(0xFFFEF3C7);
        statusLabel = 'Menunggu';
        break;
      default:
        statusColor = Colors.grey.shade500;
        statusBg = Colors.grey.shade100;
        statusLabel = d.statusDistribusi;
    }

    final tanggal = '${DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(d.createdAt)} WIB';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StrukDistribusiSembakoScreen(disbakoId: d.disbakoId),
        ),
      ),
      child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          width: 1,
          color: _C.dark.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: _C.dark.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.local_shipping_rounded,
              color: _C.dark,
              size: 18,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  showNamaBsu ? d.namaBsu : tanggal,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _C.dark,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  showNamaBsu ? tanggal : '${d.totalItem.toInt()} item',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11.5,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }

}
