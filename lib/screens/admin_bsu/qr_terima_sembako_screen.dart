import 'package:enviroo/providers/auth_provider.dart';
import 'package:enviroo/widgets/topbar_back.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrTerimaSembakoScreen extends StatelessWidget {
  const QrTerimaSembakoScreen({super.key});

  static const Color _dark   = Color(0xFF013236);
  static const Color _accent = Color(0xFF4EA771);
  static const Color _teal   = Color(0xFF06C0C9);

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final identityId = auth.identityId ?? '';
    final namaUser   = auth.currentUser?.nama ?? auth.currentUser?.email ?? '';
    final qrData     = 'ENVIROO-BSU|$identityId';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const TopBarBack(title: 'QR Terima Distribusi'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Instruction
                    Text(
                      'Tunjukkan QR ini ke petugas BSI\nuntuk menerima distribusi sembako',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        height: 1.5,
                        color: _dark.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // QR card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: _accent.withValues(alpha: 0.3),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _accent.withValues(alpha: 0.12),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // QR image
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF4FBF4),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: QrImageView(
                              data: qrData,
                              version: QrVersions.auto,
                              size: 240,
                              backgroundColor: Colors.white,
                              errorCorrectionLevel: QrErrorCorrectLevel.H,
                              eyeStyle: const QrEyeStyle(
                                eyeShape: QrEyeShape.square,
                                color: _dark,
                              ),
                              dataModuleStyle: const QrDataModuleStyle(
                                dataModuleShape: QrDataModuleShape.square,
                                color: _dark,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Nama
                          if (namaUser.isNotEmpty) ...[
                            Text(
                              namaUser,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: _dark,
                              ),
                            ),
                            const SizedBox(height: 4),
                          ],

                          // ID label
                          Text(
                            'ID Petugas',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              color: _dark.withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(height: 4),
                          SelectableText(
                            identityId,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _dark.withValues(alpha: 0.7),
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Copy button
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _accent,
                              side: BorderSide(
                                  color: _accent.withValues(alpha: 0.4)),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(50)),
                            ),
                            onPressed: () async {
                              await Clipboard.setData(
                                  ClipboardData(text: identityId));
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    behavior: SnackBarBehavior.floating,
                                    backgroundColor: _dark,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    content: const Text(
                                      'ID Petugas disalin',
                                      style: TextStyle(fontFamily: 'Poppins'),
                                    ),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.copy_rounded, size: 16),
                            label: const Text(
                              'Salin ID',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Info box
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _teal.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: _teal.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.qr_code_scanner_rounded,
                              color: _teal.withValues(alpha: 0.8), size: 20),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Petugas BSI akan memindai QR ini pada langkah konfirmasi distribusi sembako.',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                height: 1.5,
                                color: _dark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
