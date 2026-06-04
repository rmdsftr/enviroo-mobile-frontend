import 'package:enviroo/screens/admin_bsu/sesi_pengangkutan_screen.dart';
import 'package:enviroo/services/pengangkutan_service.dart';
import 'package:enviroo/widgets/topbar_back.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ─── Models ─────────────────────────────────────────────────────────────────

class _PengangkutanHeader {
  final String paketId;
  final String pengangkutanId;
  final String namaBsi;
  final String namaBsu;
  final String namaAdminBsi;
  final int totalItem;
  final String statusSetoran;
  final String createdAt;

  _PengangkutanHeader({
    required this.paketId,
    required this.pengangkutanId,
    required this.namaBsi,
    required this.namaBsu,
    required this.namaAdminBsi,
    required this.totalItem,
    required this.statusSetoran,
    required this.createdAt,
  });

  factory _PengangkutanHeader.fromJson(Map<String, dynamic> json) {
    String createdAt = '-';
    if (json['created_at'] != null) {
      try {
        createdAt =
            DateFormat('EEEE, dd MMMM yyyy HH:mm', 'id_ID').format(DateTime.parse(json['created_at'].toString()));
      } catch (_) {
        createdAt = json['created_at'].toString();
      }
    }
    return _PengangkutanHeader(
      paketId: json['paket_id'] ?? '',
      pengangkutanId: json['pengangkutan_id'] ?? '',
      namaBsi: json['nama_bsi'] ?? '-',
      namaBsu: json['nama_bsu'] ?? '-',
      namaAdminBsi: json['nama_admin_bsi'] ?? '-',
      totalItem: (json['total_item'] ?? 0) as int,
      statusSetoran: json['status_setoran'] ?? 'pending',
      createdAt: createdAt,
    );
  }
}

class _PengangkutanItem {
  final String namaSampah;
  final String satuan;
  final double qty;

  _PengangkutanItem({
    required this.namaSampah,
    required this.satuan,
    required this.qty,
  });

