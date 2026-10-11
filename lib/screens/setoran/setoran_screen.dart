import 'dart:async';

import 'package:enviroo/core/messaging/fcm_messaging.dart';
import 'package:enviroo/core/messaging/notif_payload.dart';
import 'package:enviroo/providers/auth_provider.dart';
import 'package:enviroo/screens/setoran/detail_setoran_screen.dart';
import 'package:enviroo/widgets/success_bottom_sheet.dart';
import 'package:enviroo/widgets/topbar_back.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:enviroo/core/theme/app_colors.dart';
import 'package:enviroo/core/theme/app_text.dart';

class SetoranScreen extends StatefulWidget {
  final String penimbanganId;
  const SetoranScreen({super.key, required this.penimbanganId});

  @override
  State<SetoranScreen> createState() => _SetoranScreenState();
}

class _SetoranScreenState extends State<SetoranScreen> {
  String _qrData = '';
  StreamSubscription<NotifPayload>? _notifSub;
  bool _sudahDiproses = false;

  @override
  void initState() {
    super.initState();
    _generateQRCode();
    _notifSub = context.read<FcmMessaging>().foregroundPayloads.listen(_onNotif);
  }

  @override
  void dispose() {
    _notifSub?.cancel();
    super.dispose();
  }

  Future<void> _onNotif(NotifPayload payload) async {
    if (payload.refType != 'setoran' || _sudahDiproses || !mounted) return;
    _sudahDiproses = true;

    await showSuccessBottomSheet(
      context,
      title: 'Setoran Sampah Berhasil',
      message: 'Sampahmu sudah ditimbang petugas dan tercatat di buku tabungan sampah.',
      buttonLabel: 'Lihat Struk Setoran',
    );
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => DetailSetoranScreen(setoranId: payload.refId),
      ),
    );
  }

  void _generateQRCode() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final nasabahId = auth.identityId ?? '';
    setState(() {
      _qrData = '{"type":"ENVIROO-SETORAN","nasabah_id":"$nasabahId","penimbangan_id":"${widget.penimbanganId}"}';
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
              TopBarBack(title: "QR Penyetoran"),
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
                        "Tunjukkan QR code ini pada petugas bank sampah untuk konfirmasi setoran",
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
                  child: QrImageView(
                    data: _qrData,
                    version: QrVersions.auto,
                    size: 280.0,
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
              ),

              const Spacer(),

              Padding(
                padding: const EdgeInsets.only(bottom: 28, left: 25, right: 25),
                child: Text(
                  'Scan QR code ini menggunakan aplikasi petugas Bank Sampah',
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
