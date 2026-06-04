import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/mutasi_model.dart';
import '../providers/auth_provider.dart';
import '../providers/mutasi_provider.dart';
import '../widgets/filter_chip_row.dart';
import '../widgets/filter_month_year.dart';

class TransaksiLayouts extends StatefulWidget {
  const TransaksiLayouts({super.key});

  @override
  State<TransaksiLayouts> createState() => _TransaksiLayoutsState();
}

class _TransaksiLayoutsState extends State<TransaksiLayouts> {
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
          child: Builder(
            builder: (ctx) {
              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                  // Date filter
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                      child: MonthYearFilterRow(
                        filterStart: prov.filterStart,
                        filterEnd: prov.filterEnd,
                        onChanged: prov.setDateFilter,
                      ),
                    ),
                  ),
                  // Reward filter chips
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: FilterChipRow<int>(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        selectedValue: prov.rewardId,
                        onSelected: prov.setRewardFilter,
                        items: const [
                          FilterChipItem(value: 1, label: 'Uang'),
                          FilterChipItem(value: 2, label: 'Sembako'),
                        ],
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                  // Chart section
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
                  // List header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Row(
                        children: [
                          const Text(
                            'Mutasi Saldo',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF013236),
                            ),
                          ),
                          const Spacer(),
                          if (!prov.loading && prov.data != null)
                            Text(
                              '${prov.data!.mutasiItems.length} transaksi',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 11,
                                color: const Color(0xFF013236)
                                    .withValues(alpha: 0.4),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 8)),
                  // List content
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
                  else if (prov.data == null ||
                      prov.data!.mutasiItems.isEmpty)
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
                      height: MediaQuery.of(ctx).padding.bottom + 32,
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

// ── Chart Section ─────────────────────────────────────────────────────────────

class _ChartSection extends StatelessWidget {
  final MutasiResponse data;
  final int rewardId;

  const _ChartSection({required this.data, required this.rewardId});

  static const _green = Color(0xFF4EA771);
  static const _red = Color(0xFFEF4444);
  static const _dark = Color(0xFF013236);

  double get _totalKredit => data.totalKredit; // saldo masuk  (isPositive=true)
  double get _totalDebit  => data.totalDebit;  // saldo keluar (isPositive=false)

  String _fmt(double v) {
    final f = NumberFormat.decimalPattern('id_ID');
    f.maximumFractionDigits = rewardId == 1 ? 0 : 4;
    f.minimumFractionDigits = 0;
    switch (rewardId) {
      case 1:
        return 'Rp${f.format(v)}';
      case 2:
        return '${f.format(v.round())} poin';
      default:
        return f.format(v);
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
            color: const Color(0xFF4EA771).withValues(alpha: 0.12)),
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
                color: _green,
              ),
              _BarColumn(
                label: 'Debit',
                value: _fmt(_totalDebit),
                barHeight: debitRatio * maxBarH,
                color: _red,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
              height: 1,
              color: _dark.withValues(alpha: 0.06)),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Selisih saldo',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: _dark.withValues(alpha: 0.5),
                ),
              ),
              const Spacer(),
              Text(
                '${selisih >= 0 ? '+' : '-'}${_fmt(selisih.abs())}',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selisih >= 0 ? _green : _red,
                ),
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
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
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
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11,
            color: const Color(0xFF013236).withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}

// ── Mutasi Item ───────────────────────────────────────────────────────────────

class _MutasiItemTile extends StatelessWidget {
  final MutasiItem item;
  final int rewardId;
  final bool showDivider;

  const _MutasiItemTile({
    required this.item,
    required this.rewardId,
    required this.showDivider,
  });

  static const _green = Color(0xFF4EA771);
  static const _red = Color(0xFFEF4444);
  static const _dark = Color(0xFF013236);

  String _formatNominal() {
    final f = NumberFormat.decimalPattern('id_ID');
    f.maximumFractionDigits = rewardId == 1 ? 0 : 4;
    f.minimumFractionDigits = 0;
    final prefix = item.isPositive ? '+' : '-';
    switch (rewardId) {
      case 1:
        return '${prefix}Rp${f.format(item.nominal)}';
      case 2:
        return '$prefix${f.format(item.nominal.round())} poin';
      default:
        return '$prefix${f.format(item.nominal)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = item.isPositive ? _green : _red;
    final bgColor =
        item.isPositive ? const Color(0xFFF0FAF4) : const Color(0xFFFDF2F2);
    final dateStr = DateFormat('d MMM yyyy', 'id_ID')
        .format(item.tanggalTransaksi);
    final timeStr = DateFormat('HH:mm', 'id_ID').format(item.tanggalTransaksi);

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
                          dateStr,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _dark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          timeStr,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            color: _dark.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _formatNominal(),
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
            if (showDivider)
              Divider(
                height: 1,
                indent: 20,
                endIndent: 20,
                color: _dark.withValues(alpha: 0.06),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Skeleton Loading ──────────────────────────────────────────────────────────

class _SkeletonChart extends StatelessWidget {
  const _SkeletonChart();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 130,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
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
              color: const Color(0xFFF0F0F0),
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
                    color: const Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  height: 10,
                  width: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F0F0),
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
              color: const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 32),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 56,
            color: const Color(0xFF013236).withValues(alpha: 0.12),
          ),
          const SizedBox(height: 14),
          Text(
            'Belum ada mutasi saldo pada periode ini',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: const Color(0xFF013236).withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Error State ───────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 32),
      child: Column(
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
    );
  }
}
