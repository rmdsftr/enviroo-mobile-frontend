import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:enviroo/config/api_config.dart';
import 'package:enviroo/providers/auth_provider.dart';
import 'package:enviroo/widgets/topbar_back.dart';

// ─── Models ──────────────────────────────────────────────────────────────────

class SetoranHeader {
  final String setoranId;
  final String namaPetugas;
  final String namaNasabah;
  final String transaksiTimestamp;
  final int totalItem;
  final double totalPoin;       // backend: float64
  final String statusSetoran;

  SetoranHeader({
    required this.setoranId,
    required this.namaPetugas,
    required this.namaNasabah,
    required this.transaksiTimestamp,
    required this.totalItem,
    required this.totalPoin,
    required this.statusSetoran,
  });

  factory SetoranHeader.fromJson(Map<String, dynamic> json) {
    String timestamp = '-';
    if (json['transaksi_timestamp'] != null) {
      try {
        timestamp = '${DateFormat('EEEE, dd MMMM yyyy HH:mm', 'id_ID')
            .format(DateTime.parse(json['transaksi_timestamp']))} WIB';
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
      totalPoin: (json['total_poin'] as num? ?? 0).toDouble(),
      statusSetoran: json['status_setoran'] ?? 'pending',
    );
  }
}

class SetoranItem {
  final String namaSampah;
  final double qty;           // backend: float64
  final double nilaiPoin;     // backend: float64
  final double subtotalPoin;  // backend: float64

  SetoranItem({
    required this.namaSampah,
    required this.qty,
    required this.nilaiPoin,
    required this.subtotalPoin,
  });

  factory SetoranItem.fromJson(Map<String, dynamic> json) {
    return SetoranItem(
      namaSampah:   json['nama_sampah'] ?? '-',
      qty:          (json['qty']           as num? ?? 0).toDouble(),
      nilaiPoin:    (json['nilai_poin']    as num? ?? 0).toDouble(),
      subtotalPoin: (json['subtotal_poin'] as num? ?? 0).toDouble(),
    );
  }

  /// Format angka: hilangkan desimal jika bulat (1.0 → "1", 1.5 → "1,5")
  static String _fmt(double v) {
    if (v == v.truncateToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(2).replaceAll('.', ',');
  }

  String get qtyFmt          => _fmt(qty);
  String get nilaiPoinFmt    => _fmt(nilaiPoin);
  String get subtotalPoinFmt => _fmt(subtotalPoin);
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

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final token = auth.currentUser?.accessToken ?? '';

    try {
      final uri = Uri.parse(
          '${ApiConfig.detailSetoranNasabahUrl}/${widget.setoranId}');
      final response = await http.get(uri, headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token.isNotEmpty) 'Authorization': 'Bearer $token',
      });

      if (!mounted) return;

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) {
        final data = body['data'] as Map<String, dynamic>;
        setState(() {
          _header = SetoranHeader.fromJson(
              data['header'] as Map<String, dynamic>);
          final rawItems = data['items'] as List? ?? [];
          _items = rawItems.map((e) => SetoranItem.fromJson(e)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMsg = body['message'] ?? 'Gagal memuat detail setoran';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMsg = 'Terjadi kesalahan: $e';
        _isLoading = false;
      });
    }
  }

  // ─── Format helpers ───────────────────────────────────────────────────────

  String _formatPoin(double value) {
    if (value == value.truncateToDouble()) {
      // Bilangan bulat — format dengan pemisah ribuan
      final formatted = value.toInt().toString()
          .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
      return '$formatted poin';
    }
    // Desimal
    final intPart = value.toInt().toString()
        .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
    final dec = (value - value.truncateToDouble()).toStringAsFixed(2).substring(1);
    return '$intPart$dec poin';
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
      body: SafeArea(
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
          )
        ],
      ),
      child: Column(
        children: [
          // ── Header card ──────────────────────────────────────────────────
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
                    const Text(
                      'Struk Setoran',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
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
                  'Poin/unit',
                  'Subtotal',
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
                        item.nilaiPoinFmt,
                        item.subtotalPoinFmt,
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
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FFF4),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: const Color(0xFF4EA771).withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.stars_rounded,
                              color: Color(0xFF4EA771), size: 18),
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
                        _formatPoin(h.totalPoin),
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF4EA771),
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
              width: 36,
              child: Text(col2, style: style, textAlign: TextAlign.center)),
          SizedBox(
              width: 56,
              child: Text(col3, style: style, textAlign: TextAlign.right)),
          SizedBox(
              width: 64,
              child: Text(col4, style: style, textAlign: TextAlign.right)),
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
