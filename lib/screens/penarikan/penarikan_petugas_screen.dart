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
import 'package:enviroo/core/theme/app_colors.dart';
import 'package:enviroo/core/theme/app_text.dart';
import 'package:enviroo/widgets/state_message.dart';

class PenarikanPetugasScreen extends StatefulWidget {
  const PenarikanPetugasScreen({super.key});

  @override
  State<PenarikanPetugasScreen> createState() => _PenarikanPetugasScreenState();
}

class _PenarikanPetugasScreenState extends State<PenarikanPetugasScreen> {
  static const Color primary = AppColors.green;
  static const Color dark = AppColors.dark;

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

  Future<void> _openWaiting(int initialTab) async {
    final prov = context.read<PenarikanPetugasProvider>();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PenarikanWaitingScreen(initialTab: initialTab),
      ),
    );
    await prov.loadList();
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
                    style: AppText.w700(20, dark),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: AppText.w500(11, dark.withValues(alpha: 0.6)),
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
      backgroundColor: AppColors.surface,
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
                                        color : AppColors.neon ,
                                        label: 'Penarikan menunggu persetujuan',
                                        onTap: () => _openWaiting(0),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildStatCard(
                                        icon: Icons.inventory_2_rounded,
                                        jumlah: prov.approvedList.length,
                                        color : AppColors.green,
                                        label: 'Penarikan menunggu penjemputan',
                                        onTap: () => _openWaiting(1),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
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
                                        style: AppText.w600(14, dark),
                                      )
                                    ),
                                    const SizedBox(height: 12),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 20),
                                      child: MonthYearFilterRow(
                                        filterStart: prov.filterStart,
                                        filterEnd: prov.filterEnd,
                                        onChanged: (s, e) => prov.setDateFilter(s, e),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
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
                          SliverLayoutBuilder(
                            builder: (context, sc) => SliverToBoxAdapter(
                              child: Container(
                                width: double.infinity,
                                constraints: BoxConstraints(
                                  minHeight: (sc.viewportMainAxisExtent -
                                          sc.precedingScrollExtent)
                                      .clamp(0.0, double.infinity),
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

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return StateMessage(
      illustration: StateArt.emptyMoney,
      message: 'Belum ada riwayat penarikan',
      subtitle : 'Riwayat penarikan akan muncul jika penarikan nasabah telah selesai',
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return StateMessage(
      illustration: StateArt.error,
      message: message,
      action: StateRetryButton(
        onPressed: onRetry,
        label: 'Coba lagi',
        color: AppColors.green,
        radius: 50,
      ),
    );
  }
}
