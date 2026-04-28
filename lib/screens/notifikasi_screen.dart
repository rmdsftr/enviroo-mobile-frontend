import 'package:enviroo/widgets/topbar_back.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// ─── Model ────────────────────────────────────────────────────────
class NotifItem {
  final String type;
  final String title;
  final String body;
  final String time;
  bool isRead;

  NotifItem({
    required this.type,
    required this.title,
    required this.body,
    required this.time,
    this.isRead = false,
  });
}

// ─── Screen ───────────────────────────────────────────────────────
class NotifikasiScreen extends StatefulWidget {
  @override
  State<NotifikasiScreen> createState() => _NotifikasiScreenState();
}

class _NotifikasiScreenState extends State<NotifikasiScreen> {
  final List<NotifItem> _notifs = [
    NotifItem(
      type: "setoran",
      title: "Setoran Berhasil",
      body: "Setoran sampah plastik 2,5 kg telah dikonfirmasi oleh BSU.",
      time: "Baru saja",
      isRead: false,
    ),
    NotifItem(
      type: "penarikan",
      title: "Penarikan Dana",
      body: "Penarikan sebesar Rp 25.000 sedang diproses.",
      time: "10 menit lalu",
      isRead: false,
    ),
    NotifItem(
      type: "info",
      title: "Info Sistem",
      body: "Pembaruan aplikasi versi 2.1 telah tersedia.",
      time: "1 jam lalu",
      isRead: false,
    ),
    NotifItem(
      type: "jadwal",
      title: "Pengingat Jadwal",
      body: "Pengambilan sampah dijadwalkan besok pukul 08.00.",
      time: "3 jam lalu",
      isRead: true,
    ),
    NotifItem(
      type: "admin",
      title: "Pesan dari Admin",
      body: "BSU kamu akan tutup pada hari Minggu minggu ini.",
      time: "Kemarin",
      isRead: true,
    ),
    NotifItem(
      type: "",
      title: "Notifikasi Umum",
      body: "Kamu mendapatkan poin bonus dari program daur ulang.",
      time: "2 hari lalu",
      isRead: true,
    ),
  ];

  int get _unreadCount => _notifs.where((n) => !n.isRead).length;

  void _markAllRead() {
    setState(() {
      for (var n in _notifs) {
        n.isRead = true;
      }
    });
  }

  // ─── Config per type ──────────────────────────────────────────
  IconData _getIcon(String type) {
    switch (type) {
      case 'jadwal':    return CupertinoIcons.clock_fill;
      case 'setoran':   return CupertinoIcons.arrow_up_circle_fill;
      case 'penarikan': return CupertinoIcons.arrow_down_circle_fill;
      case 'info':      return CupertinoIcons.info_circle_fill;
      case 'admin':     return CupertinoIcons.person_fill;
      default:          return CupertinoIcons.bell_fill;
    }
  }

  Color _getColor(String type) {
    switch (type) {
      case 'jadwal':    return const Color(0xFF7C5CBF);
      case 'setoran':   return const Color(0xFF4EA771);
      case 'penarikan': return const Color(0xFF3B82C4);
      case 'info':      return const Color(0xFFE07B39);
      case 'admin':     return const Color(0xFF546E7A);
      default:          return const Color(0xFF013236);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FAF0),
      body: SafeArea(
        child: Column(
          children: [
            const TopBarBack(title: "Notifikasi"),
            // ── Header row ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Unread badge
                  _unreadCount > 0
                      ? Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4EA771),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "$_unreadCount belum dibaca",
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  )
                      : const Text(
                    "Semua sudah dibaca",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: Color(0xFF013236),
                    ),
                  ),
                  // Mark all read
                  if (_unreadCount > 0)
                    GestureDetector(
                      onTap: _markAllRead,
                      child: const Text(
                        "Tandai semua dibaca",
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
            SizedBox(height: 10),
            // ── List ────────────────────────────────────────────
            Expanded(
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                itemCount: _notifs.length,
                itemBuilder: (context, index) {
                  return _buildNotifCard(_notifs[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotifCard(NotifItem notif) {
    final color = _getColor(notif.type);

    return GestureDetector(
      onTap: () => setState(() => notif.isRead = true),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: notif.isRead ? Colors.white : const Color(0xFFDFF4DA),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: notif.isRead
                ? Colors.transparent
                : const Color(0xFF4EA771).withValues(alpha: 0.35),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF013236).withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Icon container ───────────────────────────────
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(_getIcon(notif.type), color: color, size: 20),
            ),
            const SizedBox(width: 12),
            // ── Text content ─────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notif.title,
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
                        notif.time,
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
                    notif.body,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      height: 1.5,
                      color: const Color(0xFF013236).withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            // ── Unread dot ───────────────────────────────────
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
}
