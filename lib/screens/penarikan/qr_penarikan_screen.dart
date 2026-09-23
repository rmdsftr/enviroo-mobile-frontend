import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../widgets/topbar_back.dart';

class QrPenarikanScreen extends StatefulWidget {
  final String transaksiId;
  final String nasabahId;
  final DateTime deadline;

  const QrPenarikanScreen({
    super.key,
    required this.transaksiId,
    required this.nasabahId,
    required this.deadline,
  });

  @override
  State<QrPenarikanScreen> createState() => _QrPenarikanScreenState();
}

class _QrPenarikanScreenState extends State<QrPenarikanScreen> {
  static const Color primary = Color(0xFF4EA771);
  static const Color dark = Color(0xFF013236);

  Timer? _ticker;
  late Duration _remaining;
  late final String _qrData;

  @override
  void initState() {
    super.initState();
    _qrData = '{"type":"ENVIROO-PENARIKAN",'
        '"nasabah_id":"${widget.nasabahId}",'
        '"penarikan_id":"${widget.transaksiId}"}';
    _remaining = widget.deadline.difference(DateTime.now());
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _remaining = widget.deadline.difference(DateTime.now()));
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  /// >= 1 hari -> "2 hari 5 jam" (kasar, gak perlu real-time sampai detik).
  /// Kurang dari 1 hari -> "05:23:41" (hh:mm:ss, ngitung mundur real-time).
  String _formatCountdown(Duration d) {
    if (d.inDays >= 1) {
      final hours = d.inHours % 24;
      return '${d.inDays} hari $hours jam';
    }
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final expired = _remaining.isNegative;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const TopBarBack(title: 'QR Penarikan'),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── Instruksi ─────────────────────────────────
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0x1B4EA771),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: primary.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline_rounded,
                                color: primary, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Tunjukkan QR code berikut kepada petugas bank sampah pada saat '
                                'pengambilan insentif. Petugas akan memindai QR code sebagai '
                                'penyelesaian proses penarikan',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  color: Colors.black.withValues(alpha: 0.7),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // ── QR code ───────────────────────────────────
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: primary.withValues(alpha: 0.3),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: primary.withValues(alpha: 0.12),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: QrImageView(
                          data: _qrData,
                          version: QrVersions.auto,
                          size: 275,
                          backgroundColor: Colors.white,
                          errorCorrectionLevel: QrErrorCorrectLevel.H,
                          eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: dark,
                          ),
                          dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: dark,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // ── Countdown ─────────────────────────────────
                      expired
                          ? const Text(
                              'Kode sudah kadaluarsa',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFEF4444),
                              ),
                            )
                          : RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Kode akan kadaluarsa dalam ',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.black.withValues(alpha: 0.6),
                                    ),
                                  ),
                                  TextSpan(
                                    text: _formatCountdown(_remaining),
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
}
