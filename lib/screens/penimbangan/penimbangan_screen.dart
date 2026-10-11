import 'package:enviroo/core/format/app_date.dart';
import 'package:enviroo/models/penimbangan_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:enviroo/widgets/custom_snackbar.dart';
import 'package:enviroo/widgets/topbar_back.dart';
import 'package:enviroo/widgets/filter_month_year.dart';
import 'package:enviroo/screens/penimbangan/list_setoran_sesi_screen.dart';
import 'package:enviroo/screens/penimbangan/penimbangan_aktif_screen.dart';
import 'package:enviroo/providers/penimbangan_provider.dart';
import 'package:enviroo/providers/penjualan_provider.dart' show FetchStatus;
import 'package:enviroo/providers/auth_provider.dart';
import 'package:enviroo/core/theme/app_colors.dart';
import 'package:enviroo/core/theme/app_text.dart';
import 'package:enviroo/widgets/state_message.dart';

class PenimbanganScreen extends StatefulWidget {
  @override
  _PenimbanganScreenState createState() => _PenimbanganScreenState();
}

class _PenimbanganScreenState extends State<PenimbanganScreen> {
  bool _listLoading = true;

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

  Future<void> _init() async {
    await Future.wait([_loadHistory(), _checkActive()]);
  }

  Future<void> _checkActive() async {
    setState(() => _headerLoading = true);

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final bankId = auth.bankId ?? '';

    if (bankId.isEmpty) {
      setState(() => _headerLoading = false);
      return;
    }

    final prov = context.read<PenimbanganProvider>();
    await prov.fetchSesiAktif(bankId);

    if (!mounted) return;
    final sesi = prov.sesiAktif;
    if (sesi != null) {
      setState(() {
        _isActiveSesi = sesi.isActive;
        _detailAktif = sesi.detail;
        _pendingSessions = sesi.pendingSessions;
        _headerLoading = false;
      });
    } else {
      setState(() => _headerLoading = false);
      showCustomSnackBar(
          context, prov.sesiAktifError ?? 'Gagal mengecek sesi aktif');
    }
  }

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
    final prov = context.read<PenimbanganProvider>();
    await prov.fetchRiwayat(bankId, startDate: startDate, endDate: endDate);

