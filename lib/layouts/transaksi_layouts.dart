import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../core/format/app_date.dart';
import '../core/format/app_number.dart';
import 'package:provider/provider.dart';

import '../models/mutasi_model.dart';
import '../providers/auth_provider.dart';
import '../providers/mutasi_provider.dart';
import '../widgets/filter_chip_row.dart';
import '../widgets/filter_month_year.dart';
import 'package:enviroo/core/theme/app_colors.dart';
import 'package:enviroo/core/theme/app_text.dart';
import 'package:enviroo/widgets/state_message.dart';

class TransaksiLayouts extends StatefulWidget {
  const TransaksiLayouts({super.key});

  @override
  State<TransaksiLayouts> createState() => _TransaksiLayoutsState();
}

class _TransaksiLayoutsState extends State<TransaksiLayouts> {
  double _dragAccum = 0;
  bool _opening = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final prov = context.read<MutasiProvider>();
      prov.bind(context.read<AuthProvider>());
      prov.load();
    });
  }

  void _openFullScreen() {
    if (_opening) return;
    _opening = true;
    Navigator.of(context)
        .push(
          PageRouteBuilder(
            opaque: false,
            barrierColor: Colors.transparent,
            transitionDuration: const Duration(milliseconds: 280),
            reverseTransitionDuration: const Duration(milliseconds: 240),
            pageBuilder: (_, __, ___) => const _TransaksiFullScreen(),
            transitionsBuilder: (_, animation, __, child) {
              final offset = Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
              return SlideTransition(position: offset, child: child);
            },
          ),
        )
        .whenComplete(() => _opening = false);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MutasiProvider>(
      builder: (_, prov, __) {
        return Container(
          margin: const EdgeInsets.only(top: 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Color(0x0A013236),
                blurRadius: 20,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onVerticalDragStart: (_) => _dragAccum = 0,
                onVerticalDragUpdate: (d) {
                  _dragAccum += d.delta.dy;
                  if (_dragAccum < -40) _openFullScreen();
                },
                onVerticalDragEnd: (d) {
                  if ((d.primaryVelocity ?? 0) < -300) _openFullScreen();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.dark.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(child: _MutasiScrollView(prov: prov)),
            ],
          ),
        );
      },
    );
  }
}

class _TransaksiFullScreen extends StatefulWidget {
  const _TransaksiFullScreen();

  @override
  State<_TransaksiFullScreen> createState() => _TransaksiFullScreenState();
}

class _TransaksiFullScreenState extends State<_TransaksiFullScreen> {
  double _dragAccum = 0;
  bool _closing = false;

