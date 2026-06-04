import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:enviroo/widgets/topbar_back.dart';
import 'package:enviroo/widgets/search.dart';
import 'package:enviroo/widgets/custom_snackbar.dart';
import 'package:enviroo/widgets/filter_month_year.dart';
import 'package:enviroo/widgets/filter_chip_row.dart';
import 'package:enviroo/widgets/navbar.dart';
import 'package:enviroo/widgets/confirm_bottom_sheet.dart';
import 'package:enviroo/services/pengangkutan_service.dart';
import 'package:enviroo/providers/auth_provider.dart';
import 'package:enviroo/providers/pengangkutan_provider.dart';
import 'package:enviroo/screens/admin_bsi/detail_pengangkutan_screen.dart';
import 'package:enviroo/screens/admin_bsi/alur_sesi_pengangkutan_screen.dart';

// ─── Model ──────────────────────────────────────────────────────────────────

class PengangkutanData {
  final String id;
  final String bsiId;
  final String bsuId;
  final String namaBsu;
  final String namaBsi;
  final String namaAdminBsi;
  final String namaAdminBsu;
  final String adminBsuId;
  final String status;
  final String tanggal;
  final DateTime? rawDate;

  PengangkutanData({
    required this.id,
    required this.bsiId,
    required this.bsuId,
    required this.namaBsu,
    required this.namaBsi,
    required this.namaAdminBsi,
    required this.namaAdminBsu,
    required this.adminBsuId,
    required this.status,
    required this.tanggal,
    this.rawDate,
  });

  factory PengangkutanData.fromJson(Map<String, dynamic> json) {
    String tanggal = '-';
    DateTime? rawDate;
    if (json['changed_at'] != null) {
      try {
        final parsed = DateTime.parse(json['changed_at'].toString());
        rawDate = parsed;
        tanggal = DateFormat('EEEE, dd MMMM yyyy HH:mm', 'id_ID').format(parsed);
      } catch (_) {
        tanggal = json['changed_at'].toString();
      }
    }

    return PengangkutanData(
      id: json['pengangkutan_id'] ?? '',
      bsiId: json['bsi_id'] ?? '',
      bsuId: json['bsu_id'] ?? '',
      namaBsu: json['nama_bsu'] ?? '-',
      namaBsi: json['nama_bsi'] ?? '-',
      namaAdminBsi: json['nama_admin_bsi'] ?? '-',
      namaAdminBsu: json['nama_admin_bsu'] ?? '-',
      adminBsuId: json['admin_bsu_id'] ?? '',
      status: json['status_pengangkutan'] ?? '',
      tanggal: tanggal,
      rawDate: rawDate,
    );
  }
}

class PengangkutanAktifBsiData {
  final String pengangkutanId;
  final String bsuId;
  final String namaBsu;
  final String statusTerkini;
  final bool isActionAllowed;

  const PengangkutanAktifBsiData({
    required this.pengangkutanId,
    required this.bsuId,
    required this.namaBsu,
    required this.statusTerkini,
    required this.isActionAllowed,
  });

  factory PengangkutanAktifBsiData.fromJson(Map<String, dynamic> json) {
    return PengangkutanAktifBsiData(
      pengangkutanId: json['pengangkutan_id'] as String? ?? '',
      bsuId: json['bsu_id'] as String? ?? '',
      namaBsu: json['nama_bsu'] as String? ?? '-',
      statusTerkini: json['status_terkini'] as String? ?? '',
      isActionAllowed: json['is_action_allowed'] as bool? ?? false,
    );
  }
}

