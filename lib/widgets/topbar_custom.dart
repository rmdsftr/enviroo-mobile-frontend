import 'package:enviroo/providers/auth_provider.dart';
import 'package:enviroo/providers/notifikasi_provider.dart';
import 'package:enviroo/screens/notifikasi_screen.dart';
import 'package:enviroo/widgets/profile_corner.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TopBarCustom extends StatefulWidget implements PreferredSizeWidget {
  final Color backgroundColor;
  final String? logo;
  final Color borderFoto;
  final Color bgFoto;

  const TopBarCustom({
    super.key,
    this.backgroundColor = const Color(0xFFEAF8E7),
    this.logo = "assets/images/logo-fix.png",
    this.borderFoto = const Color(0xFF94DF0C),
    this.bgFoto = const Color(0xFF013236),
  });

  @override
  Size get preferredSize => const Size.fromHeight(120);

  @override
  State<TopBarCustom> createState() => _TopBarCustomState();
}

class _TopBarCustomState extends State<TopBarCustom> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchNotif());
  }

  void _fetchNotif() {
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn) return;
    context.read<NotifikasiProvider>().fetchNotifikasi(
          userId: auth.userId,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: widget.backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 17),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Image.asset(
            widget.logo ?? "assets/images/logo-fix.png",
            height: 22,
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotifikasiScreen(),
                    ),
                  );
                },
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(
                      Icons.circle_notifications_rounded,
                      size: 40,
                      color: Color(0xFF013236),
                    ),
                    Consumer<NotifikasiProvider>(
                      builder: (context, notifProvider, _) {
                        final count = notifProvider.unreadCount;
                        if (count == 0) return const SizedBox.shrink();
                        final label = count > 9 ? '9+' : '$count';
                        return Positioned(
                          top: -2,
                          right: -4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF94DF0C),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: Colors.white, width: 1.5),
                            ),
                            constraints: const BoxConstraints(minWidth: 18),
                            child: Text(
                              label,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 9,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF013236),
                                height: 1.2,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 5),
              ProfileCorner(
                borderPhoto: widget.borderFoto,
                bgPhoto: widget.bgFoto,
              ),
            ],
          )
        ],
      ),
    );
  }
}
