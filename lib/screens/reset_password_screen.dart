import 'package:enviroo/services/auth_service.dart';
import 'package:enviroo/widgets/success_bottom_sheet.dart';
import 'package:enviroo/widgets/topbar_back.dart';
import 'package:flutter/material.dart';

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

  // Password minimal 8 karakter, huruf besar, angka
  bool _isPasswordStrong(String password) {
    return password.length >= 8 &&
        password.contains(RegExp(r'[A-Z]')) &&
        password.contains(RegExp(r'[0-9]'));
  }

  void _validateFields() {
    setState(() {
      _isPasswordInvalid = _passwordController.text.isNotEmpty &&
          !_isPasswordStrong(_passwordController.text);
      _isConfirmInvalid = _confirmController.text.isNotEmpty &&
          _passwordController.text != _confirmController.text;
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
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    // Validasi client-side
    if (!_isPasswordStrong(password)) {
      setState(() => _isPasswordInvalid = true);
      return;
    }
    if (password != confirm) {
      setState(() => _isConfirmInvalid = true);
      return;
    }

    setState(() => _isLoading = true);

    final result = await AuthService.resetPassword(
      widget.email,
      widget.otp,
      password,
      confirm,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      await showSuccessBottomSheet(
        context,
        title: 'Password Berhasil Diubah!',
        message: result['message'] ??
            'Password kamu telah berhasil direset. Silakan login kembali dengan password baru.',
        buttonLabel: 'Kembali ke Login',
        onDismiss: () => Navigator.of(context).popUntil((route) => route.isFirst),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Gagal mereset password'),
          backgroundColor: const Color(0xFFB61E20),
        ),
      );
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
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            color: Color(0xFF2D3748),
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            contentPadding:
                const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
            hintText: hint,
            hintStyle: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: const Color(0xFF013236).withOpacity(0.35),
            ),
            filled: true,
            fillColor: isInvalid
                ? const Color(0xFFB61E20).withOpacity(0.1)
                : const Color(0xFF013236).withOpacity(0.1),
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
                  ? const BorderSide(color: Color(0xFFB61E20), width: 1.5)
                  : const BorderSide(color: Color(0xFF013236), width: 1.5),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: isInvalid
                    ? const Color(0xFFB61E20)
                    : const Color(0xFF013236),
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
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: Color(0xFFB61E20),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const TopBarBack(title: ""),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 30),
                child: Text(
                  "Reset Password",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF013236),
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(height: 15),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Text(
                  "Buat password baru untuk akun ${widget.email}. Pastikan password mudah diingat namun sulit ditebak.",
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    height: 1.5,
                    color: Color(0xFF013236),
                  ),
                  textAlign: TextAlign.justify,
                ),
              ),
              const SizedBox(height: 30),
              // Syarat password
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
                      color: const Color(0xFF013236).withOpacity(0.25),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Syarat password:",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF013236).withOpacity(0.5),
                        ),
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
              const SizedBox(height: 20), // Extra space to scroll if keyboard shows up
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        color: const Color(0xFFFFFFFF),
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
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _onSimpan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF013236),
                  disabledBackgroundColor:
                      const Color(0xFF013236).withOpacity(0.5),
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
                              Color(0xFFFFFFFF)),
                        ),
                      )
                    : const Text(
                        "Simpan Password Baru",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFFFFFFF),
                        ),
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
              size: 5, color: const Color(0xFF013236).withOpacity(0.5)),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              color: const Color(0xFF013236).withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}
