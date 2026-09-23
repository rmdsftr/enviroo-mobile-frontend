import 'package:enviroo/models/penimbangan_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:enviroo/widgets/custom_snackbar.dart';
import 'package:enviroo/widgets/topbar_back.dart';
import 'package:enviroo/widgets/filter_month_year.dart';
import 'package:enviroo/screens/petugas/list_setoran_nasabah.dart';
import 'package:enviroo/screens/petugas/penimbangan_aktif_screen.dart';
import 'package:enviroo/services/penimbangan_service.dart';
import 'package:enviroo/providers/auth_provider.dart';

// ─── Screen ─────────────────────────────────────────────────────────────────

class PenimbanganScreen extends StatefulWidget {
  @override
  _PenimbanganScreenState createState() => _PenimbanganScreenState();
}

class _PenimbanganScreenState extends State<PenimbanganScreen> {
  bool _listLoading = true;

  // ── Status header card (dari /penimbangan/check-active/:bank_id) ──
  bool _headerLoading = true;
  bool _isActiveSesi = false;
  int _pendingSessions = 0;
  CheckActiveDetail? _detailAktif;

  List<SessionData> _riwayat = [];

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

  // ── Init: load history + cek sesi aktif ─────────────────────────────────
  Future<void> _init() async {
    await Future.wait([_loadHistory(), _checkActive()]);
  }

  // ── Cek sesi aktif hari ini (untuk header card) ──────────────────────────
  Future<void> _checkActive() async {
    setState(() => _headerLoading = true);

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final bankId = auth.bankId ?? '';

    if (bankId.isEmpty) {
      setState(() => _headerLoading = false);
      return;
    }

    final res = await PenimbanganService.checkActiveSession(bankId);

    if (!mounted) return;
    if (res['success'] == true) {
      setState(() {
        _isActiveSesi = res['is_active'] == true;
        _detailAktif = res['detail'] as CheckActiveDetail?;
        _pendingSessions = (res['pending_sessions'] as int?) ?? 0;
        _headerLoading = false;
      });
    } else {
      setState(() => _headerLoading = false);
      showCustomSnackBar(context, res['message'] ?? 'Gagal mengecek sesi aktif');
    }
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

    final startDate = '${_filterStart.year}-${_filterStart.month.toString().padLeft(2, '0')}-01';
    final endDate = '${_filterEnd.year}-${_filterEnd.month.toString().padLeft(2, '0')}-${DateTime(_filterEnd.year, _filterEnd.month + 1, 0).day.toString().padLeft(2, '0')}';
    final res = await PenimbanganService.getPenimbangan(bankId, startDate: startDate, endDate: endDate);

    if (!mounted) return;
    if (res['success'] == true) {
      final List data = res['data'] ?? [];
      // Riwayat cuma nampilin sesi yang udah kelar (selesai/dibatalkan).
      final riwayat = data
          .map((item) => SessionData.fromJson(item))
          .where((s) => s.status == 'selesai' || s.status == 'dibatalkan')
          .toList();

      setState(() {
        _riwayat = riwayat;
        _listLoading = false;
      });
    } else {
      setState(() => _listLoading = false);
      showCustomSnackBar(context, res['message'] ?? 'Gagal memuat data');
    }
  }

