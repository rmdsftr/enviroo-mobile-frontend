import 'package:enviroo/models/bsu_unit_model.dart';
import 'package:enviroo/providers/auth_provider.dart';
import 'package:enviroo/screens/admin_bsi/list_nasabah_screen.dart';
import 'package:enviroo/services/nasabah_service.dart';
import 'package:enviroo/widgets/filter_chip_row.dart';
import 'package:enviroo/widgets/search.dart';
import 'package:enviroo/widgets/topbar_back.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// ─── Palette ────────────────────────────────────────────────────────────────
class _C {
  static const bg        = Color(0xFFF2FAF0);
  static const dark      = Color(0xFF0D3B3E);
  static const midGreen  = Color(0xFF4B9E6B);
  static const softGreen = Color(0xFFD8F0D0);
  static const redSoft   = Color(0xFFFF5A36);
}

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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchBsu() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final bankId = auth.bankId;

    if (bankId == null) {
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

    final res = await NasabahService.getBsuByBsiId(bankId);

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
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg_struk.webp',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TopBarBack(title: "Daftar BSU"),
                _buildHeader(),
                _buildStatCards(),
                const SizedBox(height: 10),
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(color: Colors.white),
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator(color: _C.midGreen))
                        : _error.isNotEmpty
                            ? _buildError()
                            : RefreshIndicator(
                                color: _C.midGreen,
                                onRefresh: _fetchBsu,
                                child: SingleChildScrollView(
                                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildSearchBar(),
                                      _buildFilterChips(),
                                      const SizedBox(height: 15),
                                      _buildListBsu(),
                                      const SizedBox(height: 30),
                                    ],
                                  ),
                                ),
                              ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 6, 28, 0),
      child: Text(
        "Di sini kamu bisa lihat seluruh Bank Sampah Unit (BSU) yang terasosiasi dengan BSI kamu",
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12.5,
          height: 1.6,
          color: _C.dark.withValues(alpha: 0.75),
        ),
      ),
    );
  }

  Widget _buildStatCards() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        children: [
          _buildCardTotal(),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildMiniStat(value: "$_totalAktif",    label: "Aktif",         color: const Color(0xFF4EA771))),
              const SizedBox(width: 10),
              Expanded(child: _buildMiniStat(value: "$_totalNonaktif", label: "Nonaktif",      color: _C.redSoft)),
              const SizedBox(width: 10),
              Expanded(child: _buildMiniStat(value: "$_totalNasabah",  label: "Total Nasabah", color: _C.dark)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardTotal() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF013236).withValues(alpha: 0.08),
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
                "$_totalBsu",
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: _C.dark,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                "Total BSU",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11.5,
                  color: _C.dark.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: _C.bg,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.house_rounded, color: _C.midGreen, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat({required String value, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF013236).withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: _C.dark.withValues(alpha: 0.45),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: CustomSearchBar(
        controller: _searchController,
        hintText: 'Cari nama BSU...',
        searchQuery: _searchQuery,
        onChanged: (v) => setState(() => _searchQuery = v),
        onClear: () {
          _searchController.clear();
          setState(() => _searchQuery = '');
        },
      ),
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: FilterChipRow<String>(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        selectedValue: _filterStatus,
        onSelected: (v) => setState(() => _filterStatus = v),
        items: const [
          FilterChipItem(value: 'Semua',    label: 'Semua'),
          FilterChipItem(value: 'Aktif',    label: 'Aktif'),
          FilterChipItem(value: 'Nonaktif', label: 'Nonaktif'),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 52, color: _C.dark.withValues(alpha: 0.2)),
            const SizedBox(height: 16),
            Text(
              _error,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: _C.dark.withValues(alpha: 0.45),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _fetchBsu,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Coba Lagi', style: TextStyle(fontFamily: 'Poppins', fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _C.midGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListBsu() {
    final list = _filtered;
    if (list.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.store_mall_directory_outlined, size: 52, color: _C.dark.withValues(alpha: 0.15)),
              const SizedBox(height: 12),
              Text(
                "BSU tidak ditemukan",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: _C.dark.withValues(alpha: 0.35),
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
    final Color dotColor = bsu.isActive ? const Color(0xFF4EA771) : _C.redSoft;

    final initials = bsu.namaBank
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ListNasabahScreen(bsuId: bsu.bankId),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            width: 1,
            color: const Color(0xFF013236).withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          children: [
            Stack(
              children: [
                bsu.photoUrl.isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          bsu.photoUrl,
                          width: 52,
                          height: 52,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildInitialsAvatar(initials),
                        ),
                      )
                    : _buildInitialsAvatar(initials),
                Positioned(
                  bottom: 0, right: 0,
                  child: Container(
                    width: 13, height: 13,
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
                  const SizedBox(height: 4),
                  _buildInfoRow(Icons.badge, "ID : ${bsu.bankId}"),
                  const SizedBox(height: 2),
                  _buildInfoRow(
                    Icons.location_on_outlined,
                    bsu.alamatLengkap.isNotEmpty ? bsu.alamatLengkap : 'Alamat belum diisi',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 11, color: _C.dark.withValues(alpha: 0.35)),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10,
              color: _C.dark.withValues(alpha: 0.45),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildInitialsAvatar(String initials) {
    return Container(
      width: 52,
      height: 52,
      decoration: const BoxDecoration(
        color: _C.softGreen,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: _C.midGreen,
        ),
      ),
    );
  }
}
