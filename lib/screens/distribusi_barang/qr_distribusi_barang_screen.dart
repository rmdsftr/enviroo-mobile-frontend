import 'package:enviroo/widgets/topbar_back.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:enviroo/core/theme/app_colors.dart';
import 'package:enviroo/core/theme/app_text.dart';


class QrDistribusiBarangScreen extends StatelessWidget {
  final String disbaId;
  final String namaBsu;
  final String bsuId;

  const QrDistribusiBarangScreen({
    super.key,
    required this.disbaId,
    required this.namaBsu,
    required this.bsuId,
  });

  @override
  Widget build(BuildContext context) {
    final qrData = 'ENVIROO-DISTRIBUSI|$disbaId';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const TopBarBack(title: 'QR Distribusi Barang'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Tunjukkan QR ini ke petugas BSU\nuntuk mengkonfirmasi penerimaan',
                      textAlign: TextAlign.center,
                      style: AppText.p(13, color: AppColors.dark.withValues(alpha: 0.6), height: 1.5),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: AppColors.green.withValues(alpha: 0.3)),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.green.withValues(alpha: 0.12),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
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
                                color: AppColors.dark,
                              ),
                              dataModuleStyle: const QrDataModuleStyle(
                                dataModuleShape: QrDataModuleShape.square,
                                color: AppColors.dark,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            namaBsu,
                            textAlign: TextAlign.center,
                            style: AppText.w700(15, AppColors.dark),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'ID Distribusi',
                            style: AppText.r(11, AppColors.dark.withValues(alpha: 0.5)),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            disbaId,
                            textAlign: TextAlign.center,
                            style: AppText.p(11, weight: FontWeight.w600, color: AppColors.dark.withValues(alpha: 0.6), letterSpacing: 0.5),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.cyan.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.cyan.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.qr_code_scanner_rounded,
                              color: AppColors.cyan.withValues(alpha: 0.8), size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'QR ini unik per transaksi. Petugas BSU akan memindai QR ini untuk mengkonfirmasi penerimaan distribusi barang.',
                              style: AppText.p(12, color: AppColors.dark, height: 1.5),
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
