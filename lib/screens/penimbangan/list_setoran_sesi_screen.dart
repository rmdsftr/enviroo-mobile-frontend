import 'package:enviroo/models/setoran_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:enviroo/providers/penimbangan_provider.dart';
import 'package:enviroo/screens/setoran/detail_setoran_screen.dart';
import 'package:enviroo/widgets/search.dart';
import 'package:enviroo/widgets/topbar_back.dart';

// ─── Screen ──────────────────────────────────────────────────────────────────

class ListSetoranSesiScreen extends StatefulWidget {
  final String penimbanganId;
  final String tanggalPenimbangan;

  const ListSetoranSesiScreen({
    Key? key,
    required this.penimbanganId,
    required this.tanggalPenimbangan,
  }) : super(key: key);

  @override
  State<ListSetoranSesiScreen> createState() =>
      _ListSetoranSesiScreenState();
}

class _ListSetoranSesiScreenState extends State<ListSetoranSesiScreen> {
  bool _isLoading = true;
  List<SetoranSummary> _list = [];
  Map<String, dynamic>? _headerData;
  String? _errorMsg;

  // ─── Search ───────────────────────────────────────────────────────────────
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  bool get _isDibatalkan => _headerData?['status_penimbangan'] == 'dibatalkan';
  bool get _isPending => _headerData?['status_penimbangan'] == 'pending';

