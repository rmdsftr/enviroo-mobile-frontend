import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/penarikan_petugas_provider.dart';
import 'detail_konfirmasi_penarikan_screen.dart';

class ScanPenarikanScreen extends StatefulWidget {
  const ScanPenarikanScreen({super.key});

  @override
  State<ScanPenarikanScreen> createState() => _ScanPenarikanScreenState();
}

class _ScanPenarikanScreenState extends State<ScanPenarikanScreen> {
  static const Color primary = Color(0xFF4EA771);
  static const Color dark = Color(0xFF013236);

  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );

  bool _processing = false;
  bool _torchOn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      context.read<PenarikanPetugasProvider>().bind(auth);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleDetected(String code) async {
    if (_processing) return;
    setState(() => _processing = true);
    HapticFeedback.mediumImpact();
    try {
      await _controller.stop();
    } catch (_) {}
    await _verifyAndOpen(code);
  }

  Future<void> _verifyAndOpen(String transaksiId) async {
    final prov = context.read<PenarikanPetugasProvider>();
    final ok = await prov.verifikasi(transaksiId);

    if (!mounted) return;

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent,
          content: Text(prov.error ?? 'Verifikasi gagal'),
        ),
      );
      setState(() => _processing = false);
      try {
        await _controller.start();
      } catch (_) {}
      return;
    }

    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            DetailKonfirmasiPenarikanScreen(transaksiId: transaksiId),
      ),
    );
  }

  Future<void> _showManualInput() async {
    final ctrl = TextEditingController();
    final id = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Input Manual',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Masukkan ID transaksi penarikan',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: 'RDMN-XXXXXX',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: primary, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            child: const Text('Verifikasi'),
          ),
        ],
      ),
    );
    if (id != null && id.isNotEmpty) {
      setState(() => _processing = true);
      try {
        await _controller.stop();
      } catch (_) {}
      await _verifyAndOpen(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              for (final b in capture.barcodes) {
                final raw = b.rawValue;
                if (raw != null && raw.isNotEmpty) {
                  _handleDetected(raw);
                  break;
                }
              }
            },
          ),
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: primary, width: 3),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 18),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () async {
                      try {
                        await _controller.toggleTorch();
                      } catch (_) {}
                      setState(() => _torchOn = !_torchOn);
                    },
                    icon: Icon(
                      _torchOn
                          ? Icons.flash_on_rounded
                          : Icons.flash_off_rounded,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 56,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Text(
                  'Arahkan kamera ke QR penarikan nasabah',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                  20, 18, 20, MediaQuery.of(context).padding.bottom + 18),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_processing)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: primary,
                              strokeWidth: 2.5,
                            ),
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Memverifikasi…',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              color: dark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  GestureDetector(
                    onTap: _processing ? null : _showManualInput,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(
                            color: primary.withOpacity(0.3), width: 1),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.keyboard_alt_rounded,
                              color: primary, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Input manual?',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              color: primary,
                            ),
                          ),
                        ],
                      ),
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
}
