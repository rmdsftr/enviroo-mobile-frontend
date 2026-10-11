import 'dart:io';

import 'package:enviroo/core/messaging/fcm_messaging.dart';
import 'package:enviroo/core/messaging/notif_payload.dart';
import 'package:enviroo/core/messaging/notif_router.dart';
import 'package:enviroo/core/network/http_overrides.dart';
import 'package:enviroo/core/network/network_status.dart';
import 'package:enviroo/core/theme/app_theme.dart';
import 'package:enviroo/providers/auth_provider.dart';
import 'package:enviroo/providers/katalog_provider.dart';
import 'package:enviroo/providers/barang_provider.dart';
import 'package:enviroo/providers/konten_provider.dart';
import 'package:enviroo/providers/nasabah_provider.dart';
import 'package:enviroo/providers/jadwal_provider.dart';
import 'package:enviroo/providers/dashboard_provider.dart';
import 'package:enviroo/providers/penjualan_provider.dart';
import 'package:enviroo/providers/penarikan_petugas_provider.dart';
import 'package:enviroo/providers/penarikan_nasabah_provider.dart';
import 'package:enviroo/providers/bagi_hasil_provider.dart';
import 'package:enviroo/providers/bank_provider.dart';
import 'package:enviroo/providers/tabungan_sampah_provider.dart';
import 'package:enviroo/providers/bagi_hasil_bank_provider.dart';
import 'package:enviroo/providers/distribusi_sisa_provider.dart';
import 'package:enviroo/providers/mutasi_provider.dart';
import 'package:enviroo/providers/pengangkutan_provider.dart';
import 'package:enviroo/providers/penimbangan_provider.dart';
import 'package:enviroo/providers/setoran_provider.dart';
import 'package:enviroo/providers/reward_provider.dart';
import 'package:enviroo/providers/profil_provider.dart';
import 'package:enviroo/providers/notifikasi_provider.dart';
import 'package:enviroo/screens/no_connection_screen.dart';
import 'package:enviroo/screens/splash_screen.dart';
import 'package:enviroo/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
  final _auth = AuthProvider();
  final _notif = NotifikasiProvider();

  late final FcmMessaging _fcm = FcmMessaging(
    auth: _auth,
    notif: _notif,
    onDeepLink: _routeDeepLink,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _auth.setForceLogoutCallback(() {
      _navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => SplashScreen()),
        (_) => false,
      );
    });

    _net.addListener(_onNetworkStatusChanged);

    _fcm.start();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _net.removeListener(_onNetworkStatusChanged);
    _fcm.dispose();
    super.dispose();
  }

  final _net = NetworkStatus.instance;
  
  Route<dynamic>? _noConnRoute;

  void _onNetworkStatusChanged() {
    final nav = _navigatorKey.currentState;
    if (nav == null) return;

    if (_net.offline) {
      if (_noConnRoute != null) return;
      final route = MaterialPageRoute<void>(
        builder: (_) => const NoConnectionScreen(),
      );
      _noConnRoute = route;
      
      route.popped.whenComplete(() {
        if (_noConnRoute == route) _noConnRoute = null;
      });
      
      nav.push(route);
      return;
    }

    final route = _noConnRoute;
    if (route == null) return;
    _noConnRoute = null;
    if (route.isCurrent) {
      nav.pop();
    } else if (route.isActive) {
      
      nav.removeRoute(route);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _fcm.onAppResumed();
  }

  void _routeDeepLink(NotifPayload payload) {
    final navigator = _navigatorKey.currentState;
    if (navigator == null) return;
    NotifRouter.open(navigator, refType: payload.refType, refId: payload.refId);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _auth),
        ChangeNotifierProvider.value(value: _notif),
        
        Provider<FcmMessaging>.value(value: _fcm),
        
        ChangeNotifierProvider<NetworkStatus>.value(value: NetworkStatus.instance),
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
        ChangeNotifierProvider(create: (_) => BarangProvider()),
        ChangeNotifierProvider(create: (_) => MutasiProvider()),
        ChangeNotifierProvider(create: (_) => DistribusiSisaProvider()),
        ChangeNotifierProvider(create: (_) => PenimbanganProvider()),
        ChangeNotifierProvider(create: (_) => SetoranProvider()),
        ChangeNotifierProvider(create: (_) => RewardProvider()),
        ChangeNotifierProvider(create: (_) => BankProvider()),
        ChangeNotifierProvider(create: (_) => TabunganSampahProvider()),
        ChangeNotifierProvider(create: (_) => ProfilProvider()),
        ChangeNotifierProvider(create: (_) => PengangkutanProvider()),
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
