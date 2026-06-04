import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:enviroo/providers/auth_provider.dart';
import 'package:enviroo/services/penimbangan_service.dart';
import 'package:enviroo/screens/admin_bsu/scanner_penimbangan_screen.dart';
import 'package:enviroo/screens/petugas/struk_setoran_nasabah.dart';
import 'package:enviroo/widgets/topbar_back.dart';

// ─── Models ──────────────────────────────────────────────────────────────────

class _SetoranItem {
  final String setoranId;
  final String nasabahId;
  final String namaNasabah;
  final DateTime createdAt;

  _SetoranItem({
    required this.setoranId,
    required this.nasabahId,
    required this.namaNasabah,
    required this.createdAt,
  });

  factory _SetoranItem.fromJson(Map<String, dynamic> j) {
    DateTime dt = DateTime.now();
    try {
      dt = DateTime.parse(j['created_at'] ?? '');
    } catch (_) {}
    return _SetoranItem(
      setoranId: j['setoran_id'] ?? '',
      nasabahId: j['nasabah_id'] ?? '',
      namaNasabah: j['nama_nasabah'] ?? '-',
      createdAt: dt,
    );
  }

  String get waktuFmt =>
      DateFormat('HH:mm', 'id_ID').format(createdAt);
}

class _SesiData {
  final String penimbanganId;
  final String namaBank;
  final String startedAt;
  final String startedBy;
  final List<_SetoranItem> listSetoran;

  _SesiData({
    required this.penimbanganId,
    required this.namaBank,
    required this.startedAt,
    required this.startedBy,
    required this.listSetoran,
  });

  factory _SesiData.fromJson(Map<String, dynamic> j) {
    String startedAt = '-';
    if (j['started_at'] != null) {
      try {
        final parsed = DateTime.parse(j['started_at']);
        startedAt =
            DateFormat('EEEE, dd MMM yyyy · HH:mm', 'id_ID').format(parsed);
      } catch (_) {
        startedAt = j['started_at'].toString();
      }
    }

    final rawList = j['list_setoran'] as List? ?? [];
    final list = rawList
        .map((e) => _SetoranItem.fromJson(e as Map<String, dynamic>))
        .toList();

    return _SesiData(
      penimbanganId: j['penimbangan_id'] ?? '',
      namaBank: j['nama_bank'] ?? '-',
      startedAt: startedAt,
      startedBy: j['started_by'] ?? '-',
      listSetoran: list,
    );
  }
}

// ─── Screen ──────────────────────────────────────────────────────────────────

class PenimbanganAktifScreen extends StatefulWidget {
  final String penimbanganId;

  const PenimbanganAktifScreen({super.key, required this.penimbanganId});

  @override
  State<PenimbanganAktifScreen> createState() => _PenimbanganAktifScreenState();
}

