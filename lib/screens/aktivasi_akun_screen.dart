import 'package:enviroo/widgets/custom_snackbar.dart';
import 'package:enviroo/widgets/success_bottom_sheet.dart';
import 'package:enviroo/widgets/topbar_back.dart';
import 'package:enviroo/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AktivasiAkunScreen extends StatefulWidget {
  const AktivasiAkunScreen({super.key});

  @override
  State<AktivasiAkunScreen> createState() => _AktivasiAkunScreenState();
}

class _AktivasiAkunScreenState extends State<AktivasiAkunScreen> {
  // Step 1
  final _nikController  = TextEditingController();
  final _otpController  = TextEditingController();

  // Step 2
  final _passwordController  = TextEditingController();
  final _konfirmasiController = TextEditingController();

  int  _step = 1;
  bool _isLoading = false;

  // Validation flags
  bool _isNikInvalid   = false;
  bool _isOtpInvalid   = false;
  bool _isPassInvalid  = false;
  bool _isKonfInvalid  = false;
  bool _obscurePass    = true;
  bool _obscureKonf    = true;

  static const _teal  = Color(0xFF013236);
  static const _red   = Color(0xFFB61E20);

  @override
  void initState() {
    super.initState();
    _nikController.addListener(() {
      if (_isNikInvalid) setState(() => _isNikInvalid = false);
    });
    _otpController.addListener(() {
      if (_isOtpInvalid) setState(() => _isOtpInvalid = false);
    });
    _passwordController.addListener(() {
      if (_isPassInvalid) setState(() => _isPassInvalid = false);
    });
    _konfirmasiController.addListener(() {
      if (_isKonfInvalid) setState(() => _isKonfInvalid = false);
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

  // ─── Step 1: verifikasi NIK + OTP ───────────────────────────────────────────

  Future<void> _onStep1() async {
    final nik = _nikController.text.trim();
    final otp = _otpController.text.trim();

    bool valid = true;
    if (nik.isEmpty || !RegExp(r'^[0-9]+$').hasMatch(nik)) {
      _isNikInvalid = true;
      valid = false;
    }
    if (otp.length != 6 || !RegExp(r'^[a-zA-Z0-9]{6}$').hasMatch(otp)) {
      _isOtpInvalid = true;
      valid = false;
    }
    setState(() {});
    if (!valid) return;

    setState(() => _isLoading = true);

    // Kirim tanpa password — backend akan kasih tahu apakah password perlu diisi
    final result = await AuthService.aktivasiAkun(nik, otp, '');

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      // Password sudah ada sebelumnya — aktivasi langsung selesai
      await _showSuccess(result['message']);
    } else {
      final msg = result['message'] ?? '';
      if (msg.toLowerCase().contains('password wajib') ||
          msg.toLowerCase().contains('password')) {
        // Password belum pernah di-set — lanjut ke step 2
        setState(() => _step = 2);
      } else {
        showCustomSnackBar(context, msg.isNotEmpty ? msg : 'Aktivasi gagal');
      }
    }
  }

  // ─── Step 2: buat password ──────────────────────────────────────────────────

  Future<void> _onStep2() async {
    final password  = _passwordController.text;
    final konfirmasi = _konfirmasiController.text;

    bool valid = true;
    if (password.length < 8) {
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

    final result = await AuthService.aktivasiAkun(
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

  // ─── Build ──────────────────────────────────────────────────────────────────

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
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      color: _teal,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _step == 1
                        ? 'Masukkan NIK dan kode aktivasi dari Admin untuk memverifikasi akunmu.'
                        : 'Akun ini belum memiliki password. Buat password baru untuk mulai login.',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      height: 1.5,
                      color: _teal.withValues(alpha: 0.65),
                    ),
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

  // ─── Step 1 fields ──────────────────────────────────────────────────────────

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _field(
          controller: _nikController,
          hint: 'Masukkan NIK',
          icon: Icons.badge_rounded,
          isInvalid: _isNikInvalid,
          errorText: 'NIK wajib diisi dengan angka',
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: 15),
        _field(
          controller: _otpController,
          hint: 'Kode OTP (6 karakter)',
          icon: Icons.vpn_key_rounded,
          isInvalid: _isOtpInvalid,
          errorText: 'Kode aktivasi harus 6 karakter alfanumerik',
          maxLength: 6,
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]'))],
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  // ─── Step 2 fields ──────────────────────────────────────────────────────────

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _field(
          controller: _passwordController,
          hint: 'Password baru',
          icon: Icons.lock_rounded,
          isInvalid: _isPassInvalid,
          errorText: 'Password minimal 8 karakter',
          obscure: _obscurePass,
          onToggleObscure: () => setState(() => _obscurePass = !_obscurePass),
        ),
        const SizedBox(height: 15),
        _field(
          controller: _konfirmasiController,
          hint: 'Konfirmasi password baru',
          icon: Icons.lock_outline_rounded,
          isInvalid: _isKonfInvalid,
          errorText: 'Password tidak cocok',
          obscure: _obscureKonf,
          onToggleObscure: () => setState(() => _obscureKonf = !_obscureKonf),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  // ─── Field helper ───────────────────────────────────────────────────────────

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool isInvalid,
    required String errorText,
    bool obscure = false,
    VoidCallback? onToggleObscure,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization textCapitalization = TextCapitalization.none,
    int? maxLength,
  }) {
    final borderColor = isInvalid ? _red : _teal;
    final fillColor = isInvalid
        ? _red.withValues(alpha: 0.08)
        : _teal.withValues(alpha: 0.08);

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
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            color: Color(0xFF2D3748),
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            counterText: '',
            contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
            hintText: hint,
            hintStyle: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: _teal.withValues(alpha: 0.35),
            ),
            prefixIcon: Icon(icon, size: 20, color: borderColor),
            suffixIcon: onToggleObscure != null
                ? IconButton(
                    icon: Icon(
                      obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                      color: _teal.withValues(alpha: 0.5),
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
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: _red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  // ─── Bottom bar ─────────────────────────────────────────────────────────────

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
              backgroundColor: _teal,
              disabledBackgroundColor: _teal.withValues(alpha: 0.5),
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
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
