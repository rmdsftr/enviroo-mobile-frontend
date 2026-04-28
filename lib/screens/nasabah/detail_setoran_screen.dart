import 'dart:convert';
import 'package:enviroo/config/api_config.dart';
import 'package:enviroo/providers/auth_provider.dart';
import 'package:enviroo/widgets/topbar_back.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

// ── Models ───────────────────────────────────────────────────────────────────
class _DetailHeader {
  final String setoranId;
  final String namaPetugas;
  final String namaNasabah;
  final DateTime transaksiTimestamp;
  final int totalItem;
  final double totalPoin;
  final String statusSetoran;

  _DetailHeader({
    required this.setoranId,
    required this.namaPetugas,
    required this.namaNasabah,
    required this.transaksiTimestamp,
    required this.totalItem,
    required this.totalPoin,
    required this.statusSetoran,
  });

  factory _DetailHeader.fromJson(Map<String, dynamic> j) => _DetailHeader(
        setoranId: j['setoran_id'] ?? '',
        namaPetugas: j['nama_petugas'] ?? '',
        namaNasabah: j['nama_nasabah'] ?? '',
        transaksiTimestamp:
            DateTime.tryParse(j['transaksi_timestamp'] ?? '') ?? DateTime.now(),
        totalItem: j['total_item'] ?? 0,
        totalPoin: (j['total_poin'] as num?)?.toDouble() ?? 0.0,
        statusSetoran: j['status_setoran'] ?? '',
      );
}

class _ItemSetoran {
  final String namaSampah;
  final int qty;
  final double nilaiPoin;
  final double subtotalPoin;

  _ItemSetoran({
    required this.namaSampah,
    required this.qty,
    required this.nilaiPoin,
    required this.subtotalPoin,
  });

  factory _ItemSetoran.fromJson(Map<String, dynamic> j) => _ItemSetoran(
        namaSampah: j['nama_sampah'] ?? '',
        qty: j['qty'] ?? 0,
        nilaiPoin: (j['nilai_poin'] as num?)?.toDouble() ?? 0.0,
        subtotalPoin: (j['subtotal_poin'] as num?)?.toDouble() ?? 0.0,
      );
}

// ── Screen ───────────────────────────────────────────────────────────────────
class DetailSetoranScreen extends StatefulWidget {
  final String setoranId;
  const DetailSetoranScreen({super.key, required this.setoranId});

  @override
  State<DetailSetoranScreen> createState() => _DetailSetoranScreenState();
}

class _DetailSetoranScreenState extends State<DetailSetoranScreen> {
  static const _teal = Color(0xFF013236);
  static const _accent = Color(0xFF4EA771);

  _DetailHeader? _header;
  List<_ItemSetoran> _items = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final token = auth.currentUser?.accessToken ?? '';

    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.detailSetoranNasabahUrl}/${widget.setoranId}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (!mounted) return;

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final data = body['data'];
        setState(() {
          _header = _DetailHeader.fromJson(data['header'] ?? {});
          final List items = data['items'] ?? [];
          _items = items.map((e) => _ItemSetoran.fromJson(e)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Gagal memuat detail setoran';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Tidak dapat terhubung ke server';
        _isLoading = false;
      });
    }
  }

  String _fmt(double poin) {
    final intPart = poin.truncate();
    final dec = poin - intPart;
    final formatted = NumberFormat('#,###', 'id_ID').format(intPart);
    if (dec > 0) return '$formatted${dec.toStringAsFixed(2).substring(1)}';
    return formatted;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      body: SafeArea(
        child: Column(
          children: [
            TopBarBack(title: 'Detail Setoran'),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: _accent))
                  : _error != null
                      ? _buildError()
                      : _buildStruk(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStruk() {
    final h = _header!;
    final isSuccess = h.statusSetoran == 'berhasil';
    final statusColor = isSuccess ? _accent : Colors.orange;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        children: [
          // ── Status Badge & Icon ──────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF013236), Color(0xFF025A62)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: _teal.withOpacity(0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isSuccess ? Icons.check_circle_rounded : Icons.info_rounded,
                    color: statusColor,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  isSuccess ? 'Setoran Berhasil' : h.statusSetoran.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('EEEE, dd MMMM yyyy · HH:mm', 'id_ID')
                      .format(h.transaksiTimestamp.toLocal()),
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 20),
                // Total Poin highlight
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.eco_rounded, color: Color(0xFF94DF0C), size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '${_fmt(h.totalPoin)} Poin',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w800,
                          fontSize: 22,
                          color: Color(0xFF94DF0C),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Info Card ────────────────────────────────────────────────────
          _buildInfoCard(h),

          const SizedBox(height: 16),

          // ── Items Card ───────────────────────────────────────────────────
          _buildItemsCard(),
        ],
      ),
    );
  }

  Widget _buildInfoCard(_DetailHeader h) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _teal.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoRow(Icons.receipt_long_rounded, 'ID Setoran', h.setoranId),
          _divider(),
          _infoRow(Icons.person_rounded, 'Nasabah', h.namaNasabah),
          _divider(),
          _infoRow(Icons.badge_rounded, 'Petugas', h.namaPetugas),
          _divider(),
          _infoRow(Icons.inventory_2_rounded, 'Jumlah Item', '${h.totalItem} item sampah'),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: _accent.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 15, color: _accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    color: _teal.withOpacity(0.45),
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: _teal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Divider(color: _teal.withOpacity(0.06), height: 1);

  Widget _buildItemsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _teal.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header tabel
          Row(
            children: const [
              Icon(Icons.list_alt_rounded, color: _accent, size: 18),
              SizedBox(width: 8),
              Text(
                'Detail Item Sampah',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: _teal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _teal.withOpacity(0.04),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Expanded(
                  flex: 4,
                  child: Text(
                    'Nama Sampah',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _teal,
                    ),
                  ),
                ),
                const SizedBox(
                  width: 36,
                  child: Text(
                    'Qty',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w600, color: _teal),
                  ),
                ),
                const SizedBox(
                  width: 52,
                  child: Text(
                    'Harga',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w600, color: _teal),
                  ),
                ),
                SizedBox(
                  width: 58,
                  child: Text(
                    'Subtotal',
                    textAlign: TextAlign.right,
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w600, color: _accent),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // Rows
          ..._items.asMap().entries.map((entry) {
            final i = entry.key;
            final item = entry.value;
            final isEven = i % 2 == 0;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isEven ? Colors.transparent : _teal.withOpacity(0.02),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Text(
                      item.namaSampah,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: _teal,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 36,
                    child: Text(
                      '${item.qty}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: _teal.withOpacity(0.6),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 52,
                    child: Text(
                      _fmt(item.nilaiPoin),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: _teal.withOpacity(0.6),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 58,
                    child: Text(
                      _fmt(item.subtotalPoin),
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _accent,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          // Total row
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: _accent.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Total Poin Diperoleh',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _teal,
                    ),
                  ),
                ),
                Text(
                  '${_fmt(_header!.totalPoin)} poin',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: _accent,
                  ),
                ),
              ],
            ),
          ),
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
            Icon(Icons.wifi_off_rounded, size: 40, color: Colors.red.withOpacity(0.5)),
            const SizedBox(height: 12),
            Text(
              _error ?? 'Terjadi kesalahan',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: _teal.withOpacity(0.5)),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchDetail,
              style: ElevatedButton.styleFrom(
                backgroundColor: _teal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Coba Lagi', style: TextStyle(fontFamily: 'Poppins')),
            ),
          ],
        ),
      ),
    );
  }
}
