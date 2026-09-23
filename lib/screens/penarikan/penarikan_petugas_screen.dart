import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/penarikan_petugas_provider.dart';
import '../../widgets/filter_chip_row.dart';
import '../../widgets/filter_month_year.dart';
import '../../widgets/penarikan_petugas_card.dart';
import '../../widgets/topbar_back.dart';
import 'detail_transaksi_penarikan_screen.dart';
import 'penarikan_waiting_screen.dart';

class PenarikanPetugasScreen extends StatefulWidget {
  const PenarikanPetugasScreen({super.key});

  @override
  State<PenarikanPetugasScreen> createState() => _PenarikanPetugasScreenState();
}

class _PenarikanPetugasScreenState extends State<PenarikanPetugasScreen> {
  static const Color primary = Color(0xFF4EA771);
  static const Color dark = Color(0xFF013236);

  static const _rewardOptions = ['Semua', 'Uang', 'Barang'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prov = context.read<PenarikanPetugasProvider>();
      prov.bind(context.read<AuthProvider>());
      final now = DateTime.now();
      final filterEnd = DateTime(now.year, now.month);
      final startMonth = now.month - 2;
      final filterStart = startMonth <= 0
          ? DateTime(now.year - 1, 12 + startMonth)
          : DateTime(now.year, startMonth);
      prov.setDateFilter(filterStart, filterEnd);
    });
  }

  void _openWaiting(int initialTab) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PenarikanWaitingScreen(initialTab: initialTab),
      ),
    ).then((_) => context.read<PenarikanPetugasProvider>().loadList());
  }

  Widget _buildStatCard({
    required IconData icon,
    required int jumlah,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
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
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Icon(icon, color: color, size: 20),
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
                label,
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
          child: Consumer<PenarikanPetugasProvider>(
            builder: (_, prov, __) {
              final displayList = prov.selesaiList;

              return Column(
                children: [
                  const TopBarBack(title: 'Penarikan Nasabah'),
                  Expanded(
                    child: RefreshIndicator(
                      color: primary,
                      onRefresh: prov.loadList,
                      child: CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          // Kartu statistik: pending & approved — scroll away normally
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                              child: IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      child: _buildStatCard(
                                        icon: Icons.pending_actions_rounded,
                                        jumlah: prov.pendingList.length,
                                        color : Color(0xFF94DF0C) ,
                                        label: 'Penarikan menunggu persetujuan',
                                        onTap: () => _openWaiting(0),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildStatCard(
                                        icon: Icons.inventory_2_rounded,
                                        jumlah: prov.approvedList.length,
                                        color : Color(0xFF4EA771),
                                        label: 'Penarikan menunggu penjemputan',
                                        onTap: () => _openWaiting(1),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Sticky: "Riwayat Penarikan" + filter bulan + filter reward,
                          // pin di bawah TopBarBack
                          SliverPersistentHeader(
                            pinned: true,
                            delegate: _StickyHeaderDelegate(
                              height: 150,
                              child: Container(
                                color: Colors.white,
                                padding: const EdgeInsets.only(top: 20, bottom: 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding : const EdgeInsets.symmetric(horizontal: 22),
                                      child : Text(
                                        "Riwayat Penarikan",
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          color: dark,
                                        ),
                                      )
                                    ),
                                    const SizedBox(height: 12),
                                    // Date filter
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 20),
                                      child: MonthYearFilterRow(
                                        filterStart: prov.filterStart,
                                        filterEnd: prov.filterEnd,
                                        onChanged: (s, e) => prov.setDateFilter(s, e),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    // Reward filter chips
                                    FilterChipRow<String>(
                                      items: _rewardOptions
                                          .map((v) => FilterChipItem<String>(value: v, label: v))
                                          .toList(),
                                      selectedValue: prov.rewardFilter,
                                      onSelected: prov.setRewardFilter,
                                      padding: const EdgeInsets.symmetric(horizontal: 20),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // List — cuma ini yang scroll di bawah sticky header
                          SliverToBoxAdapter(
                            child: Container(
                              width: double.infinity,
                              constraints: BoxConstraints(
                                minHeight: MediaQuery.of(context).size.height,
                              ),
                              color: Colors.white,
                              padding: const EdgeInsets.only(top: 10, bottom: 32),
                              child: prov.loadingList
                                  ? const Padding(
                                      padding: EdgeInsets.only(top: 40),
                                      child: Center(child: CircularProgressIndicator(color: primary)),
                                    )
                                  : prov.errorList != null && displayList.isEmpty
                                      ? Padding(
                                          padding: const EdgeInsets.only(top: 40),
                                          child: _ErrorState(
                                            message: prov.errorList!,
                                            onRetry: prov.loadList,
                                          ),
                                        )
                                      : displayList.isEmpty
                                          ? const _EmptyState()
                                          : ListView.builder(
                                              shrinkWrap: true,
                                              physics: const NeverScrollableScrollPhysics(),
                                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                                              itemCount: displayList.length,
                                              itemBuilder: (ctx, i) {
                                                final item = displayList[i];
                                                return PenarikanPetugasCard(
                                                  item: item,
                                                  onTap: () async {
                                                    await Navigator.push(
                                                      ctx,
                                                      MaterialPageRoute(
                                                        builder: (_) => DetailTransaksiPenarikanScreen(
                                                          penarikanId: item.penarikanId,
                                                        ),
                                                      ),
                                                    );
                                                    if (ctx.mounted) {
                                                      ctx.read<PenarikanPetugasProvider>().loadList();
                                                    }
                                                  },
                                                );
                                              },
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

// ── Sticky header delegate ───────────────────────────────────────────────────
// Bikin "Riwayat Penarikan" + filter bulan + filter reward nempel (pinned) di
// bawah TopBarBack saat di-scroll, sementara cuma list riwayat yang ikut bergerak.
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

// ── Empty ─────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    const dark = Color(0xFF013236);
    const label = 'Belum ada riwayat selesai';
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
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: dark.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error ─────────────────────────────────────────────────────────────────────

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
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
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
