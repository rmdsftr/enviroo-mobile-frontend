import 'package:enviroo/core/messaging/fcm_messaging.dart';
import 'package:enviroo/providers/auth_provider.dart';
import 'package:enviroo/widgets/confirm_bottom_sheet.dart';
import 'package:enviroo/widgets/custom_snackbar.dart';
import 'package:enviroo/screens/petugas/home_bsi_screen.dart';
import 'package:enviroo/screens/petugas/home_bsu_screen.dart';
import 'package:enviroo/screens/petugas/home_bsm_screen.dart';
import 'package:enviroo/screens/nasabah/home_screen.dart';
import 'package:enviroo/screens/lupapassword_screen.dart';
import 'package:enviroo/screens/verifikasi_otp_screen.dart';
import 'package:enviroo/screens/aktivasi_akun_screen.dart';
import 'package:enviroo/screens/role_options_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:enviroo/core/theme/app_colors.dart';
import 'package:enviroo/core/theme/app_text.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  static const Color bgColor = AppColors.dark;
  static const Color primaryColor = AppColors.neon;
  static const Color inputBgColor = Colors.white;
  static const Color softWhiteGreen = Colors.white;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final auth = Provider.of<AuthProvider>(context, listen: false);

      if (auth.sessionEndedMessage != null) {
        showCustomSnackBar(
          context,
          auth.sessionEndedCode == 'SESSION_REVOKED'
              ? 'Akun kamu dipakai login di perangkat lain. Silakan login kembali.'
              : 'Sesi kamu sudah berakhir. Silakan login kembali.',
        );
        auth.clearSessionEnded();
      }

      await _tawarkanLanjutReset(auth);
    });
  }

  Future<void> _tawarkanLanjutReset(AuthProvider auth) async {
    final pending = await auth.loadPendingReset();
    if (!mounted) return;
    if (pending == null) return;

    final sisa = pending.expiredAt.difference(DateTime.now());
    final sisaTeks = '${sisa.inMinutes.toString().padLeft(2, '0')}:'
        '${(sisa.inSeconds % 60).toString().padLeft(2, '0')}';

    final lanjut = await showConfirmBottomSheet(
      context,
      icon: Icons.mark_email_read_outlined,
      title: 'Lanjutkan Reset Password?',
      message: 'Kode OTP sudah dikirim ke ${pending.email} dan masih berlaku '
          '$sisaTeks lagi. Lanjutkan tanpa minta kode baru?',
      cancelLabel: 'Abaikan',
      confirmLabel: 'Lanjutkan',
    );

    if (!mounted) return;

    if (!lanjut) {
      await auth.clearPendingReset();
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VerifikasiOtpScreen(
          email: pending.email,
          expiredAt: pending.expiredAt.toIso8601String(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      showCustomSnackBar(context, 'Email dan password tidak boleh kosong');
      return;
    }

    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final cekResult = await authProvider.cekUserMobile(email, password);

    if (!mounted) return;

    if (cekResult['success'] != true) {
      setState(() => _isLoading = false);
      showCustomSnackBar(context, cekResult['message'] ?? 'Verifikasi gagal');
      return;
    }

    final List<String> roles = List<String>.from(cekResult['roles'] ?? []);
    final bool multipleRoles = cekResult['multiple_roles'] == true;

    authProvider.setAvailableRoles(roles);

    if (roles.isEmpty) {
      setState(() => _isLoading = false);
      showCustomSnackBar(context, 'Tidak ada role yang tersedia untuk akun ini');
      return;
    }

    if (multipleRoles && roles.length > 1) {
      setState(() => _isLoading = false);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RoleOptionsScreen(
            email: email,
            password: password,
            roles: roles,
          ),
        ),
      );
      return;
    }

    final selectedRole = roles.first;
    final success = await authProvider.login(email, password, selectedRole);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      _navigateToHome(authProvider.role);
    } else {
      showCustomSnackBar(context, authProvider.errorMessage ?? 'Login gagal');
    }
  }

  void _navigateToHome(String role) {
    Provider.of<FcmMessaging>(context, listen: false).onLogin(tag: 'Login');

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
      MaterialPageRoute(builder: (_) => destination),
      (route) => false,
    );
  }

  void _handleForgotPassword() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => LupaPasswordScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: SafeArea(
          child: SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 60),

                    Column(
                      children: [
                        Center(
                          child: Image.asset(
                            "assets/images/logo-fix.png",
                            height: 50,
                          ),
                        ),
                        Text(
                          "enviroo",
                          style: AppText.p(20, weight: FontWeight.w700, color: primaryColor, letterSpacing: 3),
                        )
                      ],
                    ),
                    const SizedBox(height: 75),

                    Text(
                      "Selamat Datang",
                      style: AppText.p(28, weight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 10),

                    Text(
                      "Udah punya akun aktif?",
                      style: AppText.r(14, softWhiteGreen),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "Yuk, login ke aplikasinya",
                      style: AppText.r(14, softWhiteGreen),
                    ),
                    const SizedBox(height: 35),

                    _buildInputField(
                      controller: _emailController,
                      hintText: "Email",
                      icon: Icons.email_rounded,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 20),

                    _buildInputField(
                      controller: _passwordController,
                      hintText: "Password",
                      icon: Icons.lock_rounded,
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        onPressed: _isLoading
                            ? null
                            : () => setState(() => _obscurePassword = !_obscurePassword),
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                          color: primaryColor.withValues(alpha: 0.7),
                          size: 22,
                        ),
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                      ),
                    ),
                    const SizedBox(height: 20),

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _handleForgotPassword,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          "Lupa Password?",
                          style: AppText.w600(13, softWhiteGreen),
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),

                    _buildLoginButton(_isLoading),
                    const SizedBox(height: 40),

                    Center(
                      child: Text(
                        "Belum bisa login karena akun belum aktif?",
                        textAlign: TextAlign.center,
                        style: AppText.r(12, softWhiteGreen),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const AktivasiAkunScreen()));
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(50),
                            border: Border.all(
                              color: primaryColor.withValues(alpha: 0.5),
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            "Aktivasi di sini",
                            style: AppText.w700(13, primaryColor.withValues(alpha: 0.75)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: inputBgColor,
        borderRadius: BorderRadius.circular(50),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: AppText.r(14, Color(0xFF2D3748)),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
          hintText: hintText,
          hintStyle: AppText.r(14, Colors.grey.shade500),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(50),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(50),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(50),
            borderSide: const BorderSide(color: primaryColor, width: 2),
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 15, right: 10),
            child: Icon(
              icon,
              size: 22,
              color: primaryColor.withValues(alpha: 0.8),
            ),
          ),
          suffixIcon: suffixIcon != null
              ? Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: suffixIcon,
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildLoginButton(bool isLoading) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: bgColor,
          disabledBackgroundColor: primaryColor.withValues(alpha: 0.6),
          elevation: 8,
          shadowColor: primaryColor.withValues(alpha: 0.25),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.dark),
                ),
              )
            : Text(
                "LOGIN",
                style: AppText.w700(18),
              ),
      ),
    );
  }
}
