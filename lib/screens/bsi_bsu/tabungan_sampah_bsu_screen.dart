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

class TabunganSampahBsuScreen extends StatefulWidget {
  const TabunganSampahBsuScreen({super.key});

  @override
  State<TabunganSampahBsuScreen> createState() =>
      _TabunganSampahBsuScreenState();
}

class _TabunganSampahBsuScreenState extends State<TabunganSampahBsuScreen> {

  List<PengangkutanGroup> _pengangkutan = [];
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
    final startMonth = now.month - 2;
    _filterStart = startMonth <= 0
        ? DateTime(now.year - 1, 12 + startMonth)
        : DateTime(now.year, startMonth);
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
  }

  Future<void> _fetch() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final bsuId = auth.bankId ?? '';

    final startDate = '${_filterStart.year}-${_filterStart.month.toString().padLeft(2, '0')}-01';
    final endDate = '${_filterEnd.year}-${_filterEnd.month.toString().padLeft(2, '0')}-${DateTime(_filterEnd.year, _filterEnd.month + 1, 0).day.toString().padLeft(2, '0')}';
    final prov = context.read<TabunganSampahProvider>();
    await prov.fetchBsu(bsuId, startDate: startDate, endDate: endDate);

    if (!mounted) return;
    if (prov.bsuStatus == FetchStatus.success) {
      setState(() {
        _pengangkutan = prov.bsu?.pengangkutan ?? [];
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = prov.bsuError ?? 'Gagal memuat data tabungan BSU';
        _isLoading = false;
      });
    }
  }

  List<PengangkutanGroup> get _filtered {
    final rangeStart = DateTime(_filterStart.year, _filterStart.month);
    final rangeEnd = DateTime(_filterEnd.year, _filterEnd.month + 1);

    return _pengangkutan
        .map((group) {
          final filteredItems = group.items.where((item) {
            final s = item.status.toLowerCase();
            if (_selectedTab == 0) {
              return s == 'cair' || s == 'cair sebagian';
            } else {
              return s == 'belum cair';
            }
          }).toList();
          return PengangkutanGroup(
            sourceId: group.sourceId,
            tanggalSetoran: group.tanggalSetoran,
            items: filteredItems,
          );
        })
        .where((group) {
          if (group.items.isEmpty) return false;
          if (_selectedTab == 1) return true;
          final t = group.tanggalSetoran;
          if (t == null) return true;
          return !t.isBefore(rangeStart) && t.isBefore(rangeEnd);
        })
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
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
              const TopBarBack(title: 'Buku Tabungan BSU'),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.green,
                  onRefresh: _fetch,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),
                        _buildSubtitle(),
                        const SizedBox(height: 14),
                        MainNavbar(
                          selectedIndex: _selectedTab,
                          onTabChanged: (i) => setState(() => _selectedTab = i),
                          tabs: const ['Cair', 'Belum Cair'],
                          backgroundColor: Colors.white.withValues(alpha: 0.6),
                          border: Border.all(
                            color: AppColors.dark.withValues(alpha: 0.1),
                            width: 1,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          constraints: BoxConstraints(
                            minHeight: MediaQuery.of(context).size.height,
                          ),
                          decoration: const BoxDecoration(color: Colors.white),
                          padding: const EdgeInsets.only(top: 10, bottom: 40),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                                child: Text(
                                  'Monitoring tabungan sampah',
                                  style: AppText.w600(14, AppColors.dark),
                                ),
                              ),
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
                                    _fetch();
                                  },
                                ),
                              ),
                              const SizedBox(height: 20),
                              if (_isLoading)
                                const Center(
                                  child: CircularProgressIndicator(color: AppColors.green),
                                )
                              else if (_error != null)
                                _buildError()
                              else if (filtered.isEmpty)
                                _buildEmpty()
                              else
                                _buildList(filtered),
                            ],
                          ),
                        ),
                      ],
                    ),
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
      padding: const EdgeInsets.fromLTRB(30, 12, 30, 0),
      child: Text(
        'Lihat status tabungan sampah BSU, mulai dari belum cair hingga sudah dicairkan melalui bagi hasil pengangkutan',
        style: AppText.r(12, AppColors.dark.withValues(alpha: 0.6)),
      ),
    );
  }

  Widget _buildList(List<PengangkutanGroup> list) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _buildGroupCard(list[i]),
    );
  }

  Widget _buildGroupCard(PengangkutanGroup group) {
    final tanggal = group.tanggalSetoran != null
        ? AppDate.tanggalSingkatJam(group.tanggalSetoran!)
        : 'Menunggu Selesai';

    final allCair = group.items.every((e) => e.status == 'Cair');
    final allBelum = group.items.every((e) => e.status == 'Belum Cair');
    final groupStatus =
        allCair ? 'Cair' : allBelum ? 'Belum Cair' : 'Cair Sebagian';

    final key = group.sourceId;
    final isExpanded = _expandedCards.contains(key);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
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
                  child: const Icon(Icons.local_shipping_rounded,
                      size: 18, color: AppColors.green),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pengangkutan $tanggal',
                        style: AppText.w600(13, AppColors.dark),
                      ),
                      Text(
                        '${group.items.length} item',
                        style: AppText.r(11, AppColors.dark.withValues(alpha: 0.55)),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(groupStatus),
              ],
            ),
          ),

          if (isExpanded) ...[
            const Divider(height: 1, thickness: 1, color: AppColors.divider),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: group.items.length,
              separatorBuilder: (_, __) => const Divider(
                height: 1,
                thickness: 1,
                indent: 16,
                endIndent: 16,
                color: AppColors.divider,
              ),
              itemBuilder: (_, i) => _buildItemRow(group.items[i]),
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

  Widget _buildItemRow(ItemTabunganBsu item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.namaSampah,
                  style: AppText.w600(12, AppColors.dark),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_fmtQty(item.qtySetoran)} ${item.satuan}'
                  '${item.sisaQty < item.qtySetoran ? '  •  Sisa ${_fmtQty(item.sisaQty)} ${item.satuan}' : ''}',
                  style: AppText.r(11, AppColors.dark.withValues(alpha: 0.55)),
                ),
                if (item.hargaItem != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${_fmtNilai(item.hargaItem!, item.namaReward)}'
                    ' / ${item.satuan}',
                    style: AppText.r(11, AppColors.dark.withValues(alpha: 0.55)),
                  ),
                ],
                if (item.namaReward.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.namaReward,
                    style: AppText.r(10, AppColors.green.withValues(alpha: 0.8)),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (item.nilaiTotal != null)
                Text(
                  _fmtNilai(item.nilaiTotal!, item.namaReward),
                  style: AppText.w700(12, AppColors.dark),
                ),
              const SizedBox(height: 4),
              _buildStatusBadge(item.status, small: true),
            ],
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

  Widget _buildEmpty() => const StateMessage(
        illustration: StateArt.emptyMoney,
        message: 'Belum ada tabungan sampah',
        subtitle: 'Data tabungan akan muncul setelah '
            'pengangkutan sampah berhasil dilakukan.',
      );

  Widget _buildError() => StateMessage(
        illustration: StateArt.error,
        message: _error!,
        action: StateRetryButton.icon(onPressed: _fetch),
      );

  String _fmtQty(double v) => AppNumber.desimal(v);

  String _fmtNilai(double v, String namaReward) => AppNumber.nominalSatuan(
      v, 'poin',
      isUang: namaReward.toLowerCase() != 'barang');
}