  void _close() {
    if (_closing) return;
    _closing = true;
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Consumer<MutasiProvider>(
        builder: (_, prov, __) {
          return Container(
            width: double.infinity,
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onVerticalDragStart: (_) => _dragAccum = 0,
                  onVerticalDragUpdate: (d) {
                    _dragAccum += d.delta.dy;
                    if (_dragAccum > 40) _close();
                  },
                  onVerticalDragEnd: (d) {
                    if ((d.primaryVelocity ?? 0) > 300) _close();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.dark.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(child: _MutasiScrollView(prov: prov)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MutasiScrollView extends StatelessWidget {
  final MutasiProvider prov;

  const _MutasiScrollView({required this.prov});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPersistentHeader(
          pinned: true,
          delegate: _StickyHeaderDelegate(
            height: 112,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                    child: MonthYearFilterRow(
                      filterStart: prov.filterStart,
                      filterEnd: prov.filterEnd,
                      onChanged: prov.setDateFilter,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: FilterChipRow<int>(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      selectedValue: prov.rewardId,
                      onSelected: prov.setRewardFilter,
                      items: const [
                        FilterChipItem(value: 1, label: 'Rupiah'),
                        FilterChipItem(value: 2, label: 'Poin'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        SliverToBoxAdapter(
          child: prov.loading
              ? const _SkeletonChart()
              : prov.data != null
                  ? _ChartSection(
                      data: prov.data!,
                      rewardId: prov.rewardId,
                    )
                  : const SizedBox.shrink(),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              children: [
                Text(
                  'Mutasi Saldo',
                  style: AppText.w700(13, AppColors.dark),
                ),
                const Spacer(),
                if (!prov.loading && prov.data != null)
                  Text(
                    '${prov.data!.mutasiItems.length} transaksi',
                    style: AppText.r(11, AppColors.dark.withValues(alpha: 0.4)),
                  ),
              ],
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 8)),
        if (prov.loading)
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, __) => const _SkeletonItem(),
              childCount: 6,
            ),
          )
        else if (prov.error != null)
          SliverToBoxAdapter(
            child: _ErrorState(
              message: prov.error!,
              onRetry: prov.load,
            ),
          )
        else if (prov.data == null || prov.data!.mutasiItems.isEmpty)
          const SliverToBoxAdapter(child: _EmptyState())
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) {
                final items = prov.data!.mutasiItems;
                return _MutasiItemTile(
                  item: items[i],
                  rewardId: prov.rewardId,
                  showDivider: i < items.length - 1,
                );
              },
              childCount: prov.data!.mutasiItems.length,
            ),
          ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: MediaQuery.of(context).padding.bottom + 32,
          ),
        ),
      ],
    );
  }
}

class _ChartSection extends StatelessWidget {
  final MutasiResponse data;
  final int rewardId;

  const _ChartSection({required this.data, required this.rewardId});


  double get _totalKredit => data.totalKredit;
  double get _totalDebit  => data.totalDebit;

  String _fmt(double v) {
    switch (rewardId) {
      case 1:
        return AppNumber.rupiah(v);
      case 2:
        return AppNumber.denganSatuan(v, 'poin');
      default:
        return AppNumber.desimal(v);
    }
  }

  @override
  Widget build(BuildContext context) {
    final max = math.max(_totalKredit, _totalDebit);
    final kreditRatio = max > 0 ? _totalKredit / max : 0.0;
    final debitRatio  = max > 0 ? _totalDebit  / max : 0.0;
    const maxBarH = 72.0;
    final selisih = _totalKredit - _totalDebit;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FFFE),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: AppColors.green.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _BarColumn(
                label: 'Kredit',
                value: _fmt(_totalKredit),
                barHeight: kreditRatio * maxBarH,
                color: AppColors.green,
              ),
              _BarColumn(
                label: 'Debit',
                value: _fmt(_totalDebit),
                barHeight: debitRatio * maxBarH,
                color: AppColors.danger,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
              height: 1,
              color: AppColors.dark.withValues(alpha: 0.06)),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Selisih saldo',
                style: AppText.r(12, AppColors.dark.withValues(alpha: 0.5)),
              ),
              const Spacer(),
              Text(
                '${selisih >= 0 ? '+' : '-'}${_fmt(selisih.abs())}',
                style: AppText.w700(13, selisih >= 0 ? AppColors.green : AppColors.danger),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BarColumn extends StatelessWidget {
  final String label;
  final String value;
  final double barHeight;
  final Color color;

  const _BarColumn({
    required this.label,
    required this.value,
    required this.barHeight,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: AppText.w600(11, color),
        ),
        const SizedBox(height: 6),
        AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
          width: 44,
          height: math.max(barHeight, 6),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: AppText.r(11, AppColors.dark.withValues(alpha: 0.5)),
        ),
      ],
    );
  }
}

class _MutasiItemTile extends StatelessWidget {
  final MutasiItem item;
  final int rewardId;
  final bool showDivider;

  const _MutasiItemTile({
    required this.item,
    required this.rewardId,
    required this.showDivider,
  });


  String _formatNominal() {
    final prefix = item.isPositive ? '+' : '-';
    switch (rewardId) {
      case 1:
        return '$prefix${AppNumber.rupiah(item.nominal)}';
      case 2:
        return '$prefix${AppNumber.denganSatuan(item.nominal, 'poin')}';
      default:
        return '$prefix${AppNumber.desimal(item.nominal)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = item.isPositive ? AppColors.green : AppColors.danger;
    final bgColor =
        item.isPositive ? const Color(0xFFF0FAF4) : const Color(0xFFFDF2F2);
    final dateTimeStr =
        AppDate.tanggalSingkatJam(item.tanggalTransaksi);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        child: Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      item.isPositive
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      color: color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dateTimeStr,
                          style: AppText.w600(13, AppColors.dark),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.keterangan.isNotEmpty ? item.keterangan : '-',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.r(11, AppColors.dark.withValues(alpha: 0.4)),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _formatNominal(),
                    style: AppText.w700(14, color),
                  ),
                ],
              ),
            ),
            if (showDivider)
              Divider(
                height: 1,
                indent: 20,
                endIndent: 20,
                color: AppColors.dark.withValues(alpha: 0.06),
              ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonChart extends StatelessWidget {
  const _SkeletonChart();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 130,
      decoration: BoxDecoration(
        color: AppColors.divider,
        borderRadius: BorderRadius.circular(18),
      ),
    );
  }
}

class _SkeletonItem extends StatelessWidget {
  const _SkeletonItem();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 12,
                  width: 90,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  height: 10,
                  width: 60,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 14,
            width: 72,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const StateMessage(
      illustration: StateArt.emptyMoney,
      message: 'Belum ada mutasi saldo pada periode ini',
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
