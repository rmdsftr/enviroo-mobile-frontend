import 'package:enviroo/providers/auth_provider.dart';
import 'package:enviroo/providers/notifikasi_provider.dart';
import 'package:enviroo/screens/nasabah/home_screen.dart';
import 'package:enviroo/screens/admin_bsu/home_bsu_screen.dart';
import 'package:enviroo/screens/admin_bsi/home_bsi_screen.dart';
import 'package:enviroo/screens/admin_bsm/home_bsm_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RoleOptionsScreen extends StatefulWidget {
  final String email;
  final String password;
  final List<String> roles;

  const RoleOptionsScreen({
    super.key,
    required this.email,
    required this.password,
    required this.roles,
  });

  @override
  State<RoleOptionsScreen> createState() => _RoleOptionsScreenState();
}

class _RoleOptionsScreenState extends State<RoleOptionsScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  String? _selectedRole;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  String _getRoleLabel(String role) {
    switch (role) {
      case 'nasabah':
        return 'Nasabah';
      case 'admin':
        return 'Petugas';
      default:
        return role;
    }
  }

  String _getRoleDescription(String role) {
    switch (role) {
      case 'nasabah':
        return 'Kelola setoran sampah, cek saldo, dan riwayat transaksi Anda.';
      case 'admin':
        return 'Lakukan pencatatan setoran dan pengangkutan di lapangan.';
      default:
        return 'Masuk sebagai $role';
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'nasabah':
        return Icons.person_rounded;
      case 'admin':
        return Icons.assignment_ind_rounded;
      default:
        return Icons.account_circle_rounded;
    }
  }

  void _handleRoleSelect(String role) async {
    setState(() {
      _selectedRole = role;
      _isLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.login(widget.email, widget.password, role);

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (success) {
      // Simpan available roles agar fitur switch akun bisa bekerja
      authProvider.setAvailableRoles(widget.roles);
      final actualRole = authProvider.role;
      Widget destination;

      if (actualRole == 'nasabah') {
        destination = const HomeScreen();
      } else if (actualRole.contains('bsu')) {
        destination = const HomeBsuScreen();
      } else if (actualRole.contains('bsm')) {
        destination = const HomeBsmScreen();
      } else if (actualRole.contains('bsi')) {
        destination = const HomeBsiScreen();
      } else {
        destination = const HomeBsuScreen();
      }

      final auth = Provider.of<AuthProvider>(context, listen: false);
      final notifProvider = Provider.of<NotifikasiProvider>(context, listen: false);

      // Fetch daftar notifikasi
      notifProvider.fetchNotifikasi(
        userId: auth.userId,
      );

      // Daftarkan FCM token ke backend — ini yang selama ini HILANG!
      FirebaseMessaging.instance.getToken().then((fcmToken) {
        if (fcmToken != null && fcmToken.isNotEmpty) {
          debugPrint('[RoleOptions] FCM token diperoleh, mendaftarkan ke backend...');
          notifProvider.registerFcmToken(
            fcmToken: fcmToken,
          );
        } else {
          debugPrint('[RoleOptions] FCM token null/kosong, skip register.');
        }
      });

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => destination),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Login gagal'),
          backgroundColor: const Color(0xFFB61E20),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF013236),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                // Back Button
                GestureDetector(
                  onTap: _isLoading ? null : () => Navigator.pop(context),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFFFF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: Color(0xFFFFFFFF),
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(height: 35),

                // Header
                const Text(
                  "Pilih Role",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF94DF0C),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Akun kamu memiliki lebih dari satu role.\nPilih role yang ingin digunakan sekarang.",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    height: 1.6,
                    color: const Color(0xFFFFFFFF).withOpacity(0.65),
                  ),
                ),
                const SizedBox(height: 40),

                // Role Cards
                Expanded(
                  child: ListView.separated(
                    itemCount: widget.roles.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final role = widget.roles[index];
                      final isSelected = _selectedRole == role;
                      final isCurrentLoading = isSelected && _isLoading;

                      return GestureDetector(
                        onTap: _isLoading ? null : () => _handleRoleSelect(role),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOutCubic,
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFFFF),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF94DF0C)
                                  : Colors.transparent,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isSelected
                                    ? const Color(0xFF94DF0C).withOpacity(0.25)
                                    : Colors.black.withOpacity(0.08),
                                blurRadius: isSelected ? 20 : 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Icon Circle
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF94DF0C)
                                      : const Color(0xFF013236).withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(
                                  _getRoleIcon(role),
                                  size: 28,
                                  color: isSelected
                                      ? const Color(0xFF013236)
                                      : const Color(0xFF013236),
                                ),
                              ),
                              const SizedBox(width: 18),

                              // Label & Description
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _getRoleLabel(role),
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                        color: isSelected
                                            ? const Color(0xFF013236)
                                            : const Color(0xFF013236),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _getRoleDescription(role),
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 11,
                                        height: 1.4,
                                        color: isSelected
                                            ? const Color(0xFF013236).withOpacity(0.8)
                                            : const Color(0xFF013236).withOpacity(0.5),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Arrow / Loading
                              if (isCurrentLoading)
                                const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Color(0xFF94DF0C),
                                    ),
                                  ),
                                )
                              else
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFF94DF0C)
                                        : const Color(0xFF013236).withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 20,
                                    color: isSelected
                                        ? const Color(0xFF013236)
                                        : const Color(0xFF013236).withOpacity(0.6),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