  List<SetoranSummary> get _filtered {
    return _list.where((s) {
      final q = _searchQuery.toLowerCase();
      final matchSearch = q.isEmpty ||
          s.namaNasabah.toLowerCase().contains(q) ||
          s.namaPetugas.toLowerCase().contains(q) ||
          s.setoranId.toLowerCase().contains(q);
      return matchSearch;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchData());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    final res = await context
        .read<PenimbanganProvider>()
        .getListSetoran(widget.penimbanganId);
    if (!mounted) return;
    if (res['success'] == true) {
      final data = (res['data'] as Map<String, dynamic>?) ?? {};
      final rawList = data['list_setoran'] as List? ?? [];
      setState(() {
        _headerData = data;
        _list = rawList.map((e) => SetoranSummary.fromJson(e)).toList();
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMsg = res['message'] ?? 'Gagal memuat data';
        _isLoading = false;
      });
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F8),
      body: SafeArea(
        child: Column(
          children: [
            TopBarBack(title: 'Setoran Nasabah'),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFF4EA771)))
                  : RefreshIndicator(
                      onRefresh: _fetchData,
                      color: const Color(0xFF4EA771),
                      child: CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          if (_headerData != null)
                            SliverToBoxAdapter(child: _buildInfoBanner()),
                          if (_headerData != null && _isDibatalkan)
                            SliverToBoxAdapter(child: _buildAlasanPembatalanCard()),
                          if (_headerData != null && _isPending)
                            SliverToBoxAdapter(child: _buildPersiapanCard()),
                          if (_headerData != null && !_isDibatalkan && !_isPending)
                            SliverToBoxAdapter(child: _buildListHeader()),
                          if (!_isPending)
                            if (_errorMsg != null)
                              SliverFillRemaining(child: _buildError())
                            else if (_list.isEmpty)
                              SliverFillRemaining(child: _buildEmpty())
                            else
                              _buildSliverList(),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListHeader() {
    // Hitung stats dari data asli (bukan filtered)
    final totalTransaksi = _list.length;
    final totalNasabah = _list
        .map((s) => s.nasabahId)
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet()
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Summary Stats ───────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Row(
            children: [
              Expanded(child: _statCard(
                icon: Icons.people_alt_rounded,
                label: 'Total Nasabah',
                value: totalNasabah.toString(),
              )),
              const SizedBox(width: 12),
              Expanded(child: _statCard(
                icon: Icons.receipt_long_rounded,
                label: 'Total Transaksi',
                value: totalTransaksi.toString(),
              )),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // ── Search ───────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: CustomSearchBar(
            controller: _searchController,
            hintText: 'Cari nama nasabah, petugas...',
            searchQuery: _searchQuery,
            onChanged: (v) => setState(() => _searchQuery = v),
            onClear: () => setState(() {
              _searchController.clear();
              _searchQuery = '';
            }),
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _statCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha:0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF013236).withValues(alpha:0.08),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF013236).withValues(alpha:0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: const Color(0xFF013236)),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF013236),
                  height: 1.1,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10,
                  color: const Color(0xFF013236).withValues(alpha:0.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: const Color(0xFF013236).withValues(alpha:0.55),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF013236),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBanner() {
    final status = _headerData!['status_penimbangan'] ?? 'aktif';
    final startedBy = (_headerData!['started_by'] ?? '').toString().trim();
    final endedBy = (_headerData!['ended_by'] ?? '').toString().trim();

    String? startedAtStr;
    if (_headerData!['started_at'] != null) {
       try {
         final dt = DateTime.parse(_headerData!['started_at']).toLocal();
         startedAtStr = DateFormat('EEEE, dd MMMM yyyy HH:mm', 'id_ID').format(dt);
       } catch (_) {}
    }

    String? endedAtStr;
    if (_headerData!['ended_at'] != null) {
       try {
         final dt = DateTime.parse(_headerData!['ended_at']).toLocal();
         endedAtStr = DateFormat('EEEE, dd MMMM yyyy HH:mm', 'id_ID').format(dt);
       } catch (_) {}
    }

    final isSelesai    = status == 'selesai';
    final isDibatalkan = status == 'dibatalkan';
    final isPending    = status == 'pending';

    final Color badgeBg    = isSelesai    ? const Color(0xFFE8F5E9)
                           : isDibatalkan ? const Color(0xFFFFEEEA)
                           : isPending    ? const Color(0xFFE8F5E9)
                           :                const Color(0xFFE3F2FD);
    final Color badgeColor = isSelesai    ? const Color(0xFF4EA771)
                           : isDibatalkan ? const Color(0xFFFF5A36)
                           : isPending    ? const Color(0xFF4EA771)
                           :                const Color(0xFF1E88E5);
    final String badgeLabel = isSelesai    ? 'SELESAI'
                            : isDibatalkan ? 'DIBATALKAN'
                            : isPending    ? 'MENDATANG'
                            :                'AKTIF';

    final hasInfoRows = startedAtStr != null ||
        startedBy.isNotEmpty ||
        endedAtStr != null ||
        endedBy.isNotEmpty;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha:0.5),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          width: 1,
          color: const Color(0xFF013236).withValues(alpha:0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(22),
                topRight: Radius.circular(22),
              ),
              border: hasInfoRows
                  ? Border(
                      bottom: BorderSide(
                        color: const Color(0xFF013236).withValues(alpha:0.04),
                        width: 1,
                      ),
                    )
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF013236).withValues(alpha:0.06),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.scale_rounded,
                      color: Color(0xFF013236), size: 16),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Sesi Penimbangan',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF013236),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'ID: ${_headerData!['penimbangan_id'] ?? widget.penimbanganId}',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF013236).withValues(alpha:0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    badgeLabel,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: badgeColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (hasInfoRows)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (startedAtStr != null) _infoRow('Sesi Dibuka', startedAtStr),
                  if (startedBy.isNotEmpty) _infoRow('Dibuka Oleh', startedBy),
                  if (endedAtStr != null)
                    _infoRow(isDibatalkan ? 'Sesi Dibatalkan' : 'Sesi Ditutup', endedAtStr),
                  if (endedBy.isNotEmpty)
                    _infoRow(isDibatalkan ? 'Dibatalkan Oleh' : 'Ditutup Oleh', endedBy),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAlasanPembatalanCard() {
    final alasan = (_headerData?['alasan_pembatalan'] ?? '').toString().trim();
    if (alasan.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          width: 1,
          color: const Color(0xFF013236).withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Alasan Pembatalan',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF013236),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF013236).withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              alasan,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12.5,
                height: 1.5,
                color: const Color(0xFF013236).withValues(alpha: 0.75),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersiapanCard() {
    final data = _headerData!;

    String tanggalStr = '-';
    if (data['tanggal_sesi'] != null) {
      try {
        final dt = DateTime.parse(data['tanggal_sesi']).toLocal();
        tanggalStr = DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(dt);
      } catch (_) {}
    }

    String? fmtJam(dynamic raw) {
      final s = (raw ?? '').toString();
      if (s.length < 5) return null;
      return s.substring(0, 5).replaceAll(':', '.');
    }

    final jamMulai = fmtJam(data['jam_mulai']);
    final jamSelesai = fmtJam(data['jam_selesai']);
    final jamStr = (jamMulai != null && jamSelesai != null)
        ? '$jamMulai - $jamSelesai WIB'
        : null;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          width: 1,
          color: const Color(0xFF4EA771).withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(25, 18, 25, 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4EA771),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Icon(Icons.notifications,
                      color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Jangan lupa persiapkan bank sampah anda untuk sesi penimbangan pada:',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF013236),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF4EA771).withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  _persiapanRow(Icons.calendar_today_rounded, tanggalStr),
                  if (jamStr != null) ...[
                    Divider(height: 1, color: const Color(0xFF013236).withValues(alpha: 0.08)),
                    _persiapanRow(Icons.access_time_rounded, jamStr),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _persiapanRow(IconData icon, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 15, color: const Color(0xFF4EA771)),
          const SizedBox(width: 18),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF013236),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverList() {
    final filtered = _filtered;
    if (filtered.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(top: 40),
          child: Center(
            child: Text(
              'Tidak ada setoran yang cocok',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.grey[400]),
            ),
          ),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (_, i) => Padding(
            padding: EdgeInsets.only(bottom: i < filtered.length - 1 ? 10 : 0),
            child: _buildTile(filtered[i]),
          ),
          childCount: filtered.length,
        ),
      ),
    );
  }

  Widget _buildTile(SetoranSummary s) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DetailSetoranScreen(setoranId: s.setoranId),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          // 1. Warna Latar Semi-Transparan (Glassmorphic vibe)
          color: Colors.white.withValues(alpha:0.5),

          // 2. Sudut Rounded yang Cukup Besar (Modern & Friendly)
          borderRadius: BorderRadius.circular(25),

          // 3. Batas Garis Super Tipis & Halus (Magic Formula!)
          border: Border.all(
            width: 1,
            color: const Color(0xFF013236).withValues(alpha:0.1), // Brand color dengan opacity cuma 10%
          ),
        ),
        child: Row(
          children: [
            // Avatar icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF4EA771).withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_rounded, color: Color(0xFF4EA771), size: 20),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.namaNasabah,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF013236),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    s.transaksiTimestamp,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 6),
                  _chipInfo(Icons.category_outlined, '${s.totalItem} jenis'),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(Icons.chevron_right_rounded,
                color: Colors.grey[300], size: 20),
          ],
        ),
      ),
    );
  }

  Widget _chipInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 12, color: Colors.grey[400]),
        const SizedBox(width: 3),
        Text(
          text,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 80),
        Center(
          child: Column(
            children: [
              Icon(Icons.inbox_rounded, size: 56, color: Colors.grey[300]),
              const SizedBox(height: 14),
              Text(
                'Belum ada setoran',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Sesi penimbangan ini belum memiliki\ndata setoran nasabah.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: Colors.grey[400],
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildError() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 80),
        Center(
          child: Column(
            children: [
              Icon(Icons.error_outline_rounded, size: 56, color: Colors.grey[300]),
              const SizedBox(height: 14),
              Text(
                _errorMsg!,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _fetchData,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Coba Lagi',
                    style: TextStyle(fontFamily: 'Poppins')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4EA771),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