class _PenimbanganAktifScreenState extends State<PenimbanganAktifScreen> {
  bool _isLoading = true;
  bool _actionLoading = false;
  bool _isExpanded = false;
  _SesiData? _sesi;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
  }

  Future<void> _fetch() async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });
    final res =
        await PenimbanganService.getSesiAktif(widget.penimbanganId);
    if (!mounted) return;

    if (res['success'] == true) {
      setState(() {
        _sesi = _SesiData.fromJson(res['data'] as Map<String, dynamic>);
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMsg = res['message'] ?? 'Gagal memuat data sesi';
        _isLoading = false;
      });
    }
  }

  Future<void> _updateSesi(String status) async {
    setState(() => _actionLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final adminId = auth.userId;

    final res = await PenimbanganService.updatePenimbangan(
        widget.penimbanganId, adminId, status);
    if (!mounted) return;
    setState(() => _actionLoading = false);

    if (res['success'] == true) {
      Navigator.pop(context, true);
    } else {
      _snackBar(res['message'] ?? 'Gagal memperbarui sesi', isError: true);
    }
  }

  void _snackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: const TextStyle(fontFamily: 'Poppins', color: Colors.white)),
      backgroundColor:
          isError ? Colors.red.shade700 : const Color(0xFF4EA771),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ));
  }

  void _showKonfirmasi(String status) {
    final isSelesai = status == 'selesai';

    final IconData icon     = isSelesai ? Icons.check_circle_outline_rounded : Icons.cancel_outlined;
    final Color iconBg      = isSelesai ? const Color(0xFFE8F5E9) : const Color(0xFFFFEEEA);
    final Color iconColor   = isSelesai ? const Color(0xFF4EA771) : const Color(0xFFFF5A36);
    final String title      = isSelesai ? 'Tutup Sesi Penimbangan' : 'Batalkan Penimbangan';
    final String subtitle   = isSelesai
        ? 'Apakah sesi penimbangan ini sudah benar-benar selesai?'
        : 'Apakah Anda yakin ingin membatalkan sesi ini?\nSemua data akan dihapus.';
    final String labelAksi  = isSelesai ? 'Ya, Tutup' : 'Ya, Batalkan';
    final Color colorAksi   = isSelesai ? const Color(0xFF4EA771) : const Color(0xFFFF5A36);

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
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: Color(0xFF013236),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                height: 1.6,
                color: const Color(0xFF013236).withValues(alpha: 0.5),
              ),
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
                      _updateSesi(status);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorAksi,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                    ),
                    child: Text(labelAksi, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F8),
      body: SafeArea(
        child: Column(
          children: [
            TopBarBack(title: 'Sesi Penimbangan Aktif'),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFF4EA771)))
                  : _errorMsg != null
                      ? _buildError()
                      : RefreshIndicator(
                          onRefresh: _fetch,
                          color: const Color(0xFF4EA771),
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding:
                                const EdgeInsets.fromLTRB(20, 16, 20, 32),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildHeaderCard(),
                                const SizedBox(height: 16),
                                _buildScannerButton(),
                                const SizedBox(height: 28),
                                _buildSetoranSection(),
                                const SizedBox(height: 24),
                                _buildActionButtons(),
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

  // ── Header card (putih) ───────────────────────────────────────────────────

  Widget _buildHeaderCard() {
    final s = _sesi!;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          width: 1,
          color: const Color(0xFF013236).withOpacity(0.1), // Brand color dengan opacity cuma 10%
        ),
      ),
      child: Column(
        children: [
          // Title row
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sesi Penimbangan',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF013236),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'ID: ${s.penimbanganId}',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF013236).withOpacity(0.55),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4EA771).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF4EA771),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Text(
                        'AKTIF',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF4EA771),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFF0F0F0)),

          // Info rows
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
            child: Column(
              children: [
                _infoRow(
                    Icons.account_balance_rounded, 'Bank Sampah', s.namaBank),
                const SizedBox(height: 12),
                _infoRow(
                    Icons.calendar_today_rounded, 'Dibuka', s.startedAt),
                const SizedBox(height: 12),
                _infoRow(Icons.person_rounded, 'Sesi dibuka oleh', s.startedBy),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: const Color(0xFF4EA771).withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: const Color(0xFF4EA771)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10.5,
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
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
      ],
    );
  }

  // ── Scanner button ────────────────────────────────────────────────────────

  Widget _buildScannerButton() {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              ScannerPenimbanganScreen(penimbanganId: widget.penimbanganId),
        ),
      ).then((_) => _fetch()),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: const Color(0xFF013236),
          borderRadius: BorderRadius.circular(50),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Text(
              'Scanner Penyetoran Nasabah',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Setoran section ───────────────────────────────────────────────────────

  Widget _buildSetoranSection() {
    final list = _sesi!.listSetoran;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
              child: const Text(
                'Setoran Masuk',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF013236),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                color: list.isEmpty
                    ? Colors.grey.shade100
                    : const Color(0xFF013236).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${list.length}',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: list.isEmpty
                      ? Colors.grey.shade400
                      : const Color(0xFF013236),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (list.isEmpty)
          _buildEmptySetoran()
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _buildSetoranTile(list[i]),
          ),
      ],
    );
  }

  Widget _buildEmptySetoran() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          width: 1,
          color: const Color(0xFF013236).withOpacity(0.1), // Brand color dengan opacity cuma 10%
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.inbox_rounded, size: 40, color: Colors.grey[300]),
          const SizedBox(height: 8),
          Text(
            'Belum ada setoran',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap "Scanner" untuk mulai mencatat setoran',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              color: Colors.grey[350],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetoranTile(_SetoranItem item) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StrukSetoranNasabahScreen(
            setoranId: item.setoranId,
            namaNasabah: item.namaNasabah,
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
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFF4EA771).withValues(alpha: 0.07),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_rounded,
                  size: 20, color: Color(0xFF4EA771)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.namaNasabah,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF013236),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Pukul ${item.waktuFmt}',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: Colors.grey[350], size: 20),
          ],
        ),
      ),
    );
  }

  // ── Expandable card akhiri sesi ──────────────────────────────────────────

  Widget _buildActionButtons() {
    final isEmpty = _sesi?.listSetoran.isEmpty ?? true;

    return GestureDetector(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.5),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            width: 1,
            color: const Color(0xFF013236).withOpacity(0.1), // Brand color dengan opacity cuma 10%
          ),
        ),
        child: Column(
          children: [
            // ── Header selalu tampil ────────────────────────────────────────
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: Color(0xFF013236),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Penimbangan selesai?',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF013236),
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 22,
                      color: Color(0xFF013236),
                    ),
                  ),
                ],
              ),
            ),

            // ── Konten tombol (muncul saat expand) ─────────────────────────
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              child: _isExpanded
                  ? Column(
                      children: [
                        const Divider(height: 1, color: Color(0xFFF0F0F0)),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                          child: _actionLoading
                              ? const Center(
                                  child: Padding(
                                    padding:
                                        EdgeInsets.symmetric(vertical: 8),
                                    child: CircularProgressIndicator(
                                        color: Color(0xFF4EA771),
                                        strokeWidth: 2.5),
                                  ),
                                )
                              : Row(
                                  children: [
                                    if (isEmpty) ...[
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () =>
                                              _showKonfirmasi('dibatalkan'),
                                          icon: const Icon(
                                              Icons.cancel_outlined,
                                              size: 15,
                                              color: Colors.red),
                                          label: const Text(
                                            'Batalkan',
                                            style: TextStyle(
                                              color: Colors.red,
                                              fontFamily: 'Poppins',
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12,
                                            ),
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            side: BorderSide(
                                                color: Colors.red.shade300),
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        50)),
                                            padding: const EdgeInsets
                                                .symmetric(vertical: 12),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                    ],
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () =>
                                            _showKonfirmasi('selesai'),
                                        icon: const Icon(
                                            Icons.check_circle_outline_rounded,
                                            size: 15,
                                            color: Color(0xFF013236)),
                                        label: const Text(
                                          'Tutup Sesi',
                                          style: TextStyle(
                                            color: Color(0xFF013236),
                                            fontFamily: 'Poppins',
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                          ),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(
                                              color: Color(0xFF013236)),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(50)),
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 12),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  // ── Error state ───────────────────────────────────────────────────────────

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 52, color: Colors.grey[300]),
            const SizedBox(height: 14),
            Text(
              _errorMsg!,
              style: TextStyle(
                  fontFamily: 'Poppins', fontSize: 13, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _fetch,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Coba Lagi',
                  style: TextStyle(fontFamily: 'Poppins')),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4EA771),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
