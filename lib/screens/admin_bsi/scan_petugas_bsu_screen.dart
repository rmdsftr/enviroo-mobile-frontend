import 'dart:io';

import 'package:enviroo/providers/auth_provider.dart';
import 'package:enviroo/screens/admin_bsu/inapp_camera_screen.dart';
import 'package:enviroo/services/pengangkutan_service.dart';
import 'package:enviroo/widgets/topbar_back.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

/// Scanner QR petugas BSU + fallback foto bukti.
///
/// Alur:
///  1. Petugas BSI scan QR petugas BSU → ambil admin_bsu_id dari token QR.
///  2. Jika scan tidak bekerja, petugas BSI dapat mengambil foto bukti
///     pengangkutan. Foto akan dikirim sebagai bukti_foto pada multipart
///     request input pengangkutan. Path foto wajib menyertakan
///     [adminBsuIdAwal] (yaitu admin_bsu_id yang sudah tercatat sejak sesi
///     mulai). Jika [adminBsuIdAwal] kosong, foto-only fallback tidak bisa
///     dipakai dan QR scan menjadi wajib.
class ScanPetugasBsuScreen extends StatefulWidget {
  final String pengangkutanId;
  final String namaBsu;
  final List<Map<String, dynamic>> items;
  final double totalPoin;
  final String adminBsuIdAwal;

  const ScanPetugasBsuScreen({
    super.key,
    required this.pengangkutanId,
    required this.namaBsu,
    required this.items,
    required this.totalPoin,
    this.adminBsuIdAwal = '',
  });

  @override
  State<ScanPetugasBsuScreen> createState() => _ScanPetugasBsuScreenState();
}

class _ScanPetugasBsuScreenState extends State<ScanPetugasBsuScreen>
    with SingleTickerProviderStateMixin {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isProcessing = false;
  bool _isSubmitting = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // ── QR detect ──────────────────────────────────────────────────────────────
  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing || _isSubmitting) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    final raw = barcode.rawValue!;
    if (!raw.startsWith('ENVIROO-ANGKUTBSU|')) return;

    setState(() => _isProcessing = true);
    _scannerController.stop();
    HapticFeedback.mediumImpact();

    final parts = raw.split('|');
    final adminBsuId = parts.length >= 2 ? parts[1] : '';

    if (adminBsuId.isEmpty) {
      _showError('QR code tidak valid');
      _resumeScan();
      return;
    }

    await _submit(adminBsuId, null);
  }

  void _resumeScan() {
    if (!mounted) return;
    setState(() => _isProcessing = false);
    _scannerController.start();
  }

  // ── Foto fallback ──────────────────────────────────────────────────────────
  Future<void> _ambilFotoBukti() async {
    if (widget.adminBsuIdAwal.isEmpty) {
      _showError(
        'Foto bukti hanya bisa digunakan jika sesi pengangkutan dimulai dari sisi BSU. '
        'Silakan scan QR petugas BSU terlebih dahulu.',
      );
      return;
    }

    _scannerController.stop();
    final File? foto = await Navigator.push<File?>(
      context,
      MaterialPageRoute(builder: (_) => const InAppCameraScreen()),
    );

    if (!mounted) return;

    if (foto == null) {
      _scannerController.start();
      return;
    }

    setState(() => _isProcessing = true);
    await _submit(widget.adminBsuIdAwal, foto);
  }

  // ── Submit ─────────────────────────────────────────────────────────────────
  Future<void> _submit(String adminBsuId, File? bukti) async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final adminBsiId = auth.identityId ?? '';
    final token = auth.currentUser?.accessToken ?? '';

    final res = await PengangkutanService.inputSampah(
      widget.pengangkutanId,
      adminBsiId,
      adminBsuId,
      widget.items,
      token,
      buktiFoto: bukti,
    );

    if (!mounted) return;

    if (res['success'] == true) {
      HapticFeedback.heavyImpact();
      await _showSuccessDialog(
        totalItem: (res['total_item'] ?? 0) as int,
        totalPoin: (res['total_poin'] as num? ?? widget.totalPoin).toDouble(),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } else {
      setState(() {
        _isSubmitting = false;
        _isProcessing = false;
      });
      _showError(res['message'] ?? 'Gagal mengirim setoran pengangkutan');
      _scannerController.start();
    }
  }

  // ── Dialogs ────────────────────────────────────────────────────────────────
  Future<void> _showSuccessDialog({
    required int totalItem,
    required double totalPoin,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF4EA771).withOpacity(0.13),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF4EA771),
                  size: 42,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Setoran BSU Tersimpan',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: Color(0xFF013236),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                '$totalItem jenis sampah berhasil dicatat',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FFF4),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFF4EA771).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.stars_rounded,
                            color: Color(0xFF4EA771), size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Total Poin',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF013236),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${_formatPoin(totalPoin)} poin',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF4EA771),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF013236),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Selesai',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
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

  void _showError(String msg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Terjadi Kesalahan',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: Colors.red,
          ),
        ),
        content: Text(
          msg,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            color: Colors.grey[700],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Tutup',
              style: TextStyle(
                color: Color(0xFF013236),
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(color: Colors.white),
        child: SafeArea(
          child: Column(
            children: [
              const TopBarBack(title: 'Verifikasi Petugas BSU'),
              const SizedBox(height: 12),
              _buildInfoBsu(),
              const SizedBox(height: 12),
              _buildInstructionCard(),
              const SizedBox(height: 16),
              Expanded(child: _buildScannerArea()),
              const SizedBox(height: 16),
              _buildFotoButton(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBsu() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF013236),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF013236).withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: const Color(0xFF06C0C9).withOpacity(0.18),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.local_shipping_rounded,
              color: Color(0xFF06C0C9),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.namaBsu,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${widget.items.length} item · ${_formatPoin(widget.totalPoin)} poin',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.65),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF06C0C9).withOpacity(0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF06C0C9).withOpacity(0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.qr_code_scanner_rounded,
              color: Color(0xFF06C0C9),
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Scan QR identitas petugas BSU untuk memvalidasi & menyimpan setoran pengangkutan.',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: Color(0xFF013236),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerArea() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF013236).withOpacity(0.18),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            MobileScanner(
              controller: _scannerController,
              onDetect: _onDetect,
            ),
            IgnorePointer(
              child: CustomPaint(
                painter: _OverlayPainter(),
                child: const SizedBox.expand(),
              ),
            ),
            if (!_isProcessing && !_isSubmitting)
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (_, __) => Center(
                  child: Transform.scale(
                    scale: _pulseAnimation.value,
                    child: const _ScanFrame(),
                  ),
                ),
              ),
            if (_isProcessing || _isSubmitting) _buildProcessingOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.65),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: const Color(0xFF06C0C9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF06C0C9).withOpacity(0.45),
                    blurRadius: 28,
                    spreadRadius: 6,
                  ),
                ],
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    )
                  : const Icon(
                      Icons.qr_code_2_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
            ),
            const SizedBox(height: 18),
            Text(
              _isSubmitting ? 'Mengirim Setoran...' : 'Memverifikasi Petugas...',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _isSubmitting
                  ? 'Mohon tunggu sebentar'
                  : 'Memproses identitas BSU',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFotoButton() {
    return GestureDetector(
      onTap: _isProcessing || _isSubmitting ? null : _ambilFotoBukti,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF013236).withOpacity(0.10),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF06C0C9).withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.photo_camera_rounded,
                color: Color(0xFF06C0C9),
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'QR tidak bekerja? Ambil foto bukti',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Color(0xFF013236),
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 13,
              color: Color(0xFF06C0C9),
            ),
          ],
        ),
      ),
    );
  }

  String _formatPoin(double value) {
    final intPart = value.truncate();
    final dec = value - intPart;
    final formatted = intPart
        .toString()
        .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
    if (dec > 0) return '$formatted${dec.toStringAsFixed(2).substring(1)}';
    return formatted;
  }
}

