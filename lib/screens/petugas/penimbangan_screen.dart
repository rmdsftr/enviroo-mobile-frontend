import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:enviroo/widgets/custom_snackbar.dart';
import 'package:enviroo/widgets/topbar_back.dart';
import 'package:enviroo/widgets/filter_month_year.dart';
import 'package:enviroo/screens/petugas/list_setoran_nasabah.dart';
import 'package:enviroo/screens/petugas/penimbangan_aktif_screen.dart';
import 'package:enviroo/services/penimbangan_service.dart';
import 'package:enviroo/providers/auth_provider.dart';

// ─── Model ──────────────────────────────────────────────────────────────────

class SessionData {
  final String id;
  final String tanggal;
  final String waktu;
  final String fullTanggal;
  final String status;
  final DateTime? rawDate;

  SessionData({
    required this.id,
    required this.tanggal,
    required this.waktu,
    required this.fullTanggal,
    required this.status,
    this.rawDate,
  });

  factory SessionData.fromJson(Map<String, dynamic> json) {
    String tanggal = '-';
    String waktu = '';
    String fullTanggal = '-';
    DateTime? rawDate;

    if (json['started_at'] != null) {
      try {
        final parsedStart = DateTime.parse(json['started_at']);
        rawDate = parsedStart;
        tanggal = DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(parsedStart);

        final startTimeStr = DateFormat('HH:mm', 'id_ID').format(parsedStart);
        String endTimeStr = '';

        if (json['ended_at'] != null) {
          final parsedEnd = DateTime.parse(json['ended_at']);
          endTimeStr = ' - ${DateFormat('HH:mm', 'id_ID').format(parsedEnd)}';
        }

        waktu = '$startTimeStr$endTimeStr';
        fullTanggal = '$tanggal $waktu';
      } catch (_) {
        tanggal = json['started_at'].toString();
        fullTanggal = tanggal;
      }
    }

    return SessionData(
      id: json['penimbangan_id'] ?? '',
      tanggal: tanggal,
      waktu: waktu,
      fullTanggal: fullTanggal,
      status: json['status_penimbangan'] ?? 'selesai',
      rawDate: rawDate,
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

  late DateTime _filterStart;
  late DateTime _filterEnd;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    int startMonth = now.month - 2;
    int startYear = now.year;
    if (startMonth <= 0) {
      startMonth += 12;
      startYear--;
    }
    _filterStart = DateTime(startYear, startMonth);
    _filterEnd = DateTime(now.year, now.month);
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

    if (bankId.isEmpty) {
      setState(() => _listLoading = false);
      return;
    }

    final res = await PenimbanganService.getPenimbangan(bankId);

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
      showCustomSnackBar(context, res['message'] ?? 'Gagal memuat data');
    }
  }

