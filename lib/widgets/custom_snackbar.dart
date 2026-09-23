import 'dart:async';

import 'package:flutter/material.dart';

enum SnackBarType { error, success, info }

/// Snackbar standar aplikasi — muncul di **atas layar**, bukan bawah.
///
/// [subtitle] menambah baris kedua yang lebih kecil di bawah [message] —
/// dipakai saat pesan butuh keterangan lanjutan.
/// [icon] menimpa ikon bawaan tipe, untuk kasus yang punya makna spesifik
/// (mis. ikon amplop saat OTP dikirim ulang).
/// [hideCurrent] dipertahankan demi kecocokan pemanggil lama. Sekarang
/// perilakunya sudah jadi bawaan: snackbar baru selalu menimpa yang lama.
///
/// ## Kenapa Overlay, bukan ScaffoldMessenger
///
/// `SnackBar` bawaan Flutter **tidak punya properti posisi** — yang
/// menempatkannya adalah `Scaffold`, dan selalu di bawah. `SnackBarBehavior`
/// cuma menawarkan `fixed`/`floating`, dua-duanya tetap di bawah.
///
/// Trik memberi `margin` bawah sebesar tinggi layar memang bisa mendorongnya
/// ke atas, tapi rapuh: ikut melompat saat keyboard muncul, berantakan saat
/// rotasi, dan bisa melempar error layout kalau margin melebihi ruang yang
/// tersedia. Jadi presentasinya dipindah ke [OverlayEntry] — posisinya
/// dikendalikan penuh dan sadar akan safe area.
void showCustomSnackBar(
  BuildContext context,
  String message, {
  SnackBarType type = SnackBarType.error,
  String? subtitle,
  IconData? icon,
  bool hideCurrent = false,
}) {
  // maybeOf, bukan of: gagal menampilkan snackbar tidak boleh menjatuhkan app.
  final overlay = Overlay.maybeOf(context);
  if (overlay == null) return;

  late final Color borderColor;
  late final Color iconBgColor;
  late final Color iconColor;
  late final IconData defaultIcon;

  switch (type) {
    case SnackBarType.error:
      borderColor = const Color(0xFFFFD6D6);
      iconBgColor = const Color(0xFFFFEBEE);
      iconColor = const Color(0xFFB61E20);
      defaultIcon = Icons.error_outline_rounded;
    case SnackBarType.success:
      borderColor = const Color(0xFFB8E6C8);
      iconBgColor = const Color(0xFFEBF7F0);
      iconColor = const Color(0xFF2E7D4F);
      defaultIcon = Icons.check_circle_outline_rounded;
    case SnackBarType.info:
      borderColor = const Color(0xFFC7E0DE);
      iconBgColor = const Color(0xFFE8F2F1);
      iconColor = const Color(0xFF013236);
      defaultIcon = Icons.info_outline_rounded;
  }

  // Selalu timpa yang sedang tampil. Antrean ala ScaffoldMessenger sengaja
  // tidak ditiru: di posisi atas, pesan yang mengantre sering baru muncul saat
  // user sudah pindah layar.
  _tutupAktif();

  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _TopSnackBar(
      message: message,
      subtitle: subtitle,
      icon: icon ?? defaultIcon,
      borderColor: borderColor,
      iconBgColor: iconBgColor,
      iconColor: iconColor,
      onSelesai: () {
        // Jaga-jaga kalau entry ini sudah keburu diganti yang lebih baru.
        if (_entriAktif == entry) _tutupAktif();
      },
    ),
  );

  _entriAktif = entry;
  overlay.insert(entry);
}

// ── Satu snackbar aktif pada satu waktu ──────────────────────────────────────

OverlayEntry? _entriAktif;

void _tutupAktif() {
  _entriAktif?.remove();
  _entriAktif = null;
}

/// Isi visualnya sama persis dengan versi SnackBar sebelumnya — yang berganti
/// cuma cara menampilkannya.
class _TopSnackBar extends StatefulWidget {
  final String message;
  final String? subtitle;
  final IconData icon;
  final Color borderColor;
  final Color iconBgColor;
  final Color iconColor;
  final VoidCallback onSelesai;

  const _TopSnackBar({
    required this.message,
    required this.subtitle,
    required this.icon,
    required this.borderColor,
    required this.iconBgColor,
    required this.iconColor,
    required this.onSelesai,
  });

  @override
  State<_TopSnackBar> createState() => _TopSnackBarState();
}

class _TopSnackBarState extends State<_TopSnackBar>
    with SingleTickerProviderStateMixin {
  static const _durasiTampil = Duration(seconds: 4);

  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );

  late final Animation<Offset> _geser = Tween<Offset>(
    begin: const Offset(0, -1.2),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _ctrl.forward();
    _timer = Timer(_durasiTampil, _tutup);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  /// Animasi keluar dulu, baru entry-nya dicopot.
  Future<void> _tutup() async {
    _timer?.cancel();
    if (!mounted) return;
    await _ctrl.reverse();
    if (mounted) widget.onSelesai();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      // Sadar safe area — jangan tertimpa status bar atau poni layar.
      top: MediaQuery.of(context).padding.top + 8,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _geser,
        child: FadeTransition(
          opacity: _ctrl,
          child: Material(
            color: Colors.transparent,
            child: Dismissible(
              key: const ValueKey('top-snackbar'),
              direction: DismissDirection.up,
              onDismissed: (_) => widget.onSelesai(),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: widget.borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: widget.iconBgColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child:
                          Icon(widget.icon, color: widget.iconColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: widget.subtitle == null
                          ? Text(
                              widget.message,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                                color: Color(0xFF222222),
                              ),
                            )
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.message,
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12.5,
                                    color: Color(0xFF222222),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.subtitle!,
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 11,
                                    height: 1.4,
                                    color: Color(0xFF6B6B6B),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
