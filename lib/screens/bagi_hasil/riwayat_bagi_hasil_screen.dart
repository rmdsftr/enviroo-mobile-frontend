import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format/app_date.dart';
import '../../core/format/app_number.dart';
import '../../models/bagi_hasil_bank_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/bagi_hasil_bank_provider.dart';
import '../../providers/reward_provider.dart';
import '../../providers/penjualan_provider.dart' show FetchStatus;
import '../../widgets/filter_chip_row.dart';
import '../../widgets/topbar_back.dart';
import '../../widgets/filter_month_year.dart';
import '../../screens/penjualan/riwayat_penjualan_screen.dart';
import 'detail_bagi_hasil_screen.dart';
import 'package:enviroo/core/theme/app_colors.dart';
import 'package:enviroo/core/theme/app_text.dart';
import 'package:enviroo/widgets/state_message.dart';


class RiwayatBagiHasilScreen extends StatefulWidget {
  const RiwayatBagiHasilScreen({super.key});

  @override
  State<RiwayatBagiHasilScreen> createState() => _RiwayatBagiHasilScreenState();
}

class _RiwayatBagiHasilScreenState extends State<RiwayatBagiHasilScreen> {
  String _rewardFilter = 'semua';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final auth = context.read<AuthProvider>();
    final prov = context.read<BagiHasilBankProvider>();
    final bankId = auth.bankId ?? '';
    if (bankId.isEmpty) return;
    final now = DateTime.now();
    final filterEnd = DateTime(now.year, now.month);
    final startMonth = now.month - 2;
    final filterStart = startMonth <= 0
        ? DateTime(now.year - 1, 12 + startMonth)
        : DateTime(now.year, startMonth);
    prov.setDateFilter(filterStart, filterEnd, bankId);
    context.read<RewardProvider>().fetchNilaiReward(bankId);
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
          child: Column(
            children: [
              const TopBarBack(title: 'Bagi Hasil'),
              Expanded(
                child: Consumer<BagiHasilBankProvider>(
                  builder: (_, prov, __) => _buildBody(prov),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BagiHasilBankProvider prov) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 8, 28, 12),
                child: Text(
                  'Pada menu ini kamu bisa melihat semua riwayat bagi hasil yang pernah dilakukan bank sampah',
                  style: AppText.p(13, color: AppColors.dark.withValues(alpha: 0.8), height: 1.5),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildLakukanBagiHasilCard(),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Consumer<RewardProvider>(
                  builder: (_, reward, __) =>
                      _buildPersenBagiHasilCard(reward),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
        SliverPersistentHeader(
          pinned: true,
          delegate: _StickyHeaderDelegate(
            height: 145,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                      padding : const EdgeInsets.symmetric(horizontal: 5),
                      child : Text(
                        "Riwayat Bagi Hasil",
                        style: AppText.w600(14, AppColors.dark),
                      )
                  ),
                  const SizedBox(height: 12),
                  _buildFilterRow(prov),
                  const SizedBox(height: 10),
                  _buildRewardChipFilter(),
                  const SizedBox(height: 10),
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
              decoration: const BoxDecoration(color: Colors.white),
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 40),
              child: _buildList(prov),
            ),
          ),
        ),
      ],
    );
  }

  String _labelSaldo(PersenBagiHasilReward r) {
    final s = r.satuan.toLowerCase();
    if (s.contains('poin')) return 'saldo poin';
    if (s.contains('rp') || s.contains('rupiah')) return 'saldo rupiah';
    return r.namaReward.toLowerCase().contains('barang')
        ? 'saldo poin'
        : 'saldo rupiah';
  }

  Widget _buildPersenBagiHasilCard(RewardProvider reward) {
    if (reward.nilaiStatus == FetchStatus.loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator(color: AppColors.green)),
      );
    }
    if (reward.persenNasabah.isEmpty) return const SizedBox.shrink();

    final items = reward.persenNasabah;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            Expanded(child: _kartuPersen(items[i])),
          ],
        ],
      ),
    );
  }

  Widget _kartuPersen(PersenBagiHasilReward r) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.dark.withValues(alpha: 0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            AppNumber.persen(r.persenBagiHasil, maksDesimal: 0),
            style: AppText.p(20, weight: FontWeight.w700, color: AppColors.green, height: 1.1),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'bagi hasil ${_labelSaldo(r)} nasabah',
              style: AppText.p(9.5, color: AppColors.dark.withValues(alpha: 0.5), height: 1.35),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLakukanBagiHasilCard() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const RiwayatPenjualanScreen(
              initialStatusFilter: 'Menunggu Bagi Hasil',
            ),
          ),
        ).then((_) => _load());
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.dark,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.neon.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(25),
              ),
              child: const Icon(Icons.payments_rounded,
                  color: AppColors.neon, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lakukan Bagi Hasil',
                    style: AppText.w700(13, Colors.white),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Distribusikan hasil penjualan ke nasabah',
                    style: AppText.r(11, Colors.white60),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterRow(BagiHasilBankProvider prov) {
    final auth = context.read<AuthProvider>();
    return MonthYearFilterRow(
      filterStart: prov.filterStart,
      filterEnd: prov.filterEnd,
      onChanged: (start, end) {
        prov.setDateFilter(
          start,
          end,
          auth.bankId ?? '',
        );
      },
    );
  }

  Widget _buildRewardChipFilter() {
    return FilterChipRow<String>(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      items: const [
        FilterChipItem(value: 'semua', label: 'Semua'),
        FilterChipItem(value: 'uang', label: 'Rupiah'),
        FilterChipItem(value: 'barang', label: 'Poin'),
      ],
      selectedValue: _rewardFilter,
      onSelected: (v) => setState(() => _rewardFilter = v),
    );
  }

  Widget _buildList(BagiHasilBankProvider prov) {
    if (prov.listStatus == BhBankStatus.loading) {
      return Column(
        children: List.generate(
          4,
          (_) => _SkeletonCard(),
        ),
      );
    }

    if (prov.listStatus == BhBankStatus.error) {
      return _buildError(prov.listError ?? 'Gagal memuat data', _load);
    }

    final raw = prov.listData?.riwayatBagiHasil ?? [];
    final items = _rewardFilter == 'semua'
        ? raw
        : raw.where((item) {
            final lower = item.namaReward.toLowerCase();
            if (_rewardFilter == 'uang') return lower.contains('uang');
            if (_rewardFilter == 'barang') return lower.contains('barang');
            return true;
          }).toList();

    if (items.isEmpty) {
      return _buildEmpty();
    }

    return Column(
      children: items
          .map((item) => _BagiHasilCard(
                item: item,
                onTap: () => _openDetail(item.bagiHasilId),
              ))
          .toList(),
    );
  }

  void _openDetail(String bagiHasilId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailBagiHasilScreen(bagiHasilId: bagiHasilId),
      ),
    );
  }

  Widget _buildEmpty() => StateMessage(
        illustration: StateArt.emptyMoney,
        message: 'Belum ada riwayat bagi hasil',
        subtitle: 'Pilih menu lakukan bagi hasil untuk mulai melakukan bagi hasil',
      );

  Widget _buildError(String msg, VoidCallback onRetry) => StateMessage(
        illustration: StateArt.error,
        message: msg,
        action: TextButton(
          onPressed: onRetry,
          child: const Text('Coba Lagi',
              style:
                  TextStyle(fontFamily: 'Poppins', color: AppColors.green)),
        ),
      );
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

class _BagiHasilCard extends StatelessWidget {
  final BagiHasilBankItem item;
  final VoidCallback onTap;

  const _BagiHasilCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tanggal = AppDate.tanggalPanjang(item.tanggalBagiHasil);
    final jam = AppDate.jam(item.tanggalBagiHasil);

    IconData rewardIcon;
    switch (item.rewardId) {
      case 2:
        rewardIcon = Icons.stars_rounded;
        break;
      case 3:
        rewardIcon = Icons.toll_rounded;
        break;
      default:
        rewardIcon = Icons.payments_rounded;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.dark.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.dark.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(rewardIcon, color: AppColors.dark, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$tanggal · $jam',
                    style: AppText.w600(13, AppColors.dark),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'ID : ${item.bagiHasilId}',
                    style: AppText.r(11, AppColors.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                    height: 13,
                    width: 140,
                    decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(6))),
                const SizedBox(height: 6),
                Container(
                    height: 11,
                    width: 100,
                    decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(6))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
