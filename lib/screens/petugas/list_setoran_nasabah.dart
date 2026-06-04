import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:enviroo/services/setoran_service.dart';
import 'package:enviroo/screens/petugas/struk_setoran_nasabah.dart';
import 'package:enviroo/widgets/filter_chip_row.dart';
import 'package:enviroo/widgets/search.dart';
import 'package:enviroo/widgets/topbar_back.dart';

// ─── Model ───────────────────────────────────────────────────────────────────

class SetoranSummary {
  final String setoranId;
  final String namaPetugas;
  final String? nasabahId;
  final String namaNasabah;
  final String transaksiTimestamp;
  final int totalItem;
  final String statusSetoran;

  SetoranSummary({
    required this.setoranId,
    required this.namaPetugas,
    this.nasabahId,
    required this.namaNasabah,
    required this.transaksiTimestamp,
    required this.totalItem,
    required this.statusSetoran,
  });

  factory SetoranSummary.fromJson(Map<String, dynamic> json) {
    String timestamp = '-';
    if (json['transaksi_timestamp'] != null) {
      try {
        timestamp = DateFormat('EEEE, dd MMMM yyyy HH:mm', 'id_ID')
            .format(DateTime.parse(json['transaksi_timestamp']));
      } catch (_) {
        timestamp = json['transaksi_timestamp'].toString();
      }
    }
    return SetoranSummary(
      setoranId: json['setoran_id'] ?? '',
      namaPetugas: json['nama_petugas'] ?? '-',
      nasabahId: json['nasabah_id'] ?? '',
      namaNasabah: json['nama_nasabah'] ?? '-',
      transaksiTimestamp: timestamp,
      totalItem: (json['total_item'] ?? 0) as int,
      statusSetoran: json['status_setoran'] ?? 'pending',
    );
  }
}

// ─── Screen ──────────────────────────────────────────────────────────────────

class ListSetoranNasabahScreen extends StatefulWidget {
  final String penimbanganId;
  final String tanggalPenimbangan;

  const ListSetoranNasabahScreen({
    Key? key,
    required this.penimbanganId,
    required this.tanggalPenimbangan,
  }) : super(key: key);

  @override
  State<ListSetoranNasabahScreen> createState() =>
      _ListSetoranNasabahScreenState();
}

class _ListSetoranNasabahScreenState extends State<ListSetoranNasabahScreen> {
  bool _isLoading = true;
  List<SetoranSummary> _list = [];
  Map<String, dynamic>? _headerData;
  String? _errorMsg;

  // ─── Search & Filter ──────────────────────────────────────────────────────
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedStatus = 'semua';

  List<SetoranSummary> get _filtered {
    return _list.where((s) {
      final matchStatus = _selectedStatus == 'semua' ||
          s.statusSetoran.toLowerCase() == _selectedStatus;
      final q = _searchQuery.toLowerCase();
      final matchSearch = q.isEmpty ||
          s.namaNasabah.toLowerCase().contains(q) ||
          s.namaPetugas.toLowerCase().contains(q) ||
          s.setoranId.toLowerCase().contains(q);
      return matchStatus && matchSearch;
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

    final res = await SetoranService.getListSetoranPenimbangan(widget.penimbanganId);
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

  // ─── Status helpers ───────────────────────────────────────────────────────

  Color _statusColor(String status) {
    switch (status) {
      case 'berhasil':
        return const Color(0xFF4EA771);
      case 'pending':
        return const Color(0xFFFAA324);
      default:
        return Colors.red.shade400;
    }
  }

  Color _statusBg(String status) {
    switch (status) {
      case 'berhasil':
        return const Color(0xFFE8F5E9);
      case 'pending':
        return const Color(0xFFFFF8E1);
      default:
        return Colors.red.withValues(alpha:0.08);
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'berhasil':
        return Icons.check_circle_outline_rounded;
      case 'pending':
        return Icons.hourglass_empty_rounded;
      default:
        return Icons.cancel_outlined;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'berhasil':
        return 'Berhasil';
      case 'pending':
        return 'Pending';
      default:
        return 'Gagal';
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
                          if (_headerData != null)
                            SliverToBoxAdapter(child: _buildListHeader()),
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
        const SizedBox(height: 10),
        // ── Filter status ─────────────────────────────────────────────────
        FilterChipRow<String>(
          items: const [
            FilterChipItem(value: 'semua',    label: 'Semua'),
            FilterChipItem(value: 'berhasil', label: 'Berhasil'),
            FilterChipItem(value: 'pending',  label: 'Pending'),
            FilterChipItem(value: 'gagal',    label: 'Gagal'),
          ],
          selectedValue: _selectedStatus,
          onSelected: (v) => setState(() => _selectedStatus = v),
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
    final startedBy = _headerData!['started_by'] ?? '-';
    final endedBy = _headerData!['ended_by'];
    
    String startedAtStr = widget.tanggalPenimbangan;
    if (_headerData!['started_at'] != null) {
       try {
         final dt = DateTime.parse(_headerData!['started_at']);
         startedAtStr = DateFormat('EEEE, dd MMMM yyyy HH:mm', 'id_ID').format(dt);
       } catch (_) {}
    }

    String? endedAtStr;
    if (_headerData!['ended_at'] != null) {
       try {
         final dt = DateTime.parse(_headerData!['ended_at']);
         endedAtStr = DateFormat('EEEE, dd MMMM yyyy HH:mm', 'id_ID').format(dt);
       } catch (_) {}
    }

    final isSelesai    = status == 'selesai';
    final isDibatalkan = status == 'dibatalkan';
    final isClosed     = isSelesai || isDibatalkan;

    final Color badgeBg    = isSelesai    ? const Color(0xFFE8F5E9)
                           : isDibatalkan ? const Color(0xFFFFEEEA)
                           :                const Color(0xFFE3F2FD);
    final Color badgeColor = isSelesai    ? const Color(0xFF4EA771)
                           : isDibatalkan ? const Color(0xFFFF5A36)
                           :                const Color(0xFF1E88E5);
    final String badgeLabel = isSelesai    ? 'SELESAI'
                            : isDibatalkan ? 'DIBATALKAN'
                            :                'AKTIF';

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
              border: Border(
                bottom: BorderSide(
                  color: const Color(0xFF013236).withValues(alpha:0.04),
                  width: 1,
                ),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow('Sesi Dibuka', startedAtStr),
                _infoRow('Dibuka Oleh', startedBy),
                if (isClosed && endedAtStr != null)
                  _infoRow(isDibatalkan ? 'Sesi Dibatalkan' : 'Sesi Ditutup', endedAtStr),
                if (isClosed && endedBy != null && endedBy.toString().trim().isNotEmpty)
                  _infoRow(isDibatalkan ? 'Dibatalkan Oleh' : 'Ditutup Oleh', endedBy.toString()),
              ],
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
    final statusColor = _statusColor(s.statusSetoran);
    final statusBg = _statusBg(s.statusSetoran);
    final statusIcon = _statusIcon(s.statusSetoran);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StrukSetoranNasabahScreen(
            setoranId: s.setoranId,
            namaNasabah: s.namaNasabah,
          ),
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
                color: statusBg,
                shape: BoxShape.circle,
              ),
              child: Icon(statusIcon, color: statusColor, size: 20),
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
            // Status + chevron
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _statusLabel(s.statusSetoran),
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Icon(Icons.chevron_right_rounded,
                    color: Colors.grey[300], size: 20),
              ],
            ),
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
              Icon(Icons.wifi_off_rounded, size: 56, color: Colors.grey[300]),
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
