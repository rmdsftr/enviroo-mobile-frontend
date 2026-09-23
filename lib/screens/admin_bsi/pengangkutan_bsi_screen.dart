import 'dart:async';
import 'package:enviroo/models/pengangkutan_bsi_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:enviroo/widgets/topbar_back.dart';
import 'package:enviroo/widgets/search.dart';
import 'package:enviroo/widgets/custom_snackbar.dart';
import 'package:enviroo/widgets/filter_month_year.dart';
import 'package:enviroo/widgets/filter_chip_row.dart';
import 'package:enviroo/widgets/navbar.dart';
import 'package:enviroo/services/pengangkutan_service.dart';
import 'package:enviroo/providers/auth_provider.dart';
import 'package:enviroo/providers/pengangkutan_provider.dart';
import 'package:enviroo/screens/admin_bsi/detail_pengangkutan_screen.dart';
import 'package:enviroo/screens/admin_bsi/alur_sesi_pengangkutan_screen.dart';

// ─── Screen ─────────────────────────────────────────────────────────────────

class PengangkutanBsiScreen extends StatefulWidget {
  final int initialTab;
  final String initialFilter;

  const PengangkutanBsiScreen({
    super.key,
    this.initialTab = 0,
    this.initialFilter = 'semua',
  });

  @override
  State<PengangkutanBsiScreen> createState() => _PengangkutanBsiScreenState();
}

class _PengangkutanBsiScreenState extends State<PengangkutanBsiScreen> {
  bool _listLoading = true;
  bool _actionLoading = false;
  List<PengangkutanData> _riwayat = [];
  List<PengangkutanAktifBsiData> _activeSessions = [];
  List<BsuUnit> _bsuList = [];
  List<JadwalHariIniItem> _jadwalHariIni = [];
  int _selectedTab = 0;
  String _filterSesi = 'semua';
  String? _highlightedId;
  Timer? _highlightTimer;

  PengangkutanProvider? _pengangkutanProvider;
  int _lastRefreshToken = -1;

