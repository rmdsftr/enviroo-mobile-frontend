import 'package:enviroo/providers/auth_provider.dart';
import 'package:enviroo/screens/splash_screen.dart';
import 'package:enviroo/screens/verifikasi_otp_screen.dart';
import 'package:enviroo/widgets/confirm_bottom_sheet.dart';
import 'package:enviroo/widgets/custom_snackbar.dart';
import 'package:enviroo/widgets/success_bottom_sheet.dart';
import 'package:enviroo/widgets/topbar_back.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:enviroo/core/theme/app_colors.dart';
import 'package:enviroo/core/theme/app_text.dart';

class UbahPasswordScreen extends StatefulWidget {
  @override
  State<UbahPasswordScreen> createState() => _UbahPasswordState();
}

class _UbahPasswordState extends State<UbahPasswordScreen> {
  final TextEditingController _passwordLamaController = TextEditingController();
  final TextEditingController _passwordBaruController = TextEditingController();
  final TextEditingController _konfirmasiPasswordController = TextEditingController();

  bool _obscureLama = true;
  bool _obscureBaru = true;
  bool _obscureKonfirmasi = true;
  bool _isLoading = false;

  bool _isPassBaruInvalid = false;
  bool _isKonfirmasiInvalid = false;

  @override
  void initState() {
    super.initState();
    _passwordBaruController.addListener(_validatePasswordFields);
    _konfirmasiPasswordController.addListener(_validatePasswordFields);
  }

  void _validatePasswordFields() {
    final baru = _passwordBaruController.text.trim();
    final konfirmasi = _konfirmasiPasswordController.text.trim();

    setState(() {
      _isPassBaruInvalid = baru.isNotEmpty && !_isPasswordStrong(baru);
      _isKonfirmasiInvalid = konfirmasi.isNotEmpty && baru != konfirmasi;
    });
  }

  bool _isPasswordStrong(String password) {
    return password.length >= 8 &&
        password.contains(RegExp(r'[A-Z]')) &&
        password.contains(RegExp(r'[0-9]'));
  }

  void _onSimpanPassword() async {
    final passwordLama = _passwordLamaController.text.trim();
    final passwordBaru = _passwordBaruController.text.trim();
    final konfirmasiPassword = _konfirmasiPasswordController.text.trim();

    if (passwordLama.isEmpty || passwordBaru.isEmpty || konfirmasiPassword.isEmpty) {
      showCustomSnackBar(context, 'Semua field harus diisi');
      return;
    }

    if (!_isPasswordStrong(passwordBaru)) {
      setState(() => _isPassBaruInvalid = true);
      return;
    }

    if (passwordBaru != konfirmasiPassword) {
      setState(() => _isKonfirmasiInvalid = true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final response =
        await Provider.of<AuthProvider>(context, listen: false).changePassword(
      passwordLama,
      passwordBaru,
      konfirmasiPassword,
    );

    setState(() {
      _isLoading = false;
    });

    if (response['success']) {
      if (!mounted) return;

      await showSuccessBottomSheet(
        context,
        title: 'Berhasil!',
        message: 'Password kamu berhasil diperbarui. '
            'Silakan login kembali dengan password baru.',
        buttonLabel: 'Login Ulang',
      );

      if (!mounted) return;
      await Provider.of<AuthProvider>(context, listen: false).logout();

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => SplashScreen()),
        (route) => false,
      );
    } else {
      if (mounted) {
        showCustomSnackBar(context, response['message'] ?? 'Gagal mengubah password');
      }
    }
  }

  Future<void> _onLupaPasswordLama() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final email = auth.currentUser?.email ?? '';

    if (email.isEmpty) {
      showCustomSnackBar(
          context, 'Email akun tidak ditemukan. Silakan login ulang.');
      return;
    }

    final lanjut = await showConfirmBottomSheet(
      context,
      icon: Icons.mark_email_read_outlined,
      title: 'Reset Lewat Email?',
      message: 'Kode OTP akan dikirim ke $email. Setelah password diganti, '
          'kamu perlu login kembali.',
      confirmLabel: 'Kirim Kode',
    );
    if (!mounted || !lanjut) return;

