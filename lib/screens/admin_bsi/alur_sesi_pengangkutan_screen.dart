import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:enviroo/models/sesi_pengangkutan_model.dart';
import 'package:enviroo/providers/auth_provider.dart';
import 'package:enviroo/providers/pengangkutan_provider.dart';
import 'package:enviroo/services/pengangkutan_service.dart';
import 'package:enviroo/widgets/topbar_back.dart';
import 'package:enviroo/widgets/custom_snackbar.dart';
import 'package:enviroo/screens/admin_bsi/angkut_setoran_bsi_screen.dart';
import 'package:enviroo/screens/lihat_foto_screen.dart';

class AlurSesiPengangkutanScreen extends StatefulWidget {
  final String pengangkutanId;
  const AlurSesiPengangkutanScreen({super.key, required this.pengangkutanId});

  @override
  State<AlurSesiPengangkutanScreen> createState() => _AlurSesiPengangkutanScreenState();
}

class _AlurSesiPengangkutanScreenState extends State<AlurSesiPengangkutanScreen> {
  static const _dark  = Color(0xFF013236);
  static const _green = Color(0xFF4EA771);
  static const _pollInterval = Duration(seconds: 5);

  DetailSesiPengangkutanModel? _data;
  bool _isLoading    = true;
  bool _actionLoading = false;
  String? _error;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetch();
      _timer = Timer.periodic(_pollInterval, (_) => _fetch());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ── Data fetch (polling) ────────────────────────────────────────────────────
  Future<void> _fetch() async {
    final result = await PengangkutanService.detailSesiActive(widget.pengangkutanId);
    if (!mounted) return;
    setState(() {
      _data    = result.data;
      _error   = result.error;
      _isLoading = false;
    });
  }

  // ── Update status ───────────────────────────────────────────────────────────
  Future<void> _doUpdate(String currentStatus, String newStatus, {String notes = ''}) async {
    setState(() => _actionLoading = true);
    final auth    = Provider.of<AuthProvider>(context, listen: false);
    final adminId = auth.identityId ?? '';

    final res = await PengangkutanService.updateStatus(
      widget.pengangkutanId, adminId, currentStatus, newStatus, notes: notes,
    );
    if (!mounted) return;
    setState(() => _actionLoading = false);

    if (res['success'] == true) {
      _showSnackBar(res['message'] ?? 'Status berhasil diperbarui');
      context.read<PengangkutanProvider>().refresh();
      _fetch();
    } else {
      _showSnackBar(res['message'] ?? 'Gagal memperbarui status', isError: true);
    }
  }

