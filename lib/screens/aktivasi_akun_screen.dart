import 'package:enviroo/widgets/custom_snackbar.dart';
import 'package:enviroo/widgets/success_bottom_sheet.dart';
import 'package:enviroo/widgets/topbar_back.dart';
import 'package:enviroo/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:enviroo/core/theme/app_colors.dart';
import 'package:enviroo/core/theme/app_text.dart';

class AktivasiAkunScreen extends StatefulWidget {
  const AktivasiAkunScreen({super.key});

  @override
  State<AktivasiAkunScreen> createState() => _AktivasiAkunScreenState();
}

class _AktivasiAkunScreenState extends State<AktivasiAkunScreen> {
  final _nikController  = TextEditingController();
  final _otpController  = TextEditingController();

  final _passwordController  = TextEditingController();
  final _konfirmasiController = TextEditingController();

  int  _step = 1;
  bool _isLoading = false;

  bool _isNikInvalid   = false;
  bool _isOtpInvalid   = false;
  bool _isPassInvalid  = false;
  bool _isKonfInvalid  = false;
  bool _obscurePass    = true;
  bool _obscureKonf    = true;


  @override
  void initState() {
    super.initState();
    _nikController.addListener(() {
      if (_isNikInvalid) setState(() => _isNikInvalid = false);
    });
    _otpController.addListener(() {
      if (_isOtpInvalid) setState(() => _isOtpInvalid = false);
    });
    _passwordController.addListener(_validatePasswordFields);
    _konfirmasiController.addListener(_validatePasswordFields);
  }

  void _validatePasswordFields() {
    final password = _passwordController.text.trim();
    final konfirmasi = _konfirmasiController.text.trim();

    setState(() {
      _isPassInvalid = password.isNotEmpty && !_isPasswordStrong(password);
      _isKonfInvalid = konfirmasi.isNotEmpty && password != konfirmasi;
    });
  }

  @override
  void dispose() {
    _nikController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _konfirmasiController.dispose();
    super.dispose();
  }

