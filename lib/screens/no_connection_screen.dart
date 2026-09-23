import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/network/network_status.dart';
import '../widgets/custom_snackbar.dart';

/// Layar penuh saat koneksi internet terputus.
///
/// Di-push otomatis dari `_EnvirooAppState` begitu [NetworkStatus.offline]
/// menyala, dan ditutup otomatis begitu padam — lihat `main.dart`.
///
/// Probe pemulihannya TIDAK diurus di sini — siklus hidupnya melekat pada
/// status offline di [NetworkStatus]. Kalau diikat ke layar ini, user yang
/// menutupnya lewat tombol back akan mematikan probe sementara statusnya masih
/// offline, dan pemulihan jaringan tidak pernah terdeteksi.
///
/// Sengaja TANPA `TopBarBack` — layar ini bukan tujuan navigasi biasa, dia
/// nyelak. Keluarnya lewat tombol "Coba Lagi" atau lewat jaringan yang pulih.
///
/// Tampilannya sengaja polos; penataan visualnya menyusul.
class NoConnectionScreen extends StatefulWidget {
  const NoConnectionScreen({super.key});

  @override
  State<NoConnectionScreen> createState() => _NoConnectionScreenState();
}

class _NoConnectionScreenState extends State<NoConnectionScreen> {
  static const _dark = Color(0xFF013236);
  static const _green = Color(0xFF4EA771);

  late final NetworkStatus _net = context.read<NetworkStatus>();
  bool _mencoba = false;

  /// Sekali coba, supaya user tidak perlu menunggu tick probe berikutnya.
  Future<void> _cobaLagi() async {
    if (_mencoba) return;
    setState(() => _mencoba = true);

    final pulih = await _net.probeSekarang();
    if (!mounted) return;

    setState(() => _mencoba = false);

    // Kalau pulih, layar ini sudah ditutup oleh listener di main.dart —
    // tidak perlu pop sendiri. Kalau belum, tetap di sini dan beri tahu;
    // menutup lalu memunculkannya lagi kelihatan seperti bug.
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
                  color: _dark.withValues(alpha: 0.35),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Koneksi internet terputus',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _dark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Periksa jaringan kamu. Halaman akan terbuka sendiri '
                  'begitu koneksi kembali.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12.5,
                    color: _dark.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: _mencoba ? null : _cobaLagi,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
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
                      : const Text(
                          'Coba Lagi',
                          style: TextStyle(
                              fontFamily: 'Poppins', fontSize: 13),
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
