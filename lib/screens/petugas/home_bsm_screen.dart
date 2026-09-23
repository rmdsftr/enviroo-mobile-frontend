import 'package:enviroo/layouts/informasi_layouts.dart';
import 'package:enviroo/layouts/balance.dart';
import 'package:enviroo/layouts/menu_admin_bsm_layouts.dart';
import 'package:enviroo/layouts/profil_bsu_layouts.dart';
import 'package:enviroo/layouts/statistik_bsu.dart';
import 'package:enviroo/widgets/topbar_custom.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:enviroo/providers/auth_provider.dart';
import 'package:enviroo/providers/dashboard_provider.dart';
import 'package:enviroo/widgets/bottom_bar_custom.dart';
import 'package:enviroo/screens/petugas/profil_bank_screen.dart';
import 'package:enviroo/providers/konten_provider.dart';
import 'package:enviroo/core/network/network_status.dart';

class HomeBsmScreen extends StatefulWidget {
  const HomeBsmScreen({Key? key}) : super(key: key);

  @override
  State<HomeBsmScreen> createState() => _HomeBsmScreenState();
}

class _HomeBsmScreenState extends State<HomeBsmScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _muat();

      if (!mounted) return;
      _net = context.read<NetworkStatus>();
      _lastRecoveryToken = _net!.recoveryToken;
      _net!.addListener(_onNetworkRecovered);
    });
  }

  void _muat() {
    final auth = context.read<AuthProvider>();
    final provider = context.read<DashboardProvider>();
    provider.fetchDashboardPetugas(auth);

    if (auth.bankId != null) {
      context.read<KontenProvider>().fetchKonten(
        auth.bankId!,
        published: true,
      );
    }
  }

  // ─── Muat ulang otomatis saat jaringan pulih ───────────────────────────────
  //
  // Menutup NoConnectionScreen saja tidak cukup: layar ini di baliknya masih
  // menampilkan data gagal-muat dari waktu offline tadi.

  NetworkStatus? _net;
  int _lastRecoveryToken = 0;

  @override
  void dispose() {
    // WAJIB — NetworkStatus itu singleton yang hidup seumur app.
    _net?.removeListener(_onNetworkRecovered);
    super.dispose();
  }

  void _onNetworkRecovered() {
    if (!mounted || _net == null) return;
    // Bandingkan token, jangan sekadar "ada notifikasi": NetworkStatus juga
    // notify saat offline MENYALA, dan itu tidak boleh memicu fetch.
    final token = _net!.recoveryToken;
    if (token == _lastRecoveryToken) return;
    _lastRecoveryToken = token;
    _muat();
  }

  Widget _buildDashboardBody() {
    return Consumer<DashboardProvider>(
      builder: (context, dashboardProv, child) {
        if (dashboardProv.isLoading) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF4EA771)));
        }
        if (dashboardProv.error.isNotEmpty) {
          return Center(child: Text(dashboardProv.error, style: const TextStyle(color: Colors.red)));
        }
        final data = dashboardProv.dashboardData;
        if (data == null) {
          return const Center(child: Text("Tidak ada data dashboard"));
        }

        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    TopBarCustom(
                      bgFoto: const Color(0xFF06C0C9),
                      backgroundColor: const Color(0xFFEAF8E7),
                    ),
                    ProfilBsuScreen(
                      namaBank: data.namaBank,
                      alamatBank: data.alamatBank,
                      namaInduk: data.namaBankPusat,
                      photoBank: data.photoBank,
                    ),
                    SizedBox(height: 20),
                    StatistikBsuScreen(
                      jumlahNasabah: data.jumlahNasabah,
                      jumlahStaff: data.jumlahStaff ?? 0,
                    ),
                    BalanceLayouts(entityType: BalanceEntityType.bank),
                    const SizedBox(height: 10),
                    MenuAdminBSM(),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: InformasiSection(),
                    ),
                    SizedBox(height: MediaQuery.of(context).padding.bottom + 100),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _goHome() => setState(() => _currentIndex = 0);

  void _onNavTap(int i) {
    if (i == 0 && i != _currentIndex) {
      final auth = context.read<AuthProvider>();
      context.read<DashboardProvider>().fetchDashboardPetugas(auth);
      if (auth.bankId != null) {
        context.read<KontenProvider>().fetchKonten(
          auth.bankId!,
          published: true,
        );
      }
    }
    setState(() => _currentIndex = i);
  }

  @override
  Widget build(BuildContext context) {
    // Katalog & Jadwal tidak lagi jadi tab — keduanya dibuka lewat menu di
    // beranda (MenuAdminBSM) sebagai route biasa. Urutan di sini harus tetap
    // sejajar dengan items BottomBarCustom di bawah.
    final List<Widget> pages = [
      _buildDashboardBody(),
      PopScope(
        canPop: false,
        onPopInvoked: (_) => _goHome(),
        child: ProfilBankScreen(onBack: _goHome),
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFEAF8E7),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: IndexedStack(
              index: _currentIndex,
              children: pages,
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: BottomBarCustom(
              currentIndex: _currentIndex,
              onTap: _onNavTap,
              items: const [
                BottomBarItem(icon: Icons.home_outlined, label: 'Beranda'),
                BottomBarItem(icon: Icons.account_balance, label: 'Profil'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
