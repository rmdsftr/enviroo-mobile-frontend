import 'package:enviroo/models/jadwal_model.dart';
import 'package:enviroo/providers/auth_provider.dart';
import 'package:enviroo/services/jadwal_service.dart';
import 'package:enviroo/services/penimbangan_service.dart';
import 'package:enviroo/widgets/custom_snackbar.dart';
import 'package:enviroo/widgets/filter_month_year.dart';
import 'package:enviroo/widgets/topbar_back.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

// ── Screen ───────────────────────────────────────────────────────────────────
// Petugas_bsm membatalkan jadwal penimbangan MENDATANG (belum dimulai) —
// beda dari pembatalan sesi yang udah aktif (itu dari menu penimbangan).
class BatalPenimbanganScreen extends StatefulWidget {
  const BatalPenimbanganScreen({super.key});

  @override
  State<BatalPenimbanganScreen> createState() =>
      _BatalPenimbanganScreenState();
}

class _BatalPenimbanganScreenState extends State<BatalPenimbanganScreen> {
  static const _dark = Color(0xFF013236);
  static const _green = Color(0xFF4EA771);
  static const _surface = Color(0xFFF5F9F3);

  late DateTime _filterStart;
  late DateTime _filterEnd;

  bool _isLoading = true;
  String? _error;
  List<JadwalPenimbanganItem> _jadwalList = [];
  JadwalPenimbanganItem? _selectedJadwal;

