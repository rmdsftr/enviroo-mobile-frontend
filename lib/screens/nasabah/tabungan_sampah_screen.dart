import 'package:enviroo/models/tabungan_sampah_model.dart';
import 'package:enviroo/providers/auth_provider.dart';
import 'package:enviroo/services/tabungan_sampah_service.dart';
import 'package:enviroo/widgets/filter_month_year.dart';
import 'package:enviroo/widgets/navbar.dart';
import 'package:enviroo/widgets/topbar_back.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class TabunganSampahScreen extends StatefulWidget {
  const TabunganSampahScreen({super.key});

  @override
  State<TabunganSampahScreen> createState() => _TabunganSampahScreenState();
}

class _TabunganSampahScreenState extends State<TabunganSampahScreen> {
  static const _teal = Color(0xFF013236);
  static const _accent = Color(0xFF4EA771);

  List<SetoranGroup> _setoran = [];
  bool _isLoading = true;
  String? _error;
  int _selectedTab = 0; // 0 = Cair, 1 = Belum Cair
  final Set<String> _expandedCards = {};

  late DateTime _filterStart;
  late DateTime _filterEnd;

  final _rupiahFmt =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  final _dateFmt = DateFormat('dd MMM yyyy', 'id_ID');

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

    final fmt = DateFormat('yyyy-MM-dd');
    final start = DateTime(_filterStart.year, _filterStart.month, 1);
    final end = DateTime(_filterEnd.year, _filterEnd.month + 1, 0);

    final result = await TabunganSampahService.getBukuTabungan(
      nasabahId,
      startDate: fmt.format(start),
      endDate: fmt.format(end),
    );

    if (!mounted) return;
    if (result['success'] == true) {
      final response = result['data'] as BukuTabunganResponse;
      setState(() {
        _setoran = response.setoran;
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = result['message'] ?? 'Gagal memuat data tabungan';
        _isLoading = false;
      });
    }
  }

  List<SetoranGroup> get _filteredSetoran {
    return _setoran
        .map((group) {
          final filteredItems = group.items.where((item) {
            if (_selectedTab == 0) {
              return item.status == 'Cair' || item.status == 'Cair Sebagian';
            } else {
              return item.status == 'Belum Cair';
            }
          }).toList();
          return SetoranGroup(
            sourceId: group.sourceId,
            tanggalSetoran: group.tanggalSetoran,
            items: filteredItems,
          );
        })
        .where((group) => group.items.isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredSetoran;

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
          child: Column(
            children: [
              const TopBarBack(title: 'Buku Tabungan Sampah'),
              Expanded(
                child: RefreshIndicator(
                  color: _accent,
                  onRefresh: _fetch,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      // Subtitle + tab navbar — scroll away normally
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
                                color: const Color(0xFF013236)
                                    .withValues(alpha: 0.1),
                                width: 1,
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                      // Sticky: "Monitoring tabungan sampah" + filter bulan
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
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: _teal,
                                    ),
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
                      // List / Empty — cuma ini yang scroll di bawah sticky header
                      SliverToBoxAdapter(
                        child: Container(
                          width: double.infinity,
                          constraints: BoxConstraints(
                            minHeight: MediaQuery.of(context).size.height,
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
                                        color: _accent),
                                  ),
                                )
                              : _error != null
                                  ? _buildError()
                                  : filtered.isEmpty
                                      ? _buildEmpty()
                                      : _buildList(filtered),
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
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          color: _teal.withValues(alpha: 0.6),
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildList(List<SetoranGroup> list) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _buildSetoranCard(list[i]),
    );
  }

  Widget _buildSetoranCard(SetoranGroup group) {
    final tanggal = group.tanggalSetoran != null
        ? _dateFmt.format(group.tanggalSetoran!)
        : '-';

    final allCair = group.items.every((e) => e.status == 'Cair');
    final allBelum = group.items.every((e) => e.status == 'Belum Cair');
    final groupStatus =
        allCair ? 'Cair' : allBelum ? 'Belum Cair' : 'Cair Sebagian';

    final key = group.sourceId;
    final isExpanded = _expandedCards.contains(key);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          width: 1,
          color: _teal.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.savings_rounded,
                      size: 18, color: _accent),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Setoran $tanggal',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _teal,
                        ),
                      ),
                      Text(
                        '${group.items.length} item',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: _teal.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(groupStatus),
              ],
            ),
          ),

          // ── Expanded items ───────────────────────────────────────────────────
          if (isExpanded) ...[
            const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),
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
                  color: Color(0xFFF0F0F0)),
              itemBuilder: (_, i) => _buildItemRow(group.items[i]),
            ),
          ],

          // ── Toggle button ────────────────────────────────────────────────────
          const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),
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
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _accent,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: _accent,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(ItemTabungan item) {
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
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _teal,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_fmtQty(item.qtySetoran)} ${item.satuan}'
                  '${item.sisaQty < item.qtySetoran ? '  •  Sisa ${_fmtQty(item.sisaQty)} ${item.satuan}' : ''}',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: _teal.withValues(alpha: 0.55),
                  ),
                ),
                if (item.hargaItem != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.namaReward.toLowerCase() == 'barang'
                        ? '${_fmtQty(item.hargaItem!)} poin / ${item.satuan}'
                        : '${_rupiahFmt.format(item.hargaItem!)} / ${item.satuan}',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: _teal.withValues(alpha: 0.55),
                    ),
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
                  item.namaReward.toLowerCase() == 'barang'
                      ? '${_fmtQty(item.nilaiTotal!)} poin'
                      : _rupiahFmt.format(item.nilaiTotal!),
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _teal,
                  ),
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
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: small ? 10 : 11,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.savings_outlined,
                size: 64, color: _teal.withValues(alpha: 0.2)),
            const SizedBox(height: 16),
            Text(
              'Belum ada tabungan sampah',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _teal.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Data tabungan akan muncul setelah\nAnda melakukan setoran sampah.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: _teal.withValues(alpha: 0.35),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded,
                size: 56, color: _teal.withValues(alpha: 0.25)),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: _teal.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _fetch,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                decoration: BoxDecoration(
                  color: _accent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Coba Lagi',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmtQty(double v) =>
      v == v.truncateToDouble() ? v.toInt().toString() : v.toString();
}

// ── Sticky header delegate ───────────────────────────────────────────────────
// Bikin "Monitoring tabungan sampah" + filter bulan nempel (pinned) di bawah
// TopBarBack saat di-scroll, sementara cuma ListView card yang ikut bergerak.
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