// ─── Scan frame & painters ──────────────────────────────────────────────────

class _ScanFrame extends StatelessWidget {
  const _ScanFrame();

  @override
  Widget build(BuildContext context) {
    const double size = 230;
    const double bracketLen = 30;
    const double bracketThick = 3.5;
    const Color bracketColor = Color(0xFF06C0C9);

    return SizedBox(
      width: size,
      height: size + 36,
      child: Stack(
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.15),
                width: 1,
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            child: _Bracket(
              len: bracketLen,
              thick: bracketThick,
              color: bracketColor,
              showTop: true,
              showLeft: true,
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: _Bracket(
              len: bracketLen,
              thick: bracketThick,
              color: bracketColor,
              showTop: true,
              showLeft: false,
            ),
          ),
          Positioned(
            bottom: 36,
            left: 0,
            child: _Bracket(
              len: bracketLen,
              thick: bracketThick,
              color: bracketColor,
              showTop: false,
              showLeft: true,
            ),
          ),
          Positioned(
            bottom: 36,
            right: 0,
            child: _Bracket(
              len: bracketLen,
              thick: bracketThick,
              color: bracketColor,
              showTop: false,
              showLeft: false,
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Arahkan ke QR Code petugas BSU',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.75),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bracket extends StatelessWidget {
  final double len, thick;
  final Color color;
  final bool showTop, showLeft;

  const _Bracket({
    required this.len,
    required this.thick,
    required this.color,
    required this.showTop,
    required this.showLeft,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(len, len),
      painter: _BracketPainter(
        color: color,
        thick: thick,
        showTop: showTop,
        showLeft: showLeft,
      ),
    );
  }
}

class _BracketPainter extends CustomPainter {
  final Color color;
  final double thick;
  final bool showTop, showLeft;

  _BracketPainter({
    required this.color,
    required this.thick,
    required this.showTop,
    required this.showLeft,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = thick
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final w = size.width;
    final h = size.height;
    if (showLeft && showTop) {
      canvas.drawLine(Offset(0, h), const Offset(0, 0), p);
      canvas.drawLine(const Offset(0, 0), Offset(w, 0), p);
    } else if (!showLeft && showTop) {
      canvas.drawLine(const Offset(0, 0), Offset(w, 0), p);
      canvas.drawLine(Offset(w, 0), Offset(w, h), p);
    } else if (showLeft && !showTop) {
      canvas.drawLine(Offset(0, 0), Offset(0, h), p);
      canvas.drawLine(Offset(0, h), Offset(w, h), p);
    } else {
      canvas.drawLine(Offset(w, 0), Offset(w, h), p);
      canvas.drawLine(Offset(0, h), Offset(w, h), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _OverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.52)
      ..style = PaintingStyle.fill;
    const double frameSize = 230;
    final double left = (size.width - frameSize) / 2;
    final double top = (size.height - frameSize) / 2;
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, frameSize, frameSize),
        const Radius.circular(16),
      ))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
