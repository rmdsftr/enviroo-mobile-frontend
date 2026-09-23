import 'package:enviroo/models/katalog_model.dart';
import 'package:enviroo/providers/auth_provider.dart';
import 'package:enviroo/providers/katalog_provider.dart';
import 'package:enviroo/providers/sembako_provider.dart';
import 'package:enviroo/widgets/detail_sampah_sheet.dart';
import 'package:enviroo/widgets/detail_sembako_sheet.dart';
import 'package:enviroo/widgets/navbar.dart';
import 'package:enviroo/widgets/search.dart';
import 'package:enviroo/widgets/pagination.dart';
import 'package:enviroo/widgets/topbar_back.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class _C {
  static const bg     = Color(0xFFF2FAF0);
  static const dark   = Color(0xFF0D3B3E);
  static const accent = Color(0xFF4EA771);
  static const teal   = Color(0xFF013236);
}

class PerubahanHargaScreen extends StatefulWidget {
  final String role;
  final VoidCallback? onBack;
  const PerubahanHargaScreen({super.key, this.role = 'petugas_bsu', this.onBack});

  @override
  State<PerubahanHargaScreen> createState() => _PerubahanHargaScreenState();
}

class _PerubahanHargaScreenState extends State<PerubahanHargaScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _sembakoSearchController = TextEditingController();
  String _selectedFilter = 'semua';
  String _searchQuery = '';
  String _sembakoSearchQuery = '';
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.bankId != null) {
        Provider.of<KatalogProvider>(context, listen: false).fetchAll(auth.bankId!);
        if (widget.role == 'petugas_bsm') {
          Provider.of<SembakoProvider>(context, listen: false).fetchKatalogBsi(auth.bankId!);
        }
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _sembakoSearchController.dispose();
    super.dispose();
  }

  String _rewardType(KatalogSampahModel item) {
    final satuan = item.reward?.satuan.toLowerCase() ?? '';
    return satuan == 'poin' ? 'poin' : 'uang';
  }

  List<KatalogSampahModel> _getFilteredSampah(KatalogProvider katalog) {
    return katalog.katalogSampah.where((item) {
      final matchesFilter =
          _selectedFilter == 'semua' || _rewardType(item) == _selectedFilter;
      final matchesSearch =
          item.namaSampah.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesFilter && matchesSearch;
    }).toList();
  }

  List<KatalogSembakoModel> _getFilteredSembako(SembakoProvider sembako) {
    if (_sembakoSearchQuery.isEmpty) return sembako.katalogBsi;
    return sembako.katalogBsi
        .where((e) => e.namaSembako.toLowerCase().contains(_sembakoSearchQuery.toLowerCase()))
        .toList();
  }

  void _openDetail(String sampahId) {
    final katalog = Provider.of<KatalogProvider>(context, listen: false);
    katalog.fetchDetailSampah(sampahId);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            top: MediaQuery.of(context).size.height * 0.12),
        child: DetailSampahSheet(role: widget.role),
      ),
    );
  }

  void _openSembakoDetail(KatalogSembakoModel item) {
    final sembako = Provider.of<SembakoProvider>(context, listen: false);
    sembako.setDetailDirect(item);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.12),
        child: const DetailSembakoSheet(role: 'petugas_bsm', showRiwayat: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isBsm = widget.role == 'petugas_bsm';

    return Consumer<KatalogProvider>(
      builder: (context, katalog, child) {
        final filtered = _getFilteredSampah(katalog);

        return Scaffold(
          backgroundColor: _C.bg,
          body: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Image.asset(
                  'assets/images/bg_struk2.webp',
                  fit: BoxFit.fitWidth,
                ),
              ),
              SafeArea(
            child: Column(
              children: [
                TopBarBack(title: "Katalog dan stok", onBack: widget.onBack),

                if (isBsm) ...[
                  const SizedBox(height: 12),
                  MainNavbar(
                    selectedIndex: _tabIndex,
                    onTabChanged: (i) => setState(() {
                      _tabIndex = i;
                      if (i == 1) {
                        _sembakoSearchController.clear();
                        _sembakoSearchQuery = '';
                      } else {
                        _searchController.clear();
                        _searchQuery = '';
                      }
                    }),
                    tabs: const ['Sampah', 'Barang'],
                  ),
                  const SizedBox(height: 4),
                ],

                if (!isBsm || _tabIndex == 0)
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async {
                        final auth =
                            Provider.of<AuthProvider>(context, listen: false);
                        if (auth.bankId != null) {
                          await katalog.fetchAll(auth.bankId!);
                        }
                      },
                      child: ListView(
                        padding: EdgeInsets.zero,
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(28, 16, 28, 0),
                            child: Text(
                              "Klik item sampah untuk melihat detail harga dan riwayat perubahan harga sampah tersebut",
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12.5,
                                height: 1.6,
                                color: _C.dark.withOpacity(0.65),
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          CustomSearchBar(
                            controller: _searchController,
                            hintText: 'Cari jenis sampah...',
                            onChanged: (v) => setState(() => _searchQuery = v),
                            searchQuery: _searchQuery,
                            onClear: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                          ),

                          const SizedBox(height: 10),
                          _buildFilterChips(katalog),

                          const SizedBox(height: 15),

                          Container(
                            width: double.infinity,
                            constraints: BoxConstraints(
                              minHeight: MediaQuery.of(context).size.height,
                            ),
                            decoration: BoxDecoration(
                                color: Colors.white,
                              // borderRadius : BorderRadius.circular(24),
                            ),
                            padding: const EdgeInsets.only(top: 20, bottom: 40),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 28),
                                  child: Row(
                                    children: [
                                      const Text(
                                        'Katalog Sampah',
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

                                if (katalog.isLoading)
                                  const Padding(
                                    padding: EdgeInsets.only(top: 100),
                                    child: Center(
                                        child: CircularProgressIndicator(
                                            color: _C.accent)),
                                  )
                                else
                                  _buildGrid(filtered),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                if (isBsm && _tabIndex == 1)
                  Expanded(
                    child: Consumer<SembakoProvider>(
                      builder: (context, sembako, _) {
                        final filteredSembako = _getFilteredSembako(sembako);
                        return RefreshIndicator(
                          color: _C.accent,
                          onRefresh: () async {
                            final auth = Provider.of<AuthProvider>(context, listen: false);
                            if (auth.bankId != null) {
                              await sembako.fetchKatalogBsi(auth.bankId!, page: 1);
                            }
                          },
                          child: ListView(
                            padding: EdgeInsets.zero,
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(28, 16, 28, 0),
                                child: Text(
                                  "Klik item barang untuk melihat detail poin dan informasi barang tersebut",
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12.5,
                                    height: 1.6,
                                    color: _C.dark.withOpacity(0.65),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              CustomSearchBar(
                                controller: _sembakoSearchController,
                                hintText: 'Cari barang...',
                                onChanged: (v) => setState(() => _sembakoSearchQuery = v),
                                searchQuery: _sembakoSearchQuery,
                                onClear: () {
                                  _sembakoSearchController.clear();
                                  setState(() => _sembakoSearchQuery = '');
                                },
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                width: double.infinity,
                                constraints: BoxConstraints(
                                  minHeight: MediaQuery.of(context).size.height,
                                ),
                                decoration: const BoxDecoration(color: Colors.white),
                                padding: const EdgeInsets.only(top: 10, bottom: 40),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 28),
                                      child: Row(
                                        children: [
                                          const Text(
                                            'Katalog Barang',
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
                                              '${filteredSembako.length} item',
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
                                    if (sembako.isLoading)
                                      const Padding(
                                        padding: EdgeInsets.only(top: 100),
                                        child: Center(
                                            child: CircularProgressIndicator(color: _C.accent)),
                                      )
                                    else
                                      _buildSembakoGrid(filteredSembako),
                                    if (!sembako.isLoading && sembako.katalogBsiTotalPages > 1)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 20, bottom: 8),
                                        child: Pagination(
                                          currentPage: sembako.katalogBsiPage,
                                          totalPages: sembako.katalogBsiTotalPages,
                                          onPageChanged: (p) => sembako.fetchKatalogBsi(
                                            context.read<AuthProvider>().bankId ?? '',
                                            page: p,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
            ],
          ),
        );
      },
    );
  }

  // ── Sampah: Filter chips ──────────────────────────────────────────────────
  Widget _buildFilterChips(KatalogProvider katalog) {
    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        physics: const BouncingScrollPhysics(),
        children: [
          _buildFilterChip('semua', 'Semua'),
          _buildFilterChip('uang', 'Uang'),
          _buildFilterChip('poin', 'Poin'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedFilter = value);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color:
                isSelected ? _C.accent.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(50),
            border: Border.all(
              color: isSelected ? _C.accent : const Color(0xFFE5E5E5),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelected) ...[
                const Icon(Icons.check, size: 14, color: _C.accent),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? _C.accent : _C.dark.withOpacity(0.5),
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Sampah: Grid ──────────────────────────────────────────────────────────
  Widget _buildGrid(List<KatalogSampahModel> items) {
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
          childAspectRatio: 0.78,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) => _buildCard(items[index]),
      ),
    );
  }

  Widget _buildCard(KatalogSampahModel item) {
    return GestureDetector(
      onTap: () => _openDetail(item.sampahId),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: _C.dark.withOpacity(0.06),
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
                              _buildPlaceholder(Icons.recycling_rounded),
                        )
                      : _buildPlaceholder(Icons.recycling_rounded),
                  if (item.kategori != null)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _C.accent.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          item.kategori!.kategori,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.history_rounded,
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
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.namaSampah,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _C.dark,
                        letterSpacing: -0.3,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    _buildStokBadge(item.stok, item.satuan),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStokBadge(double stok, String satuan) {
    final hasStok = stok > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: hasStok
            ? _C.teal.withOpacity(0.05)
            : Colors.orange.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasStok
              ? _C.teal.withOpacity(0.12)
              : Colors.orange.withOpacity(0.2),
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
            hasStok
                ? 'Stok: ${_formatDouble(stok)} $satuan'
                : '0 $satuan',
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

  Widget _buildPlaceholder(IconData icon) {
    return Container(
      color: const Color(0xFFF2F2F2),
      child: Center(
        child: Icon(icon, size: 36, color: _C.accent.withOpacity(0.5)),
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
                size: 48, color: _C.dark.withOpacity(0.15)),
            const SizedBox(height: 12),
            Text(
              "Tidak ada hasil",
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: _C.dark.withOpacity(0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Sembako: Grid ─────────────────────────────────────────────────────────
  Widget _buildSembakoGrid(List<KatalogSembakoModel> items) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.search_off_rounded,
                  size: 48, color: _C.dark.withOpacity(0.15)),
              const SizedBox(height: 12),
              Text(
                'Tidak ada hasil',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: _C.dark.withOpacity(0.4),
                ),
              ),
            ],
          ),
        ),
      );
    }

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
        itemBuilder: (context, index) => _buildSembakoCard(items[index]),
      ),
    );
  }

  Widget _buildSembakoCard(KatalogSembakoModel item) {
    return GestureDetector(
      onTap: () => _openSembakoDetail(item),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: _C.dark.withOpacity(0.06),
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
                          errorBuilder: (_, __, ___) => _buildSembakoPlaceholder(),
                        )
                      : _buildSembakoPlaceholder(),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
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
                    _buildSembakoStokBadge(item.stok),
                    if (item.hasNilaiPoin) ...[
                      const SizedBox(height: 3),
                      _buildSembakoPoinBadge(item.nilaiPoin),
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

  Widget _buildSembakoStokBadge(double stok) {
    final hasStok = stok > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: hasStok
            ? _C.teal.withOpacity(0.05)
            : Colors.orange.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasStok
              ? _C.teal.withOpacity(0.12)
              : Colors.orange.withOpacity(0.2),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inventory_2_rounded,
              size: 9, color: hasStok ? _C.teal : Colors.orange),
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

  Widget _buildSembakoPoinBadge(double poin) {
    final label = poin == poin.truncateToDouble()
        ? '${poin.toInt()} poin'
        : '${poin.toStringAsFixed(2)} poin';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: _C.accent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _C.accent.withOpacity(0.2),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.stars_rounded, size: 9, color: _C.accent),
          const SizedBox(width: 3),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: _C.accent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSembakoPlaceholder() {
    return Container(
      color: const Color(0xFFF2F2F2),
      child: Center(
        child: Icon(Icons.storefront_rounded,
            size: 36, color: _C.accent.withOpacity(0.5)),
      ),
    );
  }

  String _formatDouble(double value) {
    if (value == value.truncateToDouble()) {
      return value
          .toInt()
          .toString()
          .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
    }
    return value
        .toStringAsFixed(2)
        .replaceAll(RegExp(r'0*$'), '')
        .replaceAll(RegExp(r'\.$'), '')
        .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
  }
}