  final _alasanController = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    // Default 2 bulan ke depan (bulan ini + bulan depan) — kalau cuma bulan
    // ini, jadwal yang jatuh di awal bulan depan (mis. hari ini 31 Agustus)
    // gak akan kelihatan buat dibatalkan.
    _filterStart = DateTime(now.year, now.month);
    _filterEnd = DateTime(now.year, now.month + 1);
    _alasanController.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchJadwal());
  }

  @override
  void dispose() {
    _alasanController.dispose();
    super.dispose();
  }

  bool get _isValid =>
      _selectedJadwal != null && _alasanController.text.trim().isNotEmpty;

  // ── Fetch jadwal mendatang (bisa lintas beberapa bulan kalau range dipilih) ──
  Future<void> _fetchJadwal() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final auth = context.read<AuthProvider>();
    final bankId = auth.bankId;
    if (bankId == null) {
      setState(() {
        _isLoading = false;
        _error = 'Bank tidak ditemukan.';
      });
      return;
    }

    final merged = <JadwalPenimbanganItem>[];
    bool anySuccess = false;
    String? lastError;

    var cursor = DateTime(_filterStart.year, _filterStart.month);
    final end = DateTime(_filterEnd.year, _filterEnd.month);
    while (!cursor.isAfter(end)) {
      final res = await JadwalService.getJadwalPenimbanganBsm(
        bankId,
        month: cursor.month,
        year: cursor.year,
      );
      if (res['success'] == true) {
        anySuccess = true;
        merged.addAll((res['data'] as List<JadwalPenimbanganItem>?) ?? []);
      } else {
        lastError = res['message']?.toString();
      }
      cursor = DateTime(cursor.year, cursor.month + 1);
    }

    if (!mounted) return;

    // Cuma jadwal yang beneran masih bisa dibatalkan: belum lewat, masih
    // aktif, dan statusnya masih 'upcoming' (belum pending/aktif/selesai/dibatalkan).
    final today = DateTime.now();
    final todayNorm = DateTime(today.year, today.month, today.day);
    // Notifikasi pengingat ke nasabah dikirim jam 20.00 — begitu lewat jam
    // segitu, jadwal hari ini gak boleh muncul lagi buat dibatalkan.
    final pastReminderCutoff = today.hour >= 20;
    final filtered = merged.where((j) {
      final tglNorm = DateTime(j.tanggal.year, j.tanggal.month, j.tanggal.day);
      if (pastReminderCutoff && tglNorm.isAtSameMomentAs(todayNorm)) return false;
      return j.isActive &&
          j.statusJadwal == 'upcoming' &&
          !tglNorm.isBefore(todayNorm);
    }).toList()
      ..sort((a, b) => a.tanggal.compareTo(b.tanggal));

    setState(() {
      _isLoading = false;
      _jadwalList = filtered;
      _error = (!anySuccess && filtered.isEmpty) ? lastError : null;
      if (_selectedJadwal != null &&
          !filtered.any((j) => j.jadwalId == _selectedJadwal!.jadwalId)) {
        _selectedJadwal = null;
      }
    });
  }

  // ── Submit ────────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    final jadwal = _selectedJadwal;
    final alasan = _alasanController.text.trim();
    if (jadwal == null || alasan.isEmpty) return;

    setState(() => _submitting = true);

    final res = await PenimbanganService.batalkanJadwalPenimbangan(
      jadwalId: jadwal.jadwalId,
      tanggalSesi: DateFormat('yyyy-MM-dd').format(jadwal.tanggal),
      alasanPembatalan: alasan,
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (res['success'] == true) {
      HapticFeedback.mediumImpact();
      showCustomSnackBar(
        context,
        res['message'] ?? 'Jadwal penimbangan berhasil dibatalkan',
        type: SnackBarType.success,
      );
      await Future.delayed(const Duration(milliseconds: 700));
      if (mounted) Navigator.pop(context, true);
    } else {
      showCustomSnackBar(
        context,
        res['message'] ?? 'Gagal membatalkan jadwal penimbangan',
      );
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
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
              const TopBarBack(title: 'Pembatalan Jadwal'),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, viewport) {
                    return SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: viewport.maxHeight),
                        // IntrinsicHeight ngasih tinggi konkret (bukan infinity)
                        // ke Column ini, jadi Expanded di bawah bisa beneran
                        // ngedorong tombol mentok ke bawah pas konten pendek —
                        // tanpa dibikin sticky/pinned. Pas konten lebih panjang
                        // dari layar, Expanded gak maksa nyusut, jadi tombol
                        // tetap lanjut ikut discroll di bawah konten.
                        child: IntrinsicHeight(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                        child: Text(
                                          'Jadwal penimbangan maksimal dibatalkan sebelum notifikasi pengingat dikirim ke nasabah pukul 20.00. Jika terlewat, sesi penimbangan masih bisa dibatalkan dari menu penimbangan',
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 12.5,
                                            height: 1.6,
                                            color: _dark.withValues(alpha: 0.65),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 18),
                                      _buildJadwalCard(),
                                      const SizedBox(height: 16),
                                      _buildAlasanCard(),
                                    ],
                                  ),
                                ),
                              ),
                              _buildBottomBar(),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Label wajib diisi, dipakai bareng di kedua card ─────────────────────────
  Widget _buildRequiredLabel(String text) {
    return Row(
      children: [
        Text(
          text,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: _dark,
          ),
        ),
        const Text(
          '*',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: Colors.red,
          ),
        ),
      ],
    );
  }

  // ── Card 1: Pilih Jadwal ─────────────────────────────────────────────────────
  Widget _buildJadwalCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _dark.withValues(alpha: 0.1), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MonthYearFilterRow(
            filterStart: _filterStart,
            filterEnd: _filterEnd,
            allowFutureMonths: true,
            allowPastMonths: false,
            onChanged: (start, end) {
              setState(() {
                _filterStart = start;
                _filterEnd = end;
              });
              _fetchJadwal();
            },
          ),
          const SizedBox(height: 16),
          _buildRequiredLabel('Pilih Jadwal'),
          const SizedBox(height: 10),
          _buildJadwalList(),
        ],
      ),
    );
  }

  // ── Card 2: Alasan Pembatalan ────────────────────────────────────────────────
  Widget _buildAlasanCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _dark.withValues(alpha: 0.1), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRequiredLabel('Alasan Pembatalan'),
          const SizedBox(height: 8),
          _buildAlasanField(),
        ],
      ),
    );
  }

  // ── Bottom bar: tombol konfirmasi, nempel kiri/kanan layar (ikut scroll) ────
  Widget _buildBottomBar() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: _buildCTA(),
    );
  }

  // ── List jadwal mendatang (selectable, scroll di dalam container sendiri) ──
  // 30+ jadwal sekalipun gak akan bikin halaman ini melar — list-nya dibatasi
  // tinggi & discroll di dalam, pakai ListView.builder biar item-nya lazy-built.
  static const double _jadwalListHeight = 260;

  Widget _buildJadwalList() {
    if (_isLoading) {
      return const SizedBox(
        height: _jadwalListHeight,
        child: Center(child: CircularProgressIndicator(color: _green)),
      );
    }

    if (_error != null) {
      return SizedBox(
        height: _jadwalListHeight,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.red.shade400),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: _fetchJadwal,
                child: const Text('Coba lagi', style: TextStyle(fontFamily: 'Poppins', color: _green)),
              ),
            ],
          ),
        ),
      );
    }

    if (_jadwalList.isEmpty) {
      return Container(
        width: double.infinity,
        height: _jadwalListHeight,
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy_rounded, size: 28, color: _dark.withValues(alpha: 0.25)),
            const SizedBox(height: 8),
            Text(
              'Gak ada jadwal mendatang di periode ini',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: _dark.withValues(alpha: 0.45)),
            ),
          ],
        ),
      );
    }

    return Container(
      height: _jadwalListHeight,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _jadwalList.length,
        itemBuilder: (_, i) => _buildJadwalOption(_jadwalList[i]),
      ),
    );
  }

  Widget _buildJadwalOption(JadwalPenimbanganItem j) {
    final isSelected = _selectedJadwal?.jadwalId == j.jadwalId;
    final months = ['','Jan','Feb','Mar','Apr','Mei','Jun','Jul','Ags','Sep','Okt','Nov','Des'];
    final dayNames = ['', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    final dateStr = '${dayNames[j.tanggal.weekday]}, ${j.tanggal.day} ${months[j.tanggal.month]}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () => setState(() => _selectedJadwal = j),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? _green.withValues(alpha: 0.08) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? _green : _dark.withValues(alpha: 0.08),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: (isSelected ? _green : _dark).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${j.tanggal.day}',
                      style: TextStyle(
                        fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w700,
                        color: isSelected ? _green : _dark, height: 1.1,
                      ),
                    ),
                    Text(
                      months[j.tanggal.month].toUpperCase(),
                      style: TextStyle(
                        fontFamily: 'Poppins', fontSize: 7,
                        fontWeight: FontWeight.w600,
                        color: (isSelected ? _green : _dark).withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      j.namaJadwal.isNotEmpty ? j.namaJadwal : 'Penimbangan',
                      style: const TextStyle(
                        fontFamily: 'Poppins', fontSize: 12.5, fontWeight: FontWeight.w600, color: _dark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$dateStr  •  ${j.formattedJam}',
                      style: TextStyle(
                        fontFamily: 'Poppins', fontSize: 10.5, color: _dark.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 20, height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? _green : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? _green : _dark.withValues(alpha: 0.25),
                    width: 1.5,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check_rounded, size: 13, color: Colors.white)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Alasan field (max 255, sama kayak penyerahan_insentif_manual_screen) ────
  Widget _buildAlasanField() {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _dark.withValues(alpha: 0.12)),
      ),
      child: TextField(
        controller: _alasanController,
        maxLines: 4,
        minLines: 4,
        maxLength: 255,
        textInputAction: TextInputAction.done,
        inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\n'))],
        style: const TextStyle(
          fontFamily: 'Poppins', fontSize: 13, color: _dark, height: 1.5,
        ),
        decoration: InputDecoration(
          hintText: 'Tulis alasan pembatalan jadwal penimbangan ini',
          hintStyle: TextStyle(
            fontFamily: 'Poppins', fontSize: 13, color: _dark.withValues(alpha: 0.35),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          counterStyle: TextStyle(
            fontFamily: 'Poppins', fontSize: 11, color: _dark.withValues(alpha: 0.35),
          ),
        ),
      ),
    );
  }

  Widget _buildCTA() {
    final disabled = !_isValid || _submitting;
    return SizedBox(
      width: double.infinity,
      child: Container(
        decoration: BoxDecoration(
          color: disabled ? Colors.grey.shade400 : Colors.red.shade400,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: disabled ? null : _submit,
            borderRadius: BorderRadius.circular(50),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 15),
              child: Center(
                child: _submitting
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Text(
                        'Konfirmasi Pembatalan Jadwal',
                        style: TextStyle(
                          fontFamily: 'Poppins', color: Colors.white,
                          fontSize: 13.5, fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
