import 'dart:convert';
import 'package:enviroo/config/api_config.dart';
import 'package:enviroo/providers/auth_provider.dart';
import 'package:enviroo/screens/nasabah/detail_setoran_screen.dart';
import 'package:enviroo/screens/setoran_screen.dart';
import 'package:enviroo/widgets/filter_chip_row.dart';
import 'package:enviroo/widgets/topbar_back.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

// ── Model ────────────────────────────────────────────────────────────────────
class RiwayatSetoranModel {
  final String setoranId;
  final String namaPetugas;
  final DateTime transaksiTimestamp;
  final int totalItem;
  final double totalPoin;
  final String statusSetoran;

  RiwayatSetoranModel({
    required this.setoranId,
    required this.namaPetugas,
    required this.transaksiTimestamp,
    required this.totalItem,
    required this.totalPoin,
    required this.statusSetoran,
  });

  factory RiwayatSetoranModel.fromJson(Map<String, dynamic> json) {
    return RiwayatSetoranModel(
      setoranId: json['setoran_id'] ?? '',
      namaPetugas: json['nama_petugas'] ?? 'Petugas',
      transaksiTimestamp:
          DateTime.tryParse(json['transaksi_timestamp'] ?? '') ?? DateTime.now(),
      totalItem: json['total_item'] ?? 0,
      totalPoin: (json['total_poin'] as num?)?.toDouble() ?? 0.0,
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

  // ── Saldo State ─────────────────────────────────────────────────────────────
  double _saldoPoin = 0;
  bool _isSaldoLoading = true;

  // ── Filter & Search State ───────────────────────────────────────────────────
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterStatus = 'semua';

  static const _filterItems = [
    FilterChipItem(value: 'semua', label: 'Semua'),
    FilterChipItem(value: 'berhasil', label: 'Berhasil'),
    FilterChipItem(value: 'lainnya', label: 'Lainnya'),
  ];

  @override
  void initState() {
    super.initState();
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
    await Future.wait([_fetchRiwayat(), _fetchSaldo()]);
  }

  // ── Fetch Riwayat ────────────────────────────────────────────────────────────
  Future<void> _fetchRiwayat() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final nasabahId = auth.identityId ?? '';
    final token = auth.currentUser?.accessToken ?? '';

    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.listSetoranNasabahUrl}/$nasabahId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final List data = body['data'] ?? [];
        setState(() {
          _list = data.map((e) => RiwayatSetoranModel.fromJson(e)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Gagal memuat riwayat setoran';
          _isLoading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Tidak dapat terhubung ke server';
        _isLoading = false;
      });
    }
  }

