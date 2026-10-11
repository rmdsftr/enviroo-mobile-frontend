import 'package:enviroo/providers/auth_provider.dart';
import 'package:enviroo/screens/splash_screen.dart';
import 'package:provider/provider.dart';
import 'package:enviroo/widgets/success_bottom_sheet.dart';
import 'package:enviroo/widgets/custom_snackbar.dart';
import 'package:enviroo/widgets/topbar_back.dart';
import 'package:flutter/material.dart';
import 'package:enviroo/core/theme/app_colors.dart';
import 'package:enviroo/core/theme/app_text.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  final String otp;
  const ResetPasswordScreen({Key? key, required this.email, required this.otp})
      : super(key: key);

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isPasswordInvalid = false;
  bool _isConfirmInvalid = false;
  bool _isLoading = false;

  bool _isPasswordStrong(String password) {
    return password.length >= 8 &&
        password.contains(RegExp(r'[A-Z]')) &&
        password.contains(RegExp(r'[0-9]'));
  }

  void _validateFields() {
    final password = _passwordController.text.trim();
    final confirm = _confirmController.text.trim();

    setState(() {
      _isPasswordInvalid = password.isNotEmpty && !_isPasswordStrong(password);
      _isConfirmInvalid = confirm.isNotEmpty && password != confirm;
    });
  }

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_validateFields);
    _confirmController.addListener(_validateFields);
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _onSimpan() async {
    final password = _passwordController.text.trim();
    final confirm = _confirmController.text.trim();

    if (!_isPasswordStrong(password)) {
      setState(() => _isPasswordInvalid = true);
      return;
    }
    if (password != confirm) {
      setState(() => _isConfirmInvalid = true);
      return;
    }

    setState(() => _isLoading = true);

    final result = await context.read<AuthProvider>().resetPassword(
          widget.email,
          widget.otp,
          password,
          confirm,
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      final auth = context.read<AuthProvider>();

      await auth.clearPendingReset();

      if (!mounted) return;

      final sedangLogin = auth.isLoggedIn;

      await showSuccessBottomSheet(
        context,
        title: 'Password Berhasil Diubah!',
        message: result['message'] ??
            'Password kamu telah berhasil direset. Silakan login kembali dengan password baru.',
        buttonLabel: 'Kembali ke Login',
      );

      if (!mounted) return;

      if (sedangLogin) {
        await auth.logout();
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => SplashScreen()),
          (route) => false,
        );
      } else {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } else {
      showCustomSnackBar(context, result['message'] ?? 'Gagal mereset password');
    }
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
    required bool isInvalid,
    required String errorMsg,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          obscureText: obscure,
          enabled: !_isLoading,
          style: AppText.w600(14, Color(0xFF2D3748)),
          decoration: InputDecoration(
            contentPadding:
                const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
            hintText: hint,
            hintStyle: AppText.r(14, AppColors.dark.withValues(alpha: 0.35)),
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
            suffixIcon: IconButton(
              icon: Icon(
                obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: isInvalid
                    ? AppColors.dangerDeep
                    : AppColors.dark,
                size: 20,
              ),
              onPressed: onToggle,
            ),
          ),
        ),
        if (isInvalid)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 8),
            child: Text(
              errorMsg,
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
                  "Reset Password",
                  style: AppText.w700(20, AppColors.dark),
                ),
              ),
              const SizedBox(height: 15),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Text(
                  "Buat password baru untuk akun ${widget.email}. Pastikan password mudah diingat namun sulit ditebak.",
                  style: AppText.p(13, color: AppColors.dark, height: 1.5),
                  textAlign: TextAlign.justify,
                ),
              ),
              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                        "Syarat password:",
                        style: AppText.w600(11, AppColors.dark.withValues(alpha: 0.5)),
                      ),
                      const SizedBox(height: 4),
                      _buildRequirement("Minimal 8 karakter"),
                      _buildRequirement("Mengandung huruf kapital (A-Z)"),
                      _buildRequirement("Mengandung angka (0-9)"),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Column(
                  children: [
                    _buildPasswordField(
                      controller: _passwordController,
                      hint: "Password baru",
                      obscure: _obscurePassword,
                      onToggle: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                      isInvalid: _isPasswordInvalid,
                      errorMsg:
                          "Password minimal 8 karakter, huruf kapital & angka",
                    ),
                    const SizedBox(height: 16),
                    _buildPasswordField(
                      controller: _confirmController,
                      hint: "Konfirmasi password baru",
                      obscure: _obscureConfirm,
                      onToggle: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                      isInvalid: _isConfirmInvalid,
                      errorMsg: "Password tidak cocok",
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
        child: SafeArea(
          child: SizedBox(
            height: 55,
            width: double.infinity,
            child: Container(
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
                onPressed: _isLoading ? null : _onSimpan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.dark,
                  disabledBackgroundColor:
                      AppColors.dark.withValues(alpha: 0.5),
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
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white),
                        ),
                      )
                    : Text(
                        "Simpan Password Baru",
                        style: AppText.w600(16, Colors.white),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
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
}
