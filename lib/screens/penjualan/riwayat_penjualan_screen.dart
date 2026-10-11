import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format/app_number.dart';
import '../../models/penjualan_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/penjualan_provider.dart';
import '../../providers/reward_provider.dart';
import '../../widgets/topbar_back.dart';
import '../../widgets/filter_month_year.dart';
import '../../widgets/filter_chip_row.dart';
import 'detail_penjualan_screen.dart';
import 'jenis_transaksi_screen.dart';
import 'package:enviroo/core/theme/app_colors.dart';
import 'package:enviroo/core/theme/app_text.dart';
import 'package:enviroo/widgets/state_message.dart';

class _C {
  static const dark = AppColors.dark;
  static const green = AppColors.green;
  static const muted = AppColors.muted;
}

class RiwayatPenjualanScreen extends StatefulWidget {
  final String initialStatusFilter;

  const RiwayatPenjualanScreen({super.key, this.initialStatusFilter = 'Selesai'});

  @override
  State<RiwayatPenjualanScreen> createState() => _RiwayatPenjualanScreenState();
}

class _RiwayatPenjualanScreenState extends State<RiwayatPenjualanScreen> {
  DateTime _filterStart =
      DateTime(DateTime.now().year, DateTime.now().month - 2);
  DateTime _filterEnd = DateTime.now();
  late String _statusFilter;

  static const _statusOptions = ['Selesai', 'Menunggu Bagi Hasil'];

  @override
  void initState() {
    super.initState();
    _statusFilter = widget.initialStatusFilter;
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    final prov = context.read<PenjualanProvider>();
    final reward = context.read<RewardProvider>();
    final bankId = auth.bankId ?? '';
    if (bankId.isEmpty) return;
    await Future.wait([
      prov.fetchRiwayat(
        bankId,
        startDate: '${_filterStart.year}-${_filterStart.month.toString().padLeft(2, '0')}-01',
        endDate: '${_filterEnd.year}-${_filterEnd.month.toString().padLeft(2, '0')}-${DateTime(_filterEnd.year, _filterEnd.month + 1, 0).day.toString().padLeft(2, '0')}',
      ),
      reward.fetchAllReward(),
      prov.fetchMitra(bankId),
    ]);
  }