class BsuUnit {
  final String bankId;
  final String namaBank;
  BsuUnit({required this.bankId, required this.namaBank});
  factory BsuUnit.fromJson(Map<String, dynamic> json) {
    return BsuUnit(
      bankId: json['bank_id'] ?? json['BankID'] ?? '',
      namaBank: json['nama_bank'] ?? json['NamaBank'] ?? '-',
    );
  }
}

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
    await Future.wait([_loadHistory(), _loadBsuList(), _loadActiveSessions()]);
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

    final res = await PengangkutanService.getAllPengangkutan(bankId);
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
        onSelected: (bsu) {
          Navigator.pop(ctx);
          _checkAndStartSesi(bsu);
        },
      ),
    );
  }

  Future<void> _checkAndStartSesi(BsuUnit bsu) async {
    setState(() => _actionLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final bsiId = auth.bankId ?? '';
    final adminId = auth.identityId ?? '';

    // Check jadwal
    final checkRes = await PengangkutanService.checkJadwal(bsiId, bsu.bankId);
    if (!mounted) return;

    if (checkRes['success'] != true) {
      setState(() => _actionLoading = false);
      _showSnackBar(checkRes['message'] ?? 'Gagal cek jadwal', isError: true);
      return;
    }

    final status = checkRes['status'] as String? ?? 'dadakan';

    if (status == 'scheduled') {
      // Langsung mulai
      await _startSesi(bsiId, bsu.bankId, adminId, false);
    } else {
      // Konfirmasi dadakan
      setState(() => _actionLoading = false);
      _showDadakanDialog(bsiId, bsu, adminId);
    }
  }

  Future<void> _startSesi(String bsiId, String bsuId, String adminId, bool dadakan) async {
    setState(() => _actionLoading = true);
    final res = await PengangkutanService.startSesi(bsiId, bsuId, adminId, statusDadakan: dadakan);
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

  // ── Dialog dadakan ───────────────────────────────────────────────────────
  Future<void> _showDadakanDialog(String bsiId, BsuUnit bsu, String adminId) async {
    final ok = await showConfirmBottomSheet(
      context,
      icon: Icons.local_shipping_rounded,
      title: 'Tidak Ada Jadwal Hari Ini',
      message: 'Tidak ada jadwal pengangkutan ke ${bsu.namaBank} hari ini. Apakah Anda ingin mengadakan sesi dadakan?',
      cancelLabel: 'Tidak',
      confirmLabel: 'Ya, Dadakan',
    );
    if (ok) {
      _startSesi(bsiId, bsu.bankId, adminId, true);
    }
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
            image: AssetImage('assets/images/bg_struk.webp'),
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
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Riwayat Pengangkutan',
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 15,
                        fontWeight: FontWeight.w700, color: Color(0xFF013236))),
                const SizedBox(height: 12),
                MonthYearFilterRow(
                  filterStart: _filterStart,
                  filterEnd: _filterEnd,
                  onChanged: (start, end) => setState(() {
                    _filterStart = start;
                    _filterEnd = end;
                  }),
                ),
                const SizedBox(height: 12),
                _buildRiwayatList(),
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
    return GestureDetector(
      onTap: isLoading ? null : _onMulaiSesiTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 17),
        decoration: BoxDecoration(
          color: isLoading ? const Color(0xFF013236).withOpacity(0.6) : const Color(0xFF013236),
          borderRadius: BorderRadius.circular(50),
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
              : const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.local_shipping_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text('Mulai Sesi Pengangkutan', style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                ]),
        ),
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
            decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
            child: Icon(_statusIcon(s.status), color: color, size: 18),
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
          if (isCompleted) ...[
            const SizedBox(width: 6),
            Icon(Icons.chevron_right_rounded, size: 18, color: Colors.grey[400]),
          ],
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

  IconData _statusIcon(String s) {
    switch (s) {
      case 'completed': return Icons.check_circle_outline_rounded;
      case 'canceled': case 'rejected': return Icons.cancel_outlined;
      case 'otw': return Icons.local_shipping_rounded;
      case 'approved': return Icons.thumb_up_alt_rounded;
      case 'requested': return Icons.hourglass_top_rounded;
      default: return Icons.info_outline_rounded;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// BSU Picker Bottom Sheet
// ═══════════════════════════════════════════════════════════════════════════════

class _BsuPickerSheet extends StatefulWidget {
  final List<BsuUnit> bsuList;
  final Set<String> activeBsuIds;
  final Function(BsuUnit) onSelected;

  const _BsuPickerSheet({
    required this.bsuList,
    required this.activeBsuIds,
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
                    return ListTile(
                      onTap: isActive ? null : () => widget.onSelected(bsu),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isActive
                              ? Colors.grey.withValues(alpha: 0.12)
                              : const Color(0xFF06C0C9).withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.store_rounded,
                            color: isActive ? Colors.grey[400] : const Color(0xFF06C0C9), size: 20),
                      ),
                      title: Text(bsu.namaBank,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isActive ? Colors.grey[400] : const Color(0xFF013236),
                          )),
                      trailing: isActive
                          ? Container(
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
                            )
                          : const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                    );
                  },
                ),
        ),
      ]),
    );
  }
}
