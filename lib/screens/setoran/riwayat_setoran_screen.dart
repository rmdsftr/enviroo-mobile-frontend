import 'package:enviroo/core/format/app_date.dart';
import 'package:enviroo/models/setoran_nasabah_model.dart';
import 'package:enviroo/providers/auth_provider.dart';
import 'package:enviroo/providers/setoran_provider.dart';
import 'package:enviroo/providers/penjualan_provider.dart' show FetchStatus;
import 'package:enviroo/screens/setoran/detail_setoran_screen.dart';
import 'package:enviroo/screens/setoran/setoran_screen.dart';
import 'package:enviroo/providers/penimbangan_provider.dart';
import 'package:enviroo/widgets/filter_month_year.dart';
import 'package:enviroo/widgets/topbar_back.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:enviroo/core/theme/app_colors.dart';
import 'package:enviroo/core/theme/app_text.dart';
import 'package:enviroo/widgets/state_message.dart';

class RiwayatSetoranScreen extends StatefulWidget {
  const RiwayatSetoranScreen({super.key});

  @override
  State<RiwayatSetoranScreen> createState() => _RiwayatSetoranScreenState();
}

class _RiwayatSetoranScreenState extends State<RiwayatSetoranScreen> {

  List<RiwayatSetoranModel> _list = [];
  bool _isLoading = true;
  String? _error;
  bool _isSessionActive = false;
  String _penimbanganId = '';
  int _pendingSessions = 0;

  final _searchController = TextEditingController();
  String _searchQuery = '';