    if (!mounted) return;
    if (prov.riwayatStatus == FetchStatus.success) {
      setState(() {
        _riwayat = prov.riwayat
            .where((s) => s.status == 'selesai' || s.status == 'dibatalkan')
            .toList();
        _listLoading = false;
      });
    } else {
      setState(() => _listLoading = false);
      showCustomSnackBar(context, prov.riwayatError ?? 'Gagal memuat data');
    }
  }

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
                color: AppColors.green.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.scale_rounded,
                  color: AppColors.green, size: 26),
            ),
            const SizedBox(height: 16),
            Text(
              'Mulai Sesi Penimbangan?',
              style: AppText.w700(15, AppColors.dark),
            ),
            const SizedBox(height: 8),
            Text(
              'Apakah Anda yakin ingin memulai sesi penimbangan ini? Aksi Anda akan mewakili petugas dan adminnya.',
              style: AppText.p(12.5, color: AppColors.dark.withValues(alpha: 0.5), height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.dark,
                      side: BorderSide(
                          color: AppColors.dark.withValues(alpha: 0.3)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50)),
                    ),
                    child: Text(
                      'Kembali',
                      style: AppText.w600(13),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.green,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50)),
                    ),
                    child: Text(
                      'Buka Sesi',
                      style: AppText.w600(13),
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

    final res = await context
        .read<PenimbanganProvider>()
        .updateStatus(penimbanganId, 'aktif');
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
                        color: AppColors.danger.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.cancel_outlined,
                          color: AppColors.danger, size: 32),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      'Batalkan sesi penimbangan?',
                      textAlign: TextAlign.center,
                      style: AppText.w700(17, AppColors.dark),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      'Isi alasan sesi penimbangan tidak jadi dilaksanakan agar nasabah mendapatkan notifikasi',
                      textAlign: TextAlign.center,
                      style: AppText.r(13, Colors.black54),
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
                    style: AppText.r(13, AppColors.dark),
                    decoration: InputDecoration(
                      hintText: 'Alasan pembatalan sesi penimbangan',
                      hintStyle: AppText.r(13, AppColors.dark.withValues(alpha: 0.35)),
                      filled: true,
                      fillColor: const Color(0xFFF5F7FA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.danger, width: 1),
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
                            backgroundColor: AppColors.danger,
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

    final res = await context
        .read<PenimbanganProvider>()
        .batalkanSesi(penimbanganId, alasan);
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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceCool,
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
                  color: AppColors.green,
                  child: _listLoading
                      ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.green))
                      : CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
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
                                  child: Text(
                                    'Riwayat Penimbangan',
                                    style: AppText.w600(14, AppColors.dark),
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
                      SliverLayoutBuilder(
                        builder: (context, sc) => SliverToBoxAdapter(
                          child: Container(
                            width: double.infinity,
                            constraints: BoxConstraints(
                              minHeight: (sc.viewportMainAxisExtent -
                                      sc.precedingScrollExtent)
                                  .clamp(0.0, double.infinity),
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

  Widget _buildHeaderCard() {
    final now = DateTime.now();
    final todayStr = AppDate.tanggalPenuh(now);

    if (_headerLoading) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.dark,
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
              style: AppText.r(12.5, Colors.white.withValues(alpha: 0.7)),
            ),
          ],
        ),
      );
    }

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
          color: AppColors.dark,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.neon,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Sesi sedang berlangsung',
                      style: AppText.r(11, Colors.white60),
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
                            style: AppText.w600(10, Colors.white.withValues(alpha: 0.85)),
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
                            style: AppText.w700(13, Colors.white),
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
                          style: AppText.w500(11.5, Colors.white),
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
                          style: AppText.w500(11.5, Colors.white),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
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
                  color: AppColors.neon,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.open_in_new_rounded,
                        color: AppColors.dark, size: 15),
                    SizedBox(width: 7),
                    Text(
                      'Buka Sesi Aktif',
                      style: AppText.w700(13, AppColors.dark),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_pendingSessions > 0) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.dark,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hari ini, $todayStr',
              style: AppText.r(11, Colors.white60),
            ),
            const SizedBox(height: 4),
            Text(
              'Hari ini ada $_pendingSessions jadwal penimbangan',
              style: AppText.w600(13, Colors.white),
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.tune_rounded,
                      color: AppColors.dark,
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Kelola Sesi Penimbangan',
                      style: AppText.w600(13, AppColors.dark),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.dark,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hari ini, $todayStr',
            style: AppText.r(11, Colors.white60),
          ),
          const SizedBox(height: 4),
          Text(
            'Tidak ada jadwal penimbangan',
            style: AppText.w600(13, Colors.white),
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
                    color: AppColors.neon, size: 16),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Penimbangan rutin ataupun penimbangan khusus tidak bisa dilakukan',
                    style: AppText.p(11, color: Colors.white, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStats() {
    final totalSesi = _riwayat.length;
    final totalSelesai = _riwayat.where((s) => s.status == 'selesai').length;
    final totalDibatalkan = _riwayat.where((s) => s.status == 'dibatalkan').length;

    return Row(
      children: [
        Expanded(child: _statCard(
          iconColor: AppColors.dark,
          label: 'Sesi Total',
          value: totalSesi.toString(),
        )),
        const SizedBox(width: 10),
        Expanded(child: _statCard(
          iconColor: AppColors.green,
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
          color: AppColors.dark.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: AppText.p(20, weight: FontWeight.w700, color: iconColor, height: 1.1),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppText.r(10, AppColors.dark.withValues(alpha: 0.5)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRiwayatList() {
    if (_riwayat.isEmpty) {
      return StateMessage(
        illustration: StateArt.empty,
        message: 'Belum ada riwayat penimbangan',
        subtitle: 'Riwayat penimbangan bakal muncul kalau udah ada sesi penimbangan',
      );
    }

    final filtered = _filteredRiwayat;
    if (filtered.isEmpty) {
      return StateMessage(
        illustration: StateArt.empty,
        message: 'Tidak ada riwayat di rentang waktu ini',
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
    isSelesai ? AppColors.green : Colors.red.shade400;
    final bgColor = isSelesai
        ? AppColors.mintPale
        : Colors.red.withValues(alpha: 0.07);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ListSetoranSesiScreen(
            penimbanganId: s.id,
            tanggalPenimbangan: s.fullTanggal,
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            width: 1,
            color: AppColors.dark.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration:
              BoxDecoration(color: AppColors.dark.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(
                Icons.line_weight,
                color: AppColors.dark,
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
                    style: AppText.w600(13, AppColors.dark),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    s.waktu,
                    style: AppText.r(11.5, Colors.grey[500]),
                  ),
                ],
              ),
            ),
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isSelesai ? 'Selesai' : 'Dibatalkan',
                style: AppText.w600(10.5, statusColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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

    final prov = context.read<PenimbanganProvider>();
    await prov.fetchSesiHariIni(widget.bankId);

    if (!mounted) return;
    if (prov.sesiHariIniStatus == FetchStatus.success) {
      setState(() {
        _sesi = prov.sesiHariIni;
        _loading = false;
      });
    } else {
      setState(() {
        _error = prov.sesiHariIniError ?? 'Gagal memuat sesi hari ini';
        _loading = false;
      });
    }
  }

  Map<String, dynamic> _statusMeta(String status) {
    switch (status) {
      case 'aktif':
        return {'label': 'Aktif', 'color': AppColors.green, 'bg': AppColors.mintPale};
      case 'selesai':
        return {'label': 'Selesai', 'color': AppColors.green, 'bg': AppColors.mintPale};
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
          Text(
            'Kelola Sesi Penimbangan',
            style: AppText.w700(15, AppColors.dark),
          ),
          const SizedBox(height: 4),
          Text(
            'Daftar sesi penimbangan hari ini',
            style: AppText.r(11.5, AppColors.dark.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: _loading
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.green),
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
          color: AppColors.surfaceCool,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.dark.withValues(alpha: 0.08)),
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
                        style: AppText.w700(13, AppColors.dark),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.calendar_today_rounded,
                              size: 11, color: AppColors.dark.withValues(alpha: 0.4)),
                          const SizedBox(width: 6),
                          Text(
                            item.tanggalFmt,
                            style: AppText.r(11, AppColors.dark.withValues(alpha: 0.5)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(Icons.access_time_rounded,
                              size: 11, color: AppColors.dark.withValues(alpha: 0.4)),
                          const SizedBox(width: 6),
                          Text(
                            jamRange,
                            style: AppText.r(11, AppColors.dark.withValues(alpha: 0.5)),
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
                    style: AppText.w600(10, meta['color'] as Color),
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
                      color: AppColors.neon,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.open_in_new_rounded, color: AppColors.dark, size: 15),
                        SizedBox(width: 8),
                        Text(
                          'Buka Sesi Aktif',
                          style: AppText.w700(12.5, AppColors.dark),
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
                      child: Text(
                        'Batalkan Sesi',
                        style: AppText.w600(12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => widget.onMulaiSesi(item.penimbanganId),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.green,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                      ),
                      child: Text(
                        'Mulai Sesi',
                        style: AppText.w600(12),
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

  Widget _buildSheetEmpty() => StateMessage(
        illustration: StateArt.empty,
        illustrationWidth: 80,
        message: 'Tidak ada sesi penimbangan hari ini',
      );

  Widget _buildSheetError() => StateMessage(
        illustration: StateArt.error,
        illustrationWidth: 80,
        message: _error ?? 'Terjadi kesalahan',
        action: TextButton(
          onPressed: _fetch,
          child: const Text(
            'Coba Lagi',
            style:
                TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
          ),
        ),
      );
}

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
