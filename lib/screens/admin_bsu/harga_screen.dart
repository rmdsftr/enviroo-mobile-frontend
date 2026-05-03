import 'package:enviroo/models/katalog_history_model.dart';
import 'package:enviroo/models/katalog_model.dart';
import 'package:enviroo/providers/auth_provider.dart';
import 'package:enviroo/providers/katalog_provider.dart';
import 'package:enviroo/widgets/navbar_katalog.dart';
import 'package:enviroo/widgets/topbar_back.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Palette (same as katalog)
// ─────────────────────────────────────────────────────────────────────────────
class _C {
  static const bg       = Color(0xFFF2FAF0);
  static const dark     = Color(0xFF0D3B3E);
  static const card     = Color(0xFFFFFFFF);
  static const accent   = Color(0xFF4EA771);
  static const teal     = Color(0xFF013236);
}

class PerubahanHargaScreen extends StatefulWidget {
  final String role; // 'petugas_bsi' or 'petugas_bsu'
  const PerubahanHargaScreen({super.key, this.role = 'petugas_bsu'});

  @override
  State<PerubahanHargaScreen> createState() => _PerubahanHargaScreenState();
}

class _PerubahanHargaScreenState extends State<PerubahanHargaScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _searchSembakoController = TextEditingController();
  int _selectedFilter = 0;
  String _searchQuery = '';
  String _searchSembakoQuery = '';
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
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

  List<KatalogSampahModel> _getFilteredSampah(KatalogProvider katalog) {
    final isBsi = widget.role == 'petugas_bsi';
    final isBsm = widget.role == 'petugas_bsm';
    return katalog.katalogSampah.where((item) {
      // BSI: tampilkan semua item yang memiliki setidaknya satu harga
      // BSM: tampilkan hanya item yang memiliki harga Nasabah atau Eksternal
      // BSU: tampilkan hanya item yang memiliki harga BSU atau Nasabah
      if (isBsi) {
        if (!item.hasAnyPrice) return false;
      } else if (isBsm) {
        if (item.poinNasabah <= 0 && item.poinEksternal <= 0) return false;
      } else {
        if (item.poinBsu <= 0 && item.poinNasabah <= 0) return false;
      }
      final matchesFilter = _selectedFilter == 0 || item.kategoriId == _selectedFilter;
      final matchesSearch = item.namaSampah.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesFilter && matchesSearch;
    }).toList();
  }

  List<KatalogSembakoModel> _getFilteredSembako(KatalogProvider katalog) {
    final isBsi = widget.role == 'petugas_bsi';
    final isBsm = widget.role == 'petugas_bsm';
    return katalog.katalogSembako.where((item) {
      if (isBsi) {
        if (!item.hasAnyPrice) return false;
      } else if (isBsm) {
        if (item.poinNasabah <= 0 && item.poinEksternal <= 0) return false;
      } else {
        // BSU
        if (item.poinNasabah <= 0 && item.poinBsu <= 0) return false;
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

  // ── Show price / poin history bottom sheet ─────────────────────────────────
  void _showRiwayatBottomSheet(dynamic item, {required bool isSampah}) {
    final String namaItem = isSampah ? (item as KatalogSampahModel).namaSampah : (item as KatalogSembakoModel).namaSembako;
    final String label = isSampah ? 'Riwayat Perubahan Harga' : 'Riwayat Perubahan Poin';
    
    if (isSampah) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final katalog = Provider.of<KatalogProvider>(context, listen: false);
      katalog.fetchHistory((item as KatalogSampahModel).sampahId, auth.currentUser!.accessToken);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.55,
          minChildSize: 0.35,
          maxChildSize: 0.85,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Handle bar
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 4),
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: _C.accent.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                isSampah
                                    ? Icons.recycling_rounded
                                    : Icons.shopping_basket_rounded,
                                color: _C.accent,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    namaItem,
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: _C.dark,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    label,
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                      color: _C.dark.withOpacity(0.5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Close button
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.close_rounded, size: 18, color: _C.dark.withOpacity(0.5)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Divider(height: 1, color: Colors.grey.shade200),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Timeline list
                  Expanded(
                    child: Consumer<KatalogProvider>(
                      builder: (context, katalog, _) {
                        if (isSampah && katalog.isHistoryLoading) {
                          return const Center(child: CircularProgressIndicator(color: _C.accent));
                        }

                        final isBsi = widget.role == 'petugas_bsi';
                        final isBsm = widget.role == 'petugas_bsm';
                        final allHistory = katalog.historyCache[(item as KatalogSampahModel).sampahId] ?? [];
                        final history = isSampah 
                            ? allHistory
                                .where((e) {
                                  if (isBsi) return true; // BSI lihat semua riwayat
                                  if (isBsm) {
                                    return e.levelUser.toLowerCase() == 'nasabah' ||
                                           e.levelUser.toLowerCase() == 'eksternal';
                                  }
                                  return e.levelUser.toLowerCase() == 'bsu' ||
                                         e.levelUser.toLowerCase() == 'nasabah';
                                })
                                .toList()
                            : [];

                        if (history.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.history_rounded, size: 40, color: _C.dark.withOpacity(0.15)),
                                const SizedBox(height: 8),
                                Text(
                                  'Belum ada riwayat',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 13,
                                    color: _C.dark.withOpacity(0.4),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
                          itemCount: history.length,
                          itemBuilder: (context, index) {
                            final entry = (history as List<KatalogHistoryModel>)[index];
                            final double sebelum = entry.oldPoin;
                            final double sesudah = entry.newPoin;
                            final bool isIncrease = sesudah >= sebelum;
                            final bool isLast = index == history.length - 1;
                            final String lvl = entry.levelUser.isNotEmpty
                                ? entry.levelUser[0].toUpperCase() + entry.levelUser.substring(1)
                                : '';

                            return IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Timeline column
                                  SizedBox(
                                    width: 28,
                                    child: Column(
                                      children: [
                                        Container(
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            color: index == 0 ? _C.accent : Colors.grey.shade300,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: index == 0 ? _C.accent : Colors.grey.shade300,
                                              width: 2,
                                            ),
                                          ),
                                        ),
                                        if (!isLast)
                                          Expanded(
                                            child: Container(
                                              width: 2,
                                              color: Colors.grey.shade200,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(width: 12),

                                  // Card content
                                  Expanded(
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 14),
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: index == 0
                                            ? _C.accent.withOpacity(0.06)
                                            : Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: index == 0
                                              ? _C.accent.withOpacity(0.15)
                                              : Colors.grey.shade200,
                                          width: 1,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Date & Admin
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.calendar_today_rounded,
                                                size: 13,
                                                color: _C.dark.withOpacity(0.4),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                DateFormat('dd MMM yyyy, HH:mm').format(entry.changedAt),
                                                style: TextStyle(
                                                  fontFamily: 'Poppins',
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w500,
                                                  color: _C.dark.withOpacity(0.5),
                                                ),
                                              ),
                                              const Spacer(),
                                              // Level user badge
                                              if (lvl.isNotEmpty)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  margin: const EdgeInsets.only(right: 4),
                                                  decoration: BoxDecoration(
                                                    color: lvl.toLowerCase() == 'bsu'
                                                        ? _C.teal.withOpacity(0.1)
                                                        : lvl.toLowerCase() == 'nasabah'
                                                            ? _C.accent.withOpacity(0.1)
                                                            : const Color(0xFFE65100).withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    lvl,
                                                    style: TextStyle(
                                                      fontFamily: 'Poppins',
                                                      fontSize: 8,
                                                      fontWeight: FontWeight.w700,
                                                      color: lvl.toLowerCase() == 'bsu'
                                                          ? _C.teal
                                                          : lvl.toLowerCase() == 'nasabah'
                                                              ? _C.accent
                                                              : const Color(0xFFE65100),
                                                    ),
                                                  ),
                                                ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: _C.accent.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  entry.adminNama,
                                                  style: const TextStyle(
                                                    fontFamily: 'Poppins',
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.w600,
                                                    color: _C.accent,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),

                                          // Price change row
                                          Row(
                                            children: [
                                              // Sebelum
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Sebelum',
                                                      style: TextStyle(
                                                        fontFamily: 'Poppins',
                                                        fontSize: 9.5,
                                                        fontWeight: FontWeight.w500,
                                                        color: _C.dark.withOpacity(0.4),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      '${_formatDouble(sebelum)} poin',
                                                      style: TextStyle(
                                                        fontFamily: 'Poppins',
                                                        fontSize: 13,
                                                        fontWeight: FontWeight.w600,
                                                        color: _C.dark.withOpacity(0.7),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),

                                              // Arrow
                                              Container(
                                                padding: const EdgeInsets.all(6),
                                                decoration: BoxDecoration(
                                                  color: isIncrease
                                                      ? const Color(0xFF4EA771).withOpacity(0.12)
                                                      : const Color(0xFFE53935).withOpacity(0.12),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  isIncrease
                                                      ? Icons.trending_up_rounded
                                                      : Icons.trending_down_rounded,
                                                  size: 16,
                                                  color: isIncrease
                                                      ? const Color(0xFF4EA771)
                                                      : const Color(0xFFE53935),
                                                ),
                                              ),

                                              const SizedBox(width: 8),

                                              // Sesudah
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.end,
                                                  children: [
                                                    Text(
                                                      'Sesudah',
                                                      style: TextStyle(
                                                        fontFamily: 'Poppins',
                                                        fontSize: 9.5,
                                                        fontWeight: FontWeight.w500,
                                                        color: _C.dark.withOpacity(0.4),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      '${_formatDouble(sesudah)} poin',
                                                      style: TextStyle(
                                                        fontFamily: 'Poppins',
                                                        fontSize: 13,
                                                        fontWeight: FontWeight.w700,
                                                        color: isIncrease
                                                            ? const Color(0xFF4EA771)
                                                            : const Color(0xFFE53935),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
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
                TopBarBack(title: "Perubahan Harga"),
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
            borderSide: BorderSide(color: _C.accent.withOpacity(0.5), width: 1.5),
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
  Widget _buildSampahGrid(List<KatalogSampahModel> items) {
    if (items.isEmpty) {
      return _buildEmptyState();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: widget.role == 'petugas_bsi' ? 0.56 : 0.66,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          return _buildSampahCard(items[index]);
        },
      ),
    );
  }

  Widget _buildSampahCard(KatalogSampahModel item) {
    final double poinBsu = item.poinBsu;
    final double poinNasabah = item.poinNasabah;
    final double poinEksternal = item.poinEksternal;
    final bool isBsi = widget.role == 'petugas_bsi';
    final bool isBsm = widget.role == 'petugas_bsm';

    return GestureDetector(
      onTap: () => _showRiwayatBottomSheet(item, isSampah: true),
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
                  // History icon indicator
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.history_rounded,
                        size: 14,
                        color: _C.accent,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Text area ──
            Expanded(
              flex: 3,
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
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _C.dark,
                        letterSpacing: -0.3,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Stok badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: item.stok > 0
                            ? _C.teal.withOpacity(0.05)
                            : Colors.orange.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: item.stok > 0
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
                            color: item.stok > 0 ? _C.teal : Colors.orange,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${_formatDouble(item.stok)} ${item.satuan}',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: item.stok > 0 ? _C.teal : Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Harga BSU (hide for BSM)
                    if (!isBsm && poinBsu > 0)
                      _buildPriceRow(
                        label: 'BSU',
                        poin: poinBsu,
                        satuan: item.satuan,
                        color: _C.teal,
                        bgColor: _C.teal.withOpacity(0.08),
                      ),
                    if (!isBsm && poinBsu > 0 && poinNasabah > 0)
                      const SizedBox(height: 4),
                    // Harga Nasabah
                    if (poinNasabah > 0)
                      _buildPriceRow(
                        label: 'Nasabah',
                        poin: poinNasabah,
                        satuan: item.satuan,
                        color: _C.accent,
                        bgColor: _C.accent.withOpacity(0.08),
                      ),
                    // Harga Eksternal — untuk BSI dan BSM
                    if ((isBsi || isBsm) && poinEksternal > 0)
                      const SizedBox(height: 4),
                    if ((isBsi || isBsm) && poinEksternal > 0)
                      _buildPriceRow(
                        label: 'Eksternal',
                        poin: poinEksternal,
                        satuan: item.satuan,
                        color: const Color(0xFFE65100),
                        bgColor: const Color(0xFFE65100).withOpacity(0.08),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow({
    required String label,
    required double poin,
    required String satuan,
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
            '${_formatDouble(poin)} poin/$satuan',
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

    final double aspectRatio = widget.role == 'petugas_bsi' ? 0.56 : 0.66;

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
        itemBuilder: (context, index) {
          return _buildSembakoCard(items[index]);
        },
      ),
    );
  }

  Widget _buildSembakoCard(KatalogSembakoModel item) {
    final bool isBsi = widget.role == 'petugas_bsi';
    final bool isBsm = widget.role == 'petugas_bsm';
    final bool isBsu = widget.role == 'petugas_bsu';

    final double poinNasabah = item.poinNasabah;
    final double poinBsu = item.poinBsu;
    final double poinEksternal = item.poinEksternal;

    return GestureDetector(
      onTap: () => _showRiwayatBottomSheet(item, isSampah: false),
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
            // ── Image area ──
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (item.photoUrl.isNotEmpty)
                    Image.network(
                      item.photoUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _buildPlaceholderImage(Icons.shopping_basket_rounded),
                    )
                  else
                    _buildPlaceholderImage(Icons.shopping_basket_rounded),
                  // History icon indicator
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.history_rounded, size: 14, color: _C.accent),
                    ),
                  ),
                ],
              ),
            ),

            // ── Text area ──
            Expanded(
              flex: 3,
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
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _C.dark,
                        letterSpacing: -0.3,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Stok badge
                    _buildStokSembakoBadge(item.stok),
                    const SizedBox(height: 4),
                    // Harga BSU — untuk BSI dan BSU
                    if ((isBsi || isBsu) && poinBsu > 0)
                      _buildPriceRow(
                        label: 'BSU',
                        poin: poinBsu,
                        satuan: 'unit',
                        color: _C.teal,
                        bgColor: _C.teal.withOpacity(0.08),
                      ),
                    if ((isBsi || isBsu) && poinBsu > 0 && poinNasabah > 0)
                      const SizedBox(height: 4),
                    // Harga Nasabah
                    if (poinNasabah > 0)
                      _buildPriceRow(
                        label: 'Nasabah',
                        poin: poinNasabah,
                        satuan: 'unit',
                        color: _C.accent,
                        bgColor: _C.accent.withOpacity(0.08),
                      ),
                    // Harga Eksternal — BSI dan BSM
                    if ((isBsi || isBsm) && poinEksternal > 0)
                      const SizedBox(height: 4),
                    if ((isBsi || isBsm) && poinEksternal > 0)
                      _buildPriceRow(
                        label: 'Eksternal',
                        poin: poinEksternal,
                        satuan: 'unit',
                        color: const Color(0xFFE65100),
                        bgColor: const Color(0xFFE65100).withOpacity(0.08),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStokSembakoBadge(double stok) {
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
