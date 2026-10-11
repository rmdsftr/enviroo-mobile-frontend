import 'package:enviroo/core/format/app_date.dart';
import 'package:enviroo/core/format/app_number.dart';
import 'package:enviroo/models/tabungan_sampah_model.dart';
import 'package:enviroo/providers/auth_provider.dart';
import 'package:enviroo/providers/penjualan_provider.dart' show FetchStatus;
import 'package:enviroo/providers/tabungan_sampah_provider.dart';
import 'package:enviroo/widgets/filter_month_year.dart';
import 'package:enviroo/widgets/navbar.dart';
import 'package:enviroo/widgets/topbar_back.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:enviroo/core/theme/app_colors.dart';
import 'package:enviroo/core/theme/app_text.dart';
import 'package:enviroo/widgets/state_message.dart';

class TabunganSampahScreen extends StatefulWidget {
  const TabunganSampahScreen({super.key});

  @override
  State<TabunganSampahScreen> createState() => _TabunganSampahScreenState();
}

class _TabunganSampahScreenState extends State<TabunganSampahScreen> {

  List<SampahTabungan> _sampah = [];
  bool _isLoading = true;
  String? _error;
  int _selectedTab = 0;
  final Set<String> _expandedCards = {};

  late DateTime _filterStart;
  late DateTime _filterEnd;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _filterEnd = DateTime(now.year, now.month);
    _filterStart = DateTime(now.year, now.month - 2);
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
  }

  Future<void> _fetch() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final nasabahId = auth.identityId ?? '';


    final prov = context.read<TabunganSampahProvider>();
    await prov.fetchNasabah(
      nasabahId,
      startDate: AppDate.apiAwalBulan(_filterStart),
      endDate: AppDate.apiAkhirBulan(_filterEnd),
    );

    if (!mounted) return;
    if (prov.nasabahStatus == FetchStatus.success) {
      setState(() {
        _sampah = prov.nasabah?.sampah ?? [];
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = prov.nasabahError ?? 'Gagal memuat data tabungan';
        _isLoading = false;
      });
    }
  }

  List<SampahTabungan> get _filteredSampah {
    return _sampah
        .map((g) {
          final baris = g.tabungan.where((t) {
            if (_selectedTab == 0) {
              return t.status == 'Cair' || t.status == 'Cair Sebagian';
            }
            return t.status == 'Belum Cair';
          }).toList();
          return SampahTabungan(
            sampahId: g.sampahId,
            namaSampah: g.namaSampah,
            satuanSampah: g.satuanSampah,
            satuanDiterima: g.satuanDiterima,
            tabungan: baris,
          );
        })
        .where((g) => g.tabungan.isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredSampah;

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
              const TopBarBack(title: 'Buku Tabungan Sampah'),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.green,
                  onRefresh: _fetch,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 12),
                            _buildSubtitle(),
                            const SizedBox(height: 14),
                            MainNavbar(
                              selectedIndex: _selectedTab,
                              onTabChanged: (i) =>
                                  setState(() => _selectedTab = i),
                              tabs: const ['Cair', 'Belum Cair'],
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.6),
                              border: Border.all(
                                color: AppColors.dark
                                    .withValues(alpha: 0.1),
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
                                  padding: const EdgeInsets.fromLTRB(
                                      20, 10, 20, 10),
                                  child: Text(
                                    'Monitoring tabungan sampah',
                                    style: AppText.w600(14, AppColors.dark),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20),
                                  child: MonthYearFilterRow(
                                    filterStart: _filterStart,
                                    filterEnd: _filterEnd,
                                    onChanged: (start, end) {
                                      setState(() {
                                        _filterStart = start;
                                        _filterEnd = end;
                                      });
                                      _fetch();
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
                                      child: CircularProgressIndicator(
                                          color: AppColors.green),
                                    ),
                                  )
                                : _error != null
                                    ? _buildError()
                                    : filtered.isEmpty
                                        ? _buildEmpty()
                                        : _buildList(filtered),
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

  Widget _buildSubtitle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Text(
        'Lihat status hasil tabungan sampahmu, mulai dari belum cair hingga sudah dicairkan',
        style: AppText.p(12, color: AppColors.dark.withValues(alpha: 0.6), height: 1.5),
      ),
    );
  }

  Widget _buildList(List<SampahTabungan> list) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _buildSampahCard(list[i]),
    );
  }

  Widget _buildSampahCard(SampahTabungan g) {
    final semuaCair = g.tabungan.every((t) => t.status == 'Cair');
    final semuaBelum = g.tabungan.every((t) => t.status == 'Belum Cair');
    final statusGrup = semuaCair
        ? 'Cair'
        : semuaBelum
            ? 'Belum Cair'
            : 'Cair Sebagian';

    final key = g.sampahId;
    final isExpanded = _expandedCards.contains(key);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          width: 1,
          color: AppColors.dark.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.green.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.recycling_rounded,
                      size: 18, color: AppColors.green),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        g.namaSampah,
                        style: AppText.w600(13, AppColors.dark),
                      ),
                      Text(
                        '${g.sampahId}  \u2022  ${g.tabungan.length} tabungan',
                        style: AppText.r(10.5, AppColors.dark.withValues(alpha: 0.55)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _buildStatusBadge(statusGrup),
              ],
            ),
          ),

          if (isExpanded) ...[
            const Divider(height: 1, thickness: 1, color: AppColors.divider),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: g.tabungan.length,
              separatorBuilder: (_, __) => const Divider(
                  height: 1,
                  thickness: 1,
                  indent: 16,
                  endIndent: 16,
                  color: AppColors.divider),
              itemBuilder: (_, i) => _buildBarisTabungan(g, g.tabungan[i]),
            ),
          ],

          const Divider(height: 1, thickness: 1, color: AppColors.divider),
          GestureDetector(
            onTap: () => setState(() {
              if (isExpanded) {
                _expandedCards.remove(key);
              } else {
                _expandedCards.add(key);
              }
            }),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isExpanded ? 'Tutup' : 'Lihat detail',
                    style: AppText.w600(12, AppColors.green),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: AppColors.green,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarisTabungan(SampahTabungan g, BarisTabungan t) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  t.createdAt != null ? AppDate.tanggalSingkatJam(t.createdAt!) : '-',
                  style: AppText.w600(12, AppColors.dark),
                ),
              ),
              const SizedBox(width: 8),
              _buildStatusBadge(t.status, small: true),
            ],
          ),
          const SizedBox(height: 8),
          _baris('ID tabungan', t.tabunganId),
          _baris('Dari setoran', t.sourceId),
          _baris('Disetor', '${_fmtQty(t.qty)} ${g.satuanSampah}'),
          _baris('Sisa', '${_fmtQty(t.sisaQty)} ${g.satuanSampah}'),

          if (t.detailPencairan.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              t.detailPencairan.length > 1
                  ? 'Pencairan (${t.detailPencairan.length}x)'
                  : 'Pencairan',
              style: AppText.w600(11, AppColors.dark.withValues(alpha: 0.65)),
            ),
            const SizedBox(height: 6),
            ...t.detailPencairan.map((d) => _buildPencairan(g, d)),
          ],
        ],
      ),
    );
  }

  Widget _buildPencairan(SampahTabungan g, DetailPencairan d) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.green.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.green.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  d.tanggalCair != null
                      ? AppDate.tanggalSingkatJam(d.tanggalCair!)
                      : '-',
                  style: AppText.r(10.5, AppColors.dark.withValues(alpha: 0.55)),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _fmtNilai(d.subtotal, g.satuanDiterima),
                style: AppText.w700(12, AppColors.green),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '${_fmtQty(d.qtyDipakai)} ${g.satuanSampah}'
            '  \u00d7  ${_fmtNilai(d.hargaItem, g.satuanDiterima)} / ${g.satuanSampah}',
            style: AppText.r(11, AppColors.dark.withValues(alpha: 0.7)),
          ),
        ],
      ),
    );
  }

  Widget _baris(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: AppText.r(11, AppColors.dark.withValues(alpha: 0.5)),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppText.w500(11, AppColors.dark.withValues(alpha: 0.85)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status, {bool small = false}) {
    Color bg;
    Color fg;
    switch (status) {
      case 'Cair':
        bg = const Color(0xFFE6F7EE);
        fg = const Color(0xFF27AE60);
        break;
      case 'Cair Sebagian':
        bg = const Color(0xFFFFF3E0);
        fg = const Color(0xFFF2994A);
        break;
      default:
        bg = const Color(0xFFFFEBEE);
        fg = const Color(0xFFEB5757);
    }
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 8 : 10,
        vertical: small ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: AppText.w600(small ? 10 : 11, fg),
      ),
    );
  }

  Widget _buildEmpty() => StateMessage(
        illustration: StateArt.emptyMoney,
        message: 'Belum ada tabungan sampah',
        subtitle: 'Data tabungan akan muncul kalau kamu udah pernah menyetor sampah ya',
      );

  Widget _buildError() => StateMessage(
        illustration: StateArt.error,
        message: _error!,
        action: StateRetryButton.pill(onPressed: _fetch),
      );

  String _fmtQty(double v) => AppNumber.desimal(v);

  String _fmtNilai(double v, String satuanDiterima) =>
      AppNumber.nominalSatuan(v, satuanDiterima);
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
