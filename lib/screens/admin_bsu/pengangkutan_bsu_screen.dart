import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:enviroo/widgets/topbar_back.dart';
import 'package:enviroo/services/pengangkutan_service.dart';
import 'package:enviroo/providers/auth_provider.dart';
import 'package:enviroo/screens/admin_bsu/QR_angkut_sampah_screen.dart';
import 'package:enviroo/screens/admin_bsi/detail_pengangkutan_screen.dart';

// ─── Model (sama dengan BSI, reuse) ─────────────────────────────────────────

class PengangkutanBsuData {
  final String id;
  final String namaBsi;
  final String namaBsu;
  final String namaAdminBsu;
  final String status;
  final String tanggal;

  PengangkutanBsuData({
    required this.id,
    required this.namaBsi,
    required this.namaBsu,
    required this.namaAdminBsu,
    required this.status,
    required this.tanggal,
  });

  factory PengangkutanBsuData.fromJson(Map<String, dynamic> json) {
    String tanggal = '-';
    if (json['changed_at'] != null) {
      try {
        tanggal = '${DateFormat('EEEE, dd MMMM yyyy HH:mm', 'id_ID').format(DateTime.parse(json['changed_at'].toString()))} WIB';
      } catch (_) {
        tanggal = json['changed_at'].toString();
      }
    }
    // nama_admin_bsu bisa null (nullable pointer di backend)
    final namaAdminBsu = json['nama_admin_bsu'] as String? ?? '-';

    return PengangkutanBsuData(
      id: json['pengangkutan_id'] ?? '',
      namaBsi: json['nama_bsi'] as String? ?? '-',
      namaBsu: json['nama_bsu'] as String? ?? '-',
      namaAdminBsu: namaAdminBsu,
      status: json['status_pengangkutan'] ?? '',
      tanggal: tanggal,
    );
  }
}

// ─── Screen ─────────────────────────────────────────────────────────────────

class PengangkutanBsuScreen extends StatefulWidget {
  const PengangkutanBsuScreen({super.key});

  @override
  State<PengangkutanBsuScreen> createState() => _PengangkutanBsuScreenState();
}

class _PengangkutanBsuScreenState extends State<PengangkutanBsuScreen> {
  bool _isLoading = true;
  List<PengangkutanBsuData> _riwayat = [];
  List<PengangkutanBsuData> _aktif = [];

  // Terminal statuses — tidak bisa diubah lagi
  static const _terminalStatuses = {'completed', 'canceled', 'rejected'};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final bankId = auth.bankId ?? '';
    final token = auth.currentUser?.accessToken ?? '';

