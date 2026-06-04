import 'package:enviroo/screens/lihat_foto_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:enviroo/services/setoran_service.dart';
import 'package:enviroo/widgets/topbar_back.dart';

// ─── Models ──────────────────────────────────────────────────────────────────

class SetoranHeader {
  final String setoranId;
  final String namaPetugas;
  final String namaNasabah;
  final String transaksiTimestamp;
  final int totalItem;
  final String statusSetoran;
  final String buktiViaManual;

  SetoranHeader({
    required this.setoranId,
    required this.namaPetugas,
    required this.namaNasabah,
    required this.transaksiTimestamp,
    required this.totalItem,
    required this.statusSetoran,
    required this.buktiViaManual,
  });

  factory SetoranHeader.fromJson(Map<String, dynamic> json) {
    String timestamp = '-';
    if (json['transaksi_timestamp'] != null) {
      try {
        timestamp = DateFormat('EEEE, dd MMMM yyyy HH:mm', 'id_ID')
            .format(DateTime.parse(json['transaksi_timestamp']));
      } catch (_) {
        timestamp = json['transaksi_timestamp'].toString();
      }
    }
    return SetoranHeader(
      setoranId: json['setoran_id'] ?? '',
      namaPetugas: json['nama_petugas'] ?? '-',
      namaNasabah: json['nama_nasabah'] ?? '-',
      transaksiTimestamp: timestamp,
      totalItem: (json['total_item'] as num? ?? 0).toInt(),
      statusSetoran: json['status_setoran'] ?? 'pending',
      buktiViaManual: json['bukti_via_manual'] ?? '',
    );
  }
}

class SetoranItem {
  final String namaSampah;
  final double qty;
  final String satuan;

  SetoranItem({
    required this.namaSampah,
    required this.qty,
    required this.satuan,
  });

  factory SetoranItem.fromJson(Map<String, dynamic> json) {
    return SetoranItem(
      namaSampah: json['nama_sampah'] ?? '-',
      qty:        (json['qty'] as num? ?? 0).toDouble(),
      satuan:     json['satuan'] ?? '',
    );
  }

  static String _fmt(double v) {
    if (v == v.truncateToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(2).replaceAll('.', ',');
  }

  String get qtyFmt => _fmt(qty);
}

// ─── Screen ──────────────────────────────────────────────────────────────────

class StrukSetoranNasabahScreen extends StatefulWidget {
  final String setoranId;
  final String namaNasabah;

  const StrukSetoranNasabahScreen({
    Key? key,
    required this.setoranId,
    required this.namaNasabah,
  }) : super(key: key);

  @override
  State<StrukSetoranNasabahScreen> createState() =>
      _StrukSetoranNasabahScreenState();
}

class _StrukSetoranNasabahScreenState extends State<StrukSetoranNasabahScreen> {
  bool _isLoading = true;
  SetoranHeader? _header;
  List<SetoranItem> _items = [];
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchData());
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    final res = await SetoranService.getDetailSetoranNasabah(widget.setoranId);
    if (!mounted) return;
    if (res['success'] == true) {
      final data = res['data'] as Map<String, dynamic>;
      setState(() {
        _header = SetoranHeader.fromJson(data['header'] as Map<String, dynamic>);
        final rawItems = data['items'] as List? ?? [];
        _items = rawItems.map((e) => SetoranItem.fromJson(e)).toList();
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMsg = res['message'] ?? 'Gagal memuat detail setoran';
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

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F8),
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
            TopBarBack(title: 'Struk Setoran'),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFF4EA771)))
                  : _errorMsg != null
                      ? _buildError()
                      : RefreshIndicator(
                          onRefresh: _fetchData,
                          color: const Color(0xFF4EA771),
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                            child: Column(
                              children: [
                                _buildStrukCard(),
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

  Widget _buildStrukCard() {
    final h = _header!;
    final statusColor = _statusColor(h.statusSetoran);
    final statusBg = _statusBg(h.statusSetoran);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // ── Header card ──────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              border: Border(
                bottom: BorderSide(
                  color: const Color(0xFF013236).withOpacity(0.04),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top Header (Center) ─────────────────────────
                Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: statusBg,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(_statusIcon(h.statusSetoran), size: 30, color: statusColor),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Setoran ${_statusLabel(h.statusSetoran)}',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Setoran ID: ${h.setoranId}',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF013236).withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                _headerRow(Icons.person_rounded, 'Nasabah', h.namaNasabah),
                const SizedBox(height: 10),
                _headerRow(
                    Icons.badge_rounded, 'Petugas', h.namaPetugas),
                const SizedBox(height: 10),
                _headerRow(Icons.access_time_rounded, 'Waktu',
                    h.transaksiTimestamp),
              ],
            ),
          ),

          // ── Perforated separator ─────────────────────────────────────────
          _buildPerforated(),

          // ── Items table ──────────────────────────────────────────────────
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
                // Table header
                _tableRow(
                  'Jenis Sampah',
                  'Qty',
                  'Satuan',
                  isHeader: true,
                ),
                const Divider(height: 1, color: Color(0xFFEEEEEE)),
                const SizedBox(height: 4),
                // Items
                ..._items.asMap().entries.map((entry) {
                  final item = entry.value;
                  return Column(
                    children: [
                      _tableRow(
                        item.namaSampah,
                        item.qtyFmt,
                        item.satuan,
                      ),
                      if (entry.key < _items.length - 1)
                        const Divider(
                            height: 1,
                            color: Color(0xFFF5F5F5)),
                    ],
                  );
                }).toList(),
              ],
            ),
          ),

          // ── Perforated separator ─────────────────────────────────────────
          _buildPerforated(),

          // ── Total ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
            child: Column(
              children: [
                _summaryRow('Total Jenis Sampah', '${h.totalItem} jenis'),
              ],
            ),
          ),

          // ── Bukti Foto ───────────────────────────────────────────────────
          if (h.buktiViaManual.isNotEmpty) ...[
            _buildPerforated(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bukti Foto Nasabah',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF013236),
                    ),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LihatFotoScreen(
                          photoUrl: h.buktiViaManual,
                          nama: 'Bukti Foto Nasabah',
                        ),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AspectRatio(
                        aspectRatio: 4 / 3,
                        child: Image.network(
                          h.buktiViaManual,
                          fit: BoxFit.cover,
                          loadingBuilder: (_, child, p) => p == null
                              ? child
                              : const Center(
                                  child: CircularProgressIndicator(
                                      color: Color(0xFF4EA771))),
                          errorBuilder: (_, __, ___) => Container(
                            color: const Color(0xFFF0F0F0),
                            child: const Center(
                              child: Icon(Icons.broken_image_rounded,
                                  color: Colors.grey, size: 36),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _headerRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF013236).withOpacity(0.5)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10,
                  color: const Color(0xFF013236).withOpacity(0.5),
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12.5,
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
                    decoration: BoxDecoration(
                        color: Colors.grey[300]),
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
    String col3, {
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
              width: 44,
              child: Text(col2, style: style, textAlign: TextAlign.center)),
          SizedBox(
              width: 60,
              child: Text(col3, style: style, textAlign: TextAlign.right)),
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
    );
  }
}