  // ── Navigasi ke input sampah (status arrived → completed via setoran) ───────
  Future<void> _openInputSampah() async {
    final d = _data!;
    final hasil = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AngkutSetoranBsiScreen(
          pengangkutanId: d.pengangkutanId,
          bsiId: d.bsiId,
          bsuId: d.bsuId,
          namaBsu: d.namaBsu,
          adminBsuIdAwal: '',
        ),
      ),
    );
    if (!mounted) return;
    if (hasil == true) {
      _showSnackBar('Setoran berhasil diinput');
      context.read<PengangkutanProvider>().refresh();
      _fetch();
    }
  }

  // ── Dialog catatan (untuk aksi yang butuh alasan) ───────────────────────────
  void _showNotesDialog(String currentStatus, String newStatus, String label) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 32),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Tulis alasan atau catatan\nsebelum melanjutkan.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12.5,
                  color: Color(0xFF6B7280),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 18),
              // ── Text field ────────────────────────────────────────
              TextField(
                controller: ctrl,
                maxLines: 3,
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: _dark),
                decoration: InputDecoration(
                  hintText: 'Tulis alasan di sini...',
                  hintStyle: const TextStyle(
                      fontFamily: 'Poppins', color: Color(0xFFB0BAC6), fontSize: 13),
                  filled: true,
                  fillColor: const Color(0xFFF5F7FA),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.red.shade300, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
              const SizedBox(height: 20),
              // ── Tombol ────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        side: const BorderSide(color: Color(0xFFD1D5DB)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text(
                        'Batal',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: _dark,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (ctrl.text.trim().isEmpty) {
                          showCustomSnackBar(context, 'Catatan tidak boleh kosong');
                          return;
                        }
                        Navigator.pop(ctx);
                        _doUpdate(currentStatus, newStatus, notes: ctrl.text.trim());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(
                        'Kirim',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
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

  void _showSnackBar(String msg, {bool isError = false}) {
    showCustomSnackBar(
      context,
      msg,
      type: isError ? SnackBarType.error : SnackBarType.success,
    );
  }

  // ── Tentukan aksi berdasarkan status terkini ────────────────────────────────
  List<_ActionDef> _getNextActions(String status) {
    switch (status) {
      case 'requested':
        return [
          _ActionDef('Tolak', 'rejected', true, Icons.cancel_outlined),
          _ActionDef('Setujui', 'approved', false, Icons.check_circle_outline_rounded),
        ];
      case 'approved':
        return [
          _ActionDef('Batalkan', 'canceled', true, Icons.cancel_outlined),
          _ActionDef('Mulai OTW', 'otw', false, Icons.local_shipping_rounded),
        ];
      case 'otw':
        return [
          _ActionDef('Batalkan', 'canceled', true, Icons.cancel_outlined),
          _ActionDef('di Lokasi', 'arrived', false, Icons.location_on_rounded),
        ];
      case 'arrived':
        return [
          _ActionDef('Batalkan', 'canceled', true, Icons.cancel_outlined),
          _ActionDef('Input', 'completed', false, Icons.inventory_2_rounded),
        ];
      default:
        return [];
    }
  }

  // ── Deteksi apakah sesi dimulai dari request BSU ────────────────────────────
  bool get _isBsuRequestFlow =>
      _data?.riwayat.any((r) => r.status == 'requested') ?? false;

  // ── Status helpers ──────────────────────────────────────────────────────────
  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'otw':       return const Color(0xFF4EA1F6);
      case 'approved':  return _green;
      case 'arrived':   return const Color(0xFF9772F8);
      case 'completed': return const Color(0xFF23EAA9);
      case 'rejected':
      case 'canceled':  return const Color(0xFFFF5454);
      case 'requested': return const Color(0xFFF59E0B);
      default:          return const Color(0xFFF59E0B);
    }
  }

  String _statusLabel(String s) {
    switch (s.toLowerCase()) {
      case 'otw':       return 'Dalam Perjalanan';
      case 'approved':  return 'Disetujui';
      case 'arrived':   return 'di Lokasi';
      case 'completed': return 'Selesai';
      case 'rejected':  return 'Ditolak';
      case 'canceled':  return 'Dibatalkan';
      case 'requested': return 'Diajukan';
      default:          return s;
    }
  }

  IconData _statusIcon(String s) {
    switch (s.toLowerCase()) {
      case 'otw':       return Icons.local_shipping_rounded;
      case 'approved':  return Icons.check_circle_rounded;
      case 'arrived':   return Icons.location_on_rounded;
      case 'completed': return Icons.done_all_rounded;
      case 'rejected':  return Icons.cancel_rounded;
      case 'canceled':  return Icons.block_rounded;
      case 'requested': return Icons.hourglass_top_rounded;
      default:          return Icons.info_rounded;
    }
  }

  // ─── BUILD ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF5F7F5),
          image: DecorationImage(
            image: AssetImage('assets/images/bg_struk.webp'),
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
        ),
        child: SafeArea(
          child: Column(children: [
            const TopBarBack(title: 'Detail Sesi Pengangkutan'),
            Expanded(child: _buildBody()),
          ]),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: _dark));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.wifi_off_rounded, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(_error!,
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.grey[500])),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _fetch,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Coba Lagi',
                  style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _dark,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ]),
        ),
      );
    }

    final d = _data!;
    return RefreshIndicator(
      color: _dark,
      onRefresh: _fetch,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _buildHeroCard(d),
          if (d.statusTerkini == 'completed' && d.buktiFoto.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildBuktiFotoButton(d.buktiFoto),
          ],
          const SizedBox(height: 20),
          _buildTimeline(d),
          const SizedBox(height: 32),
        ]),
      ),
    );
  }

  // ── Hero card ───────────────────────────────────────────────────────────────
  Widget _buildHeroCard(DetailSesiPengangkutanModel d) {
    final statusColor = _statusColor(d.statusTerkini);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: _dark, borderRadius: BorderRadius.circular(25)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(_statusIcon(d.statusTerkini), size: 12, color: statusColor),
            const SizedBox(width: 5),
            Text(_statusLabel(d.statusTerkini),
                style: TextStyle(
                    fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w700, color: statusColor)),
          ]),
        ),
        const SizedBox(height: 7),
        Text(d.pengangkutanId,
            style: const TextStyle(
                fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w700,
                color: Colors.white, letterSpacing: 0.3)),
        const SizedBox(height: 16),
        Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
        const SizedBox(height: 16),
        _heroInfoRow(Icons.business_rounded, 'BSI', d.namaBsi),
        const SizedBox(height: 10),
        _heroInfoRow(Icons.recycling_rounded, 'BSU', d.namaBsu),
      ]),
    );
  }

  Widget _heroInfoRow(IconData icon, String label, String value) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 13, color: Colors.white70),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 10, color: Colors.white60)),
          Text(value,
              style: const TextStyle(
                  fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
        ]),
      ),
    ]);
  }

  // ── Bukti Foto Button ───────────────────────────────────────────────────────
  Widget _buildBuktiFotoButton(String url) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LihatFotoScreen(
            photoUrl: url,
            nama: 'Bukti Foto Pengangkutan',
          ),
        ),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _green.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.photo_rounded, color: _green, size: 18),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Lihat Bukti Foto',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: _dark,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: _green),
          ],
        ),
      ),
    );
  }

  // ── Timeline ────────────────────────────────────────────────────────────────
  Widget _buildTimeline(DetailSesiPengangkutanModel d) {
    // 5 tahap jika dimulai dari request BSU, 3 tahap jika BSI mulai langsung
    final stages = _isBsuRequestFlow
        ? const [
            _Stage('requested', 'Diajukan',              Icons.hourglass_top_rounded),
            _Stage('approved',  'Disetujui',              Icons.thumb_up_alt_rounded),
            _Stage('otw',       'Dalam Perjalanan',       Icons.local_shipping_rounded),
            _Stage('arrived',   'di Lokasi',         Icons.location_on_rounded),
            _Stage('completed', 'Pengangkutan Selesai',   Icons.done_all_rounded),
          ]
        : const [
            _Stage('otw',       'Dalam Perjalanan',       Icons.local_shipping_rounded),
            _Stage('arrived',   'di Lokasi',         Icons.location_on_rounded),
            _Stage('completed', 'Pengangkutan Selesai',   Icons.done_all_rounded),
          ];

    final statusTerkini = d.statusTerkini;
    final isTerminalError = statusTerkini == 'rejected' || statusTerkini == 'canceled';
    final currentIdx     = stages.indexWhere((s) => s.key == statusTerkini);
    final actions        = _getNextActions(statusTerkini);

    // Map riwayat by status untuk lookup O(1)
    final riwayatByStatus = <String, RiwayatSesiPengangkutanModel>{};
    for (final r in d.riwayat) {
      riwayatByStatus.putIfAbsent(r.status, () => r);
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildTimelineHeader(d.riwayat.length, d.statusTerkini),
      const SizedBox(height: 16),
      // Compute state tiap stage, lalu filter: hanya tampilkan yang bukan waiting
      ...() {
        final entries = <({_Stage stage, _StepState state, bool isPassed})>[];
        for (var i = 0; i < stages.length; i++) {
          final stage = stages[i];
          _StepState state;
          if (isTerminalError) {
            state = riwayatByStatus.containsKey(stage.key)
                ? _StepState.done
                : _StepState.waiting;
          } else if (currentIdx == -1) {
            state = _StepState.waiting;
          } else if (i < currentIdx) {
            state = _StepState.done;
          } else if (i == currentIdx) {
            state = _StepState.current;
          } else if (i == currentIdx + 1 && actions.isNotEmpty) {
            state = _StepState.action;
          } else {
            state = _StepState.waiting;
          }
          entries.add((
            stage: stage,
            state: state,
            isPassed: !isTerminalError && currentIdx != -1 && i < currentIdx,
          ));
        }

        final visible = entries.where((e) => e.state != _StepState.waiting).toList();
        return List.generate(visible.length, (j) {
          final e = visible[j];
          return _buildStep(
            stage: e.stage,
            stepState: e.state,
            riwayatItem: riwayatByStatus[e.stage.key],
            isLast: j == visible.length - 1,
            isPassed: e.isPassed,
            actions: e.state == _StepState.action ? actions : [],
            currentStatus: statusTerkini,
          );
        });
      }(),
    ]);
  }

  Widget _buildTimelineHeader(int count, String status) {
    final isTerminal = status == 'completed' || status == 'canceled' || status == 'rejected';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(children: [
        const Text('Riwayat Sesi',
            style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w600, color: _dark)),
        const Spacer(),
        if (!isTerminal)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration:
                BoxDecoration(color: _green.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(8)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(
                  width: 6, height: 6,
                  decoration: const BoxDecoration(color: _green, shape: BoxShape.circle)),
              const SizedBox(width: 5),
              const Text('Live',
                  style: TextStyle(
                      fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w600, color: _green)),
            ]),
          ),
      ]),
    );
  }

  // ── Step tunggal ────────────────────────────────────────────────────────────
  Widget _buildStep({
    required _Stage stage,
    required _StepState stepState,
    required RiwayatSesiPengangkutanModel? riwayatItem,
    required bool isLast,
    required bool isPassed,
    required List<_ActionDef> actions,
    required String currentStatus,
  }) {
    final isWaiting = stepState == _StepState.waiting;
    final isAction  = stepState == _StepState.action;

    final Color dotColor = switch (stepState) {
      _StepState.done    => _green,
      _StepState.current => _statusColor(stage.key),
      _StepState.error   => const Color(0xFFFF5454),
      _StepState.action  => Color(0xFF06C0C9),
      _StepState.waiting => Colors.grey[300]!,
    };

    return IntrinsicHeight(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // Dot + connector line
          SizedBox(
            width: 32,
            child: Column(children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: isWaiting ? Colors.grey[100] : dotColor.withValues(alpha: 0.13),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isWaiting ? Colors.grey[300]! : dotColor,
                    width: stepState == _StepState.current ? 2 : 1,
                  ),
                ),
                child: Icon(stage.icon, size: 15, color: isWaiting ? Colors.grey[400] : dotColor),
              ),
              if (!isLast)
                Expanded(
                  child: Center(
                    child: Container(
                      width: 2,
                      decoration: BoxDecoration(
                        color: isPassed ? _green : Colors.grey[200],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
            ]),
          ),
          const SizedBox(width: 14),
          // Card konten
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16, top: 4),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isWaiting ? const Color(0xFFF9F9F9) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isWaiting
                        ? Colors.grey.withValues(alpha: 0.12)
                        : isAction
                            ? Color(0xFF06C0C9).withValues(alpha: 0.30)
                            : dotColor.withValues(alpha: 0.25),
                  ),
                  boxShadow: !isWaiting
                      ? [BoxShadow(
                          color: dotColor.withValues(alpha: 0.07),
                          blurRadius: 10, offset: const Offset(0, 4))]
                      : null,
                ),
                child: isAction
                    ? _buildActionContent(actions, currentStatus)
                    : _buildRiwayatContent(stage, isWaiting, dotColor, riwayatItem),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  // ── Konten riwayat normal (done / current / waiting) ────────────────────────
  Widget _buildRiwayatContent(
    _Stage stage,
    bool isWaiting,
    Color dotColor,
    RiwayatSesiPengangkutanModel? riwayatItem,
  ) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: isWaiting ? Colors.grey[100] : dotColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: isWaiting ? Border.all(color: Colors.grey[300]!) : null,
          ),
          child: Text(
            isWaiting ? 'Menunggu' : stage.label,
            style: TextStyle(
                fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w700,
                color: isWaiting ? Colors.grey[400] : dotColor),
          ),
        ),
        const Spacer(),
        if (riwayatItem != null)
          Text(riwayatItem.jamFormatted,
              style: TextStyle(fontFamily: 'Poppins', fontSize: 10, color: Colors.grey[400])),
      ]),
      const SizedBox(height: 6),
      Text(
        riwayatItem?.catatan.isNotEmpty == true ? riwayatItem!.catatan : stage.label,
        style: TextStyle(
            fontFamily: 'Poppins', fontSize: 13,
            fontWeight: isWaiting ? FontWeight.w400 : FontWeight.w600,
            color: isWaiting ? Colors.grey[400] : _dark),
      ),
      if (riwayatItem != null) ...[
        const SizedBox(height: 6),
        Row(children: [
          Icon(Icons.person_outline_rounded, size: 11, color: Colors.grey[400]),
          const SizedBox(width: 4),
          Text(riwayatItem.changedBy,
              style: TextStyle(fontFamily: 'Poppins', fontSize: 10, color: Colors.grey[400])),
          const Spacer(),
          Text(riwayatItem.tanggalFormatted,
              style: TextStyle(fontFamily: 'Poppins', fontSize: 10, color: Colors.grey[400])),
        ]),
      ],
    ]);
  }

  // ── Konten aksi petugas BSI ─────────────────────────────────────────────────
  Widget _buildActionContent(List<_ActionDef> actions, String currentStatus) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Badge
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
            color: Color(0xFF06C0C9).withValues(alpha: 0.10), borderRadius: BorderRadius.circular(20)),
        child: const Text('Aksi Berikutnya',
            style: TextStyle(
                fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF06C0C9))),
      ),
      const SizedBox(height: 10),
      // Tombol
      if (_actionLoading)
        const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: CircularProgressIndicator(color: _dark, strokeWidth: 2.5),
          ),
        )
      else
        Row(
          children: List.generate(actions.length, (i) {
            final a = actions[i];

            // Tentukan callback sesuai jenis aksi
            final VoidCallback onTap;
            if (currentStatus == 'arrived' && a.newStatus == 'completed') {
              onTap = _openInputSampah;
            } else if (a.needsNotes) {
              onTap = () => _showNotesDialog(currentStatus, a.newStatus, a.label);
            } else {
              onTap = () => _doUpdate(currentStatus, a.newStatus);
            }

            final Widget btn = a.needsNotes
                ? ElevatedButton.icon(
              onPressed: onTap,
              icon: Icon(
                a.icon,
                size: 14,
                color: Colors.red,
              ),
              label: Text(
                a.label,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: Colors.red,
                ),
              ),
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: Colors.red.shade50,
                foregroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            )
                : ElevatedButton.icon(
                    onPressed: onTap,
                    icon: Icon(a.icon, size: 14),
                    label: Text(a.label,
                        style: const TextStyle(
                            fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF06C0C9),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                  );

            final padding = Padding(padding: EdgeInsets.only(left: i == 0 ? 0 : 8), child: btn);
            return Expanded(flex: a.needsNotes ? 1 : 1, child: padding);
          }),
        ),
    ]);
  }
}

// ─── Data helpers ─────────────────────────────────────────────────────────────

enum _StepState { done, current, waiting, error, action }

class _Stage {
  final String   key;
  final String   label;
  final IconData icon;
  const _Stage(this.key, this.label, this.icon);
}

class _ActionDef {
  final String   label;
  final String   newStatus;
  final bool     needsNotes;
  final IconData icon;
  const _ActionDef(this.label, this.newStatus, this.needsNotes, this.icon);
}
