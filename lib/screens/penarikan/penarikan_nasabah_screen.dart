import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/redeem_models.dart';
import '../../models/redeem_overview_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/redeem_nasabah_provider.dart';
import '../../widgets/filter_chip_row.dart';
import '../../widgets/navbar.dart';
import '../../widgets/redeem_card.dart';
import '../../widgets/topbar_back.dart';
import 'detail_penarikan_screen.dart';
import 'request_penarikan_screen.dart';

class PenarikanNasabahScreen extends StatefulWidget {
  const PenarikanNasabahScreen({super.key});

  @override
  State<PenarikanNasabahScreen> createState() => _PenarikanNasabahScreenState();
}

class _PenarikanNasabahScreenState extends State<PenarikanNasabahScreen> {
  static const Color primary = Color(0xFF4EA771);
  static const Color dark = Color(0xFF013236);
  static const Color accent = Color(0xFF94DF0C);

  // Tab index: 0=Diajukan, 1=Dalam Proses, 2=Riwayat
  int _tabIndex = 0;
  // Filter dipilih saat ini ('Semua' + nama reward dari backend)
  String _filter = 'Semua';
  // PageView controller untuk overview cards
  final PageController _overviewController = PageController();
  int _overviewPage = 0;

  @override
  void initState() {
    super.initState();
    _overviewController.addListener(() {
      final page = _overviewController.page?.round() ?? 0;
      if (page != _overviewPage) setState(() => _overviewPage = page);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final prov = context.read<RedeemNasabahProvider>();
      prov.bind(auth);
      prov.loadList();
      prov.loadRewardTypes();
      prov.loadRedeemOverview();
    });
  }

  @override
  void dispose() {
    _overviewController.dispose();
    super.dispose();
  }

