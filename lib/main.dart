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
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'dart:io';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await initializeDateFormatting('id_ID', null);
  HttpOverrides.global = MyHttpOverrides();
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

    // Token refresh — kirim token baru ke backend kapanpun Firebase merotasinya.
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      _sendFcmToken(explicitToken: newToken);
    });

    // Foreground: notifikasi masuk saat app aktif di layar.
    FirebaseMessaging.onMessage.listen((msg) {
      debugPrint('[FCM] onMessage received: ${msg.notification?.title}');
      _refreshNotifikasi();
    });

    // Background → foreground: user tap notifikasi dari system tray.
    FirebaseMessaging.onMessageOpenedApp.listen((msg) {
      debugPrint('[FCM] onMessageOpenedApp: ${msg.notification?.title}');
      _refreshNotifikasi();
      _handleNotifDeepLink(msg, navigate: true);
    });

    // Terminated → foreground: app dibuka dari notifikasi (cold start).
    // Navigasi tidak dilakukan karena tree belum siap; highlight dikonsumsi
    // saat user membuka PengangkutanBsiScreen secara manual.
    FirebaseMessaging.instance.getInitialMessage().then((msg) {
      if (msg != null) {
        debugPrint('[FCM] getInitialMessage: ${msg.notification?.title}');
        _refreshNotifikasi();
        _handleNotifDeepLink(msg, navigate: false);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // App kembali ke foreground — proactive refresh token, FCM, notifikasi.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _auth.isLoggedIn) {
      // Refresh proaktif: pastikan token masih valid sebelum user melakukan
      // aksi apapun, terutama setelah idle > 10 menit di background.
      _auth.refreshToken();
      _sendFcmToken();
      _refreshNotifikasi();
    }
  }

  void _refreshNotifikasi({int retryCount = 0}) {
    if (!_auth.isLoggedIn) {
      debugPrint('[Notif] _refreshNotifikasi: user belum login, skip.');
      return;
    }
    final token = _auth.currentUser?.accessToken ?? '';
    if (token.isEmpty) {
      // Token belum ter-restore dari secure storage — coba lagi setelah 500ms
      if (retryCount < 3) {
        debugPrint('[Notif] _refreshNotifikasi: token kosong, retry ke-${retryCount + 1}...');
        Future.delayed(const Duration(milliseconds: 500), () {
          _refreshNotifikasi(retryCount: retryCount + 1);
        });
      } else {
        debugPrint('[Notif] _refreshNotifikasi: token tetap kosong setelah 3x retry, abort.');
      }
      return;
    }
    debugPrint('[Notif] _refreshNotifikasi: fetching untuk userId=${_auth.userId}');
    _notif.fetchNotifikasi(
      userId: _auth.userId,
    );
  }

  void _handleNotifDeepLink(dynamic msg, {required bool navigate}) {
    final data = msg.data as Map<String, dynamic>? ?? {};
    final refType = data['ref_type'] as String?;
    final refId   = data['ref_id']   as String?;
    if (refType != 'pengajuan_pengangkutan' || refId == null || refId.isEmpty) return;

    _pengangkutan.setHighlight(refId);

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

  Future<void> _sendFcmToken({String? explicitToken}) async {
    if (!_auth.isLoggedIn) return;
    final fcmToken =
        explicitToken ?? await FirebaseMessaging.instance.getToken();
    if (fcmToken == null) return;
    _notif.registerFcmToken(
      fcmToken: fcmToken,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Auth & notifikasi pakai .value karena instance dibuat di initState
        ChangeNotifierProvider.value(value: _auth),
        ChangeNotifierProvider.value(value: _notif),
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
        theme: ThemeData(
          useMaterial3: false,
          scaffoldBackgroundColor: Colors.white,
          canvasColor: Colors.white,
          cardColor: Colors.white,
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF013236),
            secondary: Color(0xFF94DF0C),
            surface: Colors.white,
            onSurface: Color(0xFF013236),
          ),
        ),
        home: SplashScreen(),
      ),
    );
  }
}
