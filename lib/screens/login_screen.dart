import 'package:enviroo/providers/auth_provider.dart';
import 'package:enviroo/widgets/custom_snackbar.dart';
import 'package:enviroo/providers/notifikasi_provider.dart';
import 'package:enviroo/screens/admin_bsi/home_bsi_screen.dart';
import 'package:enviroo/screens/admin_bsu/home_bsu_screen.dart';
import 'package:enviroo/screens/admin_bsm/home_bsm_screen.dart';
import 'package:enviroo/screens/nasabah/home_screen.dart';
import 'package:enviroo/screens/lupapassword_screen.dart';
import 'package:enviroo/screens/aktivasi_akun_screen.dart';
import 'package:enviroo/screens/role_options_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

  // Warna sesuai spesifikasi desain baru
  static const Color bgColor = Color(0xFF013236);
  static const Color primaryColor = Color(0xFF94DF0C);
  static const Color inputBgColor = Color(0xFFFFFFFF);
  static const Color softWhiteGreen = Color(0xFFFFFFFF);
  static const Color buttonTextColor = Colors.white;

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

    // Step 1: Cek user & role yang tersedia
    final cekResult = await authProvider.cekUserMobile(email, password);

    if (!mounted) return;

    if (cekResult['success'] != true) {
      setState(() => _isLoading = false);
      showCustomSnackBar(context, cekResult['message'] ?? 'Verifikasi gagal');
      return;
    }

    final List<String> roles = List<String>.from(cekResult['roles'] ?? []);
    final bool multipleRoles = cekResult['multiple_roles'] == true;

    // Simpan available roles agar fitur switch akun bisa bekerja
    authProvider.setAvailableRoles(roles);

    if (roles.isEmpty) {
      setState(() => _isLoading = false);
      showCustomSnackBar(context, 'Tidak ada role yang tersedia untuk akun ini');
      return;
    }

    // Step 2: Jika role lebih dari 1, arahkan ke RoleOptionsScreen
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

    // Step 3: Jika hanya 1 role, langsung login
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
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final notifProvider = Provider.of<NotifikasiProvider>(context, listen: false);

    // Fetch daftar notifikasi
    notifProvider.fetchNotifikasi(
      userId: auth.userId,
    );

    // Daftarkan FCM token ke backend — ini yang selama ini HILANG!
    FirebaseMessaging.instance.getToken().then((fcmToken) {
      if (fcmToken != null && fcmToken.isNotEmpty) {
        debugPrint('[Login] FCM token diperoleh, mendaftarkan ke backend...');
        notifProvider.registerFcmToken(
          fcmToken: fcmToken,
        );
      } else {
        debugPrint('[Login] FCM token null/kosong, skip register.');
      }
    });

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

                    // Logo centered di atas
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
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                            color: primaryColor,
                            letterSpacing: 3,
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 75),

                    // Heading "Selamat Datang"
                    const Text(
                      "Selamat Datang",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Header texts (konten asli dipertahankan)
                    const Text(
                      "Udah punya akun aktif?",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        color: softWhiteGreen,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      "Yuk, login ke aplikasinya",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        color: softWhiteGreen,
                      ),
                    ),
                    const SizedBox(height: 35),

                    // Email Input (dengan icon seperti aslinya)
                    _buildInputField(
                      controller: _emailController,
                      hintText: "Email",
                      icon: Icons.email_rounded,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 20),

                    // Password Input (dengan icon seperti aslinya)
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
                          color: primaryColor.withOpacity(0.7),
                          size: 22,
                        ),
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Lupa Password Link (rata kanan seperti aslinya)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _handleForgotPassword,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          "Lupa Password?",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: softWhiteGreen,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),

                    // Login Button
                    _buildLoginButton(_isLoading),
                    const SizedBox(height: 40),

                    // Aktivasi Akun (konten asli dipertahankan)
                    Center(
                      child: const Text(
                        "Belum bisa login karena akun belum aktif?",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: softWhiteGreen,
                        ),
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
                              color: primaryColor.withOpacity(0.5),
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            "Aktivasi di sini",
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: primaryColor.withOpacity(0.75),
                            ),
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
        borderRadius: BorderRadius.circular(50), // Border radius bulat
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          color: Color(0xFF2D3748),
        ),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
          hintText: hintText,
          hintStyle: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            color: Colors.grey.shade500,
          ),
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
              color: primaryColor.withOpacity(0.8),
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
          disabledBackgroundColor: primaryColor.withOpacity(0.6),
          elevation: 8,
          shadowColor: primaryColor.withOpacity(0.25),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50), // Border radius bulat
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF013236)),
                ),
              )
            : const Text(
                "LOGIN",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
