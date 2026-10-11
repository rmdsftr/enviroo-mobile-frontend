import 'dart:convert';
import 'package:enviroo/models/nasabah_model.dart';
import 'package:enviroo/providers/auth_provider.dart';
import 'package:enviroo/screens/setoran/input_setoran_screen.dart';
import 'package:enviroo/providers/nasabah_provider.dart';
import 'package:enviroo/providers/setoran_provider.dart';
import 'package:enviroo/widgets/search.dart';
import 'package:enviroo/widgets/topbar_back.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:enviroo/core/theme/app_colors.dart';
import 'package:enviroo/core/theme/app_text.dart';

class ScannerPenimbanganScreen extends StatefulWidget {
  final String penimbanganId;

  const ScannerPenimbanganScreen({super.key, required this.penimbanganId});

  @override
  State<ScannerPenimbanganScreen> createState() => _ScannerPenimbanganState();
}

class _ScannerPenimbanganState extends State<ScannerPenimbanganScreen>
    with SingleTickerProviderStateMixin {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isProcessing = false;
  bool _isError = false;
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

  Future<void> _verifikasiNasabah(String qrData, bool dariQr, {String? nasabahName}) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final adminId = auth.identityId ?? '';

    final res = await context
        .read<SetoranProvider>()
        .verifikasiSetoran(qrData, adminId);

    if (!mounted) return;

    if (res['success'] == true && res['status'] == 'verified') {
      final data = res['data'] ?? {};
      _navigateToSetoran(
        nasabahId: data['nasabah_id']?.toString() ?? '',
        nasabahName: data['nama_nasabah']?.toString() ?? nasabahName ?? 'Nasabah via QR',
        photoUrl: data['photo_url']?.toString() ?? '',
        dariQr: dariQr,
      );
    } else {
      setState(() {
        _isError = true;
        _errorMessage = res['message'] ?? 'Akses ditolak';
      });
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) Navigator.pop(context);
    }
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    final String rawValue = barcode.rawValue!;

    try {
      final decoded = jsonDecode(rawValue) as Map<String, dynamic>;
      if (decoded['type'] != 'ENVIROO-SETORAN') return;
    } catch (_) {
      return;
    }

    setState(() => _isProcessing = true);
    _scannerController.stop();
    HapticFeedback.mediumImpact();

    await _verifikasiNasabah(rawValue, true);
  }

  void _navigateToSetoran({
    required String nasabahId,
    required String nasabahName,
    required String photoUrl,
    required bool dariQr,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InputSetoranScreen(
          penimbanganId: widget.penimbanganId,
          nasabahId: nasabahId,
          nasabahName: nasabahName,
          photoUrl: photoUrl,
          dariQr: dariQr,
        ),
      ),
    ).then((_) {
      setState(() => _isProcessing = false);
      _scannerController.start();
    });
  }

  void _showManualPickerDialog() {
    _scannerController.stop();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ManualPickerSheet(
        onSelected: (nasabah) async {
          Navigator.pop(ctx);
          setState(() => _isProcessing = true);
          final qrData = '{"type":"ENVIROO-SETORAN","nasabah_id":"${nasabah.nasabahId}","penimbangan_id":"${widget.penimbanganId}"}';
          await _verifikasiNasabah(qrData, false, nasabahName: nasabah.user.nama);
        },
      ),
    ).then((_) {
      if (mounted && !_isProcessing) _scannerController.start();
    });
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
              TopBarBack(title: "Penimbangan"),
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
              color: AppColors.dark.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.verified_user_rounded,
              color: AppColors.dark,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "Scan QR code nasabah untuk verifikasi identitas dan memulai penginputan setoran sampah",
              style: AppText.w500(12, Color(0xFF2D5A1D)),
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
            color: AppColors.dark.withValues(alpha: 0.18),
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

            if (_isProcessing) _isError ? _buildErrorOverlay() : _buildSuccessOverlay(),
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
                color: AppColors.green,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.green.withValues(alpha: 0.45),
                    blurRadius: 28,
                    spreadRadius: 6,
                  ),
                ],
              ),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 38),
            ),
            const SizedBox(height: 18),
            Text(
              'Nasabah Terverifikasi',
              style: AppText.w700(16, Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              'Membuka halaman setoran...',
              style: AppText.r(12, Colors.white.withValues(alpha: 0.7)),
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
                color: AppColors.dangerAlt,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.dangerAlt.withValues(alpha: 0.45),
                    blurRadius: 28,
                    spreadRadius: 6,
                  ),
                ],
              ),
              child: const Icon(Icons.close_rounded, color: Colors.white, size: 38),
            ),
            const SizedBox(height: 18),
            Text(
              'Akses Ditolak',
              style: AppText.w700(16, Colors.white),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: AppText.r(12, Colors.white.withValues(alpha: 0.75)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManualButton() {
    return GestureDetector(
      onTap: _showManualPickerDialog,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.dark.withValues(alpha: 0.1),
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
                Icons.person_search_rounded,
                color: AppColors.green,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'QR tidak bekerja? Pilih nasabah manual',
                style: AppText.w600(13, AppColors.dark),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 13,
              color: AppColors.green,
            ),
          ],
        ),
      ),
    );
  }
}


