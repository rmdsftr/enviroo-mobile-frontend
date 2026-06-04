import 'package:enviroo/providers/auth_provider.dart';
import 'package:enviroo/services/setoran_service.dart';
import 'package:enviroo/screens/nasabah/detail_setoran_screen.dart';
import 'package:enviroo/screens/setoran_screen.dart';
import 'package:enviroo/services/penimbangan_service.dart';
import 'package:enviroo/widgets/filter_chip_row.dart';
import 'package:enviroo/widgets/filter_month_year.dart';
import 'package:enviroo/widgets/topbar_back.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

// ── Model ────────────────────────────────────────────────────────────────────
class RiwayatSetoranModel {
  final String setoranId;
  final String namaPetugas;
  final DateTime transaksiTimestamp;
  final int totalItem;
  final String statusSetoran;

  RiwayatSetoranModel({
    required this.setoranId,
    required this.namaPetugas,
    required this.transaksiTimestamp,
    required this.totalItem,
    required this.statusSetoran,
  });

  factory RiwayatSetoranModel.fromJson(Map<String, dynamic> json) {
    return RiwayatSetoranModel(
      setoranId: json['setoran_id'] ?? '',
      namaPetugas: json['nama_petugas'] ?? 'Petugas',
      transaksiTimestamp:
          DateTime.tryParse(json['transaksi_timestamp'] ?? '') ?? DateTime.now(),
      totalItem: json['total_item'] ?? 0,
      statusSetoran: json['status_setoran'] ?? '',
    );
  }
}

// ── Screen ───────────────────────────────────────────────────────────────────
class RiwayatSetoranScreen extends StatefulWidget {
  const RiwayatSetoranScreen({super.key});

  @override
  State<RiwayatSetoranScreen> createState() => _RiwayatSetoranScreenState();
}

class _RiwayatSetoranScreenState extends State<RiwayatSetoranScreen> {
  static const _teal = Color(0xFF013236);
  static const _accent = Color(0xFF4EA771);
  static const _lime = Color(0xFF94DF0C);

  // ── Data State ──────────────────────────────────────────────────────────────
  List<RiwayatSetoranModel> _list = [];
  bool _isLoading = true;
  String? _error;
  bool _isSessionActive = false;

  // ── Filter & Search State ───────────────────────────────────────────────────
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterStatus = 'semua';

  DateTime _filterStart = DateTime(
      DateTime.now().month - 2 <= 0 ? DateTime.now().year - 1 : DateTime.now().year,
      DateTime.now().month - 2 <= 0 ? DateTime.now().month + 10 : DateTime.now().month - 2);
  DateTime _filterEnd = DateTime(DateTime.now().year, DateTime.now().month);

  static const _filterItems = [
    FilterChipItem(value: 'semua', label: 'Semua'),
    FilterChipItem(value: 'berhasil', label: 'Berhasil'),
    FilterChipItem(value: 'lainnya', label: 'Lainnya'),
  ];

  @override
  void initState() {
    super.initState();
    // Default filter: 3 bulan terakhir
    final now = DateTime.now();
    int startMonth = now.month - 2;
    int startYear = now.year;
    if (startMonth <= 0) {
      startMonth += 12;
      startYear--;
    }
    _filterStart = DateTime(startYear, startMonth);
    _filterEnd = DateTime(now.year, now.month);

    _fetchAll();
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
    final bankId = auth.nasabahProfile?.bankId ?? '';
    if (bankId.isEmpty) return;

    try {
      final res = await PenimbanganService.checkActiveSession(bankId);
      if (res['success'] == true) {
        setState(() {
          _isSessionActive = res['is_active'] == true;
        });
      } else {
        setState(() {
          _isSessionActive = false;
        });
      }
    } catch (_) {
      setState(() {
        _isSessionActive = false;
      });
    }
  }

  // ── Fetch Riwayat ────────────────────────────────────────────────────────────
  Future<void> _fetchRiwayat() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final nasabahId = auth.identityId ?? '';