  factory _PengangkutanItem.fromJson(Map<String, dynamic> json) {
    return _PengangkutanItem(
      namaSampah: json['nama_sampah'] ?? '-',
      satuan: json['satuan'] ?? '-',
      qty: (json['qty'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

// ─── Screen ─────────────────────────────────────────────────────────────────

class DetailPengangkutanScreen extends StatefulWidget {
  final String pengangkutanId;
  final String namaBsu;

  const DetailPengangkutanScreen({
    super.key,
    required this.pengangkutanId,
    this.namaBsu = '',
  });

  @override
  State<DetailPengangkutanScreen> createState() =>
      _DetailPengangkutanScreenState();
}

class _DetailPengangkutanScreenState extends State<DetailPengangkutanScreen> {
  bool _isLoading = true;
  String? _errorMsg;
  _PengangkutanHeader? _header;
  List<_PengangkutanItem> _items = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
  }

  Future<void> _fetch() async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    final res =
        await PengangkutanService.detailSampah(widget.pengangkutanId);
    if (!mounted) return;

    if (res['success'] == true) {
      final data = res['data'] as Map<String, dynamic>?;
      if (data == null) {
        setState(() {
          _errorMsg = 'Data tidak ditemukan';
          _isLoading = false;
        });
        return;
      }
      setState(() {
        _header = _PengangkutanHeader.fromJson(
            data['header'] as Map<String, dynamic>);
        final List rawItems = data['items'] as List? ?? [];
        _items = rawItems
            .map((e) => _PengangkutanItem.fromJson(e as Map<String, dynamic>))
            .toList();
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMsg = res['message'] ?? 'Gagal memuat detail pengangkutan';
        _isLoading = false;
      });
    }
  }

  // ── Status helpers ───────────────────────────────────────────────────────
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
        return Colors.red.withOpacity(0.08);
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

  IconData _statusIcon(String status) {
    switch (status) {
      case 'berhasil':
        return Icons.check_circle_rounded;
      case 'pending':
        return Icons.hourglass_empty_rounded;
      default:
        return Icons.cancel_rounded;
    }
  }

  String _fmt(double value) {
    if (value == value.truncateToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(2).replaceAll('.', ',');
  }

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
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
              const TopBarBack(title: 'Detail Pengangkutan'),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFF06C0C9)))
                    : _errorMsg != null
                        ? _buildError()
                        : RefreshIndicator(
                            onRefresh: _fetch,
                            color: const Color(0xFF06C0C9),
                            child: SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding:
                                  const EdgeInsets.fromLTRB(20, 8, 20, 32),
                              child: Column(
                                children: [
                                  _buildHeroCard(),
                                  const SizedBox(height: 12),
                                  _buildInfoCard(),
                                  const SizedBox(height: 12),
                                  _buildRincianCard(),
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

  // ── Hero Card ────────────────────────────────────────────────────────────
  Widget _buildHeroCard() {
    final h = _header!;
    final statusColor = _statusColor(h.statusSetoran);
    final statusBg = _statusBg(h.statusSetoran);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Struk Pengangkutan',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF013236),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  h.pengangkutanId,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_statusIcon(h.statusSetoran),
                    size: 12, color: statusColor),
                const SizedBox(width: 4),
                Text(
                  _statusLabel(h.statusSetoran),
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Info Card ────────────────────────────────────────────────────────────
  Widget _buildInfoCard() {
    final h = _header!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoRow(Icons.store_rounded, 'BSU', h.namaBsu),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: Color(0xFFF0F0F0)),
          ),
          _infoRow(Icons.account_balance_rounded, 'BSI', h.namaBsi),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: Color(0xFFF0F0F0)),
          ),
          _infoRow(Icons.badge_rounded, 'Petugas BSI', h.namaAdminBsi),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SesiPengangkutanScreen(
                    pengangkutanId: widget.pengangkutanId,
                  ),
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF013236),
                side: const BorderSide(color: Color(0xFF013236), width: 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
                textStyle: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('Riwayat sesi pengangkutan'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF06C0C9).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 15, color: const Color(0xFF06C0C9)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF013236),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Rincian Sampah Card ──────────────────────────────────────────────────
  Widget _buildRincianCard() {
    final h = _header!;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF06C0C9).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.recycling_rounded,
                      size: 15, color: Color(0xFF06C0C9)),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Rincian Sampah',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF013236),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: Column(
              children: [
                _tableRow('Jenis Sampah', 'Qty', isHeader: true),
                const Divider(height: 1, color: Color(0xFFEEEEEE)),
                const SizedBox(height: 4),
                if (_items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    child: Center(
                      child: Text(
                        'Belum ada rincian sampah',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ),
                  )
                else
                  ..._items.asMap().entries.map((entry) {
                    final item = entry.value;
                    return Column(
                      children: [
                        _tableRow(
                          item.namaSampah,
                          '${_fmt(item.qty)} ${item.satuan}',
                        ),
                        if (entry.key < _items.length - 1)
                          const Divider(
                              height: 1, color: Color(0xFFF5F5F5)),
                      ],
                    );
                  }),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
            child: _summaryRow('Total Jenis Sampah', '${h.totalItem} jenis'),
          ),
        ],
      ),
    );
  }

  Widget _tableRow(
    String col1,
    String col2, {
    bool isHeader = false,
  }) {
    final style = TextStyle(
      fontFamily: 'Poppins',
      fontSize: isHeader ? 10.5 : 12,
      fontWeight: isHeader ? FontWeight.w600 : FontWeight.w400,
      color: isHeader ? Colors.grey[500] : const Color(0xFF013236),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(col1, style: style)),
          SizedBox(
            width: 90,
            child: Text(col2, style: style, textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            color: Colors.grey[500],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF013236),
          ),
        ),
      ],
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
              onPressed: _fetch,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Coba Lagi',
                  style: TextStyle(fontFamily: 'Poppins')),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF06C0C9),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
