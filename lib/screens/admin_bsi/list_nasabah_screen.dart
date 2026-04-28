import 'package:enviroo/models/nasabah_model.dart';
import 'package:enviroo/providers/auth_provider.dart';
import 'package:enviroo/providers/nasabah_provider.dart';
import 'package:enviroo/screens/form_daftar_nasabah.dart';
import 'package:enviroo/widgets/topbar_back.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

// ─── Palette ────────────────────────────────────────────────────────────────
class _C {
  static const bg         = Color(0xFFF2FAF0);
  static const dark       = Color(0xFF0D3B3E);
  static const lime       = Color(0xFF8ED60A);
  static const midGreen   = Color(0xFF4B9E6B);
  static const redSoft    = Color(0xFFFF5A36);
  static const orangeSoft = Color(0xFFFFA726);
  static const accent     = Color(0xFF4EA771);
  static const cyan       = Color(0xFF06C0C9);
}

// ─── Screen ─────────────────────────────────────────────────────────────────
class ListNasabahScreen extends StatefulWidget {
  final String bsuId;
  final String bsuName;
  final String bsuAlamat;
  final String bsuStatus;

  const ListNasabahScreen({
    super.key,
    required this.bsuId,
    required this.bsuName,
    required this.bsuAlamat,
    required this.bsuStatus,
  });

  @override
  State<ListNasabahScreen> createState() => _ListNasabahScreenState();
}

