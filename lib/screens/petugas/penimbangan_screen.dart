import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:enviroo/widgets/topbar_back.dart';
import 'package:enviroo/screens/admin_bsu/scanner_penimbangan_screen.dart';
import 'package:enviroo/screens/petugas/list_setoran_nasabah.dart';
import 'package:enviroo/services/penimbangan_service.dart';
import 'package:enviroo/providers/auth_provider.dart';

// ─── Model ──────────────────────────────────────────────────────────────────

class SessionData {
  final String id;
  final String tanggal;
  final String namaAdmin;
  final String status;

  SessionData({
    required this.id,
    required this.tanggal,
    required this.namaAdmin,
    required this.status,
  });

  factory SessionData.fromJson(Map<String, dynamic> json) {
    String tanggal = '-';
    if (json['started_at'] != null) {
      try {
        tanggal = '${DateFormat('EEEE, dd MMMM yyyy HH:mm', 'id_ID')
            .format(DateTime.parse(json['started_at']))} WIB';
      } catch (_) {
        tanggal = json['started_at'].toString();
      }
    }

    return SessionData(
      id: json['penimbangan_id'] ?? '',
      tanggal: tanggal,
      namaAdmin: json['nama_admin'] ?? json['started_by'] ?? 'Admin',
      status: json['status_penimbangan'] ?? 'selesai',
    );
  }
}

// ─── Screen ─────────────────────────────────────────────────────────────────

/// Status yang dipakai UI untuk mengatur tampilan tombol
enum _CheckStatus { idle, loading, scheduled, unscheduled, activeSession }

class PenimbanganScreen extends StatefulWidget {
  @override
  _PenimbanganScreenState createState() => _PenimbanganScreenState();
}

class _PenimbanganScreenState extends State<PenimbanganScreen> {
  _CheckStatus _checkStatus = _CheckStatus.idle;
  bool _listLoading = true;
  bool _actionLoading = false;

  List<SessionData> _riwayat = [];
  SessionData? _activeSession;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  // ── Init: load history + cek jadwal sekaligus ───────────────────────────
  Future<void> _init() async {
    await Future.wait([_loadHistory(), _checkJadwal()]);
  }

  // ── 1. Load history ──────────────────────────────────────────────────────
  Future<void> _loadHistory() async {
    setState(() => _listLoading = true);

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final bankId = auth.bankId ?? '';
    final token = auth.currentUser?.accessToken ?? '';

    if (bankId.isEmpty || token.isEmpty) {
      setState(() => _listLoading = false);
      return;
    }

    final res = await PenimbanganService.getPenimbangan(bankId, token);

    if (!mounted) return;
    if (res['success'] == true) {
      final List data = res['data'] ?? [];
      List<SessionData> riwayat = [];
      SessionData? aktif;

      for (var item in data) {
        final s = SessionData.fromJson(item);
        if (s.status == 'aktif') {
          aktif = s;
        } else {
          riwayat.add(s);
        }
      }

      setState(() {
        _riwayat = riwayat;
        _activeSession = aktif;
        _listLoading = false;
      });
    } else {
      setState(() => _listLoading = false);
      _showSnackBar(res['message'] ?? 'Gagal memuat data', isError: true);
    }
  }

  // ── 2. Cek jadwal hari ini ───────────────────────────────────────────────
  Future<void> _checkJadwal() async {
    setState(() => _checkStatus = _CheckStatus.loading);

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final bankId = auth.bankId ?? '';
    final token = auth.currentUser?.accessToken ?? '';

    if (bankId.isEmpty || token.isEmpty) {
      setState(() => _checkStatus = _CheckStatus.idle);
      return;
    }

    final res = await PenimbanganService.checkJadwalHariIni(bankId, token);

    if (!mounted) return;
    if (res['success'] == true) {
      final s = res['status'] as String? ?? '';
      setState(() {
        if (s == 'active_session') {
          _checkStatus = _CheckStatus.activeSession;
        } else if (s == 'scheduled') {
          _checkStatus = _CheckStatus.scheduled;
        } else {
          _checkStatus = _CheckStatus.unscheduled;
        }
      });
    } else {
      setState(() => _checkStatus = _CheckStatus.idle);
      _showSnackBar(res['message'] ?? 'Gagal mengecek jadwal', isError: true);
    }
  }