  // ── 2. Cek jadwal hari ini ───────────────────────────────────────────────
  // ── Bottom sheet "Kelola Sesi Penimbangan" ───────────────────────────────
  void _showKelolaSesiSheet() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final bankId = auth.bankId ?? '';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => _KelolaSesiSheet(
        bankId: bankId,
        onOpenSesiAktif: (penimbanganId) {
          Navigator.pop(sheetContext);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PenimbanganAktifScreen(penimbanganId: penimbanganId),
            ),
          ).then((_) => _init());
        },
        onBatalkanSesi: (penimbanganId) {
          Navigator.pop(sheetContext);
          _showBatalkanSesiSheet(penimbanganId);
        },
        onMulaiSesi: (penimbanganId) {
          Navigator.pop(sheetContext);
          _showMulaiSesiSheet(penimbanganId);
        },
      ),
    ).then((_) => _init());
  }

  // ── Bottom sheet: konfirmasi mulai sesi (dari card pending) ──────────────
  Future<void> _showMulaiSesiSheet(String penimbanganId) async {
    final confirm = await showModalBottomSheet<bool>(
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
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF4EA771).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.scale_rounded,
                  color: Color(0xFF4EA771), size: 26),
            ),
            const SizedBox(height: 16),
            const Text(
              'Mulai Sesi Penimbangan?',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: Color(0xFF013236),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Apakah Anda yakin ingin memulai sesi penimbangan ini? Aksi Anda akan mewakili petugas dan adminnya.',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12.5,
                color: const Color(0xFF013236).withValues(alpha: 0.5),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF013236),
                      side: BorderSide(
                          color: const Color(0xFF013236).withValues(alpha: 0.3)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50)),
                    ),
                    child: const Text(
                      'Kembali',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4EA771),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50)),
                    ),
                    child: const Text(
                      'Buka Sesi',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
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
    );

    if (confirm != true || !mounted) return;

    final res = await PenimbanganService.updatePenimbangan(penimbanganId, 'aktif');
    if (!mounted) return;

    if (res['success'] == true) {
      showCustomSnackBar(context, 'Sesi penimbangan berhasil dibuka', type: SnackBarType.success);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PenimbanganAktifScreen(penimbanganId: penimbanganId),
        ),
      ).then((_) => _init());
    } else {
      showCustomSnackBar(context, res['message'] ?? 'Gagal memulai sesi penimbangan');
    }
  }

  // ── Bottom sheet: konfirmasi + alasan pembatalan sesi ────────────────────
  Future<void> _showBatalkanSesiSheet(String penimbanganId) async {
    final alasanController = TextEditingController();

    final confirm = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: StatefulBuilder(
          builder: (ctx, setSheetState) {
            final alasanFilled = alasanController.text.trim().isNotEmpty;
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.cancel_outlined,
                          color: Color(0xFFEF4444), size: 32),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const SizedBox(
                    width: double.infinity,
                    child: Text(
                      'Batalkan sesi penimbangan?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF013236),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const SizedBox(
                    width: double.infinity,
                    child: Text(
                      'Isi alasan sesi penimbangan tidak jadi dilaksanakan agar nasabah mendapatkan notifikasi',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: alasanController,
                    maxLines: 3,
                    minLines: 3,
                    maxLength: 255,
                    textInputAction: TextInputAction.done,
                    inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\n'))],
                    onChanged: (_) => setSheetState(() {}),
                    style: const TextStyle(
                        fontFamily: 'Poppins', fontSize: 13, color: Color(0xFF013236)),
                    decoration: InputDecoration(
                      hintText: 'Alasan pembatalan sesi penimbangan',
                      hintStyle: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        color: const Color(0xFF013236).withValues(alpha: 0.35),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF5F7FA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1),
                      ),
                      contentPadding: const EdgeInsets.all(14),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.black54,
                            side: const BorderSide(color: Colors.black12),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                          ),
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text(
                            'Kembali',
                            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF4444),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey.shade300,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                          ),
                          onPressed: alasanFilled ? () => Navigator.pop(ctx, true) : null,
                          child: const Text(
                            'Konfirmasi',
                            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );

    final alasan = alasanController.text.trim();
    alasanController.dispose();

    if (confirm != true || !mounted) return;

    final res = await PenimbanganService.batalkanPenimbangan(penimbanganId, alasan);
    if (!mounted) return;

    if (res['success'] == true) {
      showCustomSnackBar(context, 'Sesi penimbangan berhasil dibatalkan', type: SnackBarType.success);
      await _init();
    } else {
      showCustomSnackBar(context, res['message'] ?? 'Gagal membatalkan sesi penimbangan');
    }
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
            image: AssetImage('assets/images/bg_struk2.webp'),
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
                      : CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      // Header card + summary stats — scroll away normally
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildHeaderCard(),
                              const SizedBox(height: 16),
                              _buildSummaryStats(),
                              const SizedBox(height: 15),
                            ],
                          ),
                        ),
                      ),
                      // Sticky: "Riwayat Penimbangan" + filter bulan, pin di bawah TopBarBack
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _StickyHeaderDelegate(
                          height: 116,
                          child: Container(
                            color: Colors.white,
                            padding: const EdgeInsets.only(top: 5),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(24, 20, 20, 8),
                                  child: const Text(
                                    'Riwayat Penimbangan',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF013236),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(20, 5, 20, 15),
                                  child: MonthYearFilterRow(
                                    filterStart: _filterStart,
                                    filterEnd: _filterEnd,
                                    onChanged: (start, end) {
                                      setState(() {
                                        _filterStart = start;
                                        _filterEnd = end;
                                      });
                                      _loadHistory();
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // List — cuma ini yang scroll di bawah sticky header
                      SliverToBoxAdapter(
                        child: Container(
                          width: double.infinity,
                          constraints: BoxConstraints(
                            minHeight: MediaQuery.of(context).size.height,
                          ),
                          padding: const EdgeInsets.fromLTRB(0, 8, 0, 40),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: _buildRiwayatList(),
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
      ),
    );
  }

  // ── HEADER CARD (gabungan jadwal + aksi) ──────────────────────────────────
  Widget _buildHeaderCard() {
    final now = DateTime.now();
    final todayStr = DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(now);

    // ── Masih mengecek status sesi ──
    if (_headerLoading) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF013236),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            const SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(
                  color: Colors.white70, strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Text(
              'Mengecek sesi penimbangan...',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12.5,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      );
    }

    // ── 1 & 2. Sesi sedang berlangsung ──
    if (_isActiveSesi) {
      final detail = _detailAktif;
      final namaJadwal = (detail?.namaJadwalSpesial != null && detail!.namaJadwalSpesial!.isNotEmpty)
          ? detail.namaJadwalSpesial!
          : 'Sesi Penimbangan';
      final jamRange = detail != null
          ? '${detail.jamMulaiFmt.replaceAll(':', '.')} - ${detail.jamSelesaiFmt.replaceAll(':', '.')} WIB'
          : '';

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF013236),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dot badge + link sesi mendatang (satu baris, gak nambah tinggi)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
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
                    const Text(
                      'Sesi sedang berlangsung',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ),
                if (_pendingSessions > 0)
                  GestureDetector(
                    onTap: _showKelolaSesiSheet,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$_pendingSessions sesi lainnya',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                          const SizedBox(width: 3),
                          Icon(Icons.arrow_forward_rounded,
                              size: 10, color: Colors.white.withValues(alpha: 0.85)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            if (detail != null) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.event_note_rounded,
                            size: 15, color: Colors.white),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            namaJadwal,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded,
                            size: 14, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          detail.tanggalFmt,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.access_time_rounded,
                            size: 14, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          jamRange,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            // Button
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PenimbanganAktifScreen(
                    penimbanganId: detail?.penimbanganId ?? '',
                  ),
                ),
              ).then((_) => _init()),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: const Color(0xFF94DF0C),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.open_in_new_rounded,
                        color: Color(0xFF013236), size: 15),
                    SizedBox(width: 7),
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
            ),
          ],
        ),
      );
    }

    // ── 3. Belum ada sesi aktif, tapi ada jadwal hari ini ──
    if (_pendingSessions > 0) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF013236),
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
              'Hari ini ada $_pendingSessions jadwal penimbangan',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: _showKelolaSesiSheet,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.tune_rounded,
                      color: Color(0xFF013236),
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Kelola Sesi Penimbangan',
                      style: TextStyle(
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

    // ── 4. Tidak ada jadwal sama sekali ──
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF013236),
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
          const Text(
            'Tidak ada jadwal penimbangan',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    color: Color(0xFF94DF0C), size: 16),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Penimbangan rutin ataupun penimbangan khusus tidak bisa dilakukan',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: Colors.white,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── SUMMARY STATS ──────────────────────────────────────────────────
  Widget _buildSummaryStats() {
    final totalSesi = _riwayat.length;
    final totalSelesai = _riwayat.where((s) => s.status == 'selesai').length;
    final totalDibatalkan = _riwayat.where((s) => s.status == 'dibatalkan').length;

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
        color: Colors.white,
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
            color: const Color(0xFF013236).withOpacity(0.1),
          ),
        ),
        child: Row(
          children: [
            // Ikon status
            Container(
              padding: const EdgeInsets.all(9),
              decoration:
              BoxDecoration(color: Color(0xFF013236).withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(
                Icons.line_weight,
                color: Color(0xFF013236),
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

// ─── Bottom Sheet: Kelola Sesi Penimbangan ────────────────────────────────
class _KelolaSesiSheet extends StatefulWidget {
  final String bankId;
  final void Function(String penimbanganId) onOpenSesiAktif;
  final void Function(String penimbanganId) onBatalkanSesi;
  final void Function(String penimbanganId) onMulaiSesi;

  const _KelolaSesiSheet({
    required this.bankId,
    required this.onOpenSesiAktif,
    required this.onBatalkanSesi,
    required this.onMulaiSesi,
  });

  @override
  State<_KelolaSesiSheet> createState() => _KelolaSesiSheetState();
}

class _KelolaSesiSheetState extends State<_KelolaSesiSheet> {
  bool _loading = true;
  String? _error;
  List<SesiHariIniItem> _sesi = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    if (widget.bankId.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Bank tidak ditemukan';
      });
      return;
    }

    final res = await PenimbanganService.getSesiHariIni(widget.bankId);

    if (!mounted) return;
    if (res['success'] == true) {
      setState(() {
        _sesi = (res['data'] as List<SesiHariIniItem>?) ?? [];
        _loading = false;
      });
    } else {
      setState(() {
        _error = res['message'] ?? 'Gagal memuat sesi hari ini';
        _loading = false;
      });
    }
  }

  Map<String, dynamic> _statusMeta(String status) {
    switch (status) {
      case 'aktif':
        return {'label': 'Aktif', 'color': const Color(0xFF4EA771), 'bg': const Color(0xFFE8F5E9)};
      case 'selesai':
        return {'label': 'Selesai', 'color': const Color(0xFF4EA771), 'bg': const Color(0xFFE8F5E9)};
      case 'dibatalkan':
        return {'label': 'Dibatalkan', 'color': Colors.red.shade400, 'bg': Colors.red.withValues(alpha: 0.07)};
      case 'pending':
      default:
        return {'label': 'Menunggu', 'color': Colors.orange.shade700, 'bg': Colors.orange.withValues(alpha: 0.1)};
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasAktif = _sesi.any((s) => s.statusPenimbangan == 'aktif');
    // Backend sudah sorting berdasarkan jam mulai paling awal — jadi pending
    // pertama yang ketemu di list ini yang paling awal jamnya.
    String? firstPendingId;
    for (final s in _sesi) {
      if (s.statusPenimbangan == 'pending') {
        firstPendingId = s.penimbanganId;
        break;
      }
    }

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const Text(
            'Kelola Sesi Penimbangan',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: Color(0xFF013236),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Daftar sesi penimbangan hari ini',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11.5,
              color: const Color(0xFF013236).withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: _loading
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: CircularProgressIndicator(color: Color(0xFF4EA771)),
                    ),
                  )
                : _error != null
                    ? _buildSheetError()
                    : _sesi.isEmpty
                        ? _buildSheetEmpty()
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const ClampingScrollPhysics(),
                            itemCount: _sesi.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (_, i) => _buildSesiCard(_sesi[i], hasAktif, firstPendingId),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildSesiCard(SesiHariIniItem item, bool hasAktif, String? firstPendingId) {
    final isAktifItem = item.statusPenimbangan == 'aktif';
    final isPending = item.statusPenimbangan == 'pending';
    final isDisabled = hasAktif
        ? !isAktifItem
        : (item.statusPenimbangan == 'selesai' || item.statusPenimbangan == 'dibatalkan');
    final showAktifButton = isAktifItem;
    // Cuma sesi pending paling awal (backend sudah sorting) yang boleh dibuka/dibatalkan —
    // sesi pending lainnya tetap terlihat normal (tidak disabled), tapi tombolnya disembunyikan.
    final showPendingButtons = !hasAktif && isPending && item.penimbanganId == firstPendingId;
    final meta = _statusMeta(item.statusPenimbangan);
    final namaJadwal = (item.namaJadwalSpesial != null && item.namaJadwalSpesial!.isNotEmpty)
        ? item.namaJadwalSpesial!
        : 'Sesi Penimbangan';
    final jamRange = '${item.jamMulaiFmt.replaceAll(':', '.')} - ${item.jamSelesaiFmt.replaceAll(':', '.')} WIB';

    return Opacity(
      opacity: isDisabled ? 0.45 : 1,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F9F8),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF013236).withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        namaJadwal,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: Color(0xFF013236),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.calendar_today_rounded,
                              size: 11, color: const Color(0xFF013236).withValues(alpha: 0.4)),
                          const SizedBox(width: 6),
                          Text(
                            item.tanggalFmt,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              color: const Color(0xFF013236).withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(Icons.access_time_rounded,
                              size: 11, color: const Color(0xFF013236).withValues(alpha: 0.4)),
                          const SizedBox(width: 6),
                          Text(
                            jamRange,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              color: const Color(0xFF013236).withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: meta['bg'] as Color,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    meta['label'] as String,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: meta['color'] as Color,
                    ),
                  ),
                ),
              ],
            ),
            if (showAktifButton) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: () => widget.onOpenSesiAktif(item.penimbanganId),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: BoxDecoration(
                      color: const Color(0xFF94DF0C),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.open_in_new_rounded, color: Color(0xFF013236), size: 15),
                        SizedBox(width: 8),
                        Text(
                          'Buka Sesi Aktif',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF013236),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ] else if (showPendingButtons) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => widget.onBatalkanSesi(item.penimbanganId),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade400,
                        side: BorderSide(color: Colors.red.shade200),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                      ),
                      child: const Text(
                        'Batalkan Sesi',
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => widget.onMulaiSesi(item.penimbanganId),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4EA771),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                      ),
                      child: const Text(
                        'Mulai Sesi',
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSheetEmpty() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event_busy_rounded, size: 40, color: Colors.grey[300]),
          const SizedBox(height: 10),
          Text(
            'Tidak ada sesi penimbangan hari ini',
            style: TextStyle(fontFamily: 'Poppins', fontSize: 12.5, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildSheetError() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wifi_off_rounded, size: 36, color: Colors.red.withValues(alpha: 0.5)),
          const SizedBox(height: 10),
          Text(
            _error ?? 'Terjadi kesalahan',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12.5,
              color: const Color(0xFF013236).withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _fetch,
            child: const Text(
              'Coba Lagi',
              style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sticky header delegate ───────────────────────────────────────────────────
// Bikin "Riwayat Penimbangan" + filter bulan nempel (pinned) di bawah TopBarBack
// saat di-scroll, sementara cuma list riwayat yang ikut bergerak.
class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  _StickyHeaderDelegate({required this.child, required this.height});

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(covariant _StickyHeaderDelegate oldDelegate) {
    return oldDelegate.child != child || oldDelegate.height != height;
  }
}