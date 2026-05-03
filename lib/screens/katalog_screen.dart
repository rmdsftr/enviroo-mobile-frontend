import 'package:enviroo/models/katalog_model.dart';
import 'package:enviroo/providers/auth_provider.dart';
import 'package:enviroo/providers/katalog_provider.dart';
import 'package:enviroo/widgets/navbar_katalog.dart';
import 'package:enviroo/widgets/topbar_back.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Palette
// ─────────────────────────────────────────────────────────────────────────────
class _C {
  static const bg       = Color(0xFFF2FAF0);
  static const dark     = Color(0xFF0D3B3E);
  static const card     = Color(0xFFFFFFFF);
  static const accent   = Color(0xFF4EA771);
  static const teal     = Color(0xFF013236);
}

class KatalogScreen extends StatefulWidget {
  final String role;
  final int initialTab;
  const KatalogScreen({super.key, this.role = 'nasabah', this.initialTab = 0});
  @override
  State<KatalogScreen> createState() => _KatalogScreenState();
}

class _KatalogScreenState extends State<KatalogScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _searchSembakoController = TextEditingController();
  int _selectedFilter = 0;
  String _searchQuery = '';
  String _searchSembakoQuery = '';
  late int _selectedTab;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.bankId != null && auth.currentUser?.accessToken != null) {
        Provider.of<KatalogProvider>(context, listen: false).fetchAll(
          auth.bankId!,
          auth.currentUser!.accessToken,
        );
      }
    });
  }

  // Getters moved to helper methods that take KatalogProvider
  List<dynamic> _getFilteredSampah(KatalogProvider katalog) {
    return katalog.katalogSampah.where((item) {
      if (item is KatalogSampahModel) {
        if (item.poinNasabah <= 0) return false;
      }
      final matchesFilter = _selectedFilter == 0 || item.kategoriId == _selectedFilter;
      final matchesSearch = item.namaSampah.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesFilter && matchesSearch;
    }).toList();
  }

  List<KatalogSembakoModel> _getFilteredSembako(KatalogProvider katalog) {
    final role = widget.role;
    return katalog.katalogSembako.where((item) {
      // Filter by role visibility
      if (role == 'petugas_bsi') {
        if (!item.hasAnyPrice) return false;
      } else if (role == 'petugas_bsm') {
        if (item.poinNasabah <= 0 && item.poinEksternal <= 0) return false;
      } else if (role == 'petugas_bsu') {
        if (item.poinNasabah <= 0 && item.poinBsu <= 0) return false;
      } else {
        // nasabah: hanya tampil jika ada harga nasabah
        if (item.poinNasabah <= 0) return false;
      }
      return item.namaSembako.toLowerCase().contains(_searchSembakoQuery.toLowerCase());
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchSembakoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String descriptionText = _selectedTab == 0
        ? "Katalog ini merupakan harga sampah yang bernilai ketika kamu menyetorkan sampah"
        : "Katalog ini merupakan sembako yang bisa kamu dapat dengan menukarkan saldo poin tabunganmu";

    return Consumer<KatalogProvider>(
      builder: (context, katalog, child) {
        final filteredSampah = _getFilteredSampah(katalog);
        final filteredSembako = _getFilteredSembako(katalog);

        return Scaffold(
          backgroundColor: _C.bg,
          body: SafeArea(
            child: Column(
              children: [
                TopBarBack(title: "Katalog"),
                NavbarKatalog(
                  selectedIndex: _selectedTab,
                  onTabChanged: (index) {
                    setState(() {
                      _selectedTab = index;
                    });
                  },
                ),

                // Content area — scrollable
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      final auth = Provider.of<AuthProvider>(context, listen: false);
                      if (auth.bankId != null && auth.currentUser?.accessToken != null) {
                        await katalog.fetchAll(auth.bankId!, auth.currentUser!.accessToken);
                      }
                    },
                    child: ListView(
                      padding: EdgeInsets.zero,
                      physics: const BouncingScrollPhysics(),
                      children: [
                        // Description
                        Padding(
                          padding: const EdgeInsets.fromLTRB(28, 12, 28, 0),
                          child: Text(
                            descriptionText,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12.5,
                              height: 1.6,
                              color: _C.dark.withOpacity(0.65),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Search bar
                        _selectedTab == 0
                            ? _buildSearchBar(
                                controller: _searchController,
                                hint: "Cari jenis sampah...",
                                onChanged: (v) => setState(() => _searchQuery = v),
                              )
                            : _buildSearchBar(
                                controller: _searchSembakoController,
                                hint: "Cari sembako...",
                                onChanged: (v) => setState(() => _searchSembakoQuery = v),
                              ),

                        // Filter chips (only for sampah tab)
                        if (_selectedTab == 0) ...[
                          const SizedBox(height: 14),
                          _buildFilterChips(katalog),
                        ],

                        const SizedBox(height: 18),

                        // Result count
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 28),
                          child: Row(
                            children: [
                              Text(
                                _selectedTab == 0 ? 'Katalog Sampah' : 'Katalog Sembako',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: _C.dark,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _C.accent.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _selectedTab == 0
                                      ? '${filteredSampah.length} item'
                                      : '${filteredSembako.length} item',
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
                            child: Center(child: CircularProgressIndicator(color: _C.accent)),
                          )
                        else
                          // Grid content
                          _selectedTab == 0
                              ? _buildSampahGrid(filteredSampah)
                              : _buildSembakoGrid(filteredSembako),

                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Search bar ────────────────────────────────────────────────────────────
  Widget _buildSearchBar({
    required TextEditingController controller,
    required String hint,
    required ValueChanged<String> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: _C.dark),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            color: _C.dark.withOpacity(0.3),
          ),
          prefixIcon: const Icon(Icons.search_rounded, color: _C.accent, size: 22),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close_rounded, size: 18, color: _C.dark.withOpacity(0.35)),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                )
              : null,
          filled: false,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(50),
            borderSide: BorderSide(color: _C.accent.withOpacity(0.5), width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(50),
            borderSide: const BorderSide(color: _C.accent, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
    );
  }

  // ── Filter chips ──────────────────────────────────────────────────────────
  Widget _buildFilterChips(KatalogProvider katalog) {
    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        physics: const BouncingScrollPhysics(),
        children: [
          _buildFilterChip(0, 'Semua'),
          ...katalog.categories.map((cat) => _buildFilterChip(cat.kategoriId, cat.kategori)).toList(),
        ],
      ),
    );
  }

  Widget _buildFilterChip(int value, String label) {
    final isSelected = _selectedFilter == value;
    final Color activeColor = _C.accent;
    final Color inactiveTextColor = _C.dark.withOpacity(0.5);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() {
            _selectedFilter = value;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected ? activeColor.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(50),
            border: Border.all(
              color: isSelected ? activeColor : const Color(0xFFE5E5E5),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelected) ...[
                Icon(Icons.check, size: 14, color: activeColor),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? activeColor : inactiveTextColor,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Sampah Grid ───────────────────────────────────────────────────────────
  Widget _buildSampahGrid(List<dynamic> items) {
    if (items.isEmpty) {
      return _buildEmptyState();
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
          childAspectRatio: 0.72,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index] as KatalogSampahModel;
          return _buildSampahCard(item);
        },
      ),
    );
  }

  Widget _buildSampahCard(KatalogSampahModel item) {
    // Determine if it's 'uang' or 'poin' based on kategori name if possible, 
    // or just show value. For now backend gives poin_satuan. 
    // In this app context, 'poin' is the primary reward for nasabah.
    final String priceText = '${_formatDouble(item.poinNasabah)} poin/${item.satuan}';

    return Container(
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
          // ── Image area (fills top) ──
          Expanded(
            flex: 3,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (item.photoUrl.isNotEmpty)
                  Image.network(
                    item.photoUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildPlaceholderImage(Icons.recycling_rounded),
                  )
                else
                  _buildPlaceholderImage(Icons.recycling_rounded),
                
                // Kategori Badge
                if (item.kategori != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
              ],
            ),
          ),

          // ── Text area ──
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
                  const SizedBox(height: 4),
                  Text(
                    priceText,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: _C.accent,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage(IconData icon) {
    return Container(
      color: const Color(0xFFF2F2F2),
      child: Center(
        child: Icon(
          icon,
          size: 36,
          color: _C.accent.withOpacity(0.5),
        ),
      ),
    );
  }

  // ── Sembako Grid ──────────────────────────────────────────────────────────
  Widget _buildSembakoGrid(List<KatalogSembakoModel> items) {
    if (items.isEmpty) {
      return _buildEmptyState();
    }

    final role = widget.role;
    // nasabah: sama seperti sampah (0.72)
    // BSI: card lebih tinggi karena 3 harga (0.56)
    // BSM/BSU: 2 harga (0.66)
    final double aspectRatio = role == 'nasabah'
        ? 0.72
        : role == 'petugas_bsi'
            ? 0.56
            : 0.66;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: aspectRatio,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) => _buildSembakoCard(items[index]),
      ),
    );
  }

  Widget _buildSembakoCard(KatalogSembakoModel item) {
    final role = widget.role;
    final isNasabah = role == 'nasabah';
    final isBsi = role == 'petugas_bsi';
    final isBsm = role == 'petugas_bsm';
    final isBsu = role == 'petugas_bsu';

    final double poinNasabah = item.poinNasabah;
    final double poinBsu = item.poinBsu;
    final double poinEksternal = item.poinEksternal;

    return Container(
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
          // ── Image area ──
          Expanded(
            flex: 3,
            child: item.photoUrl.isNotEmpty
                ? Image.network(
                    item.photoUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        _buildPlaceholderImage(Icons.shopping_basket_rounded),
                  )
                : _buildPlaceholderImage(Icons.shopping_basket_rounded),
          ),

          // ── Text area ──
          Expanded(
            flex: isNasabah ? 2 : 3,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.namaSembako,
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
                  const SizedBox(height: 4),

                  // ── Nasabah: hanya tampil poin tanpa label/stok ──
                  if (isNasabah)
                    Text(
                      '${_formatDouble(poinNasabah)} poin',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: _C.accent,
                        letterSpacing: -0.2,
                      ),
                    ),

                  // ── Petugas: tampil stok + harga per level ──
                  if (!isNasabah) ...[
                    _buildStokBadge(item.stok),
                    const SizedBox(height: 4),
                    if ((isBsi || isBsu) && poinBsu > 0)
                      _buildPriceRow(
                        label: 'BSU',
                        poin: poinBsu,
                        color: _C.teal,
                        bgColor: _C.teal.withOpacity(0.08),
                      ),
                    if ((isBsi || isBsu) && poinBsu > 0 && poinNasabah > 0)
                      const SizedBox(height: 3),
                    if (poinNasabah > 0)
                      _buildPriceRow(
                        label: 'Nasabah',
                        poin: poinNasabah,
                        color: _C.accent,
                        bgColor: _C.accent.withOpacity(0.08),
                      ),
                    if ((isBsi || isBsm) && poinEksternal > 0)
                      const SizedBox(height: 3),
                    if ((isBsi || isBsm) && poinEksternal > 0)
                      _buildPriceRow(
                        label: 'Eksternal',
                        poin: poinEksternal,
                        color: const Color(0xFFE65100),
                        bgColor: const Color(0xFFE65100).withOpacity(0.08),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStokBadge(double stok) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: stok > 0
            ? _C.teal.withOpacity(0.05)
            : Colors.orange.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: stok > 0
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
            color: stok > 0 ? _C.teal : Colors.orange,
          ),
          const SizedBox(width: 3),
          Text(
            stok > 0 ? 'Stok: ${_formatDouble(stok)}' : 'Stok Habis',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: stok > 0 ? _C.teal : Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow({
    required String label,
    required double poin,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '${_formatDouble(poin)} poin',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 9.5,
              fontWeight: FontWeight.w500,
              color: color,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }

  // ── Empty state ───────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 48,
              color: _C.dark.withOpacity(0.15),
            ),
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

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  String _formatDouble(double value) {
    if (value == value.truncateToDouble()) {
      return value.toInt().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
    }
    return value.toStringAsFixed(2).replaceAll(RegExp(r'0*$'), '').replaceAll(RegExp(r'\.$'), '').replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
  }
}
