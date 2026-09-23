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

class _C {
  static const bg     = Color(0xFFF2FAF0);
  static const dark   = Color(0xFF0D3B3E);
  static const accent = Color(0xFF4EA771);
  static const teal   = Color(0xFF013236);
}

/// Katalog sampah (dan barang) milik satu bank sampah. Murni penampil — tidak
/// ada aksi ubah data apa pun di layar ini.
///
/// Dipakai empat peran dengan isi yang berbeda-beda; lihat [role].
class KatalogScreen extends StatefulWidget {
  /// Peran pemakai. Menentukan dua hal: siapa yang dapat tab Barang (lihat
  /// `_punyaTabBarang`), dan level harga mana yang tampil di [DetailSampahSheet]
  /// — nasabah cuma level 'nasabah', petugas lebih luas.
  ///
  /// Sengaja tanpa nilai default. Sebelumnya default-nya 'petugas_bsu', jadi
  /// pemanggil yang lupa mengisinya diam-diam dapat peran yang salah.
  final String role;

  /// Diisi kalau layar ini dipasang sebagai TAB di beranda (BSI/BSU) — tombol
  /// back-nya balik ke tab beranda. Null berarti layar ini di-push sebagai
  /// route biasa (nasabah dan BSM), dan back-nya pop seperti biasa.
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

  /// Tab Barang cuma untuk BSM (yang mengelola stoknya) dan nasabah (yang
  /// menukar poin dengan barang itu). BSI dan BSU tidak berurusan dengan
  /// katalog barang bank sampah, jadi buat mereka layar ini sampah saja.
  bool get _punyaTabBarang =>
      widget.role == 'petugas_bsm' || widget.role == 'nasabah';

  /// Pengantar di atas daftar sampah.
  ///
  /// Nasabah datang ke sini untuk tahu *apa yang bisa saya setorkan*, jadi
  /// teksnya menjelaskan isi daftarnya. Petugas datang untuk memantau harga,
  /// jadi teksnya mengarahkan ke aksi (klik item -> riwayat harga).
  String get _deskripsiSampah => widget.role == 'nasabah'
      ? 'Daftar item sampah yang bisa kamu setorkan dan diterima bank sampah saat hari penimbangan'
      : 'Klik item sampah untuk melihat detail harga dan riwayat perubahan harga sampah tersebut';

  /// Pengantar di atas daftar barang — lihat [_deskripsiSampah].
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
        // Tab Riwayat isinya distribusi BSI-BSU, data internal antar-bank.
        // Tab Barang cuma dipegang BSM dan nasabah, dan tidak satu pun dari
        // keduanya berhak melihatnya. Dulu role di sini dipatok 'petugas_bsm'
        // supaya tab itu tidak muncul -- kebetulan benar dengan alasan yang
        // salah, dan langsung jadi bocor begitu nasabah ikut masuk.
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
                TopBarBack(
                  // BSI/BSU tidak punya tab Barang, jadi judulnya jangan
                  // menjanjikan sesuatu yang tidak ada di layar mereka.
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
                          // Deskripsi + search + chip: tergulir habis seperti
                          // biasa.
                          SliverToBoxAdapter(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(28, 16, 28, 0),
                                  child: Text(
                                    _deskripsiSampah,
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

                          // Judul + jumlah item nempel di bawah TopBar saat
                          // digulir, jadi konteksnya tidak ikut hilang.
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
                                          color:
                                              _C.accent.withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(20),
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
                              ),
                            ),
                          ),

                          // Grid -- satu-satunya yang bergerak di bawah header.
                          SliverToBoxAdapter(
                            child: Container(
                              width: double.infinity,
                              constraints: BoxConstraints(
                                minHeight: MediaQuery.of(context).size.height,
                              ),
                              decoration:
                                  const BoxDecoration(color: Colors.white),
                              padding: EdgeInsets.only(
                                // Bar melayang di atas konten, jadi ruangnya
                                // harus disisakan sendiri.
                                bottom: 40 +
                                    kRuangBottomBar +
                                    MediaQuery.of(context).padding.bottom,
                              ),
                              child: katalog.isLoading
                                  ? const Padding(
                                      padding: EdgeInsets.only(top: 100),
                                      child: Center(
                                          child: CircularProgressIndicator(
                                              color: _C.accent)),
                                    )
                                  : Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildGrid(filtered),
                                        // Katalog sampah dipaginasi di server
                                        // (KatalogProvider._applyPagination).
                                        // Tanpa kontrol ini isinya mentok di
                                        // halaman 1 -- dan itu yang selama ini
                                        // terjadi di layar harga.
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
                          color: _C.accent,
                          onRefresh: () async {
                            final auth = Provider.of<AuthProvider>(context, listen: false);
                            if (auth.bankId != null) {
                              await barang.fetchKatalogBsi(auth.bankId!, page: 1);
                            }
                          },
                          child: CustomScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            slivers: [
                              // Deskripsi + search: tergulir habis seperti
                              // biasa. Sama persis dengan tab Sampah.
                              SliverToBoxAdapter(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          28, 16, 28, 0),
                                      child: Text(
                                        _deskripsiBarang,
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

                              // Judul + jumlah item nempel di bawah TopBar,
                              // sama seperti tab Sampah.
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
                                              color: _C.accent
                                                  .withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              '${filteredBarang.length} item',
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
                                  ),
                                ),
                              ),

                              // Grid -- satu-satunya yang bergerak di bawah
                              // header.
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
                                                  color: _C.accent)),
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

  // ── Sampah: Filter chips ──────────────────────────────────────────────────
  Widget _buildFilterChips(KatalogProvider katalog) {
    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        physics: const BouncingScrollPhysics(),
        children: [
          // Label memakai jenis SALDO supaya seragam dengan 'Poin' di
          // sebelahnya. Nilai 'uang' tetap kunci internal dari _rewardType(),
          // jangan ikut diubah — itu yang dibandingkan saat menyaring.
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

  // ── Barang: Grid ─────────────────────────────────────────────────────────
  Widget _buildBarangGrid(List<KatalogBarangModel> items) {
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
                          errorBuilder: (_, __, ___) => _buildBarangPlaceholder(),
                        )
                      : _buildBarangPlaceholder(),
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
                      item.namaBarang,
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
            hasStok ? 'Stok: ${stok.toInt()}' : 'Stok habis',
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

  Widget _buildBarangPoinBadge(double poin) {
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

  Widget _buildBarangPlaceholder() {
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

// -- Sticky header delegate ---------------------------------------------------
// Bikin judul seksi ("Katalog Sampah" / "Katalog Barang") nempel (pinned) di
// bawah TopBarBack saat di-scroll, sementara cuma grid item yang ikut bergerak.
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
