import 'dart:async';

import 'package:flutter/material.dart';
import 'package:enviroo/core/theme/app_colors.dart';
import 'package:enviroo/core/theme/app_text.dart';

enum SnackBarType { error, success, info }

void showCustomSnackBar(
  BuildContext context,
  String message, {
  SnackBarType type = SnackBarType.error,
  String? subtitle,
  IconData? icon,
  bool hideCurrent = false,
}) {
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
      iconColor = AppColors.dangerDeep;
      defaultIcon = Icons.error_outline_rounded;
    case SnackBarType.success:
      borderColor = const Color(0xFFB8E6C8);
      iconBgColor = const Color(0xFFEBF7F0);
      iconColor = const Color(0xFF2E7D4F);
      defaultIcon = Icons.check_circle_outline_rounded;
    case SnackBarType.info:
      borderColor = const Color(0xFFC7E0DE);
      iconBgColor = const Color(0xFFE8F2F1);
      iconColor = AppColors.dark;
      defaultIcon = Icons.info_outline_rounded;
  }

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
        if (_entriAktif == entry) _tutupAktif();
      },
    ),
  );

  _entriAktif = entry;
  overlay.insert(entry);
}

OverlayEntry? _entriAktif;

void _tutupAktif() {
  _entriAktif?.remove();
  _entriAktif = null;
}

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

  Future<void> _tutup() async {
    _timer?.cancel();
    if (!mounted) return;
    await _ctrl.reverse();
    if (mounted) widget.onSelesai();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
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
                              style: AppText.w600(12, Color(0xFF222222)),
                            )
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.message,
                                  style: AppText.w700(12.5, Color(0xFF222222)),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.subtitle!,
                                  style: AppText.p(11, color: Color(0xFF6B6B6B), height: 1.4),
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
