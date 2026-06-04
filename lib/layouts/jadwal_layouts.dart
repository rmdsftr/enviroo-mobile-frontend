import 'package:enviroo/screens/admin_bsi/list_nasabah_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/jadwal_service.dart';

class JadwalSetoranSection extends StatefulWidget {
  const JadwalSetoranSection({super.key});

  @override
  State<JadwalSetoranSection> createState() => JadwalSetoranSectionState();
}

class JadwalSetoranSectionState extends State<JadwalSetoranSection> {
  String _namaBank = "";
  String _bankId = "";
  List<Map<String, dynamic>> _jadwalOperasional = [];
  bool _isLoading = true;
  String? _error;

  late final AppLifecycleListener _lifecycleListener;

  static const _darkTeal = Color(0xFF013236);
  static const _greenAccent = Color(0xFF4EA771);

  @override
  void initState() {
    super.initState();
    _fetchJadwal();
    _lifecycleListener = AppLifecycleListener(onResume: _fetchJadwal);
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    super.dispose();
  }

  Future<void> refresh() => _fetchJadwal();

  Future<void> _fetchJadwal() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final nasabahId = auth.currentUser?.identityId;

    if (nasabahId == null) {
      setState(() {
        _isLoading = false;
        _error = "Sesi tidak valid.";
      });
      return;
    }

    final result = await JadwalService.getJadwalNasabah(nasabahId);

    if (result['success'] == true) {
      final dynamic rawData = result['data'];

      String namaBank = "";
      List<Map<String, dynamic>> jadwalList = [];

      if (rawData is Map<String, dynamic>) {
        namaBank = rawData['nama_bank']?.toString() ?? "";
        _bankId = rawData['bank_id']?.toString().isNotEmpty == true
            ? rawData['bank_id'].toString()
            : auth.nasabahProfile?.bankId ?? auth.bankId ?? '';
        final rawJadwal = rawData['jadwal'];
        if (rawJadwal is List) {
          jadwalList = rawJadwal
              .whereType<Map<String, dynamic>>()
              .toList();
        }
      }

      // Fallback: gunakan namaBsu dari profil nasabah jika nama_bank kosong
      if (namaBank.isEmpty) {
        namaBank = auth.nasabahProfile?.namaBsu ?? "";
      }

      setState(() {
        _namaBank = namaBank.isNotEmpty ? namaBank : "Bank Sampah";
        _jadwalOperasional = jadwalList;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
        _error = result['message'] ?? "Gagal memuat jadwal.";
      });
    }
  }

  String _formatJam(dynamic jamMulai, dynamic jamSelesai) {
    String start = jamMulai?.toString() ?? '';
    String end = jamSelesai?.toString() ?? '';
    if (start.length >= 5) start = start.substring(0, 5);
    if (end.length >= 5) end = end.substring(0, 5);
    if (start.isEmpty && end.isEmpty) return '-';
    return "$start - $end";
  }

  int _getMingguKe(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '0') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 27),
            child: Text(
              "Jadwal Penimbangan",
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _darkTeal,
                letterSpacing: 0.1,
              ),
            ),
          ),

          const SizedBox(height: 14),

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()),
              ),
            )
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                height: 120,
                child: Center(
                  child: Text(
                    _error!,
                    style: const TextStyle(fontFamily: 'Poppins', color: Colors.red),
                  ),
                ),
              ),
            )
          else
            _buildSingleCard(),
        ],
      ),
    );
  }

  Widget _buildSingleCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Column(
            children: [
              // ─── Header: Nama Bank ───────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(
                      color: _darkTeal.withOpacity(0.07),
                      width: 1,
                    ),
                  ),
                ),
                child: GestureDetector(
                  onTap: _bankId.isEmpty
                      ? null
                      : () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ListNasabahScreen(bsuId: _bankId),
                            ),
                          ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _namaBank,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _darkTeal,
                            letterSpacing: 0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 12,
                        color: Color(0xFF4EA771),
                      ),
                    ],
                  ),
                ),
              ),

              // ─── Body: List Jadwal ───────────────────────────────────
              if (_jadwalOperasional.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  child: Center(
                    child: Text(
                      "Belum ada jadwal penimbangan.",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: _darkTeal.withOpacity(0.5),
                      ),
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: _jadwalOperasional.asMap().entries.map((entry) {
                      final i = entry.key;
                      final jadwal = entry.value;
                      final isLast = i == _jadwalOperasional.length - 1;
                      return _buildJadwalRow(jadwal, isLast: isLast);
                    }).toList(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildJadwalRow(Map<String, dynamic> jadwal, {bool isLast = false}) {
    final String hari = jadwal['hari']?.toString() ?? '-';
    final int mingguKe = _getMingguKe(jadwal['minggu_ke']);
    final String mingguInfo = mingguKe == 0 ? "Setiap Minggu" : "Minggu ke-$mingguKe";
    final String jam = _formatJam(jadwal['jam_mulai'], jadwal['jam_selesai']);

    return Column(
      children: [
        Row(
          children: [
            // Calendar icon
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: _greenAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.calendar_month_rounded,
                color: _greenAccent,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),

            // Hari & minggu ke
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hari,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _darkTeal,
                    ),
                  ),
                  Text(
                    mingguInfo,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: _darkTeal.withOpacity(0.5),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Jam badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _darkTeal.withOpacity(0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 11,
                    color: _darkTeal.withOpacity(0.65),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    jam,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _darkTeal.withOpacity(0.75),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (!isLast)
          Divider(
            height: 20,
            thickness: 1,
            color: _darkTeal.withOpacity(0.06),
          ),
      ],
    );
  }
}