class _ScanFrame extends StatelessWidget {
  const _ScanFrame();

  @override
  Widget build(BuildContext context) {
    const double size = 230;
    const double bracketLen = 30;
    const double bracketThick = 3.5;
    const Color bracketColor = AppColors.green;

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
                style: AppText.w500(11, Colors.white.withValues(alpha: 0.75)),
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

class _ManualPickerSheet extends StatefulWidget {
  final Function(NasabahModel) onSelected;

  const _ManualPickerSheet({required this.onSelected});

  @override
  State<_ManualPickerSheet> createState() => _ManualPickerSheetState();
}

class _ManualPickerSheetState extends State<_ManualPickerSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  List<NasabahModel> _nasabahList = [];
  bool _isLoading = true;

  List<NasabahModel> get _filtered => _nasabahList
      .where((n) {
        final isActive = n.statusNasabah.toLowerCase() == 'aktif';
        final matchesQuery =
            n.user.nama.toLowerCase().contains(_query.toLowerCase()) ||
            n.nasabahId.toLowerCase().contains(_query.toLowerCase()) ||
            n.nomorRekening.toLowerCase().contains(_query.toLowerCase());
        return isActive && matchesQuery;
      })
      .toList();

  @override
  void initState() {
    super.initState();
    _fetchNasabah();
  }

  Future<void> _fetchNasabah() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final bankId = auth.bankId ?? '';
    final prov = context.read<NasabahProvider>();
    await prov.fetchNasabahsByBankId(bankId);
    if (!mounted) return;
    setState(() {
      if (prov.error.isEmpty) _nasabahList = prov.nasabahs;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.dark.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 10, 20, 0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pilih Nasabah',
                        style: AppText.w700(15, AppColors.dark),
                      ),
                      Text(
                        'Pilih nasabah untuk memulai setoran',
                        style: AppText.r(11, AppColors.dark.withValues(alpha: 0.5)),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F2F2),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: const Icon(Icons.close_rounded, size: 16, color: AppColors.dark),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
            child: CustomSearchBar(
              controller: _searchCtrl,
              hintText: 'Cari nama, ID, atau no rekening...',
              searchQuery: _query,
              onChanged: (v) => setState(() => _query = v),
              onClear: () {
                _searchCtrl.clear();
                setState(() => _query = '');
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.green))
                : _buildNasabahList(),
          ),
          SizedBox(height: bottomPad + 8),
        ],
      ),
    );
  }

  Widget _buildNasabahList() {
    final list = _filtered;

    if (list.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.manage_search_rounded,
            size: 36,
            color: AppColors.dark.withValues(alpha: 0.25),
          ),
          const SizedBox(height: 12),
          Text(
            'Nasabah tidak ditemukan',
            style: AppText.w500(12, AppColors.dark.withValues(alpha: 0.5)),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (ctx, i) => _NasabahTile(
        nasabah: list[i],
        onTap: () => widget.onSelected(list[i]),
      ),
    );
  }
}

class _NasabahTile extends StatelessWidget {
  final NasabahModel nasabah;
  final VoidCallback onTap;

  const _NasabahTile({required this.nasabah, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FEFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                color: Colors.white,
              ),
              clipBehavior: Clip.antiAlias,
              child: nasabah.user.photoUrl.isNotEmpty
                  ? Image.network(
                nasabah.user.photoUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildInitial(),
                loadingBuilder: (_, child, progress) => progress == null
                    ? child
                    : const Center(
                  child: SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(AppColors.green),
                    ),
                  ),
                ),
              )
                  : _buildInitial(),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nasabah.user.nama,
                    style: AppText.w600(13, AppColors.dark),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.dark.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          nasabah.nasabahId,
                          style: AppText.w600(10, AppColors.dark.withValues(alpha: 0.6)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitial() {
    final String initial = nasabah.user.nama.isNotEmpty ? nasabah.user.nama[0].toUpperCase() : '?';
    return Container(
      color: AppColors.green.withValues(alpha: 0.15),
      child: Center(
        child: Text(
          initial,
          style: AppText.w700(22, AppColors.green),
        ),
      ),
    );
  }
}
