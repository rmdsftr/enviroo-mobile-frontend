import 'package:enviroo/models/katalog_model.dart';
import 'package:enviroo/providers/auth_provider.dart';
import 'package:enviroo/providers/sembako_provider.dart';
import 'package:enviroo/screens/admin_bsi/input_distribusi_sembako_screen.dart';
import 'package:enviroo/screens/admin_bsu/qr_terima_sembako_screen.dart';
import 'package:enviroo/widgets/detail_sembako_sheet.dart';
import 'package:enviroo/widgets/dropdown_custom.dart';
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

class KatalogSembakoScreen extends StatefulWidget {
  final String? initialBsuId;

  const KatalogSembakoScreen({super.key, this.initialBsuId});

  @override
  State<KatalogSembakoScreen> createState() => _KatalogSembakoScreenState();
}

class _KatalogSembakoScreenState extends State<KatalogSembakoScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // null = Katalog Saya (BSI), non-null = ID BSU yang dipilih
  String? _selectedBsuId;
  static const _kBsiSentinel = '__bsi__';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitial();
    });
  }

  void _loadInitial() {
    final auth = context.read<AuthProvider>();
    final sembako = context.read<SembakoProvider>();
    final bankId = auth.bankId ?? '';

    sembako.fetchKatalogBsi(bankId);
    sembako.fetchBsuList(bankId);

    if (widget.initialBsuId != null) {
      _selectedBsuId = widget.initialBsuId;
      sembako.fetchKatalogBsu(widget.initialBsuId!);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool get _viewingBsu => _selectedBsuId != null;

  List<KatalogSembakoModel> _filtered(SembakoProvider sembako) {
    final list = _viewingBsu ? sembako.katalogBsu : sembako.katalogBsi;
    if (_searchQuery.isEmpty) return list;
    return list
        .where((e) => e.namaSembako.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  void _onBsuChanged(String? bsuId, SembakoProvider sembako) {
    setState(() {
      _selectedBsuId = bsuId;
      _searchController.clear();
      _searchQuery = '';
    });

    if (bsuId != null) {
      sembako.fetchKatalogBsu(bsuId);
    } else {
      sembako.setSelectedBsu(null);
    }
  }

  void _openDetail(String sembakoId) {
    final sembako = context.read<SembakoProvider>();
    sembako.fetchDetailSembakoBsu(sembakoId);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.12),
        child: const DetailSembakoSheet(),
      ),
    );
  }

  Future<void> _refresh(SembakoProvider sembako) async {
    final auth = context.read<AuthProvider>();
    final bankId = auth.bankId ?? '';

    await sembako.fetchKatalogBsi(bankId);
    if (_selectedBsuId != null) {
      await sembako.fetchKatalogBsu(_selectedBsuId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<SembakoProvider, AuthProvider>(
      builder: (context, sembako, auth, _) {
        final role = auth.role;
        final isPetugasBsi = role == 'petugas_bsi';
        final isPetugasBsu = role == 'petugas_bsu';
        final canViewDetail = (isPetugasBsi && _viewingBsu) || isPetugasBsu;
        final filtered = _filtered(sembako);

        return Scaffold(
          backgroundColor: _C.bg,
          body: SafeArea(
            child: Column(
              children: [
                const TopBarBack(title: 'Katalog Sembako'),

                Expanded(
                  child: RefreshIndicator(
                    color: _C.accent,
                    onRefresh: () => _refresh(sembako),
                    child: ListView(
                      padding: EdgeInsets.zero,
                      physics: const BouncingScrollPhysics(),
                      children: [
                        // Button distribusi (BSI only)
                        if (isPetugasBsi) ...[
                          const SizedBox(height: 16),
                          _buildDistribusiButton(context),
                        ],

                        // Button terima distribusi (BSU only)
                        if (isPetugasBsu) ...[
                          const SizedBox(height: 16),
                          _buildTerimaDistribusiButton(context),
                        ],

                        const SizedBox(height: 16),

                        // Dropdown filter BSU (BSI only)
                        if (isPetugasBsi) ...[
                          _buildBsuDropdown(sembako),
                          const SizedBox(height: 12),
                        ],

                        // Search bar
                        _buildSearchBar(),
                        const SizedBox(height: 16),

                        // Header label
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Row(
                            children: [
                              Text(
                                _viewingBsu
                                    ? 'Katalog ${_bsuName(sembako)}'
                                    : 'Katalog Saya',
                                style: const TextStyle(
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
                        if (sembako.isLoading || sembako.isBsuLoading)
                          const Padding(
                            padding: EdgeInsets.only(top: 80),
                            child: Center(
                              child: CircularProgressIndicator(color: _C.accent),
                            ),
                          )
                        else
                          _buildGrid(filtered, canViewDetail),

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

  Widget _buildDistribusiButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const InputDistribusiSembakoScreen(),
            ),
          ).then((result) {
            if (result is String && mounted) {
              // result = bsuId yang baru menerima distribusi
              final sembako = context.read<SembakoProvider>();
              final auth = context.read<AuthProvider>();
              _onBsuChanged(result, sembako);
              sembako.fetchBsuList(auth.bankId ?? '');
            }
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
                  'Distribusikan Sembako ke BSU',
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
                  'Terima Distribusi Sembako',
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

  Widget _buildBsuDropdown(SembakoProvider sembako) {
    final items = <CustomDropdownItem<String>>[
      const CustomDropdownItem(value: _kBsiSentinel, label: 'Katalog Saya', icon: Icons.store_rounded),
      ...sembako.bsuList.map((bsu) => CustomDropdownItem(value: bsu.bankId, label: bsu.namaBank, icon: Icons.house_rounded)),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: CustomDropdown<String>(
        value: _selectedBsuId ?? _kBsiSentinel,
        items: items,
        onChanged: (val) => _onBsuChanged(val == _kBsiSentinel ? null : val, sembako),
        hintText: 'Pilih katalog',
        prefixIcon: Icons.store_rounded,
      ),
    );
  }

  Widget _buildSearchBar() {
    return CustomSearchBar(
      controller: _searchController,
      hintText: 'Cari sembako...',
      onChanged: (v) => setState(() => _searchQuery = v),
      searchQuery: _searchQuery,
      onClear: () {
        _searchController.clear();
        setState(() => _searchQuery = '');
      },
      padding: const EdgeInsets.symmetric(horizontal: 24),
    );
  }

  Widget _buildGrid(List<KatalogSembakoModel> items, bool canViewDetail) {
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
        itemBuilder: (context, index) => _buildCard(items[index], canViewDetail),
      ),
    );
  }

  Widget _buildCard(KatalogSembakoModel item, bool canViewDetail) {
    final tappable = canViewDetail;

    return GestureDetector(
      onTap: tappable ? () => _openDetail(item.sembakoId) : null,
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
            hasStok ? 'Stok: ${stok.toInt()} item' : 'Stok Habis',
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

  String _bsuName(SembakoProvider sembako) {
    if (_selectedBsuId == null) return '';
    try {
      return sembako.bsuList.firstWhere((b) => b.bankId == _selectedBsuId).namaBank;
    } catch (_) {
      return 'BSU';
    }
  }
}
