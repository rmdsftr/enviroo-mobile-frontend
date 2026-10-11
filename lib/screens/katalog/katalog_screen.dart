import 'package:enviroo/core/format/app_number.dart';
import 'package:enviroo/models/katalog_model.dart';
import 'package:enviroo/providers/auth_provider.dart';
import 'package:enviroo/providers/katalog_provider.dart';
import 'package:enviroo/providers/barang_provider.dart';
import 'package:enviroo/widgets/detail_sampah_sheet.dart';
import 'package:enviroo/widgets/detail_barang_sheet.dart';
import 'package:enviroo/widgets/navbar.dart';
import 'package:enviroo/widgets/search.dart';
import 'package:enviroo/widgets/pagination.dart';
import 'package:enviroo/widgets/bottom_bar_custom.dart';
import 'package:enviroo/widgets/topbar_back.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:enviroo/core/theme/app_colors.dart';
import 'package:enviroo/core/theme/app_text.dart';
import 'package:enviroo/widgets/state_message.dart';

class KatalogScreen extends StatefulWidget {
  final String role;
  final VoidCallback? onBack;

  const KatalogScreen({super.key, required this.role, this.onBack});

  @override
  State<KatalogScreen> createState() => _KatalogScreenState();
}

class _KatalogScreenState extends State<KatalogScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _barangSearchController = TextEditingController();
  String _selectedFilter = 'semua';
  String _searchQuery = '';
  String _barangSearchQuery = '';
  int _tabIndex = 0;

  bool get _punyaTabBarang =>
      widget.role == 'petugas_bsm' || widget.role == 'nasabah';

  String get _deskripsiSampah => widget.role == 'nasabah'
      ? 'Daftar item sampah yang bisa kamu setorkan dan diterima bank sampah saat hari penimbangan'
      : 'Klik item sampah untuk melihat detail harga dan riwayat perubahan harga sampah tersebut';

  String get _deskripsiBarang => widget.role == 'nasabah'
      ? 'Daftar item barang yang bisa kamu dapatkan ketika melakukan penarikan saldo poin'
      : 'Klik item barang untuk melihat detail poin dan informasi barang tersebut';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.bankId != null) {
        Provider.of<KatalogProvider>(context, listen: false).fetchAll(auth.bankId!);
        if (_punyaTabBarang) {
          Provider.of<BarangProvider>(context, listen: false).fetchKatalogBsi(auth.bankId!);
        }
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _barangSearchController.dispose();
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

  List<KatalogBarangModel> _getFilteredBarang(BarangProvider barang) {
    if (_barangSearchQuery.isEmpty) return barang.katalogBsi;
    return barang.katalogBsi
        .where((e) => e.namaBarang.toLowerCase().contains(_barangSearchQuery.toLowerCase()))
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

  void _openBarangDetail(KatalogBarangModel item) {
    final barang = Provider.of<BarangProvider>(context, listen: false);
    barang.setDetailDirect(item);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.12),
        
        
        
        
        
        child: DetailBarangSheet(role: widget.role, showRiwayat: false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final punyaTabBarang = _punyaTabBarang;

    return Consumer<KatalogProvider>(
      builder: (context, katalog, child) {
        final filtered = _getFilteredSampah(katalog);

        return Scaffold(
          backgroundColor: AppColors.surfaceLeaf,
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
                TopBarBack(
                  title: punyaTabBarang
                      ? "Katalog Sampah dan Barang"
                      : "Katalog Sampah",
                  onBack: widget.onBack,
                ),

                if (punyaTabBarang) ...[
                  const SizedBox(height: 12),
                  MainNavbar(
                    selectedIndex: _tabIndex,
                    onTabChanged: (i) => setState(() {
                      _tabIndex = i;
                      if (i == 1) {
                        _barangSearchController.clear();
                        _barangSearchQuery = '';
                      } else {
                        _searchController.clear();
                        _searchQuery = '';
                      }
                    }),
                    tabs: const ['Sampah', 'Barang'],
                  ),
                  const SizedBox(height: 4),
                ],

                if (!punyaTabBarang || _tabIndex == 0)
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async {
                        final auth =
                            Provider.of<AuthProvider>(context, listen: false);
                        if (auth.bankId != null) {
                          await katalog.fetchAll(auth.bankId!);
                        }
                      },
                      child: CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          SliverToBoxAdapter(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(28, 16, 28, 0),
                                  child: Text(
                                    _deskripsiSampah,
                                    style: AppText.p(12.5, color: AppColors.darkAlt.withValues(alpha: 0.65), height: 1.6),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                CustomSearchBar(
                                  controller: _searchController,
                                  hintText: 'Cari jenis sampah...',
                                  onChanged: (v) =>
                                      setState(() => _searchQuery = v),
                                  searchQuery: _searchQuery,
                                  onClear: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24),
                                ),
                                const SizedBox(height: 10),
                                _buildFilterChips(katalog),
                                const SizedBox(height: 15),
                              ],
                            ),
                          ),
                          SliverPersistentHeader(
                            pinned: true,
                            delegate: _StickyHeaderDelegate(
                              height: 56,
                              child: Container(
                                color: Colors.white,
                                padding:
                                    const EdgeInsets.only(top: 15, bottom: 12),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 28),
                                  child: Row(
                                    children: [
                                      Text(
                                        'Katalog Sampah',
                                        style: AppText.w600(13, AppColors.darkAlt),
                                      ),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color:
                                              AppColors.green.withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          '${filtered.length} item',
                                          style: AppText.w600(10, AppColors.green),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SliverLayoutBuilder(
                            builder: (context, sc) => SliverToBoxAdapter(
                              child: Container(
                                width: double.infinity,
                                constraints: BoxConstraints(
                                  minHeight: (sc.viewportMainAxisExtent -
                                          sc.precedingScrollExtent)
                                      .clamp(0.0, double.infinity),
                                ),
                                decoration:
                                    const BoxDecoration(color: Colors.white),
                                padding: EdgeInsets.only(  
                                  bottom: 40 +
                                      kRuangBottomBar +
                                      MediaQuery.of(context).padding.bottom,
                                ),
                                child: katalog.isLoading
                                    ? const Padding(
                                        padding: EdgeInsets.only(top: 100),
                                        child: Center(
                                            child: CircularProgressIndicator(
                                                color: AppColors.green)),
                                      )
                                    : Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _buildGrid(filtered),
                                          if (katalog.totalPages > 1) ...[
                                            const SizedBox(height: 24),
                                            Pagination(
                                              currentPage: katalog.currentPage,
                                              totalPages: katalog.totalPages,
                                              onPageChanged: (page) {
                                                final auth =
                                                    Provider.of<AuthProvider>(
                                                        context,
                                                        listen: false);
                                                if (auth.bankId != null) {
                                                  katalog.goToPage(
                                                      auth.bankId!, page);
                                                }
                                              },
                                            ),
                                          ],
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                if (punyaTabBarang && _tabIndex == 1)
                  Expanded(
                    child: Consumer<BarangProvider>(
                      builder: (context, barang, _) {
                        final filteredBarang = _getFilteredBarang(barang);
                        return RefreshIndicator(
                          color: AppColors.green,
                          onRefresh: () async {
                            final auth = Provider.of<AuthProvider>(context, listen: false);
                            if (auth.bankId != null) {
                              await barang.fetchKatalogBsi(auth.bankId!, page: 1);
                            }
                          },
                          child: CustomScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            slivers: [
                              SliverToBoxAdapter(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          28, 16, 28, 0),
                                      child: Text(
                                        _deskripsiBarang,
                                        style: AppText.p(12.5, color: AppColors.darkAlt.withValues(alpha: 0.65), height: 1.6),
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    CustomSearchBar(
                                      controller: _barangSearchController,
                                      hintText: 'Cari barang...',
                                      onChanged: (v) => setState(
                                          () => _barangSearchQuery = v),
                                      searchQuery: _barangSearchQuery,
                                      onClear: () {
                                        _barangSearchController.clear();
                                        setState(() => _barangSearchQuery = '');
                                      },
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 24),
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                ),
                              ),
                              SliverPersistentHeader(
                                pinned: true,
                                delegate: _StickyHeaderDelegate(
                                  height: 56,
                                  child: Container(
                                    color: Colors.white,
                                    padding: const EdgeInsets.only(
                                        top: 15, bottom: 12),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 28),
                                      child: Row(
                                        children: [
                                          Text(
                                            'Katalog Barang',
                                            style: AppText.w600(13, AppColors.darkAlt),
                                          ),
                                          const Spacer(),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: AppColors.green
                                                  .withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              '${filteredBarang.length} item',
                                              style: AppText.w600(10, AppColors.green),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SliverToBoxAdapter(
                                child: Container(
                                  width: double.infinity,
                                  constraints: BoxConstraints(
                                    minHeight:
                                        MediaQuery.of(context).size.height,
                                  ),
                                  decoration:
                                      const BoxDecoration(color: Colors.white),
                                  padding: EdgeInsets.only(
                                    bottom: 40 +
                                        kRuangBottomBar +
                                        MediaQuery.of(context).padding.bottom,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (barang.isLoading)
                                        const Padding(
                                          padding: EdgeInsets.only(top: 100),
                                          child: Center(
                                              child: CircularProgressIndicator(
                                                  color: AppColors.green)),
                                        )
                                      else
                                        _buildBarangGrid(filteredBarang),
                                      if (!barang.isLoading &&
                                          barang.katalogBsiTotalPages > 1)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              top: 20, bottom: 8),
                                          child: Pagination(
                                            currentPage: barang.katalogBsiPage,
                                            totalPages:
                                                barang.katalogBsiTotalPages,
                                            onPageChanged: (p) =>
                                                barang.fetchKatalogBsi(
                                              context
                                                      .read<AuthProvider>()
                                                      .bankId ??
                                                  '',
                                              page: p,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
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
  Widget _buildFilterChips(KatalogProvider katalog) {
    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        physics: const BouncingScrollPhysics(),
        children: [
          _buildFilterChip('semua', 'Semua'),
          _buildFilterChip('uang', 'Rupiah'),
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
                isSelected ? AppColors.green.withValues(alpha: 0.1) : Colors.white,
            borderRadius: BorderRadius.circular(50),
            border: Border.all(
              color: isSelected ? AppColors.green : const Color(0xFFE5E5E5),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelected) ...[
                const Icon(Icons.check, size: 14, color: AppColors.green),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: AppText.p(12, weight: FontWeight.w600, color: isSelected ? AppColors.green : AppColors.darkAlt.withValues(alpha: 0.5), letterSpacing: -0.2),
              ),
            ],
          ),
        ),
      ),
    );
  }
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
              color: AppColors.darkAlt.withValues(alpha: 0.06),
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
                          color: AppColors.green.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          item.kategori!.kategori,
                          style: AppText.w700(8, Colors.white),
                        ),
                      ),
                    ),
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
                        Icons.history_rounded,
                        size: 14,
                        color: AppColors.green,
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
                      style: AppText.p(13, weight: FontWeight.w600, color: AppColors.darkAlt, height: 1.2, letterSpacing: -0.3),
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
            ? AppColors.dark.withValues(alpha: 0.05)
            : Colors.orange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasStok
              ? AppColors.dark.withValues(alpha: 0.12)
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
            color: hasStok ? AppColors.dark : Colors.orange,
          ),
          const SizedBox(width: 3),
          Text(
            hasStok
                ? 'Stok: ${AppNumber.desimal(stok)} $satuan'
                : '0 $satuan',
            style: AppText.w600(9, hasStok ? AppColors.dark : Colors.orange),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(IconData icon) {
    return Container(
      color: const Color(0xFFF2F2F2),
      child: Center(
        child: Icon(icon, size: 36, color: AppColors.green.withValues(alpha: 0.5)),
      ),
    );
  }

  Widget _buildEmptyState() => StateMessage(
        illustration: StateArt.empty,
        message: "Tidak ada hasil",
      );
  Widget _buildBarangGrid(List<KatalogBarangModel> items) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.search_off_rounded,
                  size: 48, color: AppColors.darkAlt.withValues(alpha: 0.15)),
              const SizedBox(height: 12),
              Text(
                'Tidak ada hasil',
                style: AppText.r(14, AppColors.darkAlt.withValues(alpha: 0.4)),
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
        itemBuilder: (context, index) => _buildBarangCard(items[index]),
      ),
    );
  }

  Widget _buildBarangCard(KatalogBarangModel item) {
    return GestureDetector(
      onTap: () => _openBarangDetail(item),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.darkAlt.withValues(alpha: 0.06),
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
                          errorBuilder: (_, __, ___) => _buildBarangPlaceholder(),
                        )
                      : _buildBarangPlaceholder(),
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
                        color: AppColors.green,
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
                      item.namaBarang,
                      style: AppText.p(12, weight: FontWeight.w600, color: AppColors.darkAlt, height: 1.2, letterSpacing: -0.3),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    _buildBarangStokBadge(item.stok),
                    if (item.hasNilaiPoin) ...[
                      const SizedBox(height: 3),
                      _buildBarangPoinBadge(item.nilaiPoin),
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

  Widget _buildBarangStokBadge(double stok) {
    final hasStok = stok > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: hasStok
            ? AppColors.dark.withValues(alpha: 0.05)
            : Colors.orange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasStok
              ? AppColors.dark.withValues(alpha: 0.12)
              : Colors.orange.withValues(alpha: 0.2),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inventory_2_rounded,
              size: 9, color: hasStok ? AppColors.dark : Colors.orange),
          const SizedBox(width: 3),
          Text(
            hasStok ? 'Stok: ${stok.toInt()}' : 'Stok habis',
            style: AppText.w600(9, hasStok ? AppColors.dark : Colors.orange),
          ),
        ],
      ),
    );
  }

  Widget _buildBarangPoinBadge(double poin) {
    final label = AppNumber.denganSatuan(poin, 'poin');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.green.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.green.withValues(alpha: 0.2),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.stars_rounded, size: 9, color: AppColors.green),
          const SizedBox(width: 3),
          Text(
            label,
            style: AppText.w600(9, AppColors.green),
          ),
        ],
      ),
    );
  }

  Widget _buildBarangPlaceholder() {
    return Container(
      color: const Color(0xFFF2F2F2),
      child: Center(
        child: Icon(Icons.storefront_rounded,
            size: 36, color: AppColors.green.withValues(alpha: 0.5)),
      ),
    );
  }
}

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
