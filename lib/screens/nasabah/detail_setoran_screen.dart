import 'package:enviroo/screens/lihat_foto_screen.dart';
import 'package:enviroo/services/setoran_service.dart';
import 'package:enviroo/widgets/topbar_back.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ── Models ───────────────────────────────────────────────────────────────────
class _DetailHeader {
  final String setoranId;
  final String namaPetugas;
  final String namaNasabah;
  final DateTime transaksiTimestamp;
  final int totalItem;
  final String statusSetoran;
  final String buktiViaManual;

  _DetailHeader({
    required this.setoranId,
    required this.namaPetugas,
    required this.namaNasabah,
    required this.transaksiTimestamp,
    required this.totalItem,
    required this.statusSetoran,
    required this.buktiViaManual,
  });

  factory _DetailHeader.fromJson(Map<String, dynamic> j) => _DetailHeader(
        setoranId: j['setoran_id'] ?? '',
        namaPetugas: j['nama_petugas'] ?? '',
        namaNasabah: j['nama_nasabah'] ?? '',
        transaksiTimestamp:
            DateTime.tryParse(j['transaksi_timestamp'] ?? '') ?? DateTime.now(),
        totalItem: j['total_item'] ?? 0,
        statusSetoran: j['status_setoran'] ?? '',
        buktiViaManual: j['bukti_via_manual'] ?? '',
      );
}

class _ItemSetoran {
  final String namaSampah;
  final double qty;
  final String satuan;

  _ItemSetoran({
    required this.namaSampah,
    required this.qty,
    required this.satuan,
  });

  factory _ItemSetoran.fromJson(Map<String, dynamic> j) => _ItemSetoran(
        namaSampah: j['nama_sampah'] ?? '',
        qty: (j['qty'] as num?)?.toDouble() ?? 0.0,
        satuan: j['satuan'] ?? '',
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
    final res = await SetoranService.getDetailSetoranNasabah(widget.setoranId);
    if (!mounted) return;
    if (res['success'] == true) {
      final data = res['data'] as Map<String, dynamic>;
      setState(() {
        _header = _DetailHeader.fromJson(data['header'] ?? {});
        final List items = data['items'] ?? [];
        _items = items.map((e) => _ItemSetoran.fromJson(e)).toList();
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = res['message'] ?? 'Gagal memuat detail setoran';
        _isLoading = false;
      });
    }
  }

  String _fmtQty(double v) {
    if (v == v.truncateToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(2).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
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
      ),
    );
  }

  Widget _buildStruk() {
    final h = _header!;
    final isSuccess = h.statusSetoran == 'berhasil';
    final statusColor = isSuccess ? _accent : Colors.orange;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      child: Column(
        children: [
          // ── Hero status (di atas background gambar) ──────────────────────
          Column(
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
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                  color: statusColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('EEEE, dd MMMM yyyy · HH:mm', 'id_ID')
                    .format(h.transaksiTimestamp),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  color: const Color(0xFF013236).withOpacity(0.5),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          _buildInfoCard(h),
          const SizedBox(height: 16),
          _buildItemsCard(),
          if (h.buktiViaManual.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildFotoCard(h.buktiViaManual),
          ],
        ],
      ),
    );
  }

  Widget _buildFotoCard(String url) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.camera_alt_rounded, size: 15, color: _accent),
              ),
              const SizedBox(width: 12),
              const Text(
                'Bukti Foto Nasabah',
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
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => LihatFotoScreen(
                  photoUrl: url,
                  nama: 'Bukti Foto Nasabah',
                ),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: Image.network(
                  url,
                  fit: BoxFit.cover,
                  loadingBuilder: (_, child, p) => p == null
                      ? child
                      : const Center(
                          child: CircularProgressIndicator(color: _accent)),
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
    );
  }



  Widget _buildInfoCard(_DetailHeader h) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
              children: const [
                Expanded(
                  flex: 5,
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
                SizedBox(
                  width: 44,
                  child: Text(
                    'Qty',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w600, color: _teal),
                  ),
                ),
                SizedBox(
                  width: 52,
                  child: Text(
                    'Satuan',
                    textAlign: TextAlign.right,
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w600, color: _teal),
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
                    flex: 5,
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
                    width: 44,
                    child: Text(
                      _fmtQty(item.qty),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: _teal.withOpacity(0.7),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 52,
                    child: Text(
                      item.satuan,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: _teal.withOpacity(0.55),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
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
