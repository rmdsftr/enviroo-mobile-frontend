import 'package:enviroo/providers/auth_provider.dart';
import 'package:enviroo/widgets/topbar_back.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:enviroo/core/theme/app_colors.dart';
import 'package:enviroo/core/theme/app_text.dart';
class QRAngkutSampahScreen extends StatefulWidget {
  final String pengangkutanId;
  final List<Map<String, dynamic>> selectedItems;

  const QRAngkutSampahScreen({
    super.key,
    required this.pengangkutanId,
    this.selectedItems = const [],
  });

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
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final adminBsuId = auth.identityId ?? '';
    setState(() {
      _qrData = '{"type":"ENVIROO-ANGKUTBSU","admin_bsu_id":"$adminBsuId","pengangkutan_id":"${widget.pengangkutanId}"}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        child: SafeArea(
          child: Column(
            children: [
              TopBarBack(title: "Angkut Sampah"),

              const Spacer(),

              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.5),
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
                        Icons.qr_code_scanner_rounded,
                        color: AppColors.dark,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Tunjukkan QR code ini pada petugas BSI untuk konfirmasi pengangkutan sampah",
                        style: AppText.w500(13, Color(0xFF2D5A1D)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.dark.withValues(alpha: 0.15),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.8),
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.dark.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.local_shipping_rounded,
                                size: 14, color: AppColors.dark),
                            SizedBox(width: 6),
                            Text(
                              'BSU → BSI',
                              style: AppText.w600(11, AppColors.dark),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      QrImageView(
                        data: _qrData,
                        version: QrVersions.auto,
                        size: 270.0,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: AppColors.dark,
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: AppColors.dark,
                        ),
                      ),

                      if (widget.selectedItems.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLeaf,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${widget.selectedItems.length} jenis sampah diangkut',
                                style: AppText.w600(11, Color(0xFF2D5A1D)),
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
                                            color: AppColors.green,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            '${item['nama']}',
                                            style: AppText.r(11, AppColors.darkAlt),
                                          ),
                                        ),
                                        Text(
                                          '${item['jumlah']} ${item['satuan']}',
                                          style: AppText.w600(11, AppColors.green),
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

              Padding(
                padding: const EdgeInsets.only(bottom: 28),
                child: Text(
                  'Scan QR code ini menggunakan aplikasi petugas BSI',
                  textAlign: TextAlign.center,
                  style: AppText.r(12, AppColors.dark.withValues(alpha: 0.6)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
