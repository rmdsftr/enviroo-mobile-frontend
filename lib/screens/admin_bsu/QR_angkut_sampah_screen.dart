import 'package:enviroo/providers/auth_provider.dart';
import 'package:enviroo/widgets/topbar_back.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:math';

class QRAngkutSampahScreen extends StatefulWidget {
  /// Daftar sampah yang dipilih untuk diangkut (opsional, ditampilkan sebagai
  /// preview saja). Sejak input pengangkutan dilakukan oleh Admin BSI, daftar
  /// item sudah tidak dikirim via QR — yang penting hanyalah identitas
  /// petugas BSU yang akan diambil oleh Admin BSI saat scan.
  final List<Map<String, dynamic>> selectedItems;

  const QRAngkutSampahScreen({super.key, this.selectedItems = const []});

  @override
  State<QRAngkutSampahScreen> createState() => _QRAngkutSampahScreenState();
}

class _QRAngkutSampahScreenState extends State<QRAngkutSampahScreen> {
  String _qrData = '';

  @override
  void initState() {
    super.initState();
    _generateQRCode();
  }

  void _generateQRCode() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(999999).toString().padLeft(6, '0');

    // Ambil identity_id (admin_id) petugas BSU dari sesi login.
    // Format QR: ENVIROO-ANGKUTBSU|{adminBsuId}|{timestamp}|{random}
    // Pemisah '|' digunakan agar tidak konflik dengan dash di dalam adminBsuId
    // (format ID: ADM-YYYYMMDDHHMMSS-RANDOM).
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final adminBsuId = auth.identityId ?? '';
    setState(() {
      _qrData = 'ENVIROO-ANGKUTBSU|$adminBsuId|$timestamp|$random';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xFFFFFFFF),
        ),
        child: SafeArea(
          child: Column(
            children: [
              TopBarBack(title: "Angkut Sampah"),

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
                        "Tunjukkan QR code ini pada petugas BSI untuk konfirmasi pengangkutan sampah",
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
                  child: Column(
                    children: [
                      // Label "Admin BSU → Admin BSI"
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF013236).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.local_shipping_rounded,
                                size: 14, color: Color(0xFF013236)),
                            SizedBox(width: 6),
                            Text(
                              'BSU → BSI',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF013236),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // QR Code
                      QrImageView(
                        data: _qrData,
                        version: QrVersions.auto,
                        size: 270.0,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: Color(0xFF013236),
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: Color(0xFF013236),
                        ),
                        embeddedImage: const AssetImage(
                            'assets/images/enviroo-logo-small.png'),
                        embeddedImageStyle: const QrEmbeddedImageStyle(
                          size: Size(50, 50),
                        ),
                      ),

                      // Selected items summary
                      if (widget.selectedItems.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2FAF0),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${widget.selectedItems.length} jenis sampah diangkut',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2D5A1D),
                                ),
                              ),
                              const SizedBox(height: 6),
                              ...widget.selectedItems.map((item) => Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 2),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 4,
                                          height: 4,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF4EA771),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            '${item['nama']}',
                                            style: const TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 11,
                                              color: Color(0xFF0D3B3E),
                                            ),
                                          ),
                                        ),
                                        Text(
                                          '${item['jumlah']} ${item['satuan']}',
                                          style: const TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF4EA771),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // Bottom hint
              Padding(
                padding: const EdgeInsets.only(bottom: 28),
                child: Text(
                  'Scan QR code ini menggunakan aplikasi petugas BSI',
                  textAlign: TextAlign.center,
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