  // ── Fetch Saldo ──────────────────────────────────────────────────────────────
  Future<void> _fetchSaldo() async {
    setState(() => _isSaldoLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final nasabahId = auth.identityId ?? '';
    final token = auth.currentUser?.accessToken ?? '';

    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.getSaldoNasabahUrl}/$nasabahId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        setState(() {
          _saldoPoin =
              (body['data']?['saldo_poin'] as num?)?.toDouble() ?? 0.0;
          _isSaldoLoading = false;
        });
      } else {
        setState(() => _isSaldoLoading = false);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaldoLoading = false);
    }
  }

  // ── Filtered List ────────────────────────────────────────────────────────────
  List<RiwayatSetoranModel> get _filteredList {
    return _list.where((item) {
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
            .format(item.transaksiTimestamp.toLocal())
            .toLowerCase()
            .contains(_searchQuery);
        if (!namaMatch && !tanggalMatch) return false;
      }
      return true;
    }).toList();
  }

  // ── Formatter ────────────────────────────────────────────────────────────────
  String _formatPoin(double poin) {
    final intPart = poin.truncate();
    final dec = poin - intPart;
    final formatted = NumberFormat('#,###', 'id_ID').format(intPart);
    if (dec > 0) return '$formatted${dec.toStringAsFixed(2).substring(1)}';
    return formatted;
  }

  // ── Build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      body: SafeArea(
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
                          child: CustomScrollView(
                            physics: const BouncingScrollPhysics(
                              parent: AlwaysScrollableScrollPhysics(),
                            ),
                            slivers: [
                              // 1. QR Button — paling atas, mencolok
                              SliverToBoxAdapter(child: _buildQRButton()),
                              // 2. Saldo Card — putih, di bawah QR
                              SliverToBoxAdapter(child: _buildSaldoHeader()),
                              // 3. Search bar
                              SliverToBoxAdapter(child: _buildSearchBar()),
                              // 4. Filter chips
                              SliverToBoxAdapter(child: _buildFilterChips()),
                              // 5. Section header
                              SliverToBoxAdapter(child: _buildSectionHeader()),
                              // 6. List / Empty
                              if (_filteredList.isEmpty)
                                SliverFillRemaining(
                                  hasScrollBody: false,
                                  child: _buildEmpty(),
                                )
                              else
                                SliverPadding(
                                  padding: const EdgeInsets.fromLTRB(
                                      20, 0, 20, 32),
                                  sliver: SliverList(
                                    delegate: SliverChildBuilderDelegate(
                                      (ctx, i) =>
                                          _buildCard(_filteredList[i]),
                                      childCount: _filteredList.length,
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
    );
  }

  // ── QR Button ─────────────────────────────────────────────────────────────────
  Widget _buildQRButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => SetoranScreen()),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF013236), Color(0xFF025A62)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _lime.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
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
              const Icon(Icons.arrow_forward_ios_rounded, color: _lime, size: 15),
            ],
          ),
        ),
      ),
    );
  }

  // ── Saldo Header ──────────────────────────────────────────────────────────────
  Widget _buildSaldoHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: _teal.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.eco_rounded, color: _accent, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Saldo Anda Saat Ini',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: _teal.withOpacity(0.55),
                    ),
                  ),
                  const SizedBox(height: 2),
                  _isSaldoLoading
                      ? Container(
                          height: 20,
                          width: 90,
                          decoration: BoxDecoration(
                            color: _teal.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        )
                      : Text(
                          '${_formatPoin(_saldoPoin)} Poin',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w800,
                            fontSize: 20,
                            color: _accent,
                          ),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Search Bar ────────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(
            fontFamily: 'Poppins', fontSize: 13, color: _teal),
        decoration: InputDecoration(
          hintText: 'Cari nama petugas atau tanggal...',
          hintStyle: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            color: _teal.withOpacity(0.35),
          ),
          prefixIcon:
              Icon(Icons.search_rounded, color: _accent, size: 22),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close_rounded,
                      size: 18, color: _teal.withOpacity(0.4)),
                  onPressed: () => _searchController.clear(),
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(50),
            borderSide:
                BorderSide(color: _accent.withOpacity(0.4), width: 1.2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(50),
            borderSide: const BorderSide(color: _accent, width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
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
          const Spacer(),
          if (_filteredList.isNotEmpty)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: _accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_filteredList.length} transaksi',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: _accent,
                ),
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
    final statusLabel = isSuccess ? 'Berhasil' : item.statusSetoran;
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: statusColor.withOpacity(0.1)),
            boxShadow: [
              BoxShadow(
                color: _teal.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            DateFormat('dd MMM yyyy, HH:mm', 'id_ID')
                                .format(item.transaksiTimestamp.toLocal()),
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: _teal,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(statusIcon,
                                  size: 9, color: statusColor),
                              const SizedBox(width: 3),
                              Text(
                                statusLabel,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: statusColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Petugas: ${item.namaPetugas} · ${item.totalItem} item',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: _teal.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.eco_rounded,
                            size: 13, color: _accent),
                        const SizedBox(width: 4),
                        Text(
                          '${_formatPoin(item.totalPoin)} poin',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _accent,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded,
                  color: _accent.withOpacity(0.6), size: 18),
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
}