  // ── 2. Cek jadwal hari ini ───────────────────────────────────────────────
  Future<void> _checkJadwal() async {
    setState(() => _checkStatus = _CheckStatus.loading);

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final bankId = auth.bankId ?? '';

    if (bankId.isEmpty) {
      setState(() => _checkStatus = _CheckStatus.idle);
      return;
    }

    final res = await PenimbanganService.checkJadwalHariIni(bankId);

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
      showCustomSnackBar(context, res['message'] ?? 'Gagal mengecek jadwal');
    }
  }

  // ── 3. Mulai sesi — dijalan setelah check ────────────────────────────────
  Future<void> _memulaiSesi({bool forceDadakan = false}) async {
    setState(() => _actionLoading = true);

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final bankId = auth.bankId ?? '';
    final adminId = auth.userId;

    final res = await PenimbanganService.addPenimbangan(
      bankId, adminId,
      forceDadakan: forceDadakan,
    );

    if (!mounted) return;
    setState(() => _actionLoading = false);

    if (res['success'] == true) {
      showCustomSnackBar(context, 'Sesi penimbangan berhasil dimulai', type: SnackBarType.success);
      await _init();
    } else {
      showCustomSnackBar(context, res['message'] ?? 'Gagal memulai penimbangan');
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

  // ── Bottom sheet konfirmasi dadakan ──────────────────────────────────────
  void _showDadakanDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36, height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFFFF3CD),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFFAA324), size: 28),
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
              'Hari ini tidak tercatat dalam jadwal penimbangan.\nApakah Anda ingin mengadakan sesi penimbangan dadakan?',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: const Color(0xFF013236).withValues(alpha: 0.5),
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF013236),
                      side: BorderSide(color: const Color(0xFF013236).withValues(alpha: 0.25)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                    ),
                    child: const Text('Tidak', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _memulaiSesi(forceDadakan: true);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFAA324),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                    ),
                    child: const Text('Ya, Dadakan', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  List<SessionData> get _filteredRiwayat {
    return _riwayat.where((s) {
      if (s.rawDate == null) return true;
      final d = DateTime(s.rawDate!.year, s.rawDate!.month);
      final start = DateTime(_filterStart.year, _filterStart.month);
      final end = DateTime(_filterEnd.year, _filterEnd.month);
      return !d.isBefore(start) && !d.isAfter(end);
    }).toList();
  }


  // ═══════════════════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════════════════
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
            TopBarBack(title: 'Penimbangan Sampah'),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildHeaderCard(),
                                  const SizedBox(height: 16),
                                  _buildSummaryStats(),
                                  const SizedBox(height: 25),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    child : const Text(
                                      'Riwayat Penimbangan',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF013236),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  MonthYearFilterRow(
                                    filterStart: _filterStart,
                                    filterEnd: _filterEnd,
                                    onChanged: (start, end) => setState(() {
                                      _filterStart = start;
                                      _filterEnd = end;
                                    }),
                                  ),
                                ],
                              ),
                            ),
                            // ── Riwayat ──
                            Container(
                              width: double.infinity,
                              constraints: BoxConstraints(
                                minHeight: MediaQuery.of(context).size.height,
                              ),
                              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildRiwayatList(),
                                ],
                              ),
                            ),
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

  // ── HEADER CARD (gabungan jadwal + aksi) ──────────────────────────────────
  Widget _buildHeaderCard() {
    final now = DateTime.now();
    final todayStr = DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(now);

    // ── Sesi aktif ──
    if (_activeSession != null) {
      return GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PenimbanganAktifScreen(
              penimbanganId: _activeSession!.id,
            ),
          ),
        ).then((_) => _init()),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF013236), Color(0xFF025059)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dot badge
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF94DF0C),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Hari ini, $todayStr',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: Colors.white60,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Sesi penimbangan sedang berlangsung',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 14),
              // Button
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  color: const Color(0xFF94DF0C),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.open_in_new_rounded,
                        color: Color(0xFF013236), size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Buka Sesi Aktif',
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
            ],
          ),
        ),
      );
    }

    // ── Tidak ada sesi aktif ──
    final isLoading = _actionLoading || _checkStatus == _CheckStatus.loading;
    final isScheduled = _checkStatus == _CheckStatus.scheduled;
    final isUnscheduled = _checkStatus == _CheckStatus.unscheduled;

    String statusLabel;
    if (_checkStatus == _CheckStatus.loading || _checkStatus == _CheckStatus.idle) {
      statusLabel = 'Mengecek jadwal...';
    } else if (isScheduled) {
      statusLabel = 'Ada jadwal penimbangan hari ini';
    } else {
      statusLabel = 'Tidak ada jadwal penimbangan';
    }

    String btnLabel;
    if (isScheduled) {
      btnLabel = 'Mulai Sesi Penimbangan';
    } else {
      btnLabel = 'Buka Penimbangan Dadakan';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF013236), Color(0xFF025059)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hari ini, $todayStr',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              color: Colors.white60,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            statusLabel,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 14),
          // Button
          GestureDetector(
            onTap: isLoading ? null : _onMulaiSesiTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isLoading
                    ? Colors.white.withOpacity(0.5)
                    : Colors.white,
                borderRadius: BorderRadius.circular(50),
              ),
              child: isLoading
                  ? const Center(
                      child: SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            color: Color(0xFF013236), strokeWidth: 2),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isScheduled
                              ? Icons.play_circle_filled_rounded
                              : Icons.add_circle_outline_rounded,
                          color: const Color(0xFF013236),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          btnLabel,
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
          ),
        ],
      ),
    );
  }

  // ── SUMMARY STATS ──────────────────────────────────────────────────
  Widget _buildSummaryStats() {
    final allSessions = [..._riwayat, if (_activeSession != null) _activeSession!];
    final totalSesi = allSessions.length;
    final totalSelesai = allSessions.where((s) => s.status == 'selesai').length;
    final totalDibatalkan = allSessions.where((s) => s.status != 'selesai' && s.status != 'aktif').length;

    return Row(
      children: [
        Expanded(child: _statCard(
          iconColor: const Color(0xFF013236),
          label: 'Sesi Total',
          value: totalSesi.toString(),
        )),
        const SizedBox(width: 10),
        Expanded(child: _statCard(
          iconColor: const Color(0xFF4EA771),
          label: 'Selesai',
          value: totalSelesai.toString(),
        )),
        const SizedBox(width: 10),
        Expanded(child: _statCard(
          iconColor: Colors.red.shade400,
          label: 'Dibatalkan',
          value: totalDibatalkan.toString(),
        )),
      ],
    );
  }

  Widget _statCard({
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF013236).withOpacity(0.08),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: iconColor,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10,
              color: const Color(0xFF013236).withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

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

    final filtered = _filteredRiwayat;
    if (filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 36),
          child: Column(
            children: [
              Icon(Icons.search_off_rounded,
                  size: 44, color: Colors.grey[300]),
              const SizedBox(height: 10),
              Text(
                'Tidak ada riwayat di rentang waktu ini',
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
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _buildRiwayatTile(filtered[i]),
    );
  }

  Widget _buildRiwayatTile(SessionData s) {
    final isSelesai = s.status == 'selesai';
    final statusColor =
        isSelesai ? const Color(0xFF4EA771) : Colors.red.shade400;
    final bgColor = isSelesai
        ? const Color(0xFFE8F5E9)
        : Colors.red.withValues(alpha: 0.07);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ListSetoranNasabahScreen(
            penimbanganId: s.id,
            tanggalPenimbangan: s.fullTanggal,
          ),
        ),
      ),
      child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.5),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            width: 1,
            color: const Color(0xFF013236).withOpacity(0.1), // Brand color dengan opacity cuma 10%
          ),
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
                  s.waktu,
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

