import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:enviroo/models/sesi_pengangkutan_model.dart';
import 'package:enviroo/providers/pengangkutan_provider.dart';
import 'package:enviroo/services/pengangkutan_service.dart';
import 'package:enviroo/widgets/topbar_back.dart';
import 'package:enviroo/screens/admin_bsu/QR_angkut_sampah_screen.dart';
import 'package:enviroo/screens/lihat_foto_screen.dart';

class SesiPengangkutanScreen extends StatefulWidget {
  final String pengangkutanId;
  const SesiPengangkutanScreen({super.key, required this.pengangkutanId});

  @override
  State<SesiPengangkutanScreen> createState() => _SesiPengangkutanScreenState();
}

class _SesiPengangkutanScreenState extends State<SesiPengangkutanScreen> {
  static const _dark = Color(0xFF013236);
  static const _green = Color(0xFF4EA771);
  static const _pollInterval = Duration(seconds: 5);

  DetailSesiPengangkutanModel? _data;
  bool _isLoading = true;
  String? _error;
  Timer? _timer;

  PengangkutanProvider? _pengangkutanProvider;
  int _lastRefreshToken = -1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetch();
      _timer = Timer.periodic(_pollInterval, (_) => _fetch());
      _pengangkutanProvider = context.read<PengangkutanProvider>();
      _lastRefreshToken = _pengangkutanProvider!.refreshToken;
      _pengangkutanProvider!.addListener(_onPengangkutanRefresh);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pengangkutanProvider?.removeListener(_onPengangkutanRefresh);
    super.dispose();
  }

  void _onPengangkutanRefresh() {
    if (!mounted || _pengangkutanProvider == null) return;
    final token = _pengangkutanProvider!.refreshToken;
    if (token != _lastRefreshToken) {
      _lastRefreshToken = token;
      _fetch();
    }
  }

  Future<void> _fetch() async {
    final result = await PengangkutanService.detailSesiActive(
        widget.pengangkutanId);
    if (!mounted) return;
    setState(() {
      _data = result.data;
      _error = result.error;
      _isLoading = false;
    });
  }

  // ── Flow detection ──────────────────────────────────────────────────────────
  bool get _isBsuRequestFlow =>
      _data?.riwayat.any((r) => r.status == 'requested') ?? false;

  // ── Status helpers ──────────────────────────────────────────────────────────
  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'otw':
        return const Color(0xFF4EA1F6);
      case 'approved':
        return _green;
      case 'arrived':
        return const Color(0xFF9772F8);
      case 'completed':
        return const Color(0xFF23EAA9);
      case 'rejected':
      case 'canceled':
        return const Color(0xFFFF5454);
      default:
        return const Color(0xFFF59E0B);
    }
  }

  String _statusLabel(String s) {
    switch (s.toLowerCase()) {
      case 'otw':        return 'Dalam Perjalanan';
      case 'approved':   return 'Disetujui';
      case 'arrived':    return 'Tiba di Lokasi';
      case 'completed':  return 'Selesai';
      case 'rejected':   return 'Ditolak';
      case 'canceled':   return 'Dibatalkan';
      default:           return s;
    }
  }

  IconData _statusIcon(String s) {
    switch (s.toLowerCase()) {
      case 'otw':        return Icons.local_shipping_rounded;
      case 'approved':   return Icons.check_circle_rounded;
      case 'arrived':    return Icons.location_on_rounded;
      case 'completed':  return Icons.done_all_rounded;
      case 'rejected':   return Icons.cancel_rounded;
      case 'canceled':   return Icons.block_rounded;
      default:           return Icons.info_rounded;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
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
          child: Column(
            children: [
              const TopBarBack(title: 'Detail Sesi Pengangkutan'),
              Expanded(child: _buildBody()),
            ],
          ),
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off_rounded, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.grey[500]),
              ),
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
            ],
          ),
        ),
      );
    }

    final d = _data!;
    final statusColor = _statusColor(d.statusTerkini);

    return RefreshIndicator(
      color: _dark,
      onRefresh: _fetch,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroCard(d, statusColor),
            if (d.statusTerkini == 'completed' && d.buktiFoto.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildBuktiFotoButton(d.buktiFoto),
            ],
            const SizedBox(height: 20),
            _buildUnifiedTimeline(d),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
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

  // ── Timeline terpadu: tahapan + riwayat aktual digabung ────────────────────
  Widget _buildUnifiedTimeline(DetailSesiPengangkutanModel d) {
    final stages = _isBsuRequestFlow
        ? [
            const _Stage('requested', 'Permintaan Diajukan',  Icons.send_rounded),
            const _Stage('approved',  'Permintaan Disetujui', Icons.check_circle_rounded),
            const _Stage('otw',       'Dalam Perjalanan',     Icons.local_shipping_rounded),
            const _Stage('arrived',   'Tiba di Lokasi',       Icons.location_on_rounded),
            const _Stage('completed', 'Pengangkutan Selesai', Icons.done_all_rounded),
          ]
        : [
            const _Stage('otw',       'Dalam Perjalanan',     Icons.local_shipping_rounded),
            const _Stage('arrived',   'Tiba di Lokasi',       Icons.location_on_rounded),
            const _Stage('completed', 'Pengangkutan Selesai', Icons.done_all_rounded),
          ];

    final statusTerkini = d.statusTerkini;
    final isTerminalError = statusTerkini == 'rejected' || statusTerkini == 'canceled';
    final currentIdx = stages.indexWhere((s) => s.key == statusTerkini);

    // Map riwayat by status supaya mudah dicari
    final riwayatByStatus = <String, RiwayatSesiPengangkutanModel>{};
    for (final r in d.riwayat) {
      riwayatByStatus.putIfAbsent(r.status, () => r);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        _buildRiwayatHeader(d.riwayat.length),
        const SizedBox(height: 16),
        // Steps
        ...List.generate(stages.length, (i) {
          final stage = stages[i];
          final isLast = i == stages.length - 1;
          final riwayatItem = riwayatByStatus[stage.key];

          _StepState stepState;
          if (isTerminalError) {
            // Gunakan riwayat untuk deteksi step mana yang sudah terjadi
            stepState = riwayatByStatus.containsKey(stage.key)
                ? _StepState.error
                : _StepState.waiting;
          } else if (currentIdx == -1) {
            stepState = _StepState.waiting;
          } else if (i < currentIdx) {
            stepState = _StepState.done;
          } else if (i == currentIdx) {
            stepState = _StepState.current;
          } else {
            stepState = _StepState.waiting;
          }

          return _buildMergedStep(
            stage: stage,
            stepState: stepState,
            riwayatItem: riwayatItem,
            isLast: isLast,
            isPassed: !isTerminalError && currentIdx != -1 && i < currentIdx,
          );
        }),
      ],
    );
  }

  Widget _buildMergedStep({
    required _Stage stage,
    required _StepState stepState,
    required RiwayatSesiPengangkutanModel? riwayatItem,
    required bool isLast,
    required bool isPassed,
  }) {
    final Color dotColor = stepState == _StepState.done
        ? _green
        : stepState == _StepState.current
            ? _statusColor(stage.key)
            : stepState == _StepState.error
                ? const Color(0xFFFF5454)
                : Colors.grey[300]!;

    final bool isWaiting = stepState == _StepState.waiting;

    return IntrinsicHeight(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Garis + dot ─────────────────────────────────────────
            SizedBox(
              width: 32,
              child: Column(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isWaiting ? Colors.grey[100] : dotColor.withOpacity(0.13),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isWaiting ? Colors.grey[300]! : dotColor,
                        width: stepState == _StepState.current ? 2 : 1,
                      ),
                    ),
                    child: Icon(
                      stage.icon,
                      size: 15,
                      color: isWaiting ? Colors.grey[400] : dotColor,
                    ),
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
                ],
              ),
            ),
            const SizedBox(width: 14),
            // ── Konten card ─────────────────────────────────────────
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
                          ? Colors.grey.withOpacity(0.12)
                          : dotColor.withOpacity(0.25),
                    ),
                    boxShadow: !isWaiting
                        ? [BoxShadow(color: dotColor.withOpacity(0.07), blurRadius: 10, offset: const Offset(0, 4))]
                        : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Badge status / menunggu
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isWaiting ? Colors.grey[100] : dotColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: isWaiting ? Border.all(color: Colors.grey[300]!) : null,
                            ),
                            child: Text(
                              isWaiting ? 'Menunggu' : stage.label,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: isWaiting ? Colors.grey[400] : dotColor,
                              ),
                            ),
                          ),
                          const Spacer(),
                          if (riwayatItem != null)
                            Text(
                              riwayatItem.jamFormatted,
                              style: TextStyle(fontFamily: 'Poppins', fontSize: 10, color: Colors.grey[400]),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Judul tahap atau catatan
                      Text(
                        riwayatItem?.catatan.isNotEmpty == true
                            ? riwayatItem!.catatan
                            : stage.label,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: isWaiting ? FontWeight.w400 : FontWeight.w600,
                          color: isWaiting ? Colors.grey[400] : _dark,
                        ),
                      ),
                      if (riwayatItem != null) ...
                        [
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.person_outline_rounded, size: 11, color: Colors.grey[400]),
                              const SizedBox(width: 4),
                              Text(riwayatItem.changedBy,
                                  style: TextStyle(fontFamily: 'Poppins', fontSize: 10, color: Colors.grey[400])),
                              const Spacer(),
                              Text(riwayatItem.tanggalFormatted,
                                  style: TextStyle(fontFamily: 'Poppins', fontSize: 10, color: Colors.grey[400])),
                            ],
                          ),
                        ],
                      if (stepState == _StepState.current && stage.key == 'arrived') ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const QRAngkutSampahScreen()),
                            ),
                            icon: const Icon(Icons.qr_code_rounded, size: 16),
                            label: const Text(
                              'QR Code Pengangkutan',
                              style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF06C0C9),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildHeroCard(DetailSesiPengangkutanModel d, Color statusColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _dark,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_statusIcon(d.statusTerkini), size: 12, color: statusColor),
                const SizedBox(width: 5),
                Text(
                  _statusLabel(d.statusTerkini),
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w700, color: statusColor),
                ),
              ],
            ),
          ),
          const SizedBox(height: 7),
          Text(
            d.pengangkutanId,
            style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.3),
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.white.withOpacity(0.1), height: 1),
          const SizedBox(height: 16),
          _heroInfoRow(Icons.business_rounded, 'BSI', d.namaBsi),
          const SizedBox(height: 10),
          _heroInfoRow(Icons.recycling_rounded, 'BSU', d.namaBsu),
        ],
      ),
    );
  }

  Widget _buildRiwayatHeader(int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child : Row(
        children: [
          const Text(
            'Riwayat Sesi',
            style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w600, color: _dark),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: _green.withOpacity(0.10), borderRadius: BorderRadius.circular(8)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 6, height: 6, decoration: const BoxDecoration(color: _green, shape: BoxShape.circle)),
                const SizedBox(width: 5),
                const Text('Live', style: TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w600, color: _green)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 13, color: Colors.white70),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontFamily: 'Poppins', fontSize: 10, color: Colors.white60)),
              Text(value, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
            ],
          ),
        ),
      ],
    );
  }

} // end _SesiPengangkutanScreenState

// ─── Helpers ─────────────────────────────────────────────────────────────────

enum _StepState { done, current, waiting, error }

class _Stage {
  final String key;
  final String label;
  final IconData icon;
  const _Stage(this.key, this.label, this.icon);
}
