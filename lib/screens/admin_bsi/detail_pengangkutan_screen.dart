import 'package:enviroo/providers/auth_provider.dart';
import 'package:enviroo/services/pengangkutan_service.dart';
import 'package:enviroo/widgets/topbar_back.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

// ─── Models ─────────────────────────────────────────────────────────────────

class _PengangkutanHeader {
  final String paketId;
  final String pengangkutanId;
  final String namaBsi;
  final String namaBsu;
  final String namaAdminBsi;
  final int totalItem;
  final double totalPoin;
  final String statusSetoran;
  final String createdAt;

  _PengangkutanHeader({
    required this.paketId,
    required this.pengangkutanId,
    required this.namaBsi,
    required this.namaBsu,
    required this.namaAdminBsi,
    required this.totalItem,
    required this.totalPoin,
    required this.statusSetoran,
    required this.createdAt,
  });

  factory _PengangkutanHeader.fromJson(Map<String, dynamic> json) {
    String createdAt = '-';
    if (json['created_at'] != null) {
      try {
        createdAt =
            '${DateFormat('EEEE, dd MMMM yyyy HH:mm', 'id_ID').format(DateTime.parse(json['created_at'].toString()))} WIB';
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
      totalPoin: (json['total_poin'] as num?)?.toDouble() ?? 0.0,
      statusSetoran: json['status_setoran'] ?? 'pending',
      createdAt: createdAt,
    );
  }
}

class _PengangkutanItem {
  final String namaSampah;
  final String satuan;
  final double qty;
  final double nilaiPoin;
  final double subtotalPoin;

  _PengangkutanItem({
    required this.namaSampah,
    required this.satuan,
    required this.qty,
    required this.nilaiPoin,
    required this.subtotalPoin,
  });

  factory _PengangkutanItem.fromJson(Map<String, dynamic> json) {
    return _PengangkutanItem(
      namaSampah: json['nama_sampah'] ?? '-',
      satuan: json['satuan'] ?? '-',
      qty: (json['qty'] as num?)?.toDouble() ?? 0.0,
      nilaiPoin: (json['nilai_poin'] as num?)?.toDouble() ?? 0.0,
      subtotalPoin: (json['subtotal_poin'] as num?)?.toDouble() ?? 0.0,
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

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final token = auth.currentUser?.accessToken ?? '';

    final res =
        await PengangkutanService.detailSampah(widget.pengangkutanId, token);
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
      backgroundColor: const Color(0xFFF7F9F8),
      body: SafeArea(
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
                                const EdgeInsets.fromLTRB(20, 16, 20, 32),
                            child: _buildStrukCard(),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStrukCard() {
    final h = _header!;
    final statusColor = _statusColor(h.statusSetoran);
    final statusBg = _statusBg(h.statusSetoran);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Header gradient ─────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF013236), Color(0xFF025059)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF06C0C9).withOpacity(0.18),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: const Icon(
                            Icons.local_shipping_rounded,
                            color: Color(0xFF06C0C9),
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Struk Pengangkutan',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
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
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _headerRow(Icons.store_rounded, 'BSU', h.namaBsu),
                const SizedBox(height: 10),
                _headerRow(Icons.account_balance_rounded, 'BSI', h.namaBsi),
                const SizedBox(height: 10),
                _headerRow(
                    Icons.badge_rounded, 'Petugas BSI', h.namaAdminBsi),
                const SizedBox(height: 10),
                _headerRow(
                    Icons.access_time_rounded, 'Waktu', h.createdAt),
                const SizedBox(height: 10),
                _headerRow(Icons.confirmation_num_rounded, 'ID Sesi',
                    h.pengangkutanId),
              ],
            ),
          ),

          // ── Perforated separator ────────────────────────────────────────
          _buildPerforated(),

          // ── Items ───────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Rincian Sampah',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF013236),
                  ),
                ),
                const SizedBox(height: 10),
                _tableRow(
                  'Jenis Sampah',
                  'Qty',
                  'Poin/unit',
                  'Subtotal',
                  isHeader: true,
                ),
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
                          _fmt(item.nilaiPoin),
                          _fmt(item.subtotalPoin),
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

          // ── Perforated separator ────────────────────────────────────────
          _buildPerforated(),

          // ── Total ───────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
            child: Column(
              children: [
                _summaryRow('Total Jenis Sampah', '${h.totalItem} jenis'),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6FAFB),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: const Color(0xFF06C0C9).withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.stars_rounded,
                              color: Color(0xFF06C0C9), size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Total Poin',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF013236),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${_fmt(h.totalPoin)} poin',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF06C0C9),
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
    );
  }

  Widget _headerRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: Colors.white54),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10,
                  color: Colors.white54,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPerforated() {
    return Row(
      children: [
        _halfCircle(isLeft: true),
        Expanded(
          child: LayoutBuilder(
            builder: (_, c) => Flex(
              direction: Axis.horizontal,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                (c.maxWidth / 10).floor(),
                (i) => SizedBox(
                  width: 5,
                  height: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: Colors.grey[300]),
                  ),
                ),
              ),
            ),
          ),
        ),
        _halfCircle(isLeft: false),
      ],
    );
  }

  Widget _halfCircle({required bool isLeft}) {
    return Container(
      width: 16,
      height: 32,
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9F8),
        borderRadius: BorderRadius.only(
          topRight: isLeft ? const Radius.circular(16) : Radius.zero,
          bottomRight: isLeft ? const Radius.circular(16) : Radius.zero,
          topLeft: isLeft ? Radius.zero : const Radius.circular(16),
          bottomLeft: isLeft ? Radius.zero : const Radius.circular(16),
        ),
      ),
    );
  }

  Widget _tableRow(
    String col1,
    String col2,
    String col3,
    String col4, {
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
            width: 56,
            child: Text(col2, style: style, textAlign: TextAlign.center),
          ),
          SizedBox(
            width: 56,
            child: Text(col3, style: style, textAlign: TextAlign.right),
          ),
          SizedBox(
            width: 64,
            child: Text(col4, style: style, textAlign: TextAlign.right),
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