    if (bankId.isEmpty || token.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    final res = await PengangkutanService.getAllPengangkutan(bankId, token);
    if (!mounted) return;

    if (res['success'] == true) {
      final List data = res['data'] ?? [];
      final List<PengangkutanBsuData> aktif = [];
      final List<PengangkutanBsuData> riwayat = [];
      for (final item in data) {
        final p = PengangkutanBsuData.fromJson(item);
        if (_terminalStatuses.contains(p.status)) {
          riwayat.add(p);
        } else {
          aktif.add(p);
        }
      }
      setState(() {
        _aktif = aktif;
        _riwayat = riwayat;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      _snackBar(res['message'] ?? 'Gagal memuat data', isError: true);
    }
  }

  void _snackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontFamily: 'Poppins', color: Colors.white)),
      backgroundColor: isError ? Colors.red.shade700 : const Color(0xFF4EA771),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ));
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F8),
      body: SafeArea(
        child: Column(children: [
          const TopBarBack(title: 'Pengangkutan'),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadData,
              color: const Color(0xFF06C0C9),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF06C0C9)))
                  : SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        // ── Info card ──
                        _buildInfoCard(),
                        const SizedBox(height: 20),

                        // ── Sesi aktif ──
                        if (_aktif.isNotEmpty) ...[
                          ..._aktif.map((s) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildAktifCard(s),
                          )),
                          const SizedBox(height: 16),
                        ],

                        // ── Riwayat ──
                        const Text('Riwayat Pengangkutan', style: TextStyle(
                          fontFamily: 'Poppins', fontSize: 15,
                          fontWeight: FontWeight.w700, color: Color(0xFF013236),
                        )),
                        const SizedBox(height: 12),
                        _buildRiwayatList(),
                      ]),
                    ),
            ),
          ),
        ]),
      ),
    );
  }

  // ── Info card tentang request pengangkutan ───────────────────────────────
  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF013236), Color(0xFF025059)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF013236).withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF94DF0C).withOpacity(0.18),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.info_outline_rounded, color: Color(0xFF94DF0C), size: 20),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Pengajuan Pengangkutan', style: TextStyle(
              fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w700,
              color: Colors.white,
            )),
            SizedBox(height: 5),
            Text(
              'Jika ingin mengajukan pengangkutan sampah kepada BSI di luar jadwal, Anda bisa melakukan request pengangkutan di menu \'Jadwal\'.',
              style: TextStyle(
                fontFamily: 'Poppins', fontSize: 11.5, height: 1.55,
                color: Colors.white70,
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  // ── Card sesi aktif (read-only, BSU tidak bisa update status) ────────────
  Widget _buildAktifCard(PengangkutanBsuData s) {
    final statusColor = _statusColor(s.status);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Badge live
      Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(_statusLabel(s.status), style: TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w600, color: statusColor)),
        ]),
      ),
      // Card body
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF013236), Color(0xFF025059)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [BoxShadow(color: const Color(0xFF013236).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Pengangkutan Aktif', style: TextStyle(
              fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white,
            )),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(20)),
              child: Text(_statusLabel(s.status).toUpperCase(), style: const TextStyle(
                fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white,
              )),
            ),
          ]),
          const SizedBox(height: 16),
          _infoRow(Icons.business_rounded, 'BSI: ${s.namaBsi}'),
          const SizedBox(height: 8),
          _infoRow(Icons.calendar_today_rounded, s.tanggal),
          const SizedBox(height: 8),
          _infoRow(Icons.person_rounded, 'Pengaju: ${s.namaAdminBsu}'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(children: [
              const Icon(Icons.lock_clock_outlined, size: 13, color: Colors.white54),
              const SizedBox(width: 8),
              const Expanded(child: Text(
                'Status hanya dapat diperbarui oleh Admin BSI',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Colors.white54),
              )),
            ]),
          ),
        ]),
      ),
      // Tombol QR Code — tampil saat status approved atau otw
      if (s.status == 'approved' || s.status == 'otw') ...[
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const QRAngkutSampahScreen(),
                ),
              );
            },
            icon: const Icon(Icons.qr_code_2_rounded, size: 18, color: Colors.white),
            label: const Text(
              'QR Code Penyetoran',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF06C0C9),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 13),
            ),
          ),
        ),
      ],
    ]);
  }

  Widget _infoRow(IconData icon, String text) => Row(children: [
    Icon(icon, size: 14, color: Colors.white70),
    const SizedBox(width: 8),
    Expanded(child: Text(text, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.white70))),
  ]);

  // ── Riwayat (terminal statuses) ──────────────────────────────────────────
  Widget _buildRiwayatList() {
    if (_riwayat.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 36),
          child: Column(children: [
            Icon(Icons.history_toggle_off_rounded, size: 44, color: Colors.grey[300]),
            const SizedBox(height: 10),
            Text('Belum ada riwayat pengangkutan', style: TextStyle(
              fontFamily: 'Poppins', fontSize: 13, color: Colors.grey[400],
            )),
          ]),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _riwayat.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _buildRiwayatTile(_riwayat[i]),
    );
  }

  Widget _buildRiwayatTile(PengangkutanBsuData s) {
    final color = _statusColor(s.status);
    final bgColor = color.withOpacity(0.1);

    return GestureDetector(
      onTap: () {
        if (s.status == 'completed' || s.status == 'canceled') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DetailPengangkutanScreen(
                pengangkutanId: s.id,
                namaBsu: s.namaBsu,
              ),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
          child: Icon(_statusIcon(s.status), color: color, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(s.namaBsi, style: const TextStyle(
            fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF013236),
          )),
          const SizedBox(height: 3),
          Text(s.tanggal, style: TextStyle(fontFamily: 'Poppins', fontSize: 11.5, color: Colors.grey[500])),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(20)),
          child: Text(_statusLabel(s.status), style: TextStyle(
            fontFamily: 'Poppins', fontSize: 10.5, fontWeight: FontWeight.w600, color: color,
          )),
        ),
      ]),
    ));
  }

  // ── Status helpers ───────────────────────────────────────────────────────
  String _statusLabel(String s) {
    switch (s) {
      case 'requested': return 'Diajukan';
      case 'approved':  return 'Disetujui';
      case 'rejected':  return 'Ditolak';
      case 'otw':       return 'Dalam Perjalanan';
      case 'canceled':  return 'Dibatalkan';
      case 'completed': return 'Selesai';
      default: return s;
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'completed': return const Color(0xFF4EA771);
      case 'canceled': case 'rejected': return Colors.red.shade400;
      case 'otw':       return const Color(0xFF06C0C9);
      case 'approved':  return const Color(0xFF8BC34A);
      case 'requested': return const Color(0xFFFAA324);
      default: return Colors.grey;
    }
  }

  IconData _statusIcon(String s) {
    switch (s) {
      case 'completed': return Icons.check_circle_outline_rounded;
      case 'canceled': case 'rejected': return Icons.cancel_outlined;
      case 'otw':       return Icons.local_shipping_rounded;
      case 'approved':  return Icons.thumb_up_alt_rounded;
      case 'requested': return Icons.hourglass_top_rounded;
      default: return Icons.info_outline_rounded;
    }
  }
}
