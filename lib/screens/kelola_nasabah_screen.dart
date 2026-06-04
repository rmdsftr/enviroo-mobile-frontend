import 'package:enviroo/models/bsu_unit_model.dart';
import 'package:enviroo/screens/detail_profil_nasabah.dart';
import 'package:enviroo/services/nasabah_service.dart';
import 'package:enviroo/widgets/dropdown_custom.dart';
import 'package:enviroo/widgets/filter_chip_row.dart';
import 'package:enviroo/widgets/search.dart';
import 'package:enviroo/widgets/topbar_back.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:enviroo/providers/nasabah_provider.dart';
import 'package:enviroo/providers/auth_provider.dart';
import 'package:enviroo/models/nasabah_model.dart';

// ─── Palette ────────────────────────────────────────────────────────────────
class _C {
  static const bg        = Color(0xFFF2FAF0); // putih-hijau sangat terang
  static const dark      = Color(0xFF0D3B3E); // teal gelap
  static const midGreen  = Color(0xFF4B9E6B); // hijau tengah
  static const softGreen = Color(0xFFD8F0D0); // hijau pucat
  static const redSoft   = Color(0xFFFF5A36); // merah nonaktif
  static const orangeSoft = Color(0xFFFFA726); // orange pending
}



class KelolaNasabahScreen extends StatefulWidget {
  @override
  State<KelolaNasabahScreen> createState() => _KelolaNasabahScreenState();
}

