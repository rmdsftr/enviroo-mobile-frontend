import 'package:enviroo/layouts/informasi_layouts.dart';
import 'package:enviroo/layouts/kas_bank_layout.dart';
import 'package:enviroo/layouts/menu_admin_bsi.dart';
import 'package:enviroo/layouts/menu_admin_bsu_layouts.dart';
import 'package:enviroo/layouts/profil_bsu_layouts.dart';
import 'package:enviroo/layouts/statistik_bsi.dart';
import 'package:enviroo/layouts/statistik_bsu.dart';
import 'package:enviroo/widgets/topbar_custom.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:enviroo/providers/auth_provider.dart';
import 'package:enviroo/providers/dashboard_provider.dart';

class HomeBsiScreen extends StatefulWidget {
  const HomeBsiScreen({Key? key}) : super(key: key);

  @override
  State<HomeBsiScreen> createState() => _HomeBsiScreenState();
}

class _HomeBsiScreenState extends State<HomeBsiScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      context.read<DashboardProvider>().fetchDashboardPetugas(auth);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      extendBodyBehindAppBar: true,
      body: SafeArea(
        child: Consumer<DashboardProvider>(
          builder: (context, dashboardProv, child) {
            if (dashboardProv.isLoading) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFF4EA771)));
            }
            if (dashboardProv.error.isNotEmpty) {
              return Center(child: Text(dashboardProv.error, style: TextStyle(color: Colors.red)));
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
                        backgroundColor: Color(0xFFFFFFFF),
                        bgFoto: Color(0xFF06C0C9),
                      ),
                      ProfilBsuScreen(
                        namaBank: data.namaBank,
                        alamatBank: data.alamatBank,
                        namaInduk: null, // BSI tidak punya nama induk
                        photoBank: data.photoBank,
                      ),
                      StatistikBsiScreen(
                        jumlahBsu: data.jumlahBsu ?? 0,
                        jumlahNasabah: data.jumlahNasabah,
                        jumlahStaff: data.jumlahStaff ?? 0,
                      ),
                      const SizedBox(height: 16),
                      KasBankSection(
                        kasUang: data.kasUang,
                        kasEmas: data.kasEmas,
                      ),
                      SizedBox(height: 10),
                      MenuAdminBSI(),
                      SizedBox(height: 10),
                      Padding(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                        child: InformasiSection(),
                      ),
                      SizedBox(height: 30)
                    ],
                  ),
                )
            ),
          ],
        );
      }),
      ),
    );
  }
}