  Future<void> _openForm() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const RequestPenarikanScreen()),
    );
    if (result == true && mounted) {
      context.read<RedeemNasabahProvider>().loadList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      body: SafeArea(
        child: Column(
          children: [
            const TopBarBack(title: 'Penarikan Saldo'),
            Expanded(
              child: Consumer<RedeemNasabahProvider>(
                builder: (context, prov, _) {
                  return RefreshIndicator(
                    color: primary,
                    onRefresh: prov.loadList,
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(
                          child: Column(
                            children: [
                              // ── 1. Tombol Ajukan Penarikan ──────────────
                              Padding(
                                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: dark,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(50),
                                      ),
                                      elevation: 0,
                                    ),
                                    onPressed: _openForm,
                                    icon: const Icon(Icons.add_rounded, size: 22),
                                    label: const Text(
                                      'Ajukan Penarikan',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16),

                              // ── 2. Overview Card + Dot Indicator ────────
                              _buildOverviewCards(prov),
                              const SizedBox(height: 8),
                              _buildDotIndicator(
                                prov.redeemOverview.isNotEmpty
                                    ? prov.redeemOverview.length
                                    : 3,
                              ),

                              const SizedBox(height: 16),

                              // ── 3. Tab Navbar ───────────────────────────
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(50),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 10,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      _buildTab(0, 'Diajukan'),
                                      _buildTab(1, 'Dalam Proses'),
                                      _buildTab(2, 'Riwayat'),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 14),

                              // ── 4. Filter Chip ──────────────────────────
                              _buildFilterChips(prov.rewardTypes),

                              const SizedBox(height: 14),
                            ],
                          ),
                        ),

                        // ── 5. List Penarikan ─────────────────────────
                        if (prov.loadingList && prov.list.isEmpty)
                          const SliverFillRemaining(
                            child: Center(
                                child: CircularProgressIndicator(color: primary)),
                          )
                        else if (prov.error != null && prov.list.isEmpty)
                          SliverFillRemaining(
                            child: _buildError(prov.error!, prov),
                          )
                        else
                          _buildList(prov),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(int index, String label) {
    final isSelected = _tabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tabIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? accent : Colors.transparent,
            borderRadius: BorderRadius.circular(50),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? dark
                    : dark.withOpacity(0.45),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips(List<String> rewardTypes) {
    // Fallback: jika belum dimuat dari API, tampilkan semua 3 jenis
    final effectiveTypes = rewardTypes.isNotEmpty
        ? rewardTypes
        : ['Uang tunai', 'Emas', 'Sembako'];

    // Normalisasi nama reward dari backend ke label display singkat
    String toDisplay(String nama) {
      final lower = nama.toLowerCase();
      if (lower.contains('uang')) return 'Uang Tunai';
      if (lower.contains('emas')) return 'Emas';
      if (lower.contains('sembako')) return 'Sembako';
      return nama;
    }

    final items = <FilterChipItem<String>>[
      const FilterChipItem(value: 'Semua', label: 'Semua'),
      ...effectiveTypes.map((r) {
        final display = toDisplay(r);
        return FilterChipItem<String>(value: r, label: display);
      }),
    ];

    if (_filter != 'Semua' && !effectiveTypes.contains(_filter)) {
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => setState(() => _filter = 'Semua'));
    }

    return FilterChipRow<String>(
      items: items,
      selectedValue: _filter,
      onSelected: (v) => setState(() => _filter = v),
      padding: const EdgeInsets.symmetric(horizontal: 20),
    );
  }

  Widget _buildOverviewCards(RedeemNasabahProvider prov) {
    final f = NumberFormat.decimalPattern('id_ID');
    f.maximumFractionDigits = 2;
    f.minimumFractionDigits = 0;

    // Gunakan data real dari API jika tersedia
    if (prov.redeemOverview.isNotEmpty) {
      final cards = prov.redeemOverview.map((item) {
        if (item.isUang) {
          return _OverviewCard(
            icon: Icons.payments_rounded,
            color: const Color(0xFF1E88E5),
            label: 'Total Uang Tunai',
            value: 'Rp ${f.format(item.totalNominal)}',
            sub: 'Dari seluruh riwayat penarikan',
          );
        } else if (item.isEmas) {
          return _OverviewCard(
            icon: Icons.diamond_rounded,
            color: const Color(0xFFFFB300),
            label: 'Total Emas',
            value: '${f.format(item.totalNominal)} gram',
            sub: 'Dari seluruh riwayat penarikan',
          );
        } else {
          // Sembako — tampilkan ringkasan item
          final items = item.detailItemReward;
          final subText = items.isEmpty
              ? 'Belum pernah mendapatkan sembako'
              : items.map((d) => '${d.namaSembako} (x${f.format(d.totalQty)})').join(', ');
          return _OverviewCard(
            icon: Icons.shopping_basket_rounded,
            color: const Color(0xFF4EA771),
            label: 'Penarikan Sembako',
            value: items.isEmpty ? 'Belum pernah' : '${items.length} jenis',
            sub: subText,
            isSembako: true,
          );
        }
      }).toList();

      return SizedBox(
        height: 140,
        child: PageView.builder(
          padEnds: false,
          controller: _overviewController,
          itemCount: cards.length,
          itemBuilder: (context, i) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: cards[i],
          ),
        ),
      );
    }

    // Fallback saat data belum dimuat: hitung manual dari list lokal
    final list = prov.list;
    double totalUang = 0, totalEmas = 0;
    bool adaSembako = false;
    for (final item in list) {
      if (item.isUang) totalUang += item.nominal;
      if (item.isEmas) totalEmas += item.nominal;
      if (item.isSembako) adaSembako = true;
    }

    final fallbackCards = [
      _OverviewCard(
        icon: Icons.payments_rounded,
        color: const Color(0xFF1E88E5),
        label: 'Total Uang Tunai',
        value: 'Rp ${f.format(totalUang)}',
        sub: 'Dari seluruh riwayat penarikan',
      ),
      _OverviewCard(
        icon: Icons.diamond_rounded,
        color: const Color(0xFFFFB300),
        label: 'Total Emas',
        value: '${f.format(totalEmas)} gram',
        sub: 'Dari seluruh riwayat penarikan',
      ),
      _OverviewCard(
        icon: Icons.shopping_basket_rounded,
        color: const Color(0xFF4EA771),
        label: 'Penarikan Sembako',
        value: adaSembako ? 'Pernah diterima' : 'Belum pernah',
        sub: 'Barang sembako yang pernah Anda dapatkan',
        isSembako: true,
      ),
    ];

    return SizedBox(
      height: 140,
      child: PageView.builder(
        padEnds: false,
        controller: _overviewController,
        itemCount: fallbackCards.length,
        itemBuilder: (context, i) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: fallbackCards[i],
        ),
      ),
    );
  }

  Widget _buildDotIndicator(int count) {
    if (count <= 1) return const SizedBox.shrink();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final isActive = i == _overviewPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 20 : 7,
          height: 7,
          decoration: BoxDecoration(
            color: isActive ? primary : primary.withOpacity(0.25),
            borderRadius: BorderRadius.circular(50),
          ),
        );
      }),
    );
  }

  List<RedeemTransaksi> _getFilteredList(List<RedeemTransaksi> all) {
    // filter by tab
    List<RedeemTransaksi> byTab;
    switch (_tabIndex) {
      case 0: // Diajukan
        byTab = all
            .where((t) => t.status == RedeemStatus.waiting)
            .toList();
        break;
      case 1: // Dalam Proses
        byTab = all
            .where((t) => t.status == RedeemStatus.approved)
            .toList();
        break;
      case 2: // Riwayat
        byTab = all
            .where((t) =>
                t.status == RedeemStatus.success ||
                t.status == RedeemStatus.rejected ||
                t.status == RedeemStatus.canceled ||
                t.status == RedeemStatus.failed)
            .toList();
        break;
      default:
        byTab = all;
    }

    // filter by jenis: cocokkan nama reward backend (case-insensitive)
    if (_filter == 'Semua') return byTab;
    return byTab
        .where((t) =>
            (t.reward?.namaReward ?? '').toLowerCase() ==
            _filter.toLowerCase())
        .toList();
  }

  Widget _buildList(RedeemNasabahProvider prov) {
    final filtered = _getFilteredList(prov.list);

    if (filtered.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _buildEmpty(),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, i) {
            final item = filtered[i];
            return RedeemCard(
              data: item,
              onTap: () => _openDetail(item),
            );
          },
          childCount: filtered.length,
        ),
      ),
    );
  }

  void _openDetail(RedeemTransaksi item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailPenarikanScreen(item: item),
      ),
    );
  }

  Widget _buildEmpty() {
    final labels = ['Diajukan', 'Dalam Proses', 'Riwayat'];
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_rounded, size: 60, color: dark.withOpacity(0.15)),
          const SizedBox(height: 14),
          Text(
            'Tidak ada data ${labels[_tabIndex]}',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: dark.withOpacity(0.4),
            ),
          ),
          const SizedBox(height: 4),
          if (_filter != 'Semua')
            Text(
              'Filter: $_filter',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: dark.withOpacity(0.3),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildError(String message, RedeemNasabahProvider prov) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: Colors.redAccent, size: 48),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50)),
              ),
              onPressed: prov.loadList,
              child: const Text('Coba lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Overview Card Widget ──────────────────────────────────────────────────────

class _OverviewCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String sub;
  final bool isSembako;

  const _OverviewCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.sub,
    this.isSembako = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white70, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (isSembako)
            Text(
              sub,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            )
          else ...[
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              sub,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 10,
                color: Colors.white60,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