class _KelolaNasabahScreenState extends State<KelolaNasabahScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery  = '';
  String _filterStatus = 'Semua';

  // ── BSI-only dropdown state ───────────────────────────────────────────────
  bool _isBsi = false;
  String? _selectedBankId;
  List<BsuUnitModel> _bsuUnits = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.role == 'petugas_bsi') {
        setState(() {
          _isBsi = true;
          _selectedBankId = auth.bankId;
        });
        if (auth.bankId != null) {
          _fetchBsuUnits(auth.bankId!);
        }
      }
      context.read<NasabahProvider>().fetchNasabahs(auth);
    });
  }

  Future<void> _fetchBsuUnits(String bankId) async {
    final res = await NasabahService.getBsuByBsiId(bankId);
    if (mounted && res['success'] == true) {
      setState(() {
        _bsuUnits = (res['data'] as List? ?? [])
            .map((j) => BsuUnitModel.fromJson(j))
            .toList();
      });
    }
  }

  void _onBankSelected(String? bankId) {
    if (bankId == null || bankId == _selectedBankId) return;
    setState(() => _selectedBankId = bankId);
    context.read<NasabahProvider>().fetchNasabahsByBankId(bankId);
  }

  int get _totalSemua    => context.watch<NasabahProvider>().totalSemua;
  int get _totalAktif    => context.watch<NasabahProvider>().totalAktif;
  int get _totalNonaktif => context.watch<NasabahProvider>().totalNonaktif;
  int get _totalPending  => context.watch<NasabahProvider>().totalPending;

  List<NasabahModel> get _filteredNasabah => context.watch<NasabahProvider>().nasabahs.where((n) {
    final matchSearch = n.user.nama.toLowerCase().contains(_searchQuery.toLowerCase());
    final matchFilter = _filterStatus == 'Semua' || n.statusNasabah.toLowerCase() == _filterStatus.toLowerCase();
    return matchSearch && matchFilter;
  }).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image
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
                TopBarBack(title: "Daftar Nasabah"),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        if (_isBsi) _buildBankDropdown(),
                        _buildStatCards(),
                        const SizedBox(height: 10),
                        // White panel: search, filter, list
                        Container(
                          decoration: const BoxDecoration(color: Colors.white),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSearchBar(),
                              _buildFilterChips(),
                              const SizedBox(height: 15),
                              _buildListNasabah(),
                              const SizedBox(height: 30),
                            ],
                          ),
                        ),
                      ],
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
        "Di sini kamu bisa lihat daftar nasabah yang tergabung di bank sampah beserta keaktifan mereka",
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12.5,
          height: 1.6,
          color: _C.dark.withValues(alpha:0.75),
        ),
      ),
    );
  }

  Widget _buildStatCards() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF013236).withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Kolom 1 — Total
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "$_totalSemua",
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: _C.dark,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      "Total Nasabah",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: _C.dark.withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                ),
              ),
              VerticalDivider(
                width: 28,
                thickness: 0.5,
                color: _C.dark.withValues(alpha: 0.1),
              ),
              // Kolom 2 — 3 baris
              Expanded(
                flex: 6,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMiniStat(value: "$_totalAktif",    label: "Aktif",    color: const Color(0xFF4EA771)),
                    Divider(height: 10, thickness: 0.5, color: _C.dark.withValues(alpha: 0.08)),
                    _buildMiniStat(value: "$_totalPending",  label: "Pending",  color: _C.orangeSoft),
                    Divider(height: 10, thickness: 0.5, color: _C.dark.withValues(alpha: 0.08)),
                    _buildMiniStat(value: "$_totalNonaktif", label: "Nonaktif", color: _C.redSoft),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildMiniStat({
    required String value,
    required String label,
    required Color color,
  }) {
    return Row(
      children: [
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
            height: 1.0,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: _C.dark.withValues(alpha: 0.4),
          ),
        ),
      ],
    );
  }

  Widget _buildBankDropdown() {
    final auth = context.read<AuthProvider>();
    final items = <CustomDropdownItem<String>>[
      CustomDropdownItem(
        value: auth.bankId ?? '',
        label: 'Nasabah BSI Anda',
        icon: Icons.home_work_rounded,
      ),
      ..._bsuUnits.map((b) => CustomDropdownItem(
        value: b.bankId,
        label: b.namaBank,
        icon: Icons.house_rounded,
      )),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: CustomDropdown<String>(
        value: _selectedBankId,
        items: items,
        onChanged: _onBankSelected,
        hintText: 'Pilih bank sampah',
        prefixIcon: Icons.account_balance_rounded,
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: CustomSearchBar(
        controller: _searchController,
        hintText: 'Cari nama nasabah...',
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
          FilterChipItem(value: 'Pending',  label: 'Pending'),
        ],
      ),
    );
  }

  Widget _buildListNasabah() {
    final provider = context.watch<NasabahProvider>();
    if (provider.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator(color: _C.midGreen)),
      );
    }
    if (provider.error.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: Text(provider.error, style: TextStyle(color: Colors.red)),
        ),
      );
    }

    final list = _filteredNasabah;
    if (list.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: Column(children: [
            Icon(Icons.person_search_rounded, size: 52, color: _C.dark.withValues(alpha:0.15)),
            const SizedBox(height: 12),
            Text("Nasabah tidak ditemukan",
                style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: _C.dark.withValues(alpha:0.35))),
          ]),
        ),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _buildCardNasabah(list[i]),
    );
  }

  Widget _buildCardNasabah(NasabahModel nasabah) {
    final statusLower = nasabah.statusNasabah.toLowerCase();
    final Color dotColor = statusLower == 'aktif'
        ? const Color(0xFF4EA771)
        : statusLower == 'pending'
            ? _C.orangeSoft
            : _C.redSoft;

    final initials = nasabah.user.nama
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
          builder: (_) => DetailProfilNasabahScreen(nasabahId: nasabah.nasabahId),
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
              nasabah.user.photoUrl.isNotEmpty
                  ? ClipOval(
                      child: Image.network(
                        nasabah.user.photoUrl,
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
                  nasabah.user.nama,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: _C.dark,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                _buildInfoRow(Icons.badge_outlined, nasabah.nasabahId),
                const SizedBox(height: 2),
                _buildInfoRow(Icons.email_outlined, nasabah.user.email),
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