  DateTime _filterStart = DateTime(
      DateTime.now().month - 2 <= 0 ? DateTime.now().year - 1 : DateTime.now().year,
      DateTime.now().month - 2 <= 0 ? DateTime.now().month + 10 : DateTime.now().month - 2);
  DateTime _filterEnd = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    int startMonth = now.month - 2;
    int startYear = now.year;
    if (startMonth <= 0) {
      startMonth += 12;
      startYear--;
    }
    _filterStart = DateTime(startYear, startMonth);
    _filterEnd = DateTime(now.year, now.month);

    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchAll());
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchAll() async {
    await Future.wait([
      _fetchRiwayat(),
      _checkActiveSession(),
    ]);
  }

  Future<void> _checkActiveSession() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final bankId = auth.bankId ?? '';
    if (bankId.isEmpty) return;

    try {
      final prov = context.read<PenimbanganProvider>();
      await prov.fetchSesiAktif(bankId);
      if (!mounted) return;
      final sesi = prov.sesiAktif;
      if (sesi != null) {
        setState(() {
          _isSessionActive = sesi.isActive;
          _penimbanganId = sesi.detail?.penimbanganId ?? '';
          _pendingSessions = sesi.pendingSessions;
        });
      } else {
        setState(() {
          _isSessionActive = false;
          _penimbanganId = '';
          _pendingSessions = 0;
        });
      }
    } catch (_) {
      setState(() {
        _isSessionActive = false;
        _penimbanganId = '';
        _pendingSessions = 0;
      });
    }
  }

  Future<void> _fetchRiwayat() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final nasabahId = auth.identityId ?? '';

    final prov = context.read<SetoranProvider>();
    await prov.fetchRiwayat(
      nasabahId,
      startDate: AppDate.apiAwalBulan(_filterStart),
      endDate: AppDate.apiAkhirBulan(_filterEnd),
    );
    if (!mounted) return;
    if (prov.riwayatStatus == FetchStatus.success) {
      setState(() {
        _list = prov.riwayat;
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = prov.riwayatError ?? 'Gagal memuat riwayat setoran';
        _isLoading = false;
      });
    }
  }

  List<RiwayatSetoranModel> get _filteredList {
    return _list.where((item) {
      if (_searchQuery.isNotEmpty) {
        final namaMatch =
            item.namaPetugas.toLowerCase().contains(_searchQuery);
        final tanggalMatch = AppDate.tanggalSingkat(item.transaksiTimestamp)
            .toLowerCase()
            .contains(_searchQuery);
        if (!namaMatch && !tanggalMatch) return false;
      }
      return true;
    }).toList();
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
            TopBarBack(title: 'Setoran Sampah'),
            Expanded(
              child: _isLoading
                  ? _buildShimmer()
                  : _error != null
                      ? _buildError()
                      : RefreshIndicator(
                          color: AppColors.green,
                          onRefresh: _fetchAll,
                          child: CustomScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            slivers: [
                              SliverToBoxAdapter(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildQRButton(),
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                                      child: _buildSummaryStats(),
                                    ),
                                  ],
                                ),
                              ),
                              SliverPersistentHeader(
                                pinned: true,
                                delegate: _StickyHeaderDelegate(
                                  height: 116,
                                  child: Container(
                                    color: Colors.white,
                                    padding: const EdgeInsets.only(top: 5),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildSectionHeader(),
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(20, 5, 20, 15),
                                          child: MonthYearFilterRow(
                                            filterStart: _filterStart,
                                            filterEnd: _filterEnd,
                                            onChanged: (start, end) {
                                              setState(() {
                                                _filterStart = start;
                                                _filterEnd = end;
                                              });
                                              _fetchRiwayat();
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
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 8),
                                        if (_filteredList.isEmpty)
                                          _buildEmpty()
                                        else
                                          ListView.builder(
                                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                                            shrinkWrap: true,
                                            physics: const NeverScrollableScrollPhysics(),
                                            itemCount: _filteredList.length,
                                            itemBuilder: (ctx, i) => _buildCard(_filteredList[i]),
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
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildQRButton() {
    if (!_isSessionActive) return _infoCard();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => SetoranScreen(penimbanganId: _penimbanganId)),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            color : AppColors.dark,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.neon.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.qr_code_rounded, color: AppColors.neon, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'QR Code Penyetoran',
                      style: AppText.w700(14, Colors.white),
                    ),
                    Text(
                      'Tunjukkan ke petugas Bank Sampah saat menyetor',
                      style: AppText.r(11, Colors.white.withValues(alpha: 0.65)),
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


  Widget _buildSectionHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 20, 8),
      child: Row(
        children: [
          Text(
            'Riwayat Setoran',
            style: AppText.w600(14, AppColors.dark),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(RiwayatSetoranModel item) {
    const statusIcon = Icons.move_to_inbox_rounded;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                DetailSetoranScreen(setoranId: item.setoranId),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
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
                  color: AppColors.dark.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                    statusIcon,
                    color: AppColors.dark,
                    size: 22
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppDate.tanggalSingkatJam(item.transaksiTimestamp),
                      style: AppText.w600(13, AppColors.dark),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.setoranId,
                      style: AppText.r(10, AppColors.dark.withValues(alpha: 0.4)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.green.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${item.totalItem} item',
                  style: AppText.w600(10, AppColors.green),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        children: [
          _shimmerBox(height: 68, radius: 20),
          const SizedBox(height: 10),
          _shimmerBox(height: 64, radius: 18),
          const SizedBox(height: 10),
          _shimmerBox(height: 46, radius: 50),
          const SizedBox(height: 10),
          _shimmerBox(height: 34, radius: 50),
          const SizedBox(height: 16),
          ...List.generate(
            4,
            (_) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _shimmerBox(height: 88, radius: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _shimmerBox({required double height, required double radius}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.4, end: 1.0),
      duration: const Duration(milliseconds: 900),
      builder: (_, value, __) => Opacity(
        opacity: value,
        child: Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.dark.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    final searching = _searchQuery.isNotEmpty;
    return StateMessage(
      illustration: StateArt.empty,
      message: searching ? 'Tidak ada data yang cocok' : 'Belum ada riwayat setoran',
      subtitle: searching
          ? 'Coba ubah kata kunci pencarian'
          : 'Riwayat setoran sampah kamu akan tampil kalau udah pernah nyetor sampah ya',
    );
  }

  Widget _buildError() => StateMessage(
        illustration: StateArt.error,
        message: _error ?? 'Terjadi kesalahan',
        action: StateRetryButton(onPressed: _fetchAll),
      );

  Widget _buildSummaryStats() {
    final totalSetoran = _list.length;

    final sesiPenimbangan = _list
        .map((s) => s.penimbanganId)
        .where((id) => id.isNotEmpty)
        .toSet()
        .length;

    return Row(
      children: [
        Expanded(child: _statCard(
          iconColor: AppColors.dark,
          label: 'Total Setoran',
          value: totalSetoran.toString(),
        )),
        const SizedBox(width: 10),
        Expanded(child: _statCard(
          iconColor: AppColors.green,
          label: 'Sesi Penimbangan',
          value: sesiPenimbangan.toString(),
        )),
      ],
    );
  }

  Widget _infoCard(){
    final message = _pendingSessions > 0
        ? 'Hari ini terdapat $_pendingSessions sesi penimbangan. Penyetoran sampah baru bisa dilakukan jika petugas sudah membuka sesi penimbangan ya'
        : 'Fitur untuk melakukan penyetoran baru akan muncul jika sesi penimbangan sudah dibuka petugas';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
          decoration: BoxDecoration(
            color: AppColors.dark.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: AppColors.dark.withValues(alpha: 0.08),
              width: 1,
            )
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info, size: 16, color: AppColors.dark.withValues(alpha: 0.5)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: AppText.w500(11, AppColors.dark.withValues(alpha: 0.6)),
                ),
              ),
            ],
          )
      )
    );
  }

  Widget _statCard({
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.dark.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: AppText.p(20, weight: FontWeight.w700, color: iconColor, height: 1.1),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppText.r(10, AppColors.dark.withValues(alpha: 0.5)),
            textAlign: TextAlign.center,
          ),
        ],
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
