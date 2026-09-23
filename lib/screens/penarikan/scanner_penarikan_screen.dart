import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../providers/penarikan_petugas_provider.dart';
import '../../widgets/topbar_back.dart';
import 'penyerahan_insentif_manual_screen.dart';

/// Scanner QR penarikan — QR yang ditunjukkan nasabah (lihat
/// qr_penarikan_screen.dart) berisi JSON `{"type":"ENVIROO-PENARIKAN",
/// "nasabah_id":"...","penarikan_id":"..."}`. Begitu QR cocok dengan
/// transaksi yang sedang dibuka petugas, langsung diselesaikan lewat
/// PATCH /penarikan/selesai (jalur QR — tidak butuh foto lagi).
///
/// Pop dengan `true` kalau penarikan berhasil diselesaikan (baik lewat scan
/// atau lewat konfirmasi manual), `null` kalau dibatalkan.
class ScannerPenarikanScreen extends StatefulWidget {
  final String penarikanId;
  final String nasabahId;

  const ScannerPenarikanScreen({
    super.key,
    required this.penarikanId,
    required this.nasabahId,
  });

  @override
  State<ScannerPenarikanScreen> createState() =>
      _ScannerPenarikanScreenState();
}

class _ScannerPenarikanScreenState extends State<ScannerPenarikanScreen>
    with SingleTickerProviderStateMixin {
  static const Color primary = Color(0xFF4EA771);
  static const Color dark = Color(0xFF013236);

  final MobileScannerController _scannerController = MobileScannerController();
  bool _isProcessing = false;
  // null = lagi diproses (loading), true = sukses, false = gagal/gak cocok.
  bool? _success;
  String _errorMessage = '';
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

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;
    final barcode = capture.barcodes.firstOrNull;
    final raw = barcode?.rawValue;
    if (raw == null || raw.isEmpty) return;

    Map<String, dynamic>? decoded;
    try {
      decoded = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return; // bukan QR ENVIROO-PENARIKAN, abaikan & terus scan
    }
    if (decoded['type'] != 'ENVIROO-PENARIKAN') return;

    setState(() {
      _isProcessing = true;
      _success = null;
    });
    _scannerController.stop();
    HapticFeedback.mediumImpact();

    final scannedPenarikanId = decoded['penarikan_id']?.toString();
    final scannedNasabahId = decoded['nasabah_id']?.toString();
    if (scannedPenarikanId != widget.penarikanId ||
        scannedNasabahId != widget.nasabahId) {
      _handleMismatch();
      return;
    }

    _submitViaQr(raw);
  }

  Future<void> _submitViaQr(String qrData) async {
    final prov = context.read<PenarikanPetugasProvider>();
    final ok = await prov.selesaikanViaQr(
      qrData: qrData,
      penarikanId: widget.penarikanId,
    );
    if (!mounted) return;

    if (ok) {
      HapticFeedback.mediumImpact();
      setState(() => _success = true);
      await Future.delayed(const Duration(milliseconds: 700));
      if (mounted) Navigator.pop(context, true);
    } else {
      setState(() {
        _success = false;
        _errorMessage = prov.errorDetail ?? 'Gagal menyelesaikan penarikan';
      });
      await Future.delayed(const Duration(milliseconds: 1800));
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _success = null;
      });
      _scannerController.start();
    }
  }

  Future<void> _handleMismatch() async {
    setState(() {
      _success = false;
      _errorMessage = 'QR ini bukan untuk transaksi penarikan yang sedang dibuka';
    });
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    setState(() {
      _isProcessing = false;
      _success = null;
    });
    _scannerController.start();
  }

  // ── Konfirmasi manual (kalau QR tidak bisa dipindai) ─────────────────────

  Future<void> _openManualScreen() async {
    _scannerController.stop();
    final completed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PenyerahanInsentifManualScreen(
          penarikanId: widget.penarikanId,
          nasabahId: widget.nasabahId,
        ),
      ),
    );
    if (!mounted) return;
    if (completed == true) {
      Navigator.pop(context, true);
      return;
    }
    _scannerController.start();
  }

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
              const TopBarBack(title: 'Scan QR Penarikan'),
              const SizedBox(height: 16),
              _buildInstructionCard(),
              const SizedBox(height: 20),
              Expanded(child: _buildScannerArea()),
              const SizedBox(height: 20),
              _buildManualButton(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: dark.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.qr_code_scanner_rounded,
              color: dark,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Scan QR code yang ditunjukkan nasabah untuk langsung menyelesaikan penarikan insentif',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2D5A1D),
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
            color: dark.withValues(alpha: 0.18),
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
            if (!_isProcessing)
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (_, __) => Center(
                  child: Transform.scale(
                    scale: _pulseAnimation.value,
                    child: const _ScanFrame(),
                  ),
                ),
              ),
            if (_isProcessing)
              _success == null
                  ? _buildLoadingOverlay()
                  : _success == true
                      ? _buildSuccessOverlay()
                      : _buildErrorOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.65),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Menyelesaikan penarikan...',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.65),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: primary.withValues(alpha: 0.45),
                    blurRadius: 28,
                    spreadRadius: 6,
                  ),
                ],
              ),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 38),
            ),
            const SizedBox(height: 18),
            const Text(
              'Penarikan Selesai',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Insentif berhasil diserahkan ke nasabah',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.65),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: const Color(0xFFE53935),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE53935).withValues(alpha: 0.45),
                    blurRadius: 28,
                    spreadRadius: 6,
                  ),
                ],
              ),
              child: const Icon(Icons.close_rounded, color: Colors.white, size: 38),
            ),
            const SizedBox(height: 18),
            const Text(
              'Gagal Menyelesaikan',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.75),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManualButton() {
    return GestureDetector(
      onTap: _openManualScreen,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: dark.withValues(alpha: 0.1),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(
                Icons.camera_alt_outlined,
                color: primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'QR code tidak bekerja? Konfirmasi penyerahan insentif manual',
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
              color: primary,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Scan frame + brackets (visual sama dengan scanner_penimbangan_screen) ──

class _ScanFrame extends StatelessWidget {
  const _ScanFrame();

  @override
  Widget build(BuildContext context) {
    const double size = 230;
    const double bracketLen = 30;
    const double bracketThick = 3.5;
    const Color bracketColor = Color(0xFF4EA771);

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
                color: Colors.white.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
          ),
          Positioned(top: 0, left: 0,
              child: _Bracket(len: bracketLen, thick: bracketThick,
                  color: bracketColor, showTop: true, showLeft: true)),
          Positioned(top: 0, right: 0,
              child: _Bracket(len: bracketLen, thick: bracketThick,
                  color: bracketColor, showTop: true, showLeft: false)),
          Positioned(bottom: 36, left: 0,
              child: _Bracket(len: bracketLen, thick: bracketThick,
                  color: bracketColor, showTop: false, showLeft: true)),
          Positioned(bottom: 36, right: 0,
              child: _Bracket(len: bracketLen, thick: bracketThick,
                  color: bracketColor, showTop: false, showLeft: false)),
          Positioned(
            bottom: 0,
            left: 0, right: 0,
            child: Center(
              child: Text(
                'Arahkan ke QR Code nasabah',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.75),
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
    required this.len, required this.thick,
    required this.color, required this.showTop, required this.showLeft,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(len, len),
      painter: _BracketPainter(
        color: color, thick: thick,
        showTop: showTop, showLeft: showLeft,
      ),
    );
  }
}

class _BracketPainter extends CustomPainter {
  final Color color;
  final double thick;
  final bool showTop, showLeft;

  _BracketPainter({
    required this.color, required this.thick,
    required this.showTop, required this.showLeft,
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
      ..color = Colors.black.withValues(alpha: 0.52)
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
