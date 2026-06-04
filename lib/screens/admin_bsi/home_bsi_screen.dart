import 'package:enviroo/layouts/informasi_layouts.dart';
import 'package:enviroo/layouts/balance.dart';
import 'package:enviroo/layouts/menu_admin_bsi.dart';
import 'package:enviroo/layouts/profil_bsu_layouts.dart';
import 'package:enviroo/layouts/statistik_bsi.dart';
import 'package:enviroo/widgets/topbar_custom.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:enviroo/providers/auth_provider.dart';
import 'package:enviroo/providers/dashboard_provider.dart';
import 'package:enviroo/widgets/bottom_bar_custom.dart';
import 'package:enviroo/screens/admin_bsu/harga_screen.dart';
import 'package:enviroo/screens/admin_bsu/jadwal_screen.dart';
import 'package:enviroo/screens/profil_bank_screen.dart';
import 'package:enviroo/providers/katalog_provider.dart';
import 'package:enviroo/providers/konten_provider.dart';
import 'package:enviroo/providers/jadwal_provider.dart';

class HomeBsiScreen extends StatefulWidget {
  const HomeBsiScreen({Key? key}) : super(key: key);

  @override
  State<HomeBsiScreen> createState() => _HomeBsiScreenState();
}

class _HomeBsiScreenState extends State<HomeBsiScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final provider = context.read<DashboardProvider>();
      provider.fetchDashboardPetugas(auth);

      if (auth.bankId != null) {
        context.read<KontenProvider>().fetchKonten(
          auth.bankId!,
          published: true,
        );
      }
    });
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
                      backgroundColor: const Color(0xFFEAF8E7),
                      bgFoto: const Color(0xFF06C0C9),
                    ),
                    ProfilBsuScreen(
                      namaBank: data.namaBank,
                      alamatBank: data.alamatBank,
                      namaInduk: null, // BSI tidak punya nama induk
                      photoBank: data.photoBank,
                    ),
                    SizedBox(height: 20),
                    StatistikBsiScreen(
                      jumlahBsu: data.jumlahBsu ?? 0,
                      jumlahNasabah: data.jumlahNasabah,
                      jumlahStaff: data.jumlahStaff ?? 0,
                    ),
                    BalanceLayouts(entityType: BalanceEntityType.bank),
                    const SizedBox(height: 10),
                    MenuAdminBSI(),
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
      if (auth.bankId != null) {
        context.read<KontenProvider>().fetchKonten(
          auth.bankId!,
          published: true,
        );
      }
    }
    if (i == 1 && i != _currentIndex) {
      final auth = context.read<AuthProvider>();
      if (auth.bankId != null) {
        context.read<KatalogProvider>().fetchAll(
          auth.bankId!,
        );
      }
    }
    if (i == 2 && i != _currentIndex) {
      final auth = context.read<AuthProvider>();
      context.read<JadwalProvider>().fetchJadwal(auth);
    }
    setState(() => _currentIndex = i);
  }

  @override
  Widget build(BuildContext context) {
    final authRole = context.read<AuthProvider>().role;

    final List<Widget> pages = [
      _buildDashboardBody(),
      PopScope(
        canPop: false,
        onPopInvoked: (_) => _goHome(),
        child: PerubahanHargaScreen(onBack: _goHome, role: authRole),
      ),
      PopScope(
        canPop: false,
        onPopInvoked: (_) => _goHome(),
        child: JadwalScreen(onBack: _goHome),
      ),
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
                BottomBarItem(icon: Icons.collections_bookmark_outlined, label: 'Katalog'),
                BottomBarItem(icon: Icons.calendar_today_outlined, label: 'Jadwal'),
                BottomBarItem(icon: Icons.account_balance, label: 'Profil'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
