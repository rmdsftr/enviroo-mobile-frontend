import 'package:enviroo/providers/auth_provider.dart';
import 'package:enviroo/providers/sembako_provider.dart';
import 'package:enviroo/widgets/custom_snackbar.dart';
import 'package:enviroo/widgets/success_bottom_sheet.dart';
import 'package:enviroo/widgets/topbar_back.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

class ScannerDistribusiBsuScreen extends StatefulWidget {
  final String bsiId;
  final String bsuId;
  final String namaBsu;

  const ScannerDistribusiBsuScreen({
    super.key,
    required this.bsiId,
    required this.bsuId,
    required this.namaBsu,
  });

  @override
  State<ScannerDistribusiBsuScreen> createState() =>
      _ScannerDistribusiBsuScreenState();
}

class _ScannerDistribusiBsuScreenState extends State<ScannerDistribusiBsuScreen>
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

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing || _isSubmitting) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    final raw = barcode.rawValue!;
    // Format QR petugas BSU: ENVIROO-PETUGAS|{adminId}
    // Coba beberapa format yang mungkin digunakan
    String? adminBsuId;
    if (raw.startsWith('ENVIROO-PETUGAS|')) {
      adminBsuId = raw.split('|')[1];
    } else if (raw.startsWith('ENVIROO-ANGKUTBSU|')) {
      adminBsuId = raw.split('|')[1];
    } else if (raw.startsWith('ENVIROO-BSU|')) {
      adminBsuId = raw.split('|')[1];
    }

    if (adminBsuId == null || adminBsuId.isEmpty) return;

    setState(() => _isProcessing = true);
    _scannerController.stop();
    HapticFeedback.mediumImpact();

    await _submit(adminBsuId);
  }

  void _resumeScan() {
    if (!mounted) return;
    setState(() {
      _isProcessing = false;
      _isSubmitting = false;
    });
    _scannerController.start();
  }

  Future<void> _submit(String adminBsuId) async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final sembako = Provider.of<SembakoProvider>(context, listen: false);

    final result = await sembako.addDistribusi(
      bsiId: widget.bsiId,
      bsuId: widget.bsuId,
      adminBsiId: auth.identityId ?? '',
      adminBsuId: adminBsuId,
    );

    if (!mounted) return;

    if (result['success'] == true) {
      HapticFeedback.heavyImpact();
      _showSuccessDialog();
    } else {
      setState(() {
        _isSubmitting = false;
        _isProcessing = false;
      });
      showCustomSnackBar(context, result['message'] ?? 'Gagal mengirim distribusi');
      _scannerController.start();
    }
  }

  Future<void> _showSuccessDialog() async {
    await showSuccessBottomSheet(
      context,
      title: 'Distribusi Berhasil!',
      message: 'Distribusi sembako ke ${widget.namaBsu} berhasil dikirim.',
      buttonLabel: 'Selesai',
      onDismiss: () => Navigator.pop(context, widget.bsuId),
    );
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
              const TopBarBack(title: 'Scan Petugas BSU'),
              const SizedBox(height: 12),
              _buildInfoBsu(),
              const SizedBox(height: 12),
              _buildInstructionCard(),
              const SizedBox(height: 16),
              Expanded(child: _buildScannerArea()),
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
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF013236).withValues(alpha: 0.25),
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
              color: const Color(0xFF94DF0C).withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.local_shipping_rounded,
              color: Color(0xFF94DF0C),
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
                const Text(
                  'Distribusi sembako',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: Colors.white60,
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
        color: const Color(0xFF94DF0C).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF94DF0C).withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.qr_code_scanner_rounded,
              color: Color(0xFF94DF0C),
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Scan QR identitas petugas BSU untuk mengkonfirmasi penerimaan distribusi sembako.',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: Color(0xFF013236).withValues(alpha: 0.75),
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
            color: const Color(0xFF013236).withValues(alpha: 0.18),
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
      color: Colors.black.withValues(alpha: 0.65),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: const Color(0xFF94DF0C),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF94DF0C).withValues(alpha: 0.45),
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
              _isSubmitting ? 'Mengirim Distribusi...' : 'Memverifikasi Petugas...',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _isSubmitting ? 'Mohon tunggu sebentar' : 'Memproses identitas BSU',
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
}

// ─── Scan frame & painters ───────────────────────────────────────────────────

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
                color: Colors.white.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
          ),
          Positioned(
            top: 0, left: 0,
            child: _Bracket(len: bracketLen, thick: bracketThick,
                color: bracketColor, showTop: true, showLeft: true),
          ),
          Positioned(
            top: 0, right: 0,
            child: _Bracket(len: bracketLen, thick: bracketThick,
                color: bracketColor, showTop: true, showLeft: false),
          ),
          Positioned(
            bottom: 36, left: 0,
            child: _Bracket(len: bracketLen, thick: bracketThick,
                color: bracketColor, showTop: false, showLeft: true),
          ),
          Positioned(
            bottom: 36, right: 0,
            child: _Bracket(len: bracketLen, thick: bracketThick,
                color: bracketColor, showTop: false, showLeft: false),
          ),
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Center(
              child: Text(
                'Arahkan ke QR Code petugas BSU',
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
    required this.len,
    required this.thick,
    required this.color,
    required this.showTop,
    required this.showLeft,
  });

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size(len, len),
        painter: _BracketPainter(
            color: color, thick: thick, showTop: showTop, showLeft: showLeft),
      );
}

class _BracketPainter extends CustomPainter {
  final Color color;
  final double thick;
  final bool showTop, showLeft;

  _BracketPainter(
      {required this.color,
      required this.thick,
      required this.showTop,
      required this.showLeft});

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
