import 'dart:io';

import 'package:enviroo/core/messaging/fcm_messaging.dart';
import 'package:enviroo/core/messaging/notif_payload.dart';
import 'package:enviroo/core/network/http_overrides.dart';
import 'package:enviroo/core/theme/app_theme.dart';
import 'package:enviroo/providers/auth_provider.dart';
import 'package:enviroo/providers/katalog_provider.dart';
import 'package:enviroo/providers/sembako_provider.dart';
import 'package:enviroo/providers/konten_provider.dart';
import 'package:enviroo/providers/nasabah_provider.dart';
import 'package:enviroo/providers/jadwal_provider.dart';
import 'package:enviroo/providers/dashboard_provider.dart';
import 'package:enviroo/providers/penjualan_provider.dart';
import 'package:enviroo/providers/penarikan_petugas_provider.dart';
import 'package:enviroo/providers/penarikan_nasabah_provider.dart';
import 'package:enviroo/providers/bagi_hasil_provider.dart';
import 'package:enviroo/providers/bagi_hasil_bank_provider.dart';
import 'package:enviroo/providers/distribusi_sisa_provider.dart';
import 'package:enviroo/providers/mutasi_provider.dart';
import 'package:enviroo/providers/pengangkutan_provider.dart';
import 'package:enviroo/providers/notifikasi_provider.dart';
import 'package:enviroo/screens/splash_screen.dart';
import 'package:enviroo/screens/admin_bsi/pengangkutan_bsi_screen.dart';
import 'package:enviroo/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Dipasang sebelum apa pun mengirim request agar seluruh jalur jaringan
  // memakai allowlist sertifikat yang sama.
  HttpOverrides.global = EnvirooHttpOverrides();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await initializeDateFormatting('id_ID', null);
  runApp(const EnvirooApp());
}

class EnvirooApp extends StatefulWidget {
  const EnvirooApp({super.key});

  @override
  State<EnvirooApp> createState() => _EnvirooAppState();
}

final _navigatorKey = GlobalKey<NavigatorState>();

class _EnvirooAppState extends State<EnvirooApp> with WidgetsBindingObserver {
  // Dibuat di sini agar bisa diakses langsung dari FCM/lifecycle callbacks
  // tanpa perlu BuildContext — menghindari race condition saat akses provider
  // dari luar widget tree.
  final _auth = AuthProvider();
  final _notif = NotifikasiProvider();
  final _pengangkutan = PengangkutanProvider();

  late final FcmMessaging _fcm = FcmMessaging(
    auth: _auth,
    notif: _notif,
    onDeepLink: _routeDeepLink,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Saat akun dinonaktifkan (403 ACCOUNT_INACTIVE): logout sudah dilakukan
    // oleh AuthProvider; di sini cukup pop semua route ke SplashScreen.
    _auth.setForceLogoutCallback(() {
      _navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => SplashScreen()),
        (_) => false,
      );
    });

    _fcm.start();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _fcm.dispose();
    super.dispose();
  }

  // App kembali ke foreground — proactive refresh token, FCM, notifikasi.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _fcm.onAppResumed();
  }

  /// Menentukan aksi untuk payload deep-link yang sudah didekode FcmMessaging.
  ///
  /// Sengaja tinggal di sini, bukan di `core/messaging/`, supaya `core/` tidak
  /// perlu mengimpor screen — pemisahan "decode" (core) dari "act" (app).
  void _routeDeepLink(NotifPayload payload, {required bool navigate}) {
    if (payload.refType != 'pengajuan_pengangkutan') return;

    _pengangkutan.setHighlight(payload.refId);

    if (!navigate) return;
    _navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => const PengangkutanBsiScreen(
          initialTab: 1,
          initialFilter: 'requested',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Auth & notifikasi pakai .value karena instance dibuat di initState
        ChangeNotifierProvider.value(value: _auth),
        ChangeNotifierProvider.value(value: _notif),
        // Provider biasa, bukan ChangeNotifier — FcmMessaging tidak menyimpan
        // state yang perlu diobservasi UI.
        Provider<FcmMessaging>.value(value: _fcm),
        ChangeNotifierProvider(create: (_) => KatalogProvider()),
        ChangeNotifierProvider(create: (_) => KontenProvider()),
        ChangeNotifierProvider(create: (_) => NasabahProvider()),
        ChangeNotifierProvider(create: (_) => JadwalProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => PenjualanProvider()),
        ChangeNotifierProvider(create: (_) => PenarikanPetugasProvider()),
        ChangeNotifierProvider(create: (_) => PenarikanNasabahProvider()),
        ChangeNotifierProvider(create: (_) => BagiHasilProvider()),
        ChangeNotifierProvider(create: (_) => BagiHasilBankProvider()),
        ChangeNotifierProvider(create: (_) => SembakoProvider()),
        ChangeNotifierProvider(create: (_) => MutasiProvider()),
        ChangeNotifierProvider(create: (_) => DistribusiSisaProvider()),
        ChangeNotifierProvider.value(value: _pengangkutan),
      ],
      child: MaterialApp(
        navigatorKey: _navigatorKey,
        debugShowCheckedModeBanner: false,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: MediaQuery.of(context).textScaler.clamp(maxScaleFactor: 1.0),
          ),
          child: child!,
        ),
        theme: AppTheme.light,
        home: SplashScreen(),
      ),
    );
  }
}