  void _openForm({MitraModel? initialMitra}) {
    final prov = context.read<PenjualanProvider>();
    prov.resetForm();
    if (initialMitra != null) {
      prov.selectMitra(initialMitra);
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const JenisTransaksiScreen()),
    ).then((_) => _load());
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
            alignment: Alignment.topCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const TopBarBack(title: 'Penjualan Sampah'),
              Expanded(
                child: RefreshIndicator(
                  color: _C.green,
                  onRefresh: _load,
                  child: Consumer2<PenjualanProvider, RewardProvider>(
                    builder: (_, prov, reward, __) {
                      final isBusy = prov.riwayatStatus == FetchStatus.idle ||
                          prov.riwayatStatus == FetchStatus.loading;
                      final isError = prov.riwayatStatus == FetchStatus.error;

                      return CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                              child: IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(child: _buildJualCard()),
                                    const SizedBox(width: 12),
                                    Expanded(child: _buildDaftarMitraCard(prov)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          if (isBusy)
                            const SliverToBoxAdapter(
                              child: Padding(
                                padding: EdgeInsets.only(top: 40),
                                child: Center(
                                  child: CircularProgressIndicator(color: _C.green),
                                ),
                              ),
                            )
                          else if (isError)
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 40),
                                child: _buildError(
                                    prov.riwayatError ?? 'Terjadi kesalahan'),
                              ),
                            )
                          else ...[
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
                                        padding: EdgeInsets.symmetric(horizontal: 22),
                                        child: Text(
                                          'Riwayat Penjualan',
                                          style: AppText.w600(14, _C.dark),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 20),
                                        child: MonthYearFilterRow(
                                          filterStart: _filterStart,
                                          filterEnd: _filterEnd,
                                          onChanged: (start, end) {
                                            setState(() {
                                              _filterStart = start;
                                              _filterEnd = end;
                                            });
                                            _load();
                                          },
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      FilterChipRow<String>(
                                        items: _statusOptions
                                            .map((v) => FilterChipItem<String>(value: v, label: v))
                                            .toList(),
                                        selectedValue: _statusFilter,
                                        onSelected: (v) =>
                                            setState(() => _statusFilter = v),
                                        padding: const EdgeInsets.symmetric(horizontal: 20),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            SliverLayoutBuilder(
                              builder: (context, sc) => SliverToBoxAdapter(
                              child: Builder(builder: (context) {
                                final filtered =
                                    _getFilteredList(prov.riwayat, reward.allReward);
                                return Container(
                                  width: double.infinity,
                                  constraints: BoxConstraints(
                                    minHeight: (sc.viewportMainAxisExtent -
                                            sc.precedingScrollExtent)
                                        .clamp(0.0, double.infinity),
                                  ),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                  ),
                                  padding: const EdgeInsets.only(top: 10, bottom: 100),
                                  child: filtered.isEmpty
                                      ? _buildEmpty()
                                      : ListView.separated(
                                          shrinkWrap: true,
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 20),
                                          itemCount: filtered.length,
                                          separatorBuilder: (_, __) =>
                                              const SizedBox(height: 12),
                                          itemBuilder: (_, i) => _RiwayatCard(
                                            item: filtered[i],
                                            onTap: () =>
                                                _openDetail(filtered[i]),
                                          ),
                                        ),
                                );
                              }),
                            ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<RiwayatPenjualanModel> _getFilteredList(
    List<RiwayatPenjualanModel> list,
    List<RewardModel> rewards,
  ) {
    return list.where((item) {
      final d = item.createdAt;
      final start = DateTime(_filterStart.year, _filterStart.month);
      final end =
          DateTime(_filterEnd.year, _filterEnd.month + 1, 0, 23, 59, 59);
      if (d.isBefore(start) || d.isAfter(end)) return false;

      final sudah = item.statusBagiHasil.toLowerCase() == 'berhasil';
      if (_statusFilter == 'Selesai' && !sudah) return false;
      if (_statusFilter == 'Menunggu Bagi Hasil' && sudah) return false;


      return true;
    }).toList();
  }

  Widget _buildJualCard() {
    return Material(
      color: _C.dark,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => _openForm(),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 18, horizontal: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_circle_outline_rounded, color: Colors.white, size: 30),
              SizedBox(width: 12),
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Jual Sampah',
                      style: AppText.w600(13, Colors.white),
                    ),
                    Text(
                      'ke Pengepul',
                      style: AppText.w600(13, Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDaftarMitraCard(PenjualanProvider prov) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => _openMitraSheet(prov),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _C.green.withValues(alpha: 0.25), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.groups_rounded, color: _C.dark, size: 30),
              SizedBox(width: 12),
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daftar Mitra',
                      style: AppText.w500(12, _C.dark),
                    ),
                    Text(
                      'Pengepul Langganan',
                      style: AppText.w500(12, _C.dark),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openMitraSheet(PenjualanProvider prov) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  Text(
                    'Mitra Pengepul Langganan',
                    style: AppText.w600(15, _C.dark),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Consumer<PenjualanProvider>(
                      builder: (_, p, __) {
                        if (p.mitraStatus == FetchStatus.loading) {
                          return const Center(
                            child: CircularProgressIndicator(color: _C.green),
                          );
                        }
                        if (p.mitraList.isEmpty) {
                          return Center(
                            child: Text(
                              'Belum ada mitra langganan',
                              style: AppText.r(12.5, _C.muted),
                            ),
                          );
                        }
                        return ListView.separated(
                          itemCount: p.mitraList.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (_, i) {
                            final mitra = p.mitraList[i];
                            return Material(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () {
                                  Navigator.pop(sheetContext);
                                  _openForm(initialMitra: mitra);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 12),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                        color: AppColors.border),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: AppColors.neon
                                              .withValues(alpha: 0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                            Icons.storefront_rounded,
                                            size: 18,
                                            color: AppColors.neon),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          mitra.namaMitra,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppText.w500(13, _C.dark),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }


  void _openDetail(RiwayatPenjualanModel item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            DetailPenjualanScreen(penjualanId: item.penjualanId),
      ),
    );
  }

  Widget _buildEmpty() => StateMessage(
        illustration: StateArt.empty,
        message: 'Belum ada riwayat penjualan',
        subtitle: 'Pilih menu jual sampah ke pengepul untuk melakukan penjualan sampah',
      );

  Widget _buildError(String msg) => StateMessage(
        illustration: StateArt.error,
        message: msg,
        action: StateRetryButton(onPressed: _load),
      );
}

class _RiwayatCard extends StatelessWidget {
  final RiwayatPenjualanModel item;
  final VoidCallback onTap;
  const _RiwayatCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              width: 1,
              color: AppColors.dark.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.dark.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Icon(
                  item.satuanReward.toLowerCase() == 'rp' ||
                          item.satuanReward.toLowerCase() == 'rupiah'
                      ? Icons.payments_rounded
                      : Icons.shopping_basket_rounded,
                  color: AppColors.dark,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.namaMitra,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.w600(13.5, _C.dark),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.tanggalFormatted,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.r(11, _C.muted),
                          )
                        ]
                    ),
                    Text(
                      AppNumber.nominalSatuan(
                          item.totalPenjualan, item.satuanReward),
                      style: AppText.w700(13, _C.green),
                    ),
                  ],
                ),
              ),
            ],
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

