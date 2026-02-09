import 'package:enviroo/widgets/topbar_back.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:async';
import 'dart:math';

class SetoranScreen extends StatefulWidget {
  @override
  State<SetoranScreen> createState() => _SetoranScreenState();
}

class _SetoranScreenState extends State<SetoranScreen> {
  int _remainingSeconds = 60;
  Timer? _timer;
  String _qrData = '';

  @override
  void initState() {
    super.initState();
    _generateQRCode();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _generateQRCode() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(999999).toString().padLeft(6, '0');
    _qrData = 'ENVIROO-SETORAN-$timestamp-$random';
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _remainingSeconds = 60;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _timer?.cancel();
        }
      });
    });
  }

  void _regenerateQRCode() {
    _generateQRCode();
    _startTimer();
  }

  String _formatTime(int seconds) {
    int mins = seconds ~/ 60;
    int secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final bool isExpired = _remainingSeconds <= 0;
    final double progress = _remainingSeconds / 60;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xFFC1E6BA),
        ),
        child: SafeArea(
          child: Column(
            children: [
              TopBarBack(title: "Setoran"),

              const Spacer(),

              // Instruction Text
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF013236).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.qr_code_scanner_rounded,
                        color: Color(0xFF013236),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        "Tunjukkan QR code ini pada petugas BSU untuk konfirmasi setoran",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF2D5A1D),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // QR Code Card
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF013236).withOpacity(0.15),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                    BoxShadow(
                      color: Colors.white.withOpacity(0.8),
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: isExpired
                      ? Container(
                          width: 310,
                          height: 310,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color:
                                      const Color(0xFF013236).withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.timer_off_rounded,
                                  size: 40,
                                  color:
                                      const Color(0xFF013236).withOpacity(0.6),
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'QR Code Kadaluarsa',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF013236),
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tekan tombol di bawah untuk memperbarui',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 11,
                                  color:
                                      const Color(0xFF013236).withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        )
                      : QrImageView(
                          data: _qrData,
                          version: QrVersions.auto,
                          size: 310.0,
                          eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: Color(0xFF013236),
                          ),
                          dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: Color(0xFF013236),
                          ),
                          embeddedImage:
                              const AssetImage('assets/images/logo-enviroo.png'),
                          embeddedImageStyle: const QrEmbeddedImageStyle(
                            size: Size(50, 50),
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 32),

              // Timer OR Refresh Button (mutually exclusive)
              if (!isExpired)
                // Circular Timer
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF013236).withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Progress ring
                      SizedBox(
                        width: 85,
                        height: 85,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 6,
                          backgroundColor:
                              const Color(0xFF013236).withOpacity(0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            progress > 0.3
                                ? const Color(0xFF013236)
                                : const Color(0xFFE57373),
                          ),
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      // Time text (just numbers)
                      Text(
                        _formatTime(_remainingSeconds),
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                          color: progress > 0.3
                              ? const Color(0xFF013236)
                              : const Color(0xFFE57373),
                        ),
                      ),
                    ],
                  ),
                )
              else
                // Refresh Button
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2D5A1D), Color(0xFF013236)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF013236).withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _regenerateQRCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.refresh_rounded, size: 22),
                        SizedBox(width: 10),
                        Text(
                          'Perbarui QR Code',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const Spacer(),

              // Bottom hint
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Text(
                  'QR code berlaku selama 60 detik',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: const Color(0xFF013236).withOpacity(0.6),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
