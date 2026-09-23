import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/penarikan_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/penarikan_nasabah_provider.dart';
import '../../widgets/filter_chip_row.dart';
import '../../widgets/filter_month_year.dart';
import '../../widgets/topbar_back.dart';
import 'detail_penarikan_screen.dart';
import 'penarikan_ongoing_screen.dart';
import 'request_penarikan_screen.dart';

class PenarikanNasabahScreen extends StatefulWidget {
  const PenarikanNasabahScreen({super.key});

  @override
  State<PenarikanNasabahScreen> createState() =>
      _PenarikanNasabahScreenState();
}

class _PenarikanNasabahScreenState extends State<PenarikanNasabahScreen> {
  static const Color primary = Color(0xFF4EA771);
  static const Color dark = Color(0xFF013236);
  static const Color neon = Color(0xFF88CC0C);

  // 'semua' | 'uang' | 'sembako'
  String _rewardFilter = 'semua';

  static const _rewardChips = [
    FilterChipItem(value: 'semua', label: 'Semua'),
    FilterChipItem(value: 'uang', label: 'Uang'),
    FilterChipItem(value: 'sembako', label: 'Barang'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final prov = context.read<PenarikanNasabahProvider>();
      prov.bind(auth);
      prov.loadInitial();
    });
  }

  Future<void> _openAjukan() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const RequestPenarikanScreen()),
    );
    if (result == true && mounted) {
      context.read<PenarikanNasabahProvider>().loadList(refresh: true);
    }
  }

  void _openOngoing() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PenarikanOngoingScreen()),
    );
  }

  Widget _buildAjukanCard() {
    return Material(
      color: dark,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: _openAjukan,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 18, horizontal: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration : BoxDecoration(
                  color : neon.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: const Icon(Icons.add_circle_outline_rounded, color: neon, size: 25),
              ),
              SizedBox(width: 12),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children : [
                  Text(
                    'Ajukan',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Penarikan',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Colors.white,
                    ),
                  ),
                ]
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDalamProsesCard(int jumlah) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: _openOngoing,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: primary.withValues(alpha: 0.25), width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration : BoxDecoration(
                      color : neon.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: const Icon(Icons.pending_actions_rounded, color: neon, size: 18),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$jumlah',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                      color: dark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Sedang dalam proses',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500,
                  fontSize: 11,
                  color: dark.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
          child: Consumer<PenarikanNasabahProvider>(
            builder: (_, prov, __) {
              final jumlahDalamProses = prov.penarikanList
                  .where((i) => i.status.isDalamProses)
                  .length;
              final visibleList = prov.penarikanList
                  .where((i) => !i.status.isDalamProses)
                  .where((i) {
                if (_rewardFilter == 'semua') return true;
                if (_rewardFilter == 'uang') return i.isUang;
                return i.isSembako;
              }).toList();

              return Column(
                children: [
                  const TopBarBack(title: 'Penarikan Saldo'),
                  Expanded(
                    child: RefreshIndicator(
                      color: primary,
                      onRefresh: () => prov.loadInitial(),
                      child: CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          // 1. Ajukan penarikan + sedang dalam proses — scroll away normally
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                              child: IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      child: _buildAjukanCard(),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildDalamProsesCard(jumlahDalamProses),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Sticky: "Riwayat Penarikan" + filter bulan + filter chip reward
                          SliverPersistentHeader(
                            pinned: true,
                            delegate: _StickyHeaderDelegate(
                              height: 160,
                              child: Container(
                                color: Colors.white,
                                padding: const EdgeInsets.only(top: 5, bottom: 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                                      child : Text(
                                        'Riwayat Penarikan',
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: dark,
                                        ),
                                      )
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 20),
                                      child: MonthYearFilterRow(
                                        filterStart: prov.filterStart,
                                        filterEnd: prov.filterEnd,
                                        onChanged: (s, e) => prov.setFilter(start: s, end: e),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    // 2. Chip filter jenis reward
                                    FilterChipRow<String>(
                                      items: _rewardChips,
                                      selectedValue: _rewardFilter,
                                      onSelected: (v) => setState(() => _rewardFilter = v),
                                      padding: const EdgeInsets.symmetric(horizontal: 20),
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
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (prov.loadingList && prov.penarikanList.isEmpty)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 20),
                                      child: Column(
                                        children: List.generate(
                                          5,
                                          (_) => const _ShimmerCard(),
                                        ),
                                      ),
                                    )
                                  else if (prov.errorList != null && prov.penarikanList.isEmpty)
                                    _ErrorState(
                                      message: prov.errorList!,
                                      onRetry: () => prov.loadList(refresh: true),
                                    )
                                  else if (visibleList.isEmpty)
                                    const _EmptyState()
                                  else
                                    ListView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      padding: const EdgeInsets.symmetric(horizontal: 20),
                                      itemCount: visibleList.length + 1,
                                      itemBuilder: (ctx, i) {
                                        if (i == visibleList.length) {
                                          return prov.hasMore
                                              ? const Padding(
                                                  padding: EdgeInsets.symmetric(vertical: 12),
                                                  child: Center(
                                                    child: CircularProgressIndicator(
                                                      color: primary,
                                                      strokeWidth: 2,
                                                    ),
                                                  ),
                                                )
                                              : const SizedBox.shrink();
                                        }
                                        final item = visibleList[i];
                                        return _PenarikanCard(
                                          item: item,
                                          onTap: () => Navigator.push(
                                            ctx,
                                            MaterialPageRoute(
                                              builder: (_) => DetailPenarikanScreen(
                                                penarikanId: item.penarikanId,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// ── Saldo Summary Card ────────────────────────────────────────────────────────

// ── Penarikan Card ────────────────────────────────────────────────────────────

class _PenarikanCard extends StatelessWidget {
  final PenarikanItem item;
  final VoidCallback onTap;

  const _PenarikanCard({required this.item, required this.onTap});

  static const Color dark = Color(0xFF013236);

  Color get _statusColor => item.status.color;

  String get _statusLabel => item.status.label;

  String get _nominalText {
    final f = NumberFormat.decimalPattern('id_ID');
    f.maximumFractionDigits = 4;
    f.minimumFractionDigits = 0;
    final lower = item.satuanPenarikan.toLowerCase();
    if (lower.contains('rupiah') || item.isUang) {
      return 'Rp ${f.format(item.nominalPenarikan)}';
    }
    return '${f.format(item.nominalPenarikan)} ${item.satuanPenarikan.isEmpty ? 'poin' : item.satuanPenarikan}';
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd MMM yyyy, HH:mm', 'id_ID')
        .format(item.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          width: 1,
          color: const Color(0xFF013236).withValues(alpha: 0.1),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dateStr,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: dark,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Text(
                          _statusLabel,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: _statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _nominalText,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: dark,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Shimmer placeholder ───────────────────────────────────────────────────────

class _ShimmerCard extends StatelessWidget {
  const _ShimmerCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      height: 76,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(18),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    const dark = Color(0xFF013236);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_rounded,
                size: 64, color: dark.withValues(alpha: 0.12)),
            const SizedBox(height: 14),
            Text(
              'Belum ada riwayat penarikan',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: dark.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Transaksi penarikan kamu akan muncul di sini',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: dark.withValues(alpha: 0.3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error state ───────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
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
              style: const TextStyle(
                  fontFamily: 'Poppins', fontSize: 13),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4EA771),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50)),
              ),
              onPressed: onRetry,
              child: const Text('Coba lagi',
                  style: TextStyle(fontFamily: 'Poppins')),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sticky header delegate ───────────────────────────────────────────────────
// Bikin "Riwayat Penarikan" + filter bulan + filter chip reward nempel
// (pinned) di bawah TopBarBack saat di-scroll, sementara cuma ListView card
// yang ikut bergerak.
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
