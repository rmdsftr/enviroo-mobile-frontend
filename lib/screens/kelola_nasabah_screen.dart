import 'package:enviroo/screens/form_daftar_nasabah.dart';
import 'package:enviroo/widgets/topbar_back.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:enviroo/providers/nasabah_provider.dart';
import 'package:enviroo/providers/auth_provider.dart';
import 'package:enviroo/models/nasabah_model.dart';
import 'package:intl/intl.dart';

// ─── Palette ────────────────────────────────────────────────────────────────
class _C {
  static const bg        = Color(0xFFF2FAF0); // putih-hijau sangat terang
  static const dark      = Color(0xFF0D3B3E); // teal gelap
  static const lime      = Color(0xFF8ED60A); // lime aksen
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      context.read<NasabahProvider>().fetchNasabahs(auth);
    });
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
      backgroundColor: _C.bg,
      body: SafeArea(
        child: Column(
          children: [
            TopBarBack(title: "Kelola Nasabah"),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    _buildStatCards(),
                    _buildSearchBar(),
                    _buildFilterChips(),
                    _buildResultInfo(),
                    _buildListNasabah(),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(right: 10, bottom: 10),
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => FormDaftarNasabahScreen()));
          },
          backgroundColor: Color(0xFF94DF0C),
          child: Icon(
            Icons.person_add_alt_rounded,
            color: Color(0xFF013236),
            size: 30,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 6, 28, 0),
      child: Text(
        "Di sini kamu bisa lihat daftar nasabah yang tergabung di BSU Fakultas Teknologi Informasi.",
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12.5,
          height: 1.6,
          color: _C.dark.withOpacity(0.75),
        ),
      ),
    );
  }

  Widget _buildStatCards() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D3B3E), Color(0xFF1A5C61)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: _C.dark.withOpacity(0.25),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

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
                        "Total Nasabah",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.65),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "$_totalSemua",
                        style: TextStyle(
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

            // 3 Status dalam row
            Row(
              children: [
                Expanded(
                  child: _buildMiniStat(
                    value: "$_totalAktif",
                    label: "Aktif",
                    color: Color(0xFF06C0C9),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMiniStat(
                    value: "$_totalPending",
                    label: "Pending",
                    color: _C.orangeSoft,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMiniStat(
                    value: "$_totalNonaktif",
                    label: "Nonaktif",
                    color: _C.redSoft,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat({
    required String value,
    required String label,
    required Color color,
  }) {
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
            style: TextStyle(
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

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _searchQuery = v),
        style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: _C.dark),
        decoration: InputDecoration(
          hintText: "Cari nama nasabah...",
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
            borderSide: BorderSide(color: Color(0xFF4EA771).withOpacity(0.5), width: 1.5),
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

  Widget _buildFilterChips() {
    const filters = ['Semua', 'Aktif', 'Nonaktif', 'Pending'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Expanded(
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
                      color: selected ? Color(0xFF4EA771) : Colors.transparent,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: selected ? Color(0xFF4EA771) : Color(0xFF4EA771).withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: Text(f,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                          color: selected ? Colors.white : Color(0xFF4EA771),
                        )),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      )
    );
  }

  Widget _buildResultInfo() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 4),
      child: Text(
        "${_filteredNasabah.length} nasabah ditemukan",
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 11.5,
          color: Color(0xFF4EA771)
        ),
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
            Icon(Icons.person_search_rounded, size: 52, color: _C.dark.withOpacity(0.15)),
            const SizedBox(height: 12),
            Text("Nasabah tidak ditemukan",
                style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: _C.dark.withOpacity(0.35))),
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
    // Tentukan warna berdasarkan status
    Color dotColor;
    Color badgeBgColor;
    Color badgeTextColor;

    String status = nasabah.statusNasabah;
    String statusLower = status.toLowerCase();

    if (statusLower == 'aktif') {
      dotColor = Color(0xFF06C0C9);
      badgeBgColor = Color(0xFFD6F4F6);
      badgeTextColor = Color(0xFF06C0C9);
    } else if (statusLower == 'pending') {
      dotColor = _C.orangeSoft;
      badgeBgColor = _C.orangeSoft.withOpacity(0.1);
      badgeTextColor = _C.orangeSoft;
    } else {
      // Nonaktif
      dotColor = _C.redSoft;
      badgeBgColor = _C.redSoft.withOpacity(0.1);
      badgeTextColor = _C.redSoft;
    }

    String formattedDate = DateFormat('dd MMM yyyy').format(nasabah.joinedAt);
    String displayStatus = status.isNotEmpty ? status[0].toUpperCase() + status.substring(1).toLowerCase() : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          width: 1,
          color: Color(0xFF4EA771).withOpacity(0.2)
        ),
      ),
      child: Row(
        children: [
          // Avatar + status dot
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: nasabah.user.photoUrl.isNotEmpty
                    ? Image.network(
                        nasabah.user.photoUrl,
                        width: 52,
                        height: 52,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Image.asset(
                          "assets/images/profile.png",
                          width: 52,
                          height: 52,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Image.asset(
                        "assets/images/profile.png",
                        width: 52,
                        height: 52,
                        fit: BoxFit.cover,
                      ),
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
                Text(nasabah.user.nama,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: _C.dark,
                    ),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Text("Terdaftar $formattedDate",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10.5,
                      color: _C.dark.withOpacity(0.6),
                    )),
                const SizedBox(height: 7),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeBgColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(displayStatus,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: badgeTextColor,
                      )),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