  Future<void> _onStep1() async {
    final nik = _nikController.text.trim();
    final otp = _otpController.text.trim();

    bool valid = true;
    if (nik.isEmpty || !RegExp(r'^[0-9]+$').hasMatch(nik)) {
      _isNikInvalid = true;
      valid = false;
    }
    if (!RegExp(r'^[0-9]{6}$').hasMatch(otp)) {
      _isOtpInvalid = true;
      valid = false;
    }
    setState(() {});
    if (!valid) return;

    setState(() => _isLoading = true);

    final result =
        await context.read<AuthProvider>().aktivasiAkun(nik, otp, '');

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      await _showSuccess(result['message']);
    } else {
      final msg = result['message'] ?? '';

      final perluPassword = result['code'] == 'PASSWORD_REQUIRED' ||
          msg.toLowerCase().contains('password');

      if (perluPassword) {
        setState(() => _step = 2);
      } else {
        showCustomSnackBar(context, msg.isNotEmpty ? msg : 'Aktivasi gagal');
      }
    }
  }

  bool _isPasswordStrong(String password) {
    return password.length >= 8 &&
        password.contains(RegExp(r'[A-Z]')) &&
        password.contains(RegExp(r'[0-9]'));
  }

  Future<void> _onStep2() async {
    final password  = _passwordController.text.trim();
    final konfirmasi = _konfirmasiController.text.trim();

    bool valid = true;
    if (!_isPasswordStrong(password)) {
      _isPassInvalid = true;
      valid = false;
    }
    if (konfirmasi != password) {
      _isKonfInvalid = true;
      valid = false;
    }
    setState(() {});
    if (!valid) return;

    setState(() => _isLoading = true);

    final result = await context.read<AuthProvider>().aktivasiAkun(
          _nikController.text.trim(),
          _otpController.text.trim(),
          password,
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      await _showSuccess(result['message']);
    } else {
      showCustomSnackBar(context, result['message'] ?? 'Aktivasi gagal');
    }
  }

  Future<void> _showSuccess(String? message) async {
    await showSuccessBottomSheet(
      context,
      title: 'Aktivasi Berhasil!',
      message: message ?? 'Akun kamu telah berhasil diaktivasi.\nSilakan login menggunakan email dan password.',
      buttonLabel: 'Kembali ke Login',
      onDismiss: () => Navigator.pop(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TopBarBack(
              title: '',
              onBack: _step == 2
                  ? () => setState(() {
                        _step = 1;
                        _passwordController.clear();
                        _konfirmasiController.clear();
                        _isPassInvalid = false;
                        _isKonfInvalid = false;
                      })
                  : null,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _step == 1 ? 'Aktivasi Akun' : 'Buat Password',
                    style: AppText.w700(20, AppColors.dark),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _step == 1
                        ? 'Masukkan ID Pengguna dan kode aktivasi dari Admin untuk memverifikasi akunmu.'
                        : 'Akun ini belum memiliki password. Buat password baru untuk mulai login.',
                    style: AppText.p(13, color: AppColors.dark.withValues(alpha: 0.65), height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: _step == 1 ? _buildStep1() : _buildStep2(),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _field(
          controller: _nikController,
          hint: 'Masukkan ID Pengguna',
          icon: Icons.badge_rounded,
          isInvalid: _isNikInvalid,
          errorText: 'ID Pengguna wajib diisi dengan angka',
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: 15),
        _field(
          controller: _otpController,
          hint: 'Kode OTP (6 digit)',
          icon: Icons.vpn_key_rounded,
          isInvalid: _isOtpInvalid,
          errorText: 'Kode aktivasi harus 6 digit angka',
          maxLength: 6,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
        const SizedBox(height: 20),
        _field(
          controller: _passwordController,
          hint: 'Password baru',
          isInvalid: _isPassInvalid,
          errorText: 'Password minimal 8 karakter, huruf kapital & angka',
          obscure: _obscurePass,
          onToggleObscure: () => setState(() => _obscurePass = !_obscurePass),
        ),
        const SizedBox(height: 15),
        _field(
          controller: _konfirmasiController,
          hint: 'Konfirmasi password baru',
          isInvalid: _isKonfInvalid,
          errorText: 'Password tidak cocok',
          obscure: _obscureKonf,
          onToggleObscure: () => setState(() => _obscureKonf = !_obscureKonf),
        ),
        const SizedBox(height: 10),
      ],
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

  Widget _field({
    required TextEditingController controller,
    required String hint,
    IconData? icon,
    required bool isInvalid,
    required String errorText,
    bool obscure = false,
    VoidCallback? onToggleObscure,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization textCapitalization = TextCapitalization.none,
    int? maxLength,
  }) {
    final borderColor = isInvalid ? AppColors.dangerDeep : AppColors.dark;
    final fillColor = isInvalid
        ? AppColors.dangerDeep.withValues(alpha: 0.08)
        : AppColors.dark.withValues(alpha: 0.08);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          textCapitalization: textCapitalization,
          maxLength: maxLength,
          style: AppText.w600(14, Color(0xFF2D3748)),
          decoration: InputDecoration(
            counterText: '',
            contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
            hintText: hint,
            hintStyle: AppText.r(14, AppColors.dark.withValues(alpha: 0.35)),
            prefixIcon:
                icon == null ? null : Icon(icon, size: 20, color: borderColor),
            suffixIcon: onToggleObscure != null
                ? IconButton(
                    icon: Icon(
                      obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                      color: AppColors.dark.withValues(alpha: 0.5),
                      size: 20,
                    ),
                    onPressed: onToggleObscure,
                  )
                : null,
            filled: true,
            fillColor: fillColor,
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
              borderSide: BorderSide(color: borderColor, width: 1.5),
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

  Widget _buildBottomBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
      child: SafeArea(
        child: SizedBox(
          height: 50,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : (_step == 1 ? _onStep1 : _onStep2),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.dark,
              disabledBackgroundColor: AppColors.dark.withValues(alpha: 0.5),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    _step == 1 ? 'Verifikasi' : 'Aktivasi Akun',
                    style: AppText.w600(14, Colors.white),
                  ),
          ),
        ),
      ),
    );
  }
}
