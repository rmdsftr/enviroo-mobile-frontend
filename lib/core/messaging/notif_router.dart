import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/pengangkutan_provider.dart';
import '../../screens/bagi_hasil/struk_bagi_hasil_bsu_screen.dart';
import '../../screens/bagi_hasil/struk_bagi_hasil_nasabah.dart';
import '../../screens/katalog/katalog_barang_screen.dart';
import '../../screens/penarikan/detail_penarikan_screen.dart';
import '../../screens/penarikan/detail_transaksi_penarikan_screen.dart';
import '../../screens/pengangkutan/detail_pengangkutan_screen.dart';
import '../../screens/pengangkutan/pengangkutan_bsi_screen.dart';
import '../../screens/penimbangan/list_setoran_sesi_screen.dart';
import '../../screens/setoran/detail_setoran_screen.dart';

/// Satu-satunya tabel `ref_type` → screen tujuan.
///
/// Sebelumnya tabel ini ada di dua tempat: switch di NotifikasiScreen (tap dari
/// dalam app) dan `_routeDeepLink` di main.dart (tap dari system tray). Yang
/// kedua cuma mengenal satu ref_type, jadi notifikasi lain tidak pernah sampai
/// ke tujuannya. Semua jalur masuk sekarang lewat sini:
///
/// 1. [NotifikasiScreen] — user tap kartu notifikasi di dalam app;
/// 2. `main.dart` — push di-tap dari system tray saat app di background;
/// 3. [SplashScreen] — app cold-start dari notifikasi, payload-nya ditahan
///    [FcmMessaging] sampai tree siap.
class NotifRouter {
  const NotifRouter._();

  /// Builder screen tujuan, atau null kalau [refType] memang tidak punya
  /// tujuan untuk [role] ini.
  ///
  /// Sengaja satu fungsi supaya [hasDestination] dan [open] tidak bisa lagi
  /// berbeda pendapat — dulu affordance "Lihat detail" muncul untuk kombinasi
  /// yang sebenarnya tidak menavigasi ke mana-mana.
  static WidgetBuilder? _destination(String refType, String refId, String role) {
    switch (refType) {
      // Cuma ditandai dibaca, tidak navigasi ke screen lain.
      case 'jadwal_pengangkutan':
        return null;

      case 'jadwal_penimbangan':
        return (_) => ListSetoranSesiScreen(
              penimbanganId: refId,
              tanggalPenimbangan: '',
            );

      case 'setoran':
        return (_) => DetailSetoranScreen(setoranId: refId);

      case 'pengangkutan':
        return (_) => DetailPengangkutanScreen(pengangkutanId: refId);

      case 'pengajuan_pengangkutan':
        return (_) => const PengangkutanBsiScreen(
              initialTab: 1,
              initialFilter: 'requested',
            );

      case 'distribusi_barang':
        return (_) => const KatalogBarangScreen();

      case 'penarikan':
        return role == 'nasabah'
            ? (_) => DetailPenarikanScreen(penarikanId: refId)
            : (_) => DetailTransaksiPenarikanScreen(penarikanId: refId);

      case 'bagi_hasil':
        if (role == 'nasabah') {
          return (_) => StrukBagiHasilNasabah(penerimaId: refId);
        }
        if (role == 'petugas_bsu') {
          return (_) => StrukBagiHasilBsuScreen(penerimaSisaId: refId);
        }
        // Role lain (mis. petugas_bsm) tidak punya layar struk bagi hasil.
        return null;

      default:
        return null;
    }
  }

  /// Apakah notifikasi ini punya tujuan yang bisa dibuka.
  ///
  /// Dipakai NotifikasiScreen untuk memutuskan apakah affordance "Lihat detail"
  /// ditampilkan. Role-aware, jadi hasilnya selalu sinkron dengan [open].
  static bool hasDestination({
    String? refType,
    String? refId,
    required String role,
  }) {
    if (refType == null || refId == null) return false;
    return _destination(refType, refId, role) != null;
  }

  /// Buka screen tujuan notifikasi.
  ///
  /// [navigator] dikirim pemanggil supaya router ini tidak perlu pegang state
  /// global sendiri. SplashScreen mengambilnya sebelum `pushAndRemoveUntil`,
  /// karena NavigatorState tetap hidup walau context SplashScreen sudah mati.
  ///
  /// Mengembalikan false bila ref_type tidak punya tujuan untuk role user ini.
  static bool open(
    NavigatorState navigator, {
    required String refType,
    required String refId,
  }) {
    // Context milik Navigator sendiri: posisinya di bawah MultiProvider, jadi
    // aman buat context.read. Push-nya lewat navigator langsung, bukan
    // Navigator.of(context) — lookup ancestor mulai dari parent, jadi tidak
    // akan menemukan Navigator-nya sendiri.
    final context = navigator.context;

    final role = context.read<AuthProvider>().role;
    final builder = _destination(refType, refId, role);
    if (builder == null) return false;

    // Layar tujuannya berupa list, bukan detail — id-nya tidak bisa dititipkan
    // lewat konstruktor, jadi dititipkan ke provider supaya baris yang dimaksud
    // bisa disorot setelah datanya selesai dimuat.
    if (refType == 'pengajuan_pengangkutan') {
      context.read<PengangkutanProvider>().setHighlight(refId);
    }

    navigator.push(MaterialPageRoute(builder: builder));
    return true;
  }
}
