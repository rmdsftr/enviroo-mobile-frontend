import 'package:enviroo/models/bagi_hasil_nasabah_model.dart';
import 'package:enviroo/providers/auth_provider.dart';
import 'package:enviroo/providers/bagi_hasil_provider.dart';
import 'package:enviroo/providers/penjualan_provider.dart' show FetchStatus;
import 'package:enviroo/screens/bagi_hasil/struk_bagi_hasil_nasabah.dart';
import 'package:enviroo/widgets/filter_month_year.dart';
import 'package:enviroo/widgets/navbar.dart';
import 'package:enviroo/widgets/topbar_back.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:enviroo/core/format/app_date.dart';
import 'package:enviroo/core/format/app_number.dart';
import 'package:enviroo/core/theme/app_colors.dart';
import 'package:enviroo/core/theme/app_text.dart';
import 'package:enviroo/widgets/state_message.dart';

class ListBagiHasilNasabahScreen extends StatefulWidget {
  final int initialTab;
  const ListBagiHasilNasabahScreen({super.key, this.initialTab = 0});

  @override
  State<ListBagiHasilNasabahScreen> createState() =>
      _ListBagiHasilNasabahScreenState();
}

class _ListBagiHasilNasabahScreenState
    extends State<ListBagiHasilNasabahScreen> {

  static const _tabs = ['Saldo Rupiah', 'Saldo Poin'];

  static const _tabKeys = ['uang', 'barang'];
  static const _tabIcons = [
    Icons.account_balance_wallet_rounded,
    Icons.shopping_basket_rounded,
  ];

  int _selectedTab = 0;

  late DateTime _filterStart;
  late DateTime _filterEnd;

  List<BagiHasilNasabahItem> _allItems = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
    final now = DateTime.now();
    _filterEnd = DateTime(now.year, now.month);
    final startRaw = DateTime(now.year, now.month - 2);
    _filterStart = DateTime(startRaw.year, startRaw.month);
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchData());
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final nasabahId = auth.identityId ?? '';

    final prov = context.read<BagiHasilProvider>();
    await prov.fetchListNasabah(
      nasabahId,
      startDate: AppDate.apiAwalBulan(_filterStart),
      endDate: AppDate.apiAkhirBulan(_filterEnd),
    );
    if (!mounted) return;
    if (prov.nasabahListStatus == FetchStatus.success) {
      setState(() {
        _allItems = prov.nasabahList;
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = prov.nasabahListError ?? 'Gagal memuat data bagi hasil';
        _isLoading = false;
      });
    }
  }

  List<BagiHasilNasabahItem> get _filtered {
    final tabKey = _tabKeys[_selectedTab];
    return _allItems.where((item) {
      return item.reward.toLowerCase().contains(tabKey) ||
          item.satuanDiterima.toLowerCase().contains(tabKey);
    }).toList();
  }

  String _formatAmount(double amount, String satuan) =>
      AppNumber.nominalSatuan(amount, satuan);

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
                child: RefreshIndicator(
                  color: AppColors.green,
                  onRefresh: _fetchData,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 12),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Text(
                                'Pada menu ini kamu bisa melihat semua detail bagi hasil yang sudah masuk ke saldo rekeningmu',
                                style: AppText.p(12, color: AppColors.dark.withValues(alpha: 0.65), height: 1.5),
                              ),
                            ),
                            const SizedBox(height: 14),
                            MainNavbar(
                              selectedIndex: _selectedTab,
                              onTabChanged: (i) => setState(() => _selectedTab = i),
                              tabs: _tabs,
                              backgroundColor: Colors.white.withValues(alpha: 0.6),
                              border: Border.all(
                                color: AppColors.dark.withValues(alpha: 0.1),
                                width: 1,
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _StickyHeaderDelegate(
                          height: 108,
                          child: Container(
                            color: Colors.white,
                            padding: const EdgeInsets.only(top: 10, bottom: 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                                  child : Text(
                                      'Riwayat Bagi Hasil',
                                      style: AppText.w600(14, AppColors.dark),
                                  )
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  child: MonthYearFilterRow(
                                    filterStart: _filterStart,
                                    filterEnd: _filterEnd,
                                    onChanged: (s, e) {
                                      setState(() {
                                        _filterStart = s;
                                        _filterEnd = e;
                                      });
                                      _fetchData();
                                    },
                                  ),
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
                            decoration: const BoxDecoration(
                              color: Colors.white,
                            ),
                            padding: const EdgeInsets.only(bottom: 40),
                            child: _isLoading
                                ? const Padding(
                                    padding: EdgeInsets.only(top: 40),
                                    child: Center(
                                        child: CircularProgressIndicator(color: AppColors.green)),
                                  )
                                : _error != null
                                    ? _buildError()
                                    : _buildList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList() {
    final items = _filtered;
    if (items.isEmpty) {
      return StateMessage(
        illustration: StateArt.emptyMoney,
        message: 'Belum ada riwayat bagi hasil',
        subtitle: 'Riwayat bagi hasil bakalan muncul kalau bank sampah udah melakukan bagi hasil ya',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (_, i) => _buildCard(items[i]),
    );
  }

  Widget _buildCard(BagiHasilNasabahItem item) {
    final icon = _tabIcons[_selectedTab];
    final dateStr =
        AppDate.tanggalSingkat(item.tanggal);
    final amountStr = _formatAmount(item.totalDiterima, item.satuanDiterima);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              StrukBagiHasilNasabah(penerimaId: item.penerimaId),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
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
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.dark.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.dark, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dateStr,
                    style: AppText.w600(13, AppColors.dark),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.bagiHasilId,
                    style: AppText.r(10, AppColors.dark.withValues(alpha: 0.45)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  amountStr,
                  style: AppText.w700(13, AppColors.green),
                ),
                const SizedBox(height: 2),
                Icon(Icons.chevron_right_rounded,
                    size: 16, color: AppColors.dark.withValues(alpha: 0.3)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() => StateMessage(
        illustration: StateArt.error,
        message: _error!,
        action: StateRetryButton.pill(onPressed: _fetchData),
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