  // ── Filter bulan-tahun (default 3 bulan terakhir) ─────────────────────────
  DateTime _filterStart = DateTime(DateTime.now().year, DateTime.now().month - 2);
  DateTime _filterEnd = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
    _filterSesi = widget.initialFilter;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _init();
      _pengangkutanProvider = context.read<PengangkutanProvider>();
      _lastRefreshToken = _pengangkutanProvider!.refreshToken;
      _pengangkutanProvider!.addListener(_onPengangkutanRefresh);
    });
  }

  @override
  void dispose() {
    _highlightTimer?.cancel();
    _pengangkutanProvider?.removeListener(_onPengangkutanRefresh);
    super.dispose();
  }

  void _onPengangkutanRefresh() {
    if (!mounted || _pengangkutanProvider == null) return;
    final token = _pengangkutanProvider!.refreshToken;
    if (token != _lastRefreshToken) {
      _lastRefreshToken = token;
      _init();
    }
  }

  Future<void> _init() async {
    await Future.wait([_loadHistory(), _loadBsuList(), _loadActiveSessions(), _loadJadwalHariIni()]);
  }

  Future<void> _loadJadwalHariIni() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final bankId = auth.bankId ?? '';
    if (bankId.isEmpty) return;
    final res = await PengangkutanService.checkJadwalHariIni(bankId);
    if (!mounted) return;
    if (res['success'] == true) {
      final List raw = res['jadwal_hari_ini'] as List? ?? [];
      setState(() {
        _jadwalHariIni = raw
            .map((e) => JadwalHariIniItem.fromJson(e as Map<String, dynamic>))
            .toList();
      });
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
    final res = await PengangkutanService.getAllPengangkutan(bankId, startDate: startDate, endDate: endDate);
    if (!mounted) return;

    if (res['success'] == true) {
      final List data = res['data'] ?? [];
      final List<PengangkutanData> riwayat = [];
      for (var item in data) {
        final p = PengangkutanData.fromJson(item);
        if (p.status != 'otw' && p.status != 'requested' && p.status != 'approved') {
          riwayat.add(p);
        }
      }
      setState(() {
        _riwayat = riwayat;
        _listLoading = false;
      });
    } else {
      setState(() => _listLoading = false);
      _showSnackBar(res['message'] ?? 'Gagal memuat data', isError: true);
    }
  }

  // ── 1b. Load active sessions from dedicated endpoint ────────────────────
  Future<void> _loadActiveSessions() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final bankId = auth.bankId ?? '';
    final adminId = auth.identityId ?? '';
    if (bankId.isEmpty) return;

    final res = await PengangkutanService.getAllActivePengangkutan(bankId, adminId);
    if (!mounted) return;
    if (res['success'] == true) {
      final List data = res['data'] ?? [];
      setState(() {
        _activeSessions = data
            .map((e) => PengangkutanAktifBsiData.fromJson(e as Map<String, dynamic>))
            .toList();
      });
      _applyPendingHighlight();
    }
  }

  void _applyPendingHighlight() {
    final highlightId = _pengangkutanProvider?.pendingHighlightId;
    if (highlightId == null) return;
    if (!_activeSessions.any((s) => s.pengangkutanId == highlightId)) return;
    _pengangkutanProvider!.clearHighlight();
    setState(() => _highlightedId = highlightId);
    _highlightTimer?.cancel();
    _highlightTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) setState(() => _highlightedId = null);
    });
  }

  static const _sesiFilterItems = [
    FilterChipItem(value: 'semua',     label: 'Semua'),
    FilterChipItem(value: 'requested', label: 'Diajukan'),
    FilterChipItem(value: 'approved',  label: 'Disetujui'),
    FilterChipItem(value: 'otw',       label: 'Sedang Berjalan'),
  ];

  List<PengangkutanAktifBsiData> get _filteredSessions =>
      _filterSesi == 'semua'
          ? _activeSessions
          : _activeSessions.where((s) => s.statusTerkini == _filterSesi).toList();

  List<PengangkutanData> get _filteredRiwayat {
    return _riwayat.where((s) {
      if (s.rawDate == null) return true;
      final d = DateTime(s.rawDate!.year, s.rawDate!.month);
      final start = DateTime(_filterStart.year, _filterStart.month);
      final end = DateTime(_filterEnd.year, _filterEnd.month);
      return !d.isBefore(start) && !d.isAfter(end);
    }).toList();
  }

  // ── 2. Load BSU list ─────────────────────────────────────────────────────
  Future<void> _loadBsuList() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final bankId = auth.bankId ?? '';
    if (bankId.isEmpty) return;

    final res = await PengangkutanService.getUnitBsi(bankId);
    if (!mounted) return;
    if (res['success'] == true) {
      final List data = res['data'] ?? [];
      setState(() {
        _bsuList = data.map((e) => BsuUnit.fromJson(e)).toList();
      });
    }
  }

  // ── 3. Pilih BSU lalu mulai sesi ─────────────────────────────────────────
  void _onMulaiSesiTap() {
    if (_bsuList.isEmpty) {
      _showSnackBar('Tidak ada BSU terdaftar', isError: true);
      return;
    }
    _showPilihBsuDialog();
  }

  void _showPilihBsuDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _BsuPickerSheet(
        bsuList: _bsuList,
        activeBsuIds: _activeSessions.map((s) => s.bsuId).toSet(),
        jadwalHariIni: _jadwalHariIni,
        onSelected: (bsu, jadwalId) {
          Navigator.pop(ctx);
          _checkAndStartSesi(bsu, jadwalId);
        },
      ),
    );
  }

  Future<void> _checkAndStartSesi(BsuUnit bsu, String jadwalId) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final bsiId = auth.bankId ?? '';
    final adminId = auth.identityId ?? '';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _MandiriPickerSheet(
        namaBsu: bsu.namaBank,
        onSelected: (isMandiri) {
          Navigator.pop(context);
          _startSesi(bsiId, bsu.bankId, adminId, isMandiri, jadwalId);
        },
      ),
    );
  }

  Future<void> _startSesi(String bsiId, String bsuId, String adminId, bool isMandiri, String jadwalId) async {
    setState(() => _actionLoading = true);
    final res = await PengangkutanService.startSesi(
      bsiId, bsuId, adminId,
      isMandiri: isMandiri,
      jadwalId: jadwalId,
    );
    if (!mounted) return;
    setState(() => _actionLoading = false);

    if (res['success'] == true) {
      _showSnackBar('Sesi pengangkutan berhasil dimulai');
      await _init();
    } else {
      _showSnackBar(res['message'] ?? 'Gagal memulai sesi', isError: true);
    }
  }

  // ── Buka halaman detail pengangkutan (struk) ─────────────────────────────
  void _openDetailPengangkutan(PengangkutanData s) {
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

  void _showSnackBar(String msg, {bool isError = false}) {
    showCustomSnackBar(
      context,
      msg,
      type: isError ? SnackBarType.error : SnackBarType.success,
    );
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
            alignment: Alignment.topCenter,
          ),
        ),
        child: SafeArea(
          child: Column(children: [
            const TopBarBack(title: 'Pengangkutan'),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _init,
                color: const Color(0xFF4EA771),
                child: _listLoading
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF4EA771)))
                    : _selectedTab == 0
                        ? _buildRiwayatTab()
                        : _buildSesiTab(),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _mainNavbar() => Padding(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 4),
        child: MainNavbar(
          selectedIndex: _selectedTab,
          onTabChanged: (i) {
            setState(() => _selectedTab = i);
            if (i == 0) _loadHistory();
            if (i == 1) _loadActiveSessions();
          },
          tabs: const ['Riwayat', 'Sesi'],
          badges: [null, _activeSessions.isEmpty ? null : _activeSessions.length],
          backgroundColor: Colors.white.withValues(alpha: 0.6),
          border: Border.all(
            color: const Color(0xFF013236).withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      );

  Widget _buildRiwayatTab() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _mainNavbar(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: _buildStartSection(),
          ),
          Container(
            width: double.infinity,
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
            ),
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 17, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Riwayat Pengangkutan',
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 14,
                              fontWeight: FontWeight.w600, color: Color(0xFF013236))),
                      const SizedBox(height: 12),
                      MonthYearFilterRow(
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
                    ]
                  ),
                ),
                SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildRiwayatList(),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSesiTab() {
    final filtered = _filteredSessions;
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          _mainNavbar(),
          const SizedBox(height: 10),
          FilterChipRow<String>(
            items: _sesiFilterItems,
            selectedValue: _filterSesi,
            onSelected: (v) => setState(() => _filterSesi = v),
          ),
          const SizedBox(height: 20),
          if (filtered.isEmpty)
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.45,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_shipping_outlined, size: 52,
                      color: Colors.white.withValues(alpha: 0.4)),
                  const SizedBox(height: 12),
                  Text(
                    _activeSessions.isEmpty
                        ? 'Tidak ada sesi aktif'
                        : 'Tidak ada sesi dengan status ini',
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.7)),
                  ),
                  if (_activeSessions.isEmpty) ...[
                    const SizedBox(height: 6),
                    Text('Mulai sesi pengangkutan dari tab Riwayat',
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.5))),
                  ],
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(children: [
                ...filtered.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _buildActiveCard(s),
                )),
              ]),
            ),
        ],
      ),
    );
  }

  // ── Tombol mulai sesi ────────────────────────────────────────────────────
  Widget _buildStartSection() {
    final isLoading = _actionLoading;
    final now = DateTime.now();
    final todayStr = DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(now);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color : Color(0xFF013236),
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
            _jadwalHariIni.isEmpty
                ? 'Tidak ada jadwal pengangkutan hari ini'
                : _jadwalHariIni.every((j) => j.isCompleted)
                    ? 'Semua pengangkutan sudah selesai'
                    : 'Ada ${_jadwalHariIni.where((j) => !j.isCompleted).length} Jadwal Pengangkutan',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: isLoading ? null : _onMulaiSesiTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isLoading ? Colors.white.withOpacity(0.5) : Colors.white,
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
                  : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_shipping_rounded,
                      color: Color(0xFF013236), size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Cek Sesi Pengangkutan',
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

  // ── Card sesi aktif ─────────────────────────────────────────────────────
  Widget _buildActiveCard(PengangkutanAktifBsiData s) {
    final statusColor = _statusColor(s.statusTerkini);
    final statusLabel = _statusLabel(s.statusTerkini);
    final isHighlighted = _highlightedId == s.pengangkutanId;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF013236),
            borderRadius: BorderRadius.circular(20),
            border: isHighlighted
                ? Border.all(color: const Color(0xFF94DF0C), width: 1)
                : null,
            boxShadow: isHighlighted
                ? [BoxShadow(
                    color: const Color(0xFF94DF0C).withValues(alpha: 0.4),
                    blurRadius: 18,
                    spreadRadius: 2,
                  )]
                : null,
          ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pengangkutan Aktif',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
          const SizedBox(height: 16),
          _infoDetailRowDark(
            Icons.store_rounded,
            'BSU',
            Text(
              s.namaBsu,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 10),
          _infoDetailRowDark(
            Icons.info_outline_rounded,
            'Status Terkini',
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _infoDetailRowDark(
            Icons.tag_rounded,
            'ID Pengangkutan',
            Text(
              s.pengangkutanId,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AlurSesiPengangkutanScreen(
                      pengangkutanId: s.pengangkutanId),
                ),
              ),
              icon: const Icon(Icons.open_in_new_rounded, size: 16),
              label: const Text(
                'Lanjutkan Sesi',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF013236),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
            ),
          ),
        ],
      ),
        ),
        if (isHighlighted)
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: const BoxDecoration(
                color: Color(0xFF94DF0C),
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(12),
                ),
              ),
              child: const Text(
                'Baru',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _infoDetailRowDark(IconData icon, String label, Widget valueWidget) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 13, color: Colors.white70),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      color: Colors.white60)),
              const SizedBox(height: 2),
              valueWidget,
            ],
          ),
        ),
      ],
    );
  }

  // ── Riwayat list ─────────────────────────────────────────────────────────
  Widget _buildRiwayatList() {
    final filtered = _filteredRiwayat;
    if (filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 36),
          child: Column(children: [
            Icon(Icons.history_toggle_off_rounded, size: 44, color: Colors.grey[300]),
            const SizedBox(height: 10),
            Text('Belum ada riwayat pengangkutan', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.grey[400])),
          ]),
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

  Widget _buildRiwayatTile(PengangkutanData s) {
    final color = _statusColor(s.status);
    final bgColor = color.withOpacity(0.1);
    final bool isCompleted = s.status == 'completed';
    final bool isTerminal  = s.status == 'canceled' || s.status == 'rejected';

    void onTap() {
      if (isCompleted) {
        _openDetailPengangkutan(s);
      } else if (isTerminal) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AlurSesiPengangkutanScreen(pengangkutanId: s.id),
          ),
        );
      }
    }

    return GestureDetector(
      onTap: (isCompleted || isTerminal) ? onTap : null,
      behavior: HitTestBehavior.opaque,
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
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(color: Color(0xFF013236).withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(Icons.house, color: Color(0xFF013236), size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s.namaBsu, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF013236))),
            const SizedBox(height: 3),
            Text(s.tanggal, style: TextStyle(fontFamily: 'Poppins', fontSize: 11.5, color: Colors.grey[500])),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(20)),
            child: Text(_statusLabel(s.status), style: TextStyle(fontFamily: 'Poppins', fontSize: 10.5, fontWeight: FontWeight.w600, color: color)),
          ),
        ]),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────
  String _statusLabel(String s) {
    switch (s) {
      case 'requested': return 'Diajukan';
      case 'approved': return 'Disetujui';
      case 'rejected': return 'Ditolak';
      case 'otw': return 'Dalam Perjalanan';
      case 'canceled': return 'Dibatalkan';
      case 'completed': return 'Selesai';
      default: return s;
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'completed': return const Color(0xFF4EA771);
      case 'canceled': case 'rejected': return Colors.red.shade400;
      case 'otw': return const Color(0xFFFAA324);
      case 'approved': return const Color(0xFF06C0C9);
      case 'requested': return const Color(0xFF94DF0C);
      default: return Colors.grey;
    }
  }

}