    setState(() => _isLoading = true);
    final result = await auth.sendEmailForgetPassword(email);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] != true) {
      showCustomSnackBar(
          context, result['message'] ?? 'Gagal mengirim kode OTP');
      return;
    }

    await auth.savePendingReset(email, result['expired_at'] as String?);
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VerifikasiOtpScreen(
          email: email,
          expiredAt: result['expired_at'] as String?,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _passwordLamaController.dispose();
    _passwordBaruController.dispose();
    _konfirmasiPasswordController.dispose();
    super.dispose();
  }

  Widget _buildRequirement(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          Icon(Icons.circle,
              size: 5, color: AppColors.dark.withValues(alpha: 0.5)),
          const SizedBox(width: 6),
          Text(
            text,
            style: AppText.r(11, AppColors.dark.withValues(alpha: 0.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hintText,
    required bool obscureText,
    required VoidCallback toggleObscure,
    bool isInvalid = false,
    String errorText = '',
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          obscureText: obscureText,
          style: AppText.w600(14, Color(0xFF2D3748)),
          decoration: InputDecoration(
            contentPadding:
                const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
            hintText: hintText,
            hintStyle: AppText.r(14, AppColors.dark.withValues(alpha: 0.35)),
            suffixIcon: IconButton(
              icon: Icon(
                obscureText ? Icons.visibility_off : Icons.visibility,
                color: isInvalid
                    ? AppColors.dangerDeep
                    : AppColors.dark.withValues(alpha: 0.5),
              ),
              onPressed: toggleObscure,
            ),
            filled: true,
            fillColor: isInvalid
                ? AppColors.dangerDeep.withValues(alpha: 0.1)
                : AppColors.dark.withValues(alpha: 0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: isInvalid
                  ? const BorderSide(color: AppColors.dangerDeep, width: 1.5)
                  : const BorderSide(color: AppColors.dark, width: 1.5),
            ),
          ),
        ),
        if (isInvalid)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 8),
            child: Text(
              errorText,
              style: AppText.w600(12, AppColors.dangerDeep),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const TopBarBack(title: ""),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 30),
                child: Text(
                  "Ubah Password",
                  style: AppText.w700(20, AppColors.dark),
                ),
              ),
              const SizedBox(height: 15),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 30),
                child: Text(
                  "Masukkan password lama dan password baru kamu untuk meningkatkan keamanan akun.",
                  style: AppText.p(13, color: AppColors.dark, height: 1.5),
                  textAlign: TextAlign.justify,
                ),
              ),
              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPasswordField(
                      controller: _passwordLamaController,
                      hintText: "Password Lama",
                      obscureText: _obscureLama,
                      toggleObscure: () {
                        setState(() {
                          _obscureLama = !_obscureLama;
                        });
                      },
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: _isLoading ? null : _onLupaPasswordLama,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 10, right: 4),
                          child: Text(
                            "Lupa password lama?",
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.dark,
                              decoration: TextDecoration.underline,
                              decorationColor: AppColors.dark,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          width: 1,
                          color: AppColors.dark.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Syarat password baru:",
                            style: AppText.w600(
                                11, AppColors.dark.withValues(alpha: 0.5)),
                          ),
                          const SizedBox(height: 4),
                          _buildRequirement("Minimal 8 karakter"),
                          _buildRequirement("Mengandung huruf kapital (A-Z)"),
                          _buildRequirement("Mengandung angka (0-9)"),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildPasswordField(
                      controller: _passwordBaruController,
                      hintText: "Password Baru",
                      obscureText: _obscureBaru,
                      toggleObscure: () {
                        setState(() {
                          _obscureBaru = !_obscureBaru;
                        });
                      },
                      isInvalid: _isPassBaruInvalid,
                      errorText:
                          "Password minimal 8 karakter, huruf kapital & angka",
                    ),
                    const SizedBox(height: 20),
                    _buildPasswordField(
                      controller: _konfirmasiPasswordController,
                      hintText: "Konfirmasi Password Baru",
                      obscureText: _obscureKonfirmasi,
                      toggleObscure: () {
                        setState(() {
                          _obscureKonfirmasi = !_obscureKonfirmasi;
                        });
                      },
                      isInvalid: _isKonfirmasiInvalid,
                      errorText: "Password tidak cocok",
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        child: Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _isLoading ? null : _onSimpanPassword,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AppColors.dark,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    "Simpan Password",
                    style: AppText.w600(16, Colors.white),
                  ),
          ),
        ),
      ),
    );
  }
}
