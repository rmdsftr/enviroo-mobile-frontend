import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:enviroo/widgets/topbar_back.dart';
import 'package:enviroo/services/pengangkutan_service.dart';
import 'package:enviroo/providers/auth_provider.dart';
import 'package:enviroo/screens/admin_bsi/angkut_setoran_bsi_screen.dart';
import 'package:enviroo/screens/admin_bsi/detail_pengangkutan_screen.dart';

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
  });

  factory PengangkutanData.fromJson(Map<String, dynamic> json) {
    String tanggal = '-';
    if (json['changed_at'] != null) {
      try {
        tanggal = '${DateFormat('EEEE, dd MMMM yyyy HH:mm', 'id_ID').format(DateTime.parse(json['changed_at'].toString()))} WIB';
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
  const PengangkutanBsiScreen({super.key});
  @override
  State<PengangkutanBsiScreen> createState() => _PengangkutanBsiScreenState();
}

class _PengangkutanBsiScreenState extends State<PengangkutanBsiScreen> {
  bool _listLoading = true;
  bool _actionLoading = false;
  List<PengangkutanData> _riwayat = [];
  List<PengangkutanData> _activeSessions = [];
  List<BsuUnit> _bsuList = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    await Future.wait([_loadHistory(), _loadBsuList()]);
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

    final res = await PengangkutanService.getAllPengangkutan(bankId, token);
    if (!mounted) return;

    if (res['success'] == true) {
      final List data = res['data'] ?? [];
      List<PengangkutanData> riwayat = [];
      List<PengangkutanData> active = [];
      for (var item in data) {
        final p = PengangkutanData.fromJson(item);
        if (p.status == 'otw' || p.status == 'requested' || p.status == 'approved') {
          active.add(p);
        } else {
          riwayat.add(p);
        }
      }
      setState(() {
        _riwayat = riwayat;
        _activeSessions = active;
        _listLoading = false;
      });
    } else {
      setState(() => _listLoading = false);
      _showSnackBar(res['message'] ?? 'Gagal memuat data', isError: true);
    }
  }

  // ── 2. Load BSU list ─────────────────────────────────────────────────────
  Future<void> _loadBsuList() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final bankId = auth.bankId ?? '';
    final token = auth.currentUser?.accessToken ?? '';
    if (bankId.isEmpty) return;

    final res = await PengangkutanService.getUnitBsi(bankId, token);
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
    final token = auth.currentUser?.accessToken ?? '';

    // Check jadwal
    final checkRes = await PengangkutanService.checkJadwal(bsiId, bsu.bankId, token);
    if (!mounted) return;

    if (checkRes['success'] != true) {
      setState(() => _actionLoading = false);
      _showSnackBar(checkRes['message'] ?? 'Gagal cek jadwal', isError: true);
      return;
    }

    final status = checkRes['status'] as String? ?? 'dadakan';

    if (status == 'scheduled') {
      // Langsung mulai
      await _startSesi(bsiId, bsu.bankId, adminId, token, false);
    } else {
      // Konfirmasi dadakan
      setState(() => _actionLoading = false);
      _showDadakanDialog(bsiId, bsu, adminId, token);
    }
  }

  Future<void> _startSesi(String bsiId, String bsuId, String adminId, String token, bool dadakan) async {
    setState(() => _actionLoading = true);
    final res = await PengangkutanService.startSesi(bsiId, bsuId, adminId, token, statusDadakan: dadakan);
    if (!mounted) return;
    setState(() => _actionLoading = false);

    if (res['success'] == true) {
      _showSnackBar('Sesi pengangkutan berhasil dimulai');
      await _init();
    } else {
      _showSnackBar(res['message'] ?? 'Gagal memulai sesi', isError: true);
    }
  }

  // ── Update status pengangkutan ───────────────────────────────────────────
  Future<void> _updateStatus(
    PengangkutanData item,
    String newStatus, {
    String notes = '',
  }) async {
    setState(() => _actionLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final adminId = auth.identityId ?? '';
    final token = auth.currentUser?.accessToken ?? '';

    final res = await PengangkutanService.updateStatus(
      item.id, adminId, item.status, newStatus, token, notes: notes,
    );
    if (!mounted) return;
    setState(() => _actionLoading = false);

    if (res['success'] == true) {
      _showSnackBar(res['message'] ?? 'Status diperbarui');
      await _init();
    } else {
      _showSnackBar(res['message'] ?? 'Gagal memperbarui status', isError: true);
    }
  }

  /// Tampilkan dialog konfirmasi untuk aksi yang TIDAK butuh catatan.
  void _confirmAction(PengangkutanData item, String newStatus, String label) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Konfirmasi', style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 15)),
        content: Text('Ubah status pengangkutan ke "$label"?', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.grey[700])),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.grey, fontFamily: 'Poppins')),
          ),
          TextButton(
            onPressed: () { Navigator.pop(ctx); _updateStatus(item, newStatus); },
            child: Text('Ya, $label', style: const TextStyle(color: Color(0xFF4EA771), fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  /// Tampilkan dialog input catatan untuk aksi yang WAJIB ada catatan (cancel/reject).
  void _showNotesDialog(PengangkutanData item, String newStatus, String label) {
    final notesCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(label, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 15)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Catatan/alasan wajib diisi.', style: TextStyle(fontFamily: 'Poppins', fontSize: 12.5, color: Colors.grey[600])),
            const SizedBox(height: 12),
            TextField(
              controller: notesCtrl,
              maxLines: 3,
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Tulis alasan di sini...',
                hintStyle: TextStyle(fontFamily: 'Poppins', color: Colors.grey[400], fontSize: 13),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF4EA771))),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.grey, fontFamily: 'Poppins')),
          ),
          TextButton(
            onPressed: () {
              if (notesCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Catatan tidak boleh kosong')));
                return;
              }
              Navigator.pop(ctx);
              _updateStatus(item, newStatus, notes: notesCtrl.text.trim());
            },
            child: Text(label, style: const TextStyle(color: Colors.red, fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  /// Kembalikan daftar tombol aksi berdasarkan status saat ini.
  /// Sesuai transisi backend:
  ///   requested → approved | rejected
  ///   approved  → otw | canceled
  ///   otw       → input setoran (lalu otomatis completed) | canceled
  List<_ActionBtn> _getNextActions(PengangkutanData item) {
    switch (item.status) {
      case 'requested':
        return [
          _ActionBtn(label: 'Setujui', newStatus: 'approved', color: const Color(0xFF4EA771), needsNotes: false),
          _ActionBtn(label: 'Tolak', newStatus: 'rejected', color: Colors.red, needsNotes: true),
        ];
      case 'approved':
        return [
          _ActionBtn(label: 'Mulai OTW', newStatus: 'otw', color: const Color(0xFF06C0C9), needsNotes: false),
          _ActionBtn(label: 'Batalkan', newStatus: 'canceled', color: Colors.red, needsNotes: true),
        ];
      case 'otw':
        return [
          _ActionBtn(label: 'Selesai', newStatus: 'completed', color: const Color(0xFF4EA771), needsNotes: false),
          _ActionBtn(label: 'Batalkan', newStatus: 'canceled', color: Colors.red, needsNotes: true),
        ];
      default:
        return [];
    }
  }

  // ── Buka halaman input setoran BSU (khusus status otw) ───────────────────
  Future<void> _openInputSetoranBsu(PengangkutanData s) async {
    final hasil = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AngkutSetoranBsiScreen(
          pengangkutanId: s.id,
          bsiId: s.bsiId,
          bsuId: s.bsuId,
          namaBsu: s.namaBsu,
          adminBsuIdAwal: s.adminBsuId,
        ),
      ),
    );
    if (!mounted) return;
    if (hasil == true) {
      _showSnackBar('Setoran BSU berhasil disimpan');
      await _init();
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
  void _showDadakanDialog(String bsiId, BsuUnit bsu, String adminId, String token) {
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
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 30, offset: const Offset(0, 12))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(color: Color(0xFFFFF3CD), shape: BoxShape.circle),
                child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFFAA324), size: 32),
              ),
              const SizedBox(height: 16),
              const Text('Tidak Ada Jadwal Hari Ini', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF013236)), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text('Tidak ada jadwal pengangkutan ke ${bsu.namaBank} hari ini. Apakah Anda ingin mengadakan sesi dadakan?',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 12.5, color: Colors.grey[600], height: 1.5), textAlign: TextAlign.center),
              const SizedBox(height: 22),
              Row(children: [
                Expanded(child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.grey.shade300), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 12)),
                  child: const Text('Tidak', style: TextStyle(color: Color(0xFF013236), fontFamily: 'Poppins', fontWeight: FontWeight.w500)),
                )),
                const SizedBox(width: 10),
                Expanded(child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _startSesi(bsiId, bsu.bankId, adminId, token, true);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFAA324), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 12)),
                  child: const Text('Ya, Dadakan', style: TextStyle(color: Colors.white, fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
                )),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  void _showSnackBar(String msg, {bool isError = false}) {
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
              onRefresh: _init,
              color: const Color(0xFF4EA771),
              child: _listLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF4EA771)))
                  : SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        // ── Active sessions atau tombol mulai ──
                        if (_activeSessions.isNotEmpty)
                          ..._activeSessions.map((s) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildActiveCard(s),
                          ))
                        else
                          _buildStartSection(),

                        const SizedBox(height: 28),

                        // ── Riwayat ──
                        const Text('Riwayat Pengangkutan', style: TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF013236))),
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
          color: isLoading ? const Color(0xFF06C0C9).withOpacity(0.6) : const Color(0xFF06C0C9),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: const Color(0xFF06C0C9).withOpacity(0.32), blurRadius: 14, offset: const Offset(0, 6))],
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

  // ── Card sesi aktif ──────────────────────────────────────────────────────
  Widget _buildActiveCard(PengangkutanData s) {
    final actions = _getNextActions(s);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Indikator live
      Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: const Color(0xFF06C0C9).withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF06C0C9), shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text('${_statusLabel(s.status)} — ${s.namaBsu}', style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0097A7))),
        ]),
      ),
      // Card info
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF013236), Color(0xFF025059)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [BoxShadow(color: const Color(0xFF013236).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Pengangkutan Aktif', style: TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: _statusColor(s.status), borderRadius: BorderRadius.circular(20)),
              child: Text(_statusLabel(s.status).toUpperCase(), style: const TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ]),
          const SizedBox(height: 16),
          _infoRow(Icons.store_rounded, 'BSU: ${s.namaBsu}'),
          const SizedBox(height: 8),
          _infoRow(Icons.calendar_today_rounded, s.tanggal),
          const SizedBox(height: 8),
          _infoRow(Icons.person_rounded, 'Petugas: ${s.namaAdminBsi}'),
        ]),
      ),
      // Tombol Input Setoran BSU — khusus status otw
      if (s.status == 'otw') ...[
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _actionLoading ? null : () => _openInputSetoranBsu(s),
            icon: const Icon(Icons.inventory_2_rounded, size: 16, color: Colors.white),
            label: const Text(
              'Input Setoran BSU',
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
      // Tombol aksi (transisi status)
      if (actions.isNotEmpty) ...[
        const SizedBox(height: 12),
        _actionLoading
            ? const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 12), child: CircularProgressIndicator(color: Color(0xFF4EA771), strokeWidth: 2.5)))
            : Row(
                children: actions.map((a) {
                  final isFirst = actions.indexOf(a) == 0;
                  final btn = a.needsNotes
                      ? OutlinedButton.icon(
                          onPressed: () => _showNotesDialog(s, a.newStatus, a.label),
                          icon: Icon(Icons.cancel_outlined, size: 15, color: a.color),
                          label: Text(a.label, style: TextStyle(color: a.color, fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 13)),
                          style: OutlinedButton.styleFrom(side: BorderSide(color: a.color), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 12)),
                        )
                      : ElevatedButton.icon(
                          onPressed: () => _confirmAction(s, a.newStatus, a.label),
                          icon: Icon(Icons.check_circle_outline_rounded, size: 15, color: Colors.white),
                          label: Text(a.label, style: const TextStyle(color: Colors.white, fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 13)),
                          style: ElevatedButton.styleFrom(backgroundColor: a.color, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 12)),
                        );
                  return Expanded(child: Padding(padding: EdgeInsets.only(left: isFirst ? 0 : 8), child: btn));
                }).toList(),
              ),
      ],
    ]);
  }

  Widget _infoRow(IconData icon, String text) => Row(children: [
    Icon(icon, size: 14, color: Colors.white70),
    const SizedBox(width: 8),
    Expanded(child: Text(text, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.white70))),
  ]);

  // ── Riwayat list ─────────────────────────────────────────────────────────
  Widget _buildRiwayatList() {
    if (_riwayat.isEmpty) {
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
      itemCount: _riwayat.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _buildRiwayatTile(_riwayat[i]),
    );
  }

  Widget _buildRiwayatTile(PengangkutanData s) {
    final color = _statusColor(s.status);
    final bgColor = color.withOpacity(0.1);
    final bool isCompleted = s.status == 'completed';

    return GestureDetector(
      onTap: isCompleted ? () => _openDetailPengangkutan(s) : null,
      behavior: HitTestBehavior.opaque,
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
      case 'otw': return const Color(0xFF06C0C9);
      case 'approved': return const Color(0xFF8BC34A);
      case 'requested': return const Color(0xFFFAA324);
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

// ─── Action Button Definition ────────────────────────────────────────────────

class _ActionBtn {
  final String label;
  final String newStatus;
  final Color color;
  final bool needsNotes;
  const _ActionBtn({
    required this.label,
    required this.newStatus,
    required this.color,
    required this.needsNotes,
  });
}

// ═══════════════════════════════════════════════════════════════════════════════
// BSU Picker Bottom Sheet
// ═══════════════════════════════════════════════════════════════════════════════

class _BsuPickerSheet extends StatefulWidget {
  final List<BsuUnit> bsuList;
  final Function(BsuUnit) onSelected;

  const _BsuPickerSheet({required this.bsuList, required this.onSelected});

  @override
  State<_BsuPickerSheet> createState() => _BsuPickerSheetState();
}

class _BsuPickerSheetState extends State<_BsuPickerSheet> {
  String _search = '';

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
          child: TextField(
            onChanged: (v) => setState(() => _search = v),
            style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Cari nama BSU...',
              hintStyle: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.grey[400]),
              prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF4EA771)),
              filled: true,
              fillColor: const Color(0xFFF2FAF0),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
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
                    return ListTile(
                      onTap: () => widget.onSelected(bsu),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: const Color(0xFF06C0C9).withOpacity(0.12), shape: BoxShape.circle),
                        child: const Icon(Icons.store_rounded, color: Color(0xFF06C0C9), size: 20),
                      ),
                      title: Text(bsu.namaBank, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF013236))),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                    );
                  },
                ),
        ),
      ]),
    );
  }
}
