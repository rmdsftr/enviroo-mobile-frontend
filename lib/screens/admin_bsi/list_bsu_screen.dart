import 'package:enviroo/models/bsu_unit_model.dart';
import 'package:enviroo/providers/auth_provider.dart';
import 'package:enviroo/screens/admin_bsi/list_nasabah_screen.dart';
import 'package:enviroo/services/nasabah_service.dart';
import 'package:enviroo/widgets/topbar_back.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// ─── Palette ────────────────────────────────────────────────────────────────
class _C {
  static const bg        = Color(0xFFF2FAF0);
  static const dark      = Color(0xFF0D3B3E);
  static const lime      = Color(0xFF8ED60A);
  static const midGreen  = Color(0xFF4B9E6B);
  static const redSoft   = Color(0xFFFF5A36);
  static const accent    = Color(0xFF4EA771);
  static const cyan      = Color(0xFF06C0C9);
}

// ─── Screen ─────────────────────────────────────────────────────────────────
class ListBsuScreen extends StatefulWidget {
  const ListBsuScreen({super.key});

  @override
  State<ListBsuScreen> createState() => _ListBsuScreenState();
}

class _ListBsuScreenState extends State<ListBsuScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery  = '';
  String _filterStatus = 'Semua';

  List<BsuUnitModel> _bsuList = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchBsu());
  }

  Future<void> _fetchBsu() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final token = auth.currentUser?.accessToken;
    final bankId = auth.bankId;

    if (token == null || bankId == null) {
      setState(() {
        _isLoading = false;
        _error = 'Sesi login tidak ditemukan.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = '';
    });

    final res = await NasabahService.getBsuByBsiId(bankId, token);

    if (!mounted) return;

    if (res['success'] == true) {
      final List<dynamic> data = res['data'] ?? [];
      setState(() {
        _bsuList = data.map((j) => BsuUnitModel.fromJson(j)).toList();
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = res['message'] ?? 'Gagal memuat data BSU';
        _isLoading = false;
      });
    }
  }

  // ── Computed stats ───────────────────────────────────────────────────────
  int get _totalBsu      => _bsuList.length;
  int get _totalAktif    => _bsuList.where((b) => b.isActive).length;
  int get _totalNonaktif => _bsuList.where((b) => !b.isActive).length;
  int get _totalNasabah  => _bsuList.fold(0, (sum, b) => sum + b.jumlahNasabah);

  List<BsuUnitModel> get _filtered => _bsuList.where((b) {
    final matchSearch = b.namaBank.toLowerCase().contains(_searchQuery.toLowerCase());
    final matchFilter = _filterStatus == 'Semua' ||
        (_filterStatus == 'Aktif' && b.isActive) ||
        (_filterStatus == 'Nonaktif' && !b.isActive);
    return matchSearch && matchFilter;
  }).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: SafeArea(
        child: Column(
          children: [
            TopBarBack(title: "Daftar BSU"),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchBsu,
                color: _C.accent,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: _C.accent))
                    : _error.isNotEmpty
                        ? _buildError()
                        : SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(
                              parent: BouncingScrollPhysics(),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildHeader(),
                                _buildStatCards(),
                                _buildSearchBar(),
                                _buildFilterChips(),
                                _buildResultInfo(),
                                _buildListBsu(),
                                const SizedBox(height: 30),
                              ],
                            ),
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Error State ──────────────────────────────────────────────────────────
  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 52, color: _C.dark.withOpacity(0.2)),
            const SizedBox(height: 16),
            Text(
              _error,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: _C.dark.withOpacity(0.45),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _fetchBsu,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba Lagi', style: TextStyle(fontFamily: 'Poppins')),
              style: ElevatedButton.styleFrom(
                backgroundColor: _C.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 6, 28, 0),
      child: Text(
        "Di sini kamu bisa lihat seluruh Bank Sampah Unit (BSU) yang terasosiasi dengan BSI kamu.",
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12.5,
          height: 1.6,
          color: _C.dark.withOpacity(0.75),
        ),
      ),
    );
  }

  // ── Stat Cards ───────────────────────────────────────────────────────────
  Widget _buildStatCards() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0D3B3E), Color(0xFF1A5C61)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Total Nasabah semua BSU
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.15),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Total Nasabah Semua BSU",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.65),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "$_totalNasabah",
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _C.lime.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.people_rounded, color: _C.lime, size: 28),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Mini stat row
            Row(
              children: [
                Expanded(child: _buildMiniStat(value: "$_totalBsu",      label: "Total BSU", color: _C.lime)),
                const SizedBox(width: 10),
                Expanded(child: _buildMiniStat(value: "$_totalAktif",    label: "Aktif",     color: _C.cyan)),
                const SizedBox(width: 10),
                Expanded(child: _buildMiniStat(value: "$_totalNonaktif", label: "Nonaktif",  color: _C.redSoft)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat({required String value, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Search Bar ───────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _searchQuery = v),
        style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: _C.dark),
        decoration: InputDecoration(
          hintText: "Cari nama BSU...",
          hintStyle: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            color: _C.dark.withOpacity(0.35),
          ),
          prefixIcon: Icon(Icons.search_rounded, color: _C.midGreen, size: 22),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close_rounded, size: 18, color: _C.dark.withOpacity(0.35)),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.transparent,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(50),
            borderSide: BorderSide(color: _C.accent.withOpacity(0.5), width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(50),
            borderSide: BorderSide(color: _C.midGreen, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
    );
  }

  // ── Filter Chips ─────────────────────────────────────────────────────────
  Widget _buildFilterChips() {
    const filters = ['Semua', 'Aktif', 'Nonaktif'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((f) {
            final selected = _filterStatus == f;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _filterStatus = f),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? _C.accent : Colors.transparent,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: selected ? _C.accent : _C.accent.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    f,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                      color: selected ? Colors.white : _C.accent,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── Result Info ──────────────────────────────────────────────────────────
  Widget _buildResultInfo() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 4),
      child: Text(
        "${_filtered.length} BSU ditemukan",
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 11.5,
          color: _C.accent,
        ),
      ),
    );
  }

  // ── List BSU ─────────────────────────────────────────────────────────────
  Widget _buildListBsu() {
    final list = _filtered;
    if (list.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.store_mall_directory_outlined, size: 52, color: _C.dark.withOpacity(0.15)),
              const SizedBox(height: 12),
              Text(
                "BSU tidak ditemukan",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: _C.dark.withOpacity(0.35),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _buildCardBsu(list[i]),
    );
  }

  Widget _buildCardBsu(BsuUnitModel bsu) {
    final dotColor       = bsu.isActive ? _C.cyan   : _C.redSoft;
    final badgeBgColor   = bsu.isActive ? const Color(0xFFD6F4F6) : _C.redSoft.withOpacity(0.1);
    final badgeTextColor = bsu.isActive ? _C.cyan   : _C.redSoft;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ListNasabahScreen(
              bsuId: bsu.bankId,
              bsuName: bsu.namaBank,
              bsuAlamat: bsu.alamatLengkap.isNotEmpty ? bsu.alamatLengkap : 'Alamat belum diisi',
              bsuStatus: bsu.statusLabel,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            width: 1,
            color: _C.accent.withOpacity(0.25),
          ),
        ),
        child: Row(
          children: [
            // Icon avatar
            Stack(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: _C.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.house_rounded, color: _C.accent, size: 28),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bsu.namaBank,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: _C.dark,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(Icons.people_alt_outlined, size: 12, color: _C.dark.withOpacity(0.5)),
                      const SizedBox(width: 4),
                      Text(
                        "${bsu.jumlahNasabah} nasabah",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10.5,
                          color: _C.dark.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: badgeBgColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      bsu.statusLabel,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: badgeTextColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Chevron
            Icon(
              Icons.chevron_right_rounded,
              color: _C.dark.withOpacity(0.25),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
