import 'package:enviroo/core/format/app_date.dart';
import 'package:enviroo/core/format/app_number.dart';
import 'package:enviroo/models/katalog_model.dart';
import 'package:enviroo/providers/auth_provider.dart';
import 'package:enviroo/providers/barang_provider.dart';
import 'package:enviroo/screens/distribusi_barang/input_distribusi_barang_screen.dart';
import 'package:enviroo/screens/distribusi_barang/struk_distribusi_barang_screen.dart';
import 'package:enviroo/screens/distribusi_barang/qr_terima_barang_screen.dart';
import 'package:enviroo/widgets/detail_barang_sheet.dart';
import 'package:enviroo/widgets/filter_month_year.dart';
import 'package:enviroo/widgets/navbar.dart';
import 'package:enviroo/widgets/search.dart';
import 'package:enviroo/widgets/pagination.dart';
import 'package:enviroo/widgets/topbar_back.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:enviroo/core/theme/app_colors.dart';
import 'package:enviroo/core/theme/app_text.dart';
import 'package:enviroo/widgets/state_message.dart';


class KatalogBarangScreen extends StatefulWidget {
  const KatalogBarangScreen({super.key});

  @override
  State<KatalogBarangScreen> createState() => _KatalogBarangScreenState();
}

class _KatalogBarangScreenState extends State<KatalogBarangScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _tabIndex = 0;

  late DateTime _filterStart;
  late DateTime _filterEnd;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    int startMonth = now.month - 2;
    int startYear = now.year;
    if (startMonth <= 0) { startMonth += 12; startYear--; }
    _filterStart = DateTime(startYear, startMonth);
    _filterEnd = DateTime(now.year, now.month);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitial());
  }

  void _loadInitial() {
    final auth = context.read<AuthProvider>();
    final barang = context.read<BarangProvider>();
    final bankId = auth.bankId ?? '';
    barang.fetchKatalogBsi(bankId);
    if (auth.role == 'petugas_bsi' || auth.role == 'petugas_bsu') {
      barang.fetchListDistribusi(
        bankId,
        startDate: '${_filterStart.year}-${_filterStart.month.toString().padLeft(2, '0')}-01',
        endDate: '${_filterEnd.year}-${_filterEnd.month.toString().padLeft(2, '0')}-${DateTime(_filterEnd.year, _filterEnd.month + 1, 0).day.toString().padLeft(2, '0')}',
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<KatalogBarangModel> _filtered(BarangProvider barang) {
    final list = barang.katalogBsi;
    if (_searchQuery.isEmpty) return list;
    return list
        .where((e) => e.namaBarang.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  void _openDetail(KatalogBarangModel item, String role) {
    final barang = context.read<BarangProvider>();
    final bankId = context.read<AuthProvider>().bankId ?? '';

    if (role == 'petugas_bsm') {
      barang.setDetailDirect(item);
    } else {
      barang.fetchDetailBarang(item.produkId, item, bankId);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.12),
        child: DetailBarangSheet(role: role, showRiwayat: true),
      ),
    );
  }

  Future<void> _refresh(BarangProvider barang) async {
    final auth = context.read<AuthProvider>();
    final bankId = auth.bankId ?? '';
    await barang.fetchKatalogBsi(bankId, page: 1);
    if (auth.role == 'petugas_bsi' || auth.role == 'petugas_bsu') {
      await barang.fetchListDistribusi(
        bankId,
        startDate: '${_filterStart.year}-${_filterStart.month.toString().padLeft(2, '0')}-01',
        endDate: '${_filterEnd.year}-${_filterEnd.month.toString().padLeft(2, '0')}-${DateTime(_filterEnd.year, _filterEnd.month + 1, 0).day.toString().padLeft(2, '0')}',
      );
    }
  }

  List<ListDistribusiBarangModel> _filteredDistribusi(BarangProvider barang) {
    return barang.listDistribusi.where((d) {
      final m = DateTime(d.createdAt.year, d.createdAt.month);
      final start = DateTime(_filterStart.year, _filterStart.month);
      final end = DateTime(_filterEnd.year, _filterEnd.month);
      return !m.isBefore(start) && !m.isAfter(end);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<BarangProvider, AuthProvider>(
      builder: (context, barang, auth, _) {
        final role = auth.role;
        final isPetugasBsi = role == 'petugas_bsi';
        final isPetugasBsu = role == 'petugas_bsu';
        final isPetugasBsm = role == 'petugas_bsm';
        final canViewDetail = isPetugasBsi || isPetugasBsu || isPetugasBsm;
        final filtered = _filtered(barang);

        return Scaffold(
          backgroundColor: AppColors.surfaceLeaf,
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
                const TopBarBack(title: 'Katalog Barang'),

                if (isPetugasBsi || isPetugasBsu) ...[
                  const SizedBox(height: 12),
                  MainNavbar(
                    selectedIndex: _tabIndex,
                    onTabChanged: (i) => setState(() {
                      _tabIndex = i;
                      _searchController.clear();
                      _searchQuery = '';
                    }),
                    tabs: const ['Katalog', 'Distribusi'],
                    backgroundColor: Colors.white.withValues(alpha: 0.6),
                    border: Border.all(
                      color: AppColors.dark.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],

                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.green,
                    onRefresh: () => _refresh(barang),
                    child: ListView(
                      padding: EdgeInsets.zero,
                      physics: const BouncingScrollPhysics(),
                      children: [
                        if (isPetugasBsi && _tabIndex == 1) ...[
                          const SizedBox(height: 10),
                          _buildDistribusiButton(context),
                          const SizedBox(height: 16),
                          _buildRiwayatDistribusiSection(barang, showNamaBsu: true),
                          const SizedBox(height: 30),
                        ],

                        if (isPetugasBsu && _tabIndex == 1) ...[
                          const SizedBox(height: 10),
                          _buildTerimaDistribusiButton(context),
                          const SizedBox(height: 16),
                          _buildRiwayatDistribusiSection(barang, showNamaBsu: false),
                          const SizedBox(height: 30),
                        ],

                        if ((!isPetugasBsi && !isPetugasBsu) || _tabIndex == 0) ...[

                          const SizedBox(height: 10),

                          _buildSearchBar(),
                          const SizedBox(height: 16),

                          Container(
                            width: double.infinity,
                            constraints: BoxConstraints(
                              minHeight: MediaQuery.of(context).size.height,
                            ),
                            decoration: const BoxDecoration(color: Colors.white),
                            padding: const EdgeInsets.only(top: 20, bottom: 40),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 24),
                                  child: Row(
                                    children: [
                                      Text(
                                        'Katalog Saya',
                                        style: AppText.w600(13, AppColors.darkAlt),
                                      ),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppColors.green.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          '${filtered.length} item',
                                          style: AppText.w600(10, AppColors.green),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),

                                if (barang.isLoading)
                                  const Padding(
                                    padding: EdgeInsets.only(top: 80),
                                    child: Center(
                                      child: CircularProgressIndicator(color: AppColors.green),
                                    ),
                                  )
                                else
                                  _buildGrid(filtered, canViewDetail, role),
                                if (!barang.isLoading && barang.katalogBsiTotalPages > 1)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 20, bottom: 8),
                                    child: Pagination(
                                      currentPage: barang.katalogBsiPage,
                                      totalPages: barang.katalogBsiTotalPages,
                                      onPageChanged: (p) => barang.fetchKatalogBsi(auth.bankId ?? '', page: p),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
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

  Widget _buildDistribusiButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          final barang = context.read<BarangProvider>();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const InputDistribusiBarangScreen(),
            ),
          ).then((_) {
            if (!mounted) return;
            _refresh(barang);
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color : AppColors.dark,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Icon(Icons.local_shipping_rounded, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Distribusikan Barang ke BSU',
                  style: AppText.w600(13, Colors.white),
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
              builder: (_) => const QrTerimaBarangScreen(),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color : AppColors.dark,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            children: [
              Icon(Icons.qr_code_rounded, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Terima Distribusi Barang',
                  style: AppText.w600(13, Colors.white),
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 14),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return CustomSearchBar(
      controller: _searchController,
      hintText: 'Cari barang...',
      onChanged: (v) => setState(() => _searchQuery = v),
      searchQuery: _searchQuery,
      onClear: () {
        _searchController.clear();
        setState(() => _searchQuery = '');
      },
      padding: const EdgeInsets.symmetric(horizontal: 24),
    );
  }

  Widget _buildGrid(List<KatalogBarangModel> items, bool canViewDetail, String role) {
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
        itemBuilder: (context, index) => _buildCard(items[index], canViewDetail, role),
      ),
    );
  }

  Widget _buildCard(KatalogBarangModel item, bool canViewDetail, String role) {
    final tappable = canViewDetail;

    return GestureDetector(
      onTap: tappable ? () => _openDetail(item, role) : null,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.darkAlt.withValues(alpha: 0.06),
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
                          color: AppColors.green,
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
                      item.namaBarang,
                      style: AppText.p(12, weight: FontWeight.w600, color: AppColors.darkAlt, height: 1.2, letterSpacing: -0.3),
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
    final label = AppNumber.denganSatuan(poin, 'poin');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.green.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.green.withValues(alpha: 0.2),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.stars_rounded, size: 9, color: AppColors.green),
          const SizedBox(width: 3),
          Text(
            label,
            style: AppText.w600(9, AppColors.green),
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
            ? AppColors.dark.withValues(alpha: 0.05)
            : Colors.orange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasStok
              ? AppColors.dark.withValues(alpha: 0.12)
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
            color: hasStok ? AppColors.dark : Colors.orange,
          ),
          const SizedBox(width: 3),
          Text(
            'Stok: ${stok.toInt()}',
            style: AppText.w600(9, hasStok ? AppColors.dark : Colors.orange),
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
            size: 36, color: AppColors.green.withValues(alpha: 0.5)),
      ),
    );
  }

  Widget _buildEmptyState() => const StateMessage(
        illustration: StateArt.empty,
        message: 'Tidak ada hasil',
      );

  Widget _buildRiwayatDistribusiSection(BarangProvider barang, {required bool showNamaBsu}) {
    final filtered = _filteredDistribusi(barang);
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height),
      decoration: const BoxDecoration(color: Colors.white),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 2),
                  child: Text(
                    'Riwayat Distribusi',
                    style: AppText.w600(14, AppColors.darkAlt),
                  ),
                ),
                const SizedBox(height: 10),
                MonthYearFilterRow(
                  filterStart: _filterStart,
                  filterEnd: _filterEnd,
                  onChanged: (start, end) {
                    setState(() {
                      _filterStart = start;
                      _filterEnd = end;
                    });
                    _refresh(barang);
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: barang.isListDistribusiLoading
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: CircularProgressIndicator(color: AppColors.green)),
                  )
                : _buildDistribusiList(filtered, showNamaBsu: showNamaBsu),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDistribusiList(List<ListDistribusiBarangModel> items, {required bool showNamaBsu}) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 36),
          child: Column(
            children: [
              Icon(Icons.history_toggle_off_rounded,
                  size: 44, color: Colors.grey[300]),
              const SizedBox(height: 10),
              Text(
                'Belum ada riwayat distribusi',
                style: AppText.r(13, Colors.grey[400]),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _buildDistribusiCard(items[i], showNamaBsu: showNamaBsu),
    );
  }

  Widget _buildDistribusiCard(ListDistribusiBarangModel d, {required bool showNamaBsu}) {
    final status = d.statusDistribusi.toLowerCase();
    final Color statusColor;
    final Color statusBg;
    final String statusLabel;

    switch (status) {
      case 'selesai':
      case 'diterima':
        statusColor = AppColors.green;
        statusBg = AppColors.mintPale;
        statusLabel = status == 'diterima' ? 'Diterima' : 'Selesai';
        break;
      case 'pending':
        statusColor = AppColors.warning;
        statusBg = const Color(0xFFFEF3C7);
        statusLabel = 'Menunggu';
        break;
      default:
        statusColor = Colors.grey.shade500;
        statusBg = Colors.grey.shade100;
        statusLabel = d.statusDistribusi;
    }

    final tanggal = '${AppDate.tanggalSingkatJam(d.createdAt)} WIB';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StrukDistribusiBarangScreen(disbaId: d.disbaId),
        ),
      ),
      child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          width: 1,
          color: AppColors.darkAlt.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: AppColors.darkAlt.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.local_shipping_rounded,
              color: AppColors.darkAlt,
              size: 18,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  showNamaBsu ? d.namaBsu : tanggal,
                  style: AppText.w600(13, AppColors.darkAlt),
                ),
                const SizedBox(height: 3),
                Text(
                  showNamaBsu ? tanggal : '${d.totalItem.toInt()} item',
                  style: AppText.r(11.5, Colors.grey[500]),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              statusLabel,
              style: AppText.w600(10.5, statusColor),
            ),
          ),
        ],
      ),
    ),
    );
  }

}