    final res = await SetoranService.getListSetoranNasabah(nasabahId);
    if (!mounted) return;
    if (res['success'] == true) {
      final List data = (res['data'] as List?) ?? [];
      setState(() {
        _list = data.map((e) => RiwayatSetoranModel.fromJson(e)).toList();
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = res['message'] ?? 'Gagal memuat riwayat setoran';
        _isLoading = false;
      });
    }
  }

  // ── Filtered List ────────────────────────────────────────────────────────────
  List<RiwayatSetoranModel> get _filteredList {
    return _list.where((item) {
      // Filter tanggal
      final d = DateTime(item.transaksiTimestamp.year, item.transaksiTimestamp.month);
      final start = DateTime(_filterStart.year, _filterStart.month);
      final end = DateTime(_filterEnd.year, _filterEnd.month);
      if (d.isBefore(start) || d.isAfter(end)) return false;

      if (_filterStatus == 'berhasil' && item.statusSetoran != 'berhasil') {
        return false;
      }
      if (_filterStatus == 'lainnya' && item.statusSetoran == 'berhasil') {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final namaMatch =
            item.namaPetugas.toLowerCase().contains(_searchQuery);
        final tanggalMatch = DateFormat('dd MMM yyyy', 'id_ID')
            .format(item.transaksiTimestamp)
            .toLowerCase()
            .contains(_searchQuery);
        if (!namaMatch && !tanggalMatch) return false;
      }
      return true;
    }).toList();
  }

  // ── Build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bg_struk.webp'),
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
                          color: _accent,
                          onRefresh: _fetchAll,
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // QR button (padding bawah lebih kecil jika tidak ada sesi)
                                _buildQRButton(),
                                // Summary stats dengan padding atas jika QR tidak muncul
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                                  child: _buildSummaryStats(),
                                ),
                                // White container untuk riwayat
                                Container(
                                  width: double.infinity,
                                  constraints: BoxConstraints(
                                    minHeight: MediaQuery.of(context).size.height,
                                  ),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildSectionHeader(),
                                      // Filter bulan
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(20, 5, 20, 15),
                                        child: MonthYearFilterRow(
                                          filterStart: _filterStart,
                                          filterEnd: _filterEnd,
                                          onChanged: (start, end) => setState(() {
                                            _filterStart = start;
                                            _filterEnd = end;
                                          }),
                                        ),
                                      ),

                                      _buildFilterChips(),
                                      const SizedBox(height: 8),
                                      // List / Empty
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

  // ── QR Button ─────────────────────────────────────────────────────────────────
  Widget _buildQRButton() {
    if (!_isSessionActive) return _infoCard();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => SetoranScreen()),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            color : Color(0xFF013236),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _lime.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.qr_code_rounded, color: _lime, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'QR Code Penyetoran',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Tunjukkan ke petugas Bank Sampah saat menyetor',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.65),
                      ),
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


  // ── Filter Chips ──────────────────────────────────────────────────────────────
  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: FilterChipRow<String>(
        items: _filterItems,
        selectedValue: _filterStatus,
        onSelected: (val) => setState(() => _filterStatus = val),
        padding: const EdgeInsets.symmetric(horizontal: 20),
      ),
    );
  }

  // ── Section Header ────────────────────────────────────────────────────────────
  Widget _buildSectionHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 10, 20, 8),
      child: Row(
        children: [
          const Text(
            'Riwayat Setoran',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: _teal,
            ),
          ),
        ],
      ),
    );
  }

  // ── Card ──────────────────────────────────────────────────────────────────────
  Widget _buildCard(RiwayatSetoranModel item) {
    final bool isSuccess = item.statusSetoran == 'berhasil';
    final statusColor = isSuccess ? _accent : Colors.orange;
    final statusIcon =
        isSuccess ? Icons.check_circle_rounded : Icons.schedule_rounded;

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
            color: Colors.white.withOpacity(0.5),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              width: 1,
              color: const Color(0xFF013236).withOpacity(0.1), // Brand color dengan opacity cuma 10%
            ),
          ),
          child: Row(
            children: [
              // Status icon
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(statusIcon, color: statusColor, size: 22),
              ),
              const SizedBox(width: 14),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('dd MMM yyyy, HH:mm', 'id_ID')
                          .format(item.transaksiTimestamp),
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: _teal,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.setoranId,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        color: _teal.withOpacity(0.4),
                      ),
                    ),
                  ],
                ),
              ),
              // Item count badge (menggantikan arrow)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${item.totalItem} item',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _accent,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Shimmer Loading ───────────────────────────────────────────────────────────
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
            color: _teal.withOpacity(0.07),
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
      ),
    );
  }

  // ── Empty ─────────────────────────────────────────────────────────────────────
  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _accent.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.inbox_rounded,
                  size: 36, color: _teal.withOpacity(0.35)),
            ),
            const SizedBox(height: 14),
            Text(
              _searchQuery.isNotEmpty || _filterStatus != 'semua'
                  ? 'Tidak ada data yang cocok'
                  : 'Belum ada setoran',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: _teal.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _searchQuery.isNotEmpty || _filterStatus != 'semua'
                  ? 'Coba ubah kata kunci atau filter'
                  : 'Riwayat setoran sampah kamu akan muncul di sini',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                color: _teal.withOpacity(0.35),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Error ─────────────────────────────────────────────────────────────────────
  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded,
                size: 40, color: Colors.red.withOpacity(0.5)),
            const SizedBox(height: 12),
            Text(
              _error ?? 'Terjadi kesalahan',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: _teal.withOpacity(0.5)),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchAll,
              style: ElevatedButton.styleFrom(
                backgroundColor: _teal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Coba Lagi',
                  style: TextStyle(fontFamily: 'Poppins')),
            ),
          ],
        ),
      ),
    );
  }

  // ── Summary Stats ─────────────────────────────────────────────────────────────
  Widget _buildSummaryStats() {
    // Filter by date first
    final listByDate = _list.where((item) {
      final d = DateTime(item.transaksiTimestamp.year, item.transaksiTimestamp.month);
      final start = DateTime(_filterStart.year, _filterStart.month);
      final end = DateTime(_filterEnd.year, _filterEnd.month);
      return !d.isBefore(start) && !d.isAfter(end);
    }).toList();

    final totalSetoran = listByDate.length;
    final totalBerhasil = listByDate.where((s) => s.statusSetoran == 'berhasil').length;
    final totalLainnya = listByDate.where((s) => s.statusSetoran != 'berhasil').length;

    return Row(
      children: [
        Expanded(child: _statCard(
          iconColor: _teal,
          label: 'Total Setoran',
          value: totalSetoran.toString(),
        )),
        const SizedBox(width: 10),
        Expanded(child: _statCard(
          iconColor: _accent,
          label: 'Berhasil',
          value: totalBerhasil.toString(),
        )),
        const SizedBox(width: 10),
        Expanded(child: _statCard(
          iconColor: Colors.orange,
          label: 'Lainnya',
          value: totalLainnya.toString(),
        )),
      ],
    );
  }

  Widget _infoCard(){
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
          decoration: BoxDecoration(
            color: _teal.withOpacity(0.05),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: _teal.withOpacity(0.08),
              width: 1,
            )
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info, size: 16, color: _teal.withValues(alpha: 0.5)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Fitur untuk melakukan penyetoran baru akan muncul jika sesi penimbangan sudah dibuka petugas',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                    color: _teal.withValues(alpha: 0.6),
                  ),
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
          color: _teal.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: iconColor,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10,
              color: _teal.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