  // ── 3. Mulai sesi — dijalan setelah check ────────────────────────────────
  Future<void> _memulaiSesi({bool forceDadakan = false}) async {
    setState(() => _actionLoading = true);

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final bankId = auth.bankId ?? '';
    final adminId = auth.userId;
    final token = auth.currentUser?.accessToken ?? '';

    final res = await PenimbanganService.addPenimbangan(
      bankId, adminId, token,
      forceDadakan: forceDadakan,
    );

    if (!mounted) return;
    setState(() => _actionLoading = false);

    if (res['success'] == true) {
      _showSnackBar('Sesi penimbangan berhasil dimulai');
      await _init();
    } else {
      _showSnackBar(res['message'] ?? 'Gagal memulai penimbangan', isError: true);
    }
  }

  // ── 4. Akhiri / batalkan sesi ────────────────────────────────────────────
  Future<void> _updateSesi(String status) async {
    if (_activeSession == null) return;
    setState(() => _actionLoading = true);

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final adminId = auth.userId;
    final token = auth.currentUser?.accessToken ?? '';

    final res = await PenimbanganService.updatePenimbangan(
      _activeSession!.id, adminId, status, token);

    if (!mounted) return;
    setState(() => _actionLoading = false);

    if (res['success'] == true) {
      _showSnackBar('Sesi penimbangan telah $status');
      await _init();
    } else {
      _showSnackBar(res['message'] ?? 'Gagal memperbarui sesi', isError: true);
    }
  }

  // ── Helper: tombol "Mulai Sesi" diklik ──────────────────────────────────
  void _onMulaiSesiTap() {
    if (_checkStatus == _CheckStatus.scheduled) {
      // Langsung mulai — ada jadwal
      _memulaiSesi(forceDadakan: false);
    } else if (_checkStatus == _CheckStatus.unscheduled) {
      // Minta konfirmasi dadakan dulu
      _showDadakanDialog();
    } else {
      // Belum dicek / masih loading — cek dulu
      _checkJadwal();
    }
  }

