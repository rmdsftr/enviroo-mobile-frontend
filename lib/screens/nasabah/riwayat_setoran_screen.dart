import 'dart:convert';
import 'package:enviroo/config/api_config.dart';
import 'package:enviroo/providers/auth_provider.dart';
import 'package:enviroo/screens/nasabah/detail_setoran_screen.dart';
import 'package:enviroo/screens/setoran_screen.dart';
import 'package:enviroo/widgets/topbar_back.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

// ── Model ────────────────────────────────────────────────────────────────────
class RiwayatSetoranModel {
  final String setoranId;
  final String namaPetugas;
  final DateTime transaksiTimestamp;
  final int totalItem;
  final double totalPoin;
  final String statusSetoran;

  RiwayatSetoranModel({
    required this.setoranId,
    required this.namaPetugas,
    required this.transaksiTimestamp,
    required this.totalItem,
    required this.totalPoin,
    required this.statusSetoran,
  });

  factory RiwayatSetoranModel.fromJson(Map<String, dynamic> json) {
    return RiwayatSetoranModel(
      setoranId: json['setoran_id'] ?? '',
      namaPetugas: json['nama_petugas'] ?? 'Petugas',
      transaksiTimestamp: DateTime.tryParse(json['transaksi_timestamp'] ?? '') ?? DateTime.now(),
      totalItem: json['total_item'] ?? 0,
      totalPoin: (json['total_poin'] as num?)?.toDouble() ?? 0.0,
      statusSetoran: json['status_setoran'] ?? '',
    );
  }
}

// ── Screen ───────────────────────────────────────────────────────────────────
class RiwayatSetoranScreen extends StatefulWidget {
  const RiwayatSetoranScreen({super.key});

  @override
  State<RiwayatSetoranScreen> createState() => _RiwayatSetoranScreenState();
}

class _RiwayatSetoranScreenState extends State<RiwayatSetoranScreen> {
  static const _teal = Color(0xFF013236);
  static const _accent = Color(0xFF4EA771);
  static const _lime = Color(0xFF94DF0C);

  List<RiwayatSetoranModel> _list = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchRiwayat();
  }

  Future<void> _fetchRiwayat() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final nasabahId = auth.identityId ?? '';
    final token = auth.currentUser?.accessToken ?? '';

    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.listSetoranNasabahUrl}/$nasabahId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (!mounted) return;

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final List data = body['data'] ?? [];
        setState(() {
          _list = data.map((e) => RiwayatSetoranModel.fromJson(e)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Gagal memuat riwayat setoran';
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

  String _formatPoin(double poin) {
    final int intPart = poin.truncate();
    final double dec = poin - intPart;
    final formatted = NumberFormat('#,###', 'id_ID').format(intPart);
    if (dec > 0) {
      final decStr = dec.toStringAsFixed(2).substring(1); // ".50"
      return '$formatted$decStr';
    }
    return formatted;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      body: SafeArea(
        child: Column(
          children: [
            TopBarBack(title: 'Setoran Sampah'),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: _accent))
                  : _error != null
                      ? _buildError()
                      : RefreshIndicator(
                          color: _accent,
                          onRefresh: _fetchRiwayat,
                          child: CustomScrollView(
                            slivers: [
                              SliverToBoxAdapter(child: _buildQRButton()),
                              SliverToBoxAdapter(child: _buildSectionHeader()),
                              if (_list.isEmpty)
                                SliverFillRemaining(child: _buildEmpty())
                              else
                                SliverPadding(
                                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                                  sliver: SliverList(
                                    delegate: SliverChildBuilderDelegate(
                                      (ctx, i) => _buildCard(_list[i]),
                                      childCount: _list.length,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  // ── QR Button ────────────────────────────────────────────────────────────
  Widget _buildQRButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => SetoranScreen()),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF013236), Color(0xFF025A62)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: _teal.withOpacity(0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _lime.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.qr_code_rounded, color: _lime, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'QR Code Penyetoran',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Tunjukkan ke petugas BSU saat menyetor sampah',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.65),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, color: _lime, size: 15),
            ],
          ),
        ),
      ),
    );
  }

  // ── Section Header ────────────────────────────────────────────────────────
  Widget _buildSectionHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 20, 8),
      child: Row(
        children: [
          const Text(
            'Riwayat Setoran',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: _teal,
            ),
          ),
          const Spacer(),
          if (_list.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: _accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_list.length} transaksi',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: _accent,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Card ─────────────────────────────────────────────────────────────────
  Widget _buildCard(RiwayatSetoranModel item) {
    final bool isSuccess = item.statusSetoran == 'berhasil';
    final statusColor = isSuccess ? _accent : Colors.orange;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetailSetoranScreen(setoranId: item.setoranId),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: _teal.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.recycling_rounded, color: _accent, size: 22),
              ),
              const SizedBox(width: 14),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            DateFormat('dd MMM yyyy, HH:mm', 'id_ID')
                                .format(item.transaksiTimestamp.toLocal()),
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: _teal,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isSuccess ? 'Berhasil' : item.statusSetoran,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Petugas: ${item.namaPetugas} · ${item.totalItem} item',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: _teal.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.eco_rounded, size: 13, color: _accent),
                        const SizedBox(width: 4),
                        Text(
                          '${_formatPoin(item.totalPoin)} poin',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _accent,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: _accent, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  // ── Empty ─────────────────────────────────────────────────────────────────
  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _accent.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.inbox_rounded, size: 36, color: _teal.withOpacity(0.35)),
            ),
            const SizedBox(height: 14),
            Text(
              'Belum ada setoran',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: _teal.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Riwayat setoran sampah kamu akan muncul di sini',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                color: _teal.withOpacity(0.35),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Error ─────────────────────────────────────────────────────────────────
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
              onPressed: _fetchRiwayat,
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