class _ListNasabahScreenState extends State<ListNasabahScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery  = '';
  String _filterStatus = 'Semua';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchNasabah());
  }

  Future<void> _fetchNasabah() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final token = auth.currentUser?.accessToken;
    if (token == null) return;

    await Provider.of<NasabahProvider>(context, listen: false)
        .fetchNasabahsByBankId(widget.bsuId, token);
  }

  List<NasabahModel> _filtered(List<NasabahModel> all) => all.where((n) {
    final matchSearch = n.user.nama.toLowerCase().contains(_searchQuery.toLowerCase());
    final matchFilter = _filterStatus == 'Semua' ||
        n.statusNasabah.toLowerCase() == _filterStatus.toLowerCase();
    return matchSearch && matchFilter;
  }).toList();

  @override
  Widget build(BuildContext context) {
    return Consumer<NasabahProvider>(
      builder: (context, provider, _) {
        final filtered = _filtered(provider.nasabahs);

        return Scaffold(
          backgroundColor: _C.bg,
          body: SafeArea(
            child: Column(
              children: [
                TopBarBack(title: widget.bsuName),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _fetchNasabah,
                    color: _C.accent,
                    child: provider.isLoading
                        ? const Center(child: CircularProgressIndicator(color: _C.accent))
                        : provider.error.isNotEmpty
                            ? _buildError(provider.error)
                            : SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(
                                  parent: BouncingScrollPhysics(),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildBsuProfile(provider),
                                    _buildSearchBar(),
                                    _buildFilterChips(),
                                    _buildResultInfo(filtered.length),
                                    _buildListNasabah(filtered),
                                    const SizedBox(height: 30),
                                  ],
                                ),
                              ),
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(right: 10, bottom: 10),
            child: FloatingActionButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => FormDaftarNasabahScreen()),
                );
                _fetchNasabah(); // refresh setelah tambah nasabah
              },
              backgroundColor: const Color(0xFF013236),
              child: const Icon(Icons.person_add_alt_rounded, color: Colors.white, size: 28),
            ),
          ),
        );
      },
    );
  }

  // ── Error State ──────────────────────────────────────────────────────────
  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 52, color: _C.dark.withOpacity(0.2)),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: _C.dark.withOpacity(0.45),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _fetchNasabah,
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

  // ── BSU Profile + Stat Card ──────────────────────────────────────────────
  Widget _buildBsuProfile(NasabahProvider provider) {
    final isAktif     = widget.bsuStatus.toLowerCase() == 'aktif';
    final statusColor = isAktif ? _C.cyan : _C.redSoft;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0A3236), Color(0xFF134E54), Color(0xFF0D3B3E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.5, 1.0],
          ),
          borderRadius: BorderRadius.circular(32),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: Stack(
            children: [
              // Dekorasi lingkaran kanan atas
              Positioned(
                top: -60, right: -60,
                child: Container(
                  width: 180, height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [_C.lime.withOpacity(0.08), Colors.transparent]),
                  ),
                ),
              ),
              // Dekorasi lingkaran kiri bawah
              Positioned(
                bottom: -50, left: -50,
                child: Container(
                  width: 160, height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [_C.cyan.withOpacity(0.07), Colors.transparent]),
                  ),
                ),
              ),
              // Konten
              Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Baris: Icon BSU + Nama + Status
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Icon(Icons.house_rounded, color: statusColor, size: 32),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 2),
                              Text(
                                widget.bsuName,
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15.5,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  Icon(Icons.location_on_rounded, size: 11, color: Colors.white.withOpacity(0.4)),
                                  const SizedBox(width: 3),
                                  Expanded(
                                    child: Text(
                                      widget.bsuAlamat,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 10.5,
                                        height: 1.55,
                                        color: Colors.white.withOpacity(0.45),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: statusColor.withOpacity(0.35), width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6, height: 6,
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  shape: BoxShape.circle,
                                  boxShadow: [BoxShadow(color: statusColor.withOpacity(0.6), blurRadius: 4)],
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                widget.bsuStatus,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: statusColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Divider dekoratif
                    Row(
                      children: [
                        Container(
                          width: 28, height: 3,
                          decoration: BoxDecoration(color: _C.lime, borderRadius: BorderRadius.circular(4)),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Container(
                            height: 1,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.white.withOpacity(0.12), Colors.transparent],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Stats row
                    IntrinsicHeight(
                      child: Row(
                        children: [
                          Expanded(
                            flex: 5,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.07),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white.withOpacity(0.09), width: 1),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(7),
                                        decoration: BoxDecoration(
                                          color: _C.lime.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Icon(Icons.people_alt_rounded, color: _C.lime, size: 16),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        "Total\nNasabah",
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 10,
                                          height: 1.4,
                                          color: Colors.white.withOpacity(0.55),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        "${provider.totalSemua}",
                                        style: const TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 42,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                          height: 1.0,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 6, left: 4),
                                        child: Text(
                                          "org",
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 12,
                                            color: Colors.white.withOpacity(0.35),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: 1.0,
                                      backgroundColor: Colors.white.withOpacity(0.08),
                                      valueColor: AlwaysStoppedAnimation<Color>(_C.lime.withOpacity(0.6)),
                                      minHeight: 3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 4,
                            child: Column(
                              children: [
                                Expanded(child: _buildMiniStat(
                                  value: "${provider.totalAktif}",
                                  label: "Aktif",
                                  color: _C.cyan,
                                  icon: Icons.check_circle_rounded,
                                  fraction: provider.totalSemua == 0 ? 0 : provider.totalAktif / provider.totalSemua,
                                )),
                                const SizedBox(height: 8),
                                Expanded(child: _buildMiniStat(
                                  value: "${provider.totalPending}",
                                  label: "Pending",
                                  color: _C.orangeSoft,
                                  icon: Icons.access_time_filled_rounded,
                                  fraction: provider.totalSemua == 0 ? 0 : provider.totalPending / provider.totalSemua,
                                )),
                                const SizedBox(height: 8),
                                Expanded(child: _buildMiniStat(
                                  value: "${provider.totalNonaktif}",
                                  label: "Nonaktif",
                                  color: _C.redSoft,
                                  icon: Icons.cancel_rounded,
                                  fraction: provider.totalSemua == 0 ? 0 : provider.totalNonaktif / provider.totalSemua,
                                )),
                              ],
                            ),
                          ),
                        ],
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

  Widget _buildMiniStat({
    required String value,
    required String label,
    required Color color,
    required IconData icon,
    required double fraction,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.12), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 15, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 9.5,
                    color: Colors.white.withOpacity(0.5),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: fraction,
                    backgroundColor: Colors.white.withOpacity(0.08),
                    valueColor: AlwaysStoppedAnimation<Color>(color.withOpacity(0.7)),
                    minHeight: 3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.0,
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
          hintText: "Cari nama nasabah...",
          hintStyle: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: _C.dark.withOpacity(0.35)),
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
    const filters = ['Semua', 'Aktif', 'Nonaktif', 'Pending'];
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
  Widget _buildResultInfo(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 4),
      child: Text(
        "$count nasabah ditemukan",
        style: const TextStyle(fontFamily: 'Poppins', fontSize: 11.5, color: _C.accent),
      ),
    );
  }

  // ── List Nasabah ─────────────────────────────────────────────────────────
  Widget _buildListNasabah(List<NasabahModel> list) {
    if (list.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.person_search_rounded, size: 52, color: _C.dark.withOpacity(0.15)),
              const SizedBox(height: 12),
              Text(
                "Nasabah tidak ditemukan",
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
      itemBuilder: (_, i) => _buildCardNasabah(list[i]),
    );
  }

  Widget _buildCardNasabah(NasabahModel nasabah) {
    final status = nasabah.statusNasabah;
    Color dotColor;
    Color badgeBgColor;
    Color badgeTextColor;

    if (status.toLowerCase() == 'aktif') {
      dotColor       = _C.cyan;
      badgeBgColor   = const Color(0xFFD6F4F6);
      badgeTextColor = _C.cyan;
    } else if (status.toLowerCase() == 'pending') {
      dotColor       = _C.orangeSoft;
      badgeBgColor   = _C.orangeSoft.withOpacity(0.1);
      badgeTextColor = _C.orangeSoft;
    } else {
      dotColor       = _C.redSoft;
      badgeBgColor   = _C.redSoft.withOpacity(0.1);
      badgeTextColor = _C.redSoft;
    }

    final joinedFmt = DateFormat('dd MMM yyyy').format(nasabah.joinedAt);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(width: 1, color: _C.accent.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          // Avatar
          Stack(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: _C.accent.withOpacity(0.12),
                backgroundImage: nasabah.user.photoUrl.isNotEmpty
                    ? NetworkImage(nasabah.user.photoUrl)
                    : null,
                child: nasabah.user.photoUrl.isEmpty
                    ? Icon(Icons.person_rounded, color: _C.accent, size: 28)
                    : null,
              ),
              Positioned(
                bottom: 0, right: 0,
                child: Container(
                  width: 14, height: 14,
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
                  nasabah.user.nama.isNotEmpty ? nasabah.user.nama : 'Nama tidak tersedia',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: _C.dark,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                if (nasabah.nomorRekening.isNotEmpty)
                  Row(
                    children: [
                      Icon(Icons.credit_card_rounded, size: 11, color: _C.dark.withOpacity(0.4)),
                      const SizedBox(width: 4),
                      Text(
                        nasabah.nomorRekening,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10.5,
                          color: _C.dark.withOpacity(0.55),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 11, color: _C.dark.withOpacity(0.4)),
                    const SizedBox(width: 4),
                    Text(
                      "Bergabung $joinedFmt",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        color: _C.dark.withOpacity(0.45),
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
                    status,
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
        ],
      ),
    );
  }
}
