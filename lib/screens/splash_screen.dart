import 'package:enviroo/providers/auth_provider.dart';
import 'package:enviroo/providers/notifikasi_provider.dart';
import 'package:enviroo/screens/admin_bsi/home_bsi_screen.dart';
import 'package:enviroo/screens/admin_bsm/home_bsm_screen.dart';
import 'package:enviroo/screens/admin_bsu/home_bsu_screen.dart';
import 'package:enviroo/screens/nasabah/home_screen.dart';
import 'package:enviroo/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const Color bgColor = Color(0xFF013236);
  static const Color neonGreen = Color(0xFF94DF0C);

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  bool _imageLoaded = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
    ));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_imageLoaded) {
      _imageLoaded = true;
      precacheImage(
        const AssetImage("assets/images/logo-fix.png"),
        context,
      ).catchError((e) {
        debugPrint("Error precache image: $e");
      }).whenComplete(() {
        if (!mounted) return;
        _animationController.forward();

        // Tunggu animasi selesai, lalu cek sesi
        Future.delayed(const Duration(seconds: 2), () async {
          debugPrint("Splash: Future.delayed selesai");
          if (!mounted) return;

          debugPrint("Splash: Memulai cek sesi (tryRestoreSession)");
          final auth = Provider.of<AuthProvider>(context, listen: false);
          final restored = await auth.tryRestoreSession();

          debugPrint("Splash: tryRestoreSession selesai. Status restored: $restored");
          if (!mounted) return;

          if (restored) {
            debugPrint("Splash: Navigasi ke Home (${auth.role})");
            // Sesi masih valid → langsung ke home sesuai role
            _navigateToHome(auth.role);
          } else {
            debugPrint("Splash: Navigasi ke LoginScreen");
            // Tidak ada sesi → ke login
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const LoginScreen(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
                transitionDuration: const Duration(milliseconds: 500),
              ),
            );
          }
        });
      });
    }
  }

  void _navigateToHome(String role) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    Provider.of<NotifikasiProvider>(context, listen: false).fetchNotifikasi(
      userId: auth.userId,
    );

    Widget destination;
    if (role == 'nasabah') {
      destination = const HomeScreen();
    } else if (role.contains('bsu')) {
      destination = const HomeBsuScreen();
    } else if (role.contains('bsm')) {
      destination = const HomeBsmScreen();
    } else if (role.contains('bsi')) {
      destination = const HomeBsiScreen();
    } else {
      destination = const HomeBsuScreen();
    }

    Navigator.pushAndRemoveUntil(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => destination,
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
      (route) => false,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo
                Image.asset(
                  "assets/images/logo-fix.png",
                  height: 90,
                ),
                const SizedBox(height: 12),
                // Teks "enviroo"
                const Text(
                  "enviroo",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 24,
                    color: neonGreen,
                    letterSpacing: 3,
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