// ═══════════════════════════════════════════════════════════════════════════════
// BSU Picker Bottom Sheet
// ═══════════════════════════════════════════════════════════════════════════════

class _BsuPickerSheet extends StatefulWidget {
  final List<BsuUnit> bsuList;
  final Set<String> activeBsuIds;
  final List<JadwalHariIniItem> jadwalHariIni;
  final Function(BsuUnit, String jadwalId) onSelected;

  const _BsuPickerSheet({
    required this.bsuList,
    required this.activeBsuIds,
    required this.jadwalHariIni,
    required this.onSelected,
  });

  @override
  State<_BsuPickerSheet> createState() => _BsuPickerSheetState();
}

class _BsuPickerSheetState extends State<_BsuPickerSheet> {
  final _searchCtrl = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<BsuUnit> get _filtered => widget.bsuList
      .where((b) => b.namaBank.toLowerCase().contains(_search.toLowerCase()))
      .toList();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.65),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(children: [
        // Handle
        Container(
          margin: const EdgeInsets.only(top: 12),
          width: 40, height: 4,
          decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
        ),
        // Title
        const Padding(
          padding: EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: Text('Pilih BSU Tujuan', style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF013236))),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(24, 4, 24, 12),
          child: Text('Pilih BSU yang akan diangkut sampahnya', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.grey)),
        ),
        // Search
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: CustomSearchBar(
            controller: _searchCtrl,
            hintText: 'Cari nama BSU...',
            searchQuery: _search,
            onChanged: (v) => setState(() => _search = v),
            onClear: () {
              _searchCtrl.clear();
              setState(() => _search = '');
            },
          ),
        ),
        const SizedBox(height: 8),
        // List
        Expanded(
          child: _filtered.isEmpty
              ? Center(child: Text('BSU tidak ditemukan', style: TextStyle(fontFamily: 'Poppins', color: Colors.grey[400])))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  itemCount: _filtered.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final bsu = _filtered[i];
                    final isActive = widget.activeBsuIds.contains(bsu.bankId);
                    final jadwalList = widget.jadwalHariIni
                        .where((j) => j.bsuId == bsu.bankId)
                        .toList();
                    final jadwal = jadwalList.isNotEmpty ? jadwalList.first : null;
                    final hasJadwal = jadwal != null;
                    final isCompleted = jadwal?.isCompleted ?? false;
                    final canTap = hasJadwal && !isActive && !isCompleted;
                    final keterangan = hasJadwal
                        ? (jadwal.namaJadwalSpesial.isEmpty
                            ? 'Pengangkutan Rutin'
                            : jadwal.namaJadwalSpesial)
                        : null;

                    final Color iconColor;
                    final Color iconBg;
                    final Color nameColor;
                    if (isActive || isCompleted) {
                      iconColor = Colors.grey[400]!;
                      iconBg = Colors.grey.withValues(alpha: 0.12);
                      nameColor = Colors.grey[400]!;
                    } else if (hasJadwal) {
                      iconColor = const Color(0xFF4EA771);
                      iconBg = const Color(0xFF4EA771).withValues(alpha: 0.12);
                      nameColor = const Color(0xFF013236);
                    } else {
                      iconColor = Colors.grey[400]!;
                      iconBg = Colors.grey.withValues(alpha: 0.08);
                      nameColor = Colors.grey[400]!;
                    }

                    Widget? trailingWidget;
                    if (isActive) {
                      trailingWidget = Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAA324).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text('Sedang Aktif',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFFAA324),
                            )),
                      );
                    } else if (isCompleted) {
                      trailingWidget = Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4EA771).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_rounded, size: 10, color: Color(0xFF4EA771)),
                            SizedBox(width: 4),
                            Text('Selesai',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF4EA771),
                                )),
                          ],
                        ),
                      );
                    } else if (hasJadwal) {
                      trailingWidget = const Icon(Icons.arrow_forward_ios_rounded,
                          size: 14, color: Color(0xFF4EA771));
                    }

                    return ListTile(
                      onTap: canTap ? () => widget.onSelected(bsu, jadwal.jadwalId) : null,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
                        child: Icon(Icons.store_rounded, color: iconColor, size: 20),
                      ),
                      title: Text(
                        bsu.namaBank,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: nameColor,
                        ),
                      ),
                      subtitle: keterangan != null
                          ? Text(
                              keterangan,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 11,
                                color: (hasJadwal && !isCompleted)
                                    ? const Color(0xFF4EA771)
                                    : Colors.grey[400],
                              ),
                            )
                          : null,
                      trailing: trailingWidget,
                    );
                  },
                ),
        ),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Mandiri Picker Bottom Sheet
// ═══════════════════════════════════════════════════════════════════════════════

class _MandiriPickerSheet extends StatelessWidget {
  final String namaBsu;
  final void Function(bool isMandiri) onSelected;

  const _MandiriPickerSheet({
    required this.namaBsu,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
              color: const Color(0xFF013236).withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.local_shipping_rounded,
                color: Color(0xFF013236), size: 26),
          ),
          const SizedBox(height: 16),
          const Text(
            'Metode Pengangkutan',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: Color(0xFF013236),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Apakah pengangkutan sampah $namaBsu dilakukan secara mandiri atau dijemput BSI ke lokasi?',
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
                  onPressed: () => onSelected(true),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF013236),
                    side: BorderSide(
                        color: const Color(0xFF013236).withValues(alpha: 0.3)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50)),
                  ),
                  child: const Text(
                    'Diantar BSU',
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
                  onPressed: () => onSelected(false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF013236),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50)),
                  ),
                  child: const Text(
                    'Dijemput BSI',
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
    );
  }
}
