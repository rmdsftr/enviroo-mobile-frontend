import 'package:enviroo/models/notifikasi_model.dart';
import 'package:enviroo/providers/auth_provider.dart';
import 'package:enviroo/providers/notifikasi_provider.dart';
import 'package:enviroo/providers/pengangkutan_provider.dart';
import 'package:enviroo/screens/admin_bsi/detail_pengangkutan_screen.dart';
import 'package:enviroo/screens/admin_bsi/katalog_sembako_screen.dart';
import 'package:enviroo/screens/admin_bsi/pengangkutan_bsi_screen.dart';
import 'package:enviroo/screens/admin_bsu/struk_bagi_hasil_bsu_screen.dart';
import 'package:enviroo/screens/nasabah/detail_setoran_screen.dart';
import 'package:enviroo/screens/penarikan/detail_penarikan_screen.dart';
import 'package:enviroo/screens/penarikan/detail_transaksi_penarikan_screen.dart';
import 'package:enviroo/screens/nasabah/struk_bagi_hasil_nasabah.dart';
import 'package:enviroo/widgets/topbar_back.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class NotifikasiScreen extends StatefulWidget {
  const NotifikasiScreen({super.key});

  @override
  State<NotifikasiScreen> createState() => _NotifikasiScreenState();
}

class _NotifikasiScreenState extends State<NotifikasiScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
  }

  void _fetch() {
    final auth = context.read<AuthProvider>();
    context.read<NotifikasiProvider>().fetchNotifikasi(
          userId: auth.userId,
        );
  }

  void _markAllRead() {
    final auth = context.read<AuthProvider>();
    context.read<NotifikasiProvider>().markAllAsRead(
          userId: auth.userId,
        );
  }

  Future<void> _onTapNotif(NotifikasiModel notif) async {
    final auth = context.read<AuthProvider>();

    // Await agar backend selesai persist sebelum navigasi — cegah race condition
    if (!notif.isRead) {
      await context.read<NotifikasiProvider>().markAsRead(
            notifId: notif.id,
          );
    }

    if (!mounted) return;

    // Navigasi berdasarkan ref_type
    if (notif.refId == null) return;
    final refId = notif.refId!;

    switch (notif.refType) {
      case 'jadwal_penimbangan':
      case 'jadwal_pengangkutan':
        // Hanya tandai dibaca, tidak navigasi ke screen lain
        return;
      case 'setoran':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetailSetoranScreen(setoranId: refId),
          ),
        );
      case 'pengangkutan':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetailPengangkutanScreen(pengangkutanId: refId),
          ),
        );
      case 'pengajuan_pengangkutan':
        context.read<PengangkutanProvider>().setHighlight(refId);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const PengangkutanBsiScreen(
              initialTab: 1,
              initialFilter: 'requested',
            ),
          ),
        );
      case 'distribusi_sembako':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const KatalogSembakoScreen(),
          ),
        );
      case 'penarikan':
        final role = auth.role;
        if (role == 'nasabah') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DetailPenarikanScreen(penarikanId: refId),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  DetailTransaksiPenarikanScreen(penarikanId: refId),
            ),
          );
        }
      case 'bagi_hasil':
        final role = auth.role;
        if (role == 'nasabah') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => StrukBagiHasilNasabah(penerimaId: refId),
            ),
          );
        } else if (role == 'petugas_bsu') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => StrukBagiHasilBsuScreen(penerimaSisaId: refId),
            ),
          );
        }
    }
  }

  // ─── Config per ref_type ──────────────────────────────────────────────────
  bool _isJadwal(String? refType) =>
      refType == 'jadwal_penimbangan' || refType == 'jadwal_pengangkutan';

  IconData _getIcon(String? refType) {
    switch (refType) {
      case 'setoran':             return CupertinoIcons.arrow_up_circle_fill;
      case 'penarikan':           return CupertinoIcons.arrow_down_circle_fill;
      case 'bagi_hasil':          return CupertinoIcons.money_dollar_circle_fill;
      case 'kontrak':             return CupertinoIcons.clock_fill;
      case 'pengajuan':           return CupertinoIcons.doc_text_fill;
      case 'pengangkutan':           return CupertinoIcons.cube_box_fill;
      case 'pengajuan_pengangkutan': return CupertinoIcons.cube_box_fill;
      case 'distribusi_sembako':  return CupertinoIcons.cart_fill;
      case 'jadwal_penimbangan':  return Icons.scale_rounded;
      case 'jadwal_pengangkutan': return Icons.local_shipping_rounded;
      default:                    return CupertinoIcons.bell_fill;
    }
  }

  Color _getColor(String? refType) {
    switch (refType) {
      case 'setoran':             return const Color(0xFF4EA771);
      case 'penarikan':           return const Color(0xFF3B82C4);
      case 'bagi_hasil':          return const Color(0xFF7C5CBF);
      case 'kontrak':             return const Color(0xFFE07B39);
      case 'pengajuan':           return const Color(0xFF546E7A);
      case 'pengangkutan':           return const Color(0xFF0D8A8A);
      case 'pengajuan_pengangkutan': return const Color(0xFF0D8A8A);
      case 'distribusi_sembako':  return const Color(0xFFE07B39);
      case 'jadwal_penimbangan':  return const Color(0xFFF59E0B);
      case 'jadwal_pengangkutan': return const Color(0xFF0EA5E9);
      default:                    return const Color(0xFF013236);
    }
  }

  bool _isTappable(String? refType, String? refId) {
    if (refId == null) return false;
    return refType == 'setoran' ||
        refType == 'pengangkutan' ||
        refType == 'pengajuan_pengangkutan' ||
        refType == 'distribusi_sembako' ||
        refType == 'bagi_hasil' ||
        refType == 'penarikan';
  }

  String _formatWaktu(String createdAt) {
    final dt = DateTime.tryParse(createdAt);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays == 1) return 'Kemarin';
    return '${diff.inDays} hari lalu';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FAF0),
      body: SafeArea(
        child: Column(
          children: [
            const TopBarBack(title: 'Notifikasi'),
            Expanded(
              child: Consumer<NotifikasiProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(color: Color(0xFF4EA771)),
                    );
                  }

                  if (provider.errorMessage != null) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.wifi_off_rounded,
                                size: 40,
                                color: Colors.red.withOpacity(0.5)),
                            const SizedBox(height: 12),
                            Text(
                              provider.errorMessage!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                color: Color(0xFF013236),
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _fetch,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF013236),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Coba Lagi',
                                  style: TextStyle(fontFamily: 'Poppins')),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final notifs = provider.notifikasi;
                  final unread = provider.unreadCount;

                  return Column(
                    children: [
                      // ── Header row ──────────────────────────────────────
                      if (notifs.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 6, 20, 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            unread > 0
                                ? Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF4EA771),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '$unread belum dibaca',
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white,
                                      ),
                                    ),
                                  )
                                : const Text(
                                    'Semua sudah dibaca',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 11,
                                      color: Color(0xFF013236),
                                    ),
                                  ),
                            if (unread > 0)
                              GestureDetector(
                                onTap: _markAllRead,
                                child: const Text(
                                  'Tandai semua dibaca',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF4EA771),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (notifs.isNotEmpty) const SizedBox(height: 10),
                      // ── List ────────────────────────────────────────────
                      Expanded(
                        child: notifs.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(CupertinoIcons.bell_slash,
                                        size: 48,
                                        color: const Color(0xFF013236)
                                            .withOpacity(0.2)),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'Belum ada notifikasi',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 13,
                                        color: Color(0xFF013236),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                physics: const BouncingScrollPhysics(),
                                padding:
                                    const EdgeInsets.fromLTRB(16, 6, 16, 24),
                                itemCount: notifs.length,
                                itemBuilder: (context, index) =>
                                    _buildNotifCard(notifs[index]),
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotifCard(NotifikasiModel notif) {
    if (_isJadwal(notif.refType)) return _buildJadwalCard(notif);

    final color = _getColor(notif.refType);
    final tappable = _isTappable(notif.refType, notif.refId);

    return GestureDetector(
      onTap: () => _onTapNotif(notif),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: notif.isRead ? Colors.white : const Color(0xFFDFF4DA),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: notif.isRead
                ? Colors.transparent
                : const Color(0xFF4EA771).withOpacity(0.35),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF013236).withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Icon ─────────────────────────────────────────────────
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(_getIcon(notif.refType), color: color, size: 20),
            ),
            const SizedBox(width: 12),
            // ── Text ─────────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notif.judul,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: notif.isRead
                                ? FontWeight.w500
                                : FontWeight.w700,
                            fontSize: 13,
                            color: const Color(0xFF013236),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatWaktu(notif.createdAt),
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          color: const Color(0xFF013236).withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    notif.pesan,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      height: 1.5,
                      color: const Color(0xFF013236).withOpacity(0.6),
                    ),
                  ),
                  if (tappable) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          'Lihat detail',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(CupertinoIcons.chevron_right,
                            size: 10, color: color),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // ── Unread dot ───────────────────────────────────────────
            if (!notif.isRead)
              Padding(
                padding: const EdgeInsets.only(left: 8, top: 2),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF4EA771),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildJadwalCard(NotifikasiModel notif) {
    final color = _getColor(notif.refType);
    final isHariIni = notif.judul.contains('Hari Ini');
    final badgeLabel = isHariIni ? 'Hari Ini' : 'Besok';

    return GestureDetector(
      onTap: () => _onTapNotif(notif),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: notif.isRead ? Colors.white : color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: color.withValues(alpha: notif.isRead ? 0.18 : 0.4),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Left accent bar ───────────────────────────────────
                Container(width: 5, color: color),
                // ── Content ───────────────────────────────────────────
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon besar
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Icon(_getIcon(notif.refType),
                              color: color, size: 22),
                        ),
                        const SizedBox(width: 12),
                        // Teks
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Baris judul + badge waktu
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      notif.judul,
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontWeight: notif.isRead
                                            ? FontWeight.w600
                                            : FontWeight.w700,
                                        fontSize: 13,
                                        color: const Color(0xFF013236),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  // Badge hari ini / besok
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      badgeLabel,
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: color,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              Text(
                                notif.pesan,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 11,
                                  height: 1.5,
                                  color:
                                      const Color(0xFF013236).withValues(alpha: 0.6),
                                ),
                              ),
                              const SizedBox(height: 6),
                              // Footer: waktu + status
                              Row(
                                children: [
                                  Icon(CupertinoIcons.clock,
                                      size: 10,
                                      color: const Color(0xFF013236)
                                          .withValues(alpha: 0.35)),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatWaktu(notif.createdAt),
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 10,
                                      color: const Color(0xFF013236)
                                          .withValues(alpha: 0.35),
                                    ),
                                  ),
                                  if (!notif.isRead) ...[
                                    const Spacer(),
                                    Container(
                                      width: 7,
                                      height: 7,
                                      decoration: BoxDecoration(
                                        color: color,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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
