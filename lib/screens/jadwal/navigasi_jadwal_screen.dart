import 'package:enviroo/screens/penimbangan/batal_penimbangan_screen.dart';
import 'package:enviroo/screens/petugas/chat_info_ke_nasabah_screen.dart';
import 'package:enviroo/screens/jadwal/jadwal_screen.dart';
import 'package:enviroo/widgets/topbar_back.dart';
import 'package:flutter/material.dart';

// ── Screen ───────────────────────────────────────────────────────────────────
// Halaman navigasi buat petugas_bsm — pintu masuk ke 3 menu monitoring jadwal
// penimbangan. Diakses lewat menu "Jadwal" di beranda BSM (MenuAdminBSM),
// di-push sebagai route biasa — bukan lagi tab di BottomBarCustom.
class NavigasiJadwalScreen extends StatelessWidget {
  final VoidCallback? onBack;

  const NavigasiJadwalScreen({super.key, this.onBack});

  static const _dark = Color(0xFF013236);
  static const _accent = Color(0xFF4EA771);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bg_struk2.webp'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              TopBarBack(title: 'Monitoring Jadwal', onBack: onBack),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(28, 0, 28, 0),
                        child: Text(
                          'Pada halaman ini Anda bisa memantau ataupun membatalkan jadwal penimbangan mendatang',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12.5,
                            height: 1.6,
                            color: _dark.withValues(alpha: 0.65),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            _MenuCard(
                              icon: Icons.notifications_rounded,
                              color: _dark,
                              title: 'Notifikasi Jadwal',
                              description:
                                  'Pada menu ini Anda bisa melihat riwayat notifikasi yang dikirim ke nasabah terkait jadwal dan sesi penimbangan',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ChatInfoKeNasabahScreen(),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            _MenuCard(
                              icon: Icons.event_busy_rounded,
                              color: const Color(0xFFEB5757),
                              title: 'Pembatalan Jadwal',
                              description:
                                  'Pada menu ini Anda dapat membatalkan jadwal penimbangan mendatang agar nasabah mendapat pemberitahuan',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const BatalPenimbanganScreen(),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            _MenuCard(
                              icon: Icons.calendar_month_rounded,
                              color: _accent,
                              title: 'Kalender Penimbangan',
                              description:
                                  'Pada menu Anda dapat melihat seluruh jadwal penimbangan, baik yang mendatang ataupun yang lampau',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const JadwalScreen(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Menu Card ────────────────────────────────────────────────────────────────
class _MenuCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String description;
  final VoidCallback? onTap;

  const _MenuCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
    this.onTap,
  });

  static const _dark = Color(0xFF013236);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: _dark.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          splashColor: color.withValues(alpha: 0.06),
          highlightColor: color.withValues(alpha: 0.03),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 14, 18),
            child: Row(
              children: [
                // Icon: gradient + colored glow biar gak flat
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [color, color.withValues(alpha: 0.78)],
                    ),
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                          color: _dark,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        description,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          height: 1.55,
                          color: _dark.withValues(alpha: 0.45),
                        ),
                      ),
                    ],
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
