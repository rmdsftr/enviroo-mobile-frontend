import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/network/network_status.dart';
import '../widgets/custom_snackbar.dart';
import 'package:enviroo/core/theme/app_colors.dart';
import 'package:enviroo/core/theme/app_text.dart';

class NoConnectionScreen extends StatefulWidget {
  const NoConnectionScreen({super.key});

  @override
  State<NoConnectionScreen> createState() => _NoConnectionScreenState();
}

class _NoConnectionScreenState extends State<NoConnectionScreen> {

  late final NetworkStatus _net = context.read<NetworkStatus>();
  bool _mencoba = false;

  Future<void> _cobaLagi() async {
    if (_mencoba) return;
    setState(() => _mencoba = true);

    final pulih = await _net.probeSekarang();
    if (!mounted) return;

    setState(() => _mencoba = false);

    if (!pulih) {
      showCustomSnackBar(
        context,
        'Masih belum tersambung',
        hideCurrent: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.wifi_off_rounded,
                  size: 56,
                  color: AppColors.dark.withValues(alpha: 0.35),
                ),
                const SizedBox(height: 20),
                Text(
                  'Koneksi internet terputus',
                  textAlign: TextAlign.center,
                  style: AppText.w600(15, AppColors.dark),
                ),
                const SizedBox(height: 8),
                Text(
                  'Periksa jaringan kamu. Halaman akan terbuka sendiri '
                  'begitu koneksi kembali.',
                  textAlign: TextAlign.center,
                  style: AppText.r(12.5, AppColors.dark.withValues(alpha: 0.5)),
                ),
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: _mencoba ? null : _cobaLagi,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                  child: _mencoba
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Coba Lagi',
                          style: AppText.r(13),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
