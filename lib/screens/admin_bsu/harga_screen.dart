import 'package:enviroo/models/katalog_model.dart';
import 'package:enviroo/providers/auth_provider.dart';
import 'package:enviroo/providers/katalog_provider.dart';
import 'package:enviroo/widgets/detail_sampah_sheet.dart';
import 'package:enviroo/widgets/search.dart';
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
  int _selectedFilter = 0;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.bankId != null) {
        Provider.of<KatalogProvider>(context, listen: false).fetchAll(
          auth.bankId!,
        );
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<KatalogSampahModel> _getFilteredSampah(KatalogProvider katalog) {
    return katalog.katalogSampah.where((item) {
      final matchesFilter =
          _selectedFilter == 0 || item.kategoriId == _selectedFilter;
      final matchesSearch =
          item.namaSampah.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesFilter && matchesSearch;
    }).toList();
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

  @override
  Widget build(BuildContext context) {
    return Consumer<KatalogProvider>(
      builder: (context, katalog, child) {
        final filtered = _getFilteredSampah(katalog);

        return Scaffold(
          backgroundColor: _C.bg,
          body: SafeArea(
            child: Column(
              children: [
                TopBarBack(title: "Stok dan Harga Sampah", onBack: widget.onBack),
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

                        const SizedBox(height: 20),

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

                        const SizedBox(height: 14),
                        _buildFilterChips(katalog),

                        const SizedBox(height: 18),

                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 28),
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
                                  color: _C.accent.withOpacity(0.1),
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

                        const SizedBox(height: 125),
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
          ...katalog.categories
              .map((cat) => _buildFilterChip(cat.kategoriId, cat.kategori)),
        ],
      ),
    );
  }

  Widget _buildFilterChip(int value, String label) {
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

  // ── Grid ──────────────────────────────────────────────────────────────────
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
            // Image
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

            // Text area
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