  // ── Dialog konfirmasi dadakan ────────────────────────────────────────────
  void _showDadakanDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 30,
                offset: const Offset(0, 12),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Ikon peringatan
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3CD),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFFAA324),
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Tidak Ada Jadwal Hari Ini',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: Color(0xFF013236),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Hari ini tidak tercatat dalam jadwal penimbangan. '
                'Apakah Anda ingin mengadakan sesi penimbangan dadakan?',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12.5,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Tidak',
                        style: TextStyle(
                          color: Color(0xFF013236),
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _memulaiSesi(forceDadakan: true);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFAA324),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Ya, Dadakan',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Dialog konfirmasi akhiri / batalkan ─────────────────────────────────
  void _showKonfirmasiDialog(String status) {
    final isSelesai = status == 'selesai';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isSelesai ? 'Sudahi Penimbangan' : 'Batalkan Penimbangan',
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        content: Text(
          isSelesai
              ? 'Apakah sesi penimbangan ini benar-benar sudah selesai?'
              : 'Apakah Anda yakin ingin membatalkan sesi penimbangan ini?',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            color: Colors.grey[700],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tidak',
                style: TextStyle(color: Colors.grey, fontFamily: 'Poppins')),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _updateSesi(status);
            },
            child: Text(
              isSelesai ? 'Ya, Sudahi' : 'Ya, Batalkan',
              style: TextStyle(
                color: isSelesai ? const Color(0xFF4EA771) : Colors.red,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: const TextStyle(fontFamily: 'Poppins', color: Colors.white)),
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
        child: Column(
          children: [
            TopBarBack(title: 'Sesi Penimbangan'),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _init,
                color: const Color(0xFF4EA771),
                child: _listLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFF4EA771)))
                    : SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Sesi aktif atau tombol mulai ──
                            if (_activeSession != null)
                              _buildActiveCard()
                            else
                              _buildStartSection(),

                            const SizedBox(height: 28),

                            // ── Riwayat ──
                            const Text(
                              'Riwayat Penimbangan',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF013236),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildRiwayatList(),
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

  // ── Info badge jadwal ────────────────────────────────────────────────────
  Widget _buildJadwalBadge() {
    if (_checkStatus == _CheckStatus.loading || _checkStatus == _CheckStatus.idle) {
      return const SizedBox.shrink();
    }

    final isScheduled = _checkStatus == _CheckStatus.scheduled;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isScheduled
            ? const Color(0xFFE8F5E9)
            : const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isScheduled
              ? const Color(0xFF4EA771).withOpacity(0.4)
              : const Color(0xFFFAA324).withOpacity(0.4),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isScheduled
                ? Icons.event_available_rounded
                : Icons.event_busy_rounded,
            size: 18,
            color: isScheduled ? const Color(0xFF4EA771) : const Color(0xFFFAA324),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isScheduled
                  ? 'Hari ini ada jadwal penimbangan terjadwal'
                  : 'Tidak ada jadwal penimbangan hari ini',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isScheduled
                    ? const Color(0xFF2E7D32)
                    : const Color(0xFF8D6E00),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Tombol + info mulai sesi ─────────────────────────────────────────────
  Widget _buildStartSection() {
    final isLoading = _actionLoading ||
        _checkStatus == _CheckStatus.loading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildJadwalBadge(),
        GestureDetector(
          onTap: isLoading ? null : _onMulaiSesiTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 17),
            decoration: BoxDecoration(
              color: isLoading
                  ? const Color(0xFF4EA771).withOpacity(0.6)
                  : const Color(0xFF4EA771),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4EA771).withOpacity(0.32),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                )
              ],
            ),
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.play_circle_filled_rounded,
                            color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          _checkStatus == _CheckStatus.unscheduled
                              ? 'Buka Penimbangan Dadakan'
                              : 'Mulai Sesi Penimbangan',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Card sesi aktif ──────────────────────────────────────────────────────
  Widget _buildActiveCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label kecil
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF94DF0C).withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF4CAF50),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'Sesi Berjalan',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2E7D32),
                ),
              ),
            ],
          ),
        ),

        // Card utama
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => ScannerPenimbanganScreen(
                  penimbanganId: _activeSession!.id,
                )),
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF013236), Color(0xFF025059)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF013236).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Penimbangan Aktif',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF94DF0C),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'AKTIF',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF013236),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _infoRow(
                    Icons.calendar_today_rounded, _activeSession!.tanggal),
                const SizedBox(height: 8),
                _infoRow(Icons.person_rounded,
                    'Dibuka oleh: ${_activeSession!.namaAdmin}'),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: const [
                    Text(
                      'Buka Scanner',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF94DF0C),
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_ios_rounded,
                        color: Color(0xFF94DF0C), size: 12),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Tombol Selesai & Batalkan
        _actionLoading
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: CircularProgressIndicator(
                      color: Color(0xFF4EA771), strokeWidth: 2.5),
                ),
              )
            : Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          _showKonfirmasiDialog('dibatalkan'),
                      icon: const Icon(Icons.cancel_outlined,
                          size: 16, color: Colors.red),
                      label: const Text('Batalkan',
                          style: TextStyle(
                              color: Colors.red,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _showKonfirmasiDialog('selesai'),
                      icon: const Icon(
                          Icons.check_circle_outline_rounded,
                          size: 16,
                          color: Colors.white),
                      label: const Text('Sudahi',
                          style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4EA771),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
      ],
    );
  }

  Widget _infoRow(IconData icon, String text) => Row(
        children: [
          Icon(icon, size: 14, color: Colors.white70),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
          ),
        ],
      );

  // ── Riwayat ─────────────────────────────────────────────────────────────
  Widget _buildRiwayatList() {
    if (_riwayat.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 36),
          child: Column(
            children: [
              Icon(Icons.history_toggle_off_rounded,
                  size: 44, color: Colors.grey[300]),
              const SizedBox(height: 10),
              Text(
                'Belum ada riwayat penimbangan',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: Colors.grey[400]),
              ),
            ],
          ),
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

  Widget _buildRiwayatTile(SessionData s) {
    final isSelesai = s.status == 'selesai';
    final statusColor =
        isSelesai ? const Color(0xFF4EA771) : Colors.red.shade400;
    final bgColor = isSelesai
        ? const Color(0xFFE8F5E9)
        : Colors.red.withOpacity(0.07);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ListSetoranNasabahScreen(
            penimbanganId: s.id,
            tanggalPenimbangan: s.tanggal,
          ),
        ),
      ),
      child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          // Ikon status
          Container(
            padding: const EdgeInsets.all(9),
            decoration:
                BoxDecoration(color: bgColor, shape: BoxShape.circle),
            child: Icon(
              isSelesai
                  ? Icons.check_circle_outline_rounded
                  : Icons.cancel_outlined,
              color: statusColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.tanggal,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF013236),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  s.namaAdmin,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11.5,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          // Badge status
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isSelesai ? 'Selesai' : 'Dibatalkan',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }
}
