import 'dart:async';
import 'package:enviroo/screens/reset_password_screen.dart';
import 'package:enviroo/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:enviroo/widgets/custom_snackbar.dart';
import 'package:enviroo/widgets/topbar_back.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:enviroo/core/theme/app_colors.dart';
import 'package:enviroo/core/theme/app_text.dart';

class VerifikasiOtpScreen extends StatefulWidget {
  final String email;

  final String? expiredAt;

  const VerifikasiOtpScreen({
    Key? key,
    required this.email,
    this.expiredAt,
  }) : super(key: key);

  @override
  State<VerifikasiOtpScreen> createState() => _VerifikasiOtpScreenState();
}

class _VerifikasiOtpScreenState extends State<VerifikasiOtpScreen>
    with WidgetsBindingObserver {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isOtpInvalid = false;
  String _errorMessage = '';
  bool _isLoading = false;

  static const Duration _masaBerlakuDefault = Duration(minutes: 10);
  static const Duration _jedaKirimUlang = Duration(seconds: 60);

  Timer? _timer;
  DateTime? _kadaluarsaPada;
  DateTime? _kirimUlangPada;

  int _secondsRemaining = 0;
  int _resendCooldown = 0;
  bool _isExpired = false;
  bool _isResending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _kadaluarsaPada = _hitungKadaluarsa(widget.expiredAt);
    _kirimUlangPada = DateTime.now().add(_jedaKirimUlang);
    _startTimer();
    for (var i = 0; i < 6; i++) {
      _focusNodes[i].addListener(() {
        if (_focusNodes[i].hasFocus && _controllers[i].text.isNotEmpty) {
          _controllers[i].selection = TextSelection(
            baseOffset: 0,
            extentOffset: _controllers[i].text.length,
          );
        }
        setState(() {});
      });
    }
  }

  DateTime _hitungKadaluarsa(String? expiredAt) {
    final sekarang = DateTime.now();
    final parsed = expiredAt == null ? null : DateTime.tryParse(expiredAt);
    if (parsed == null) return sekarang.add(_masaBerlakuDefault);

    final sisa = parsed.difference(sekarang);
    if (sisa <= Duration.zero || sisa > const Duration(minutes: 30)) {
      return sekarang.add(_masaBerlakuDefault);
    }
    return parsed.toLocal();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => setState(_hitungSisa),
    );
    _hitungSisa();
  }

  void _hitungSisa() {
    final sekarang = DateTime.now();
    final sisaOtp = _kadaluarsaPada!.difference(sekarang).inSeconds;
    final sisaJeda = _kirimUlangPada == null
        ? 0
        : _kirimUlangPada!.difference(sekarang).inSeconds;

    _secondsRemaining = sisaOtp > 0 ? sisaOtp : 0;
    _isExpired = sisaOtp <= 0;
    _resendCooldown = sisaJeda > 0 ? sisaJeda : 0;

    if (_isExpired && _resendCooldown == 0) {
      _timer?.cancel();
      _timer = null;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    setState(_hitungSisa);
    if (_timer == null && (!_isExpired || _resendCooldown > 0)) {
      _startTimer();
    }
  }

  Future<void> _resendOtp() async {
    setState(() => _isResending = true);

    final result = await context
        .read<AuthProvider>()
        .sendEmailForgetPassword(widget.email);

    if (!mounted) return;
    setState(() => _isResending = false);

    if (result['success'] == true) {
      await context
          .read<AuthProvider>()
          .savePendingReset(widget.email, result['expired_at'] as String?);

      if (!mounted) return;

      for (final c in _controllers) {
        c.clear();
      }
      setState(() {
        _kadaluarsaPada = _hitungKadaluarsa(result['expired_at'] as String?);
        _kirimUlangPada = DateTime.now().add(_jedaKirimUlang);
        _isOtpInvalid = false;
        _errorMessage = '';
      });
      FocusScope.of(context).requestFocus(_focusNodes[0]);
      _startTimer();

      showCustomSnackBar(
        context,
        'Kode OTP baru telah dikirim!',
        subtitle: 'Cek email ${widget.email}. Berlaku $_formattedTime lagi.',
        type: SnackBarType.info,
        icon: Icons.mark_email_read_outlined,
        hideCurrent: true,
      );
    } else {
      showCustomSnackBar(
        context,
        result['message'] ?? 'Gagal mengirim ulang OTP',
        hideCurrent: true,
      );
    }
  }

  bool get _bisaKirimUlang => _resendCooldown == 0 && !_isResending;

  String get _formattedTime {
    final minutes = _secondsRemaining ~/ 60;
    final seconds = _secondsRemaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get _otpValue =>
      _controllers.map((c) => c.text.trim()).join();

  Future<void> _onKonfirmasi() async {
    final otp = _otpValue;

    if (otp.length < 6) {
      setState(() {
        _isOtpInvalid = true;
        _errorMessage = 'Kode OTP harus diisi lengkap (6 digit)';
      });
      return;
    }

    if (_isExpired) {
      setState(() {
        _isOtpInvalid = true;
        _errorMessage = 'Kode OTP sudah kadaluarsa. Silakan kirim ulang.';
      });
      return;
    }

    setState(() => _isLoading = true);

    final result = await context
        .read<AuthProvider>()
        .verifikasiOtpForgetPassword(widget.email, otp);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResetPasswordScreen(
            email: widget.email,
            otp: otp,
          ),
        ),
      );
    } else {
      setState(() {
        _isOtpInvalid = true;
        _errorMessage = result['message'] ?? 'Kode OTP salah';
      });
    }
  }

  void _onOtpChanged(String value, int index) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.length > 1) {
      _distributeCode(digits, index);
      return;
    }

    if (digits != value) {
      _controllers[index].text = digits;
    }

    if (digits.isNotEmpty) {
      if (index < 5) {
        FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
      } else {
        _focusNodes[index].unfocus();
      }
    } else {
      if (index > 0) {
        FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
      }
    }

    _clearError();
  }

  void _distributeCode(String digits, int index) {
    final start = digits.length >= 6 ? 0 : index;
    var lastFilled = start;

    for (var i = 0; i < digits.length && start + i < 6; i++) {
      _controllers[start + i].text = digits[i];
      lastFilled = start + i;
    }

    if (lastFilled < 5) {
      FocusScope.of(context).requestFocus(_focusNodes[lastFilled + 1]);
    } else {
      _focusNodes[lastFilled].unfocus();
    }

    _clearError();
    setState(() {});
  }

  void _clearError() {
    if (_isOtpInvalid) {
      setState(() {
        _isOtpInvalid = false;
        _errorMessage = '';
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
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
                  "Verifikasi Kode OTP",
                  style: AppText.w700(20, AppColors.dark),
                ),
              ),
              const SizedBox(height: 15),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Text(
                  "Masukkan 6 digit kode OTP yang telah dikirim ke ${widget.email} agar bisa melakukan reset password. Kode OTP hanya berlaku selama 10 menit",
                  style: AppText.p(13, color: AppColors.dark, height: 1.5),
                  textAlign: TextAlign.justify,
                ),
              ),
              const SizedBox(height: 28),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(6, (index) => _buildOtpBox(index)),
                ),
              ),

              if (_isOtpInvalid)
                Padding(
                  padding: const EdgeInsets.only(top: 10, left: 33),
                  child: Text(
                    _errorMessage,
                    style: AppText.w600(12, AppColors.dangerDeep),
                  ),
                ),

              const SizedBox(height: 24),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 18,
                          color: _isExpired
                              ? AppColors.dangerDeep
                              : AppColors.dark.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _isExpired ? "Kode kadaluarsa" : _formattedTime,
                          style: AppText.w600(13, _isExpired
                                ? AppColors.dangerDeep
                                : AppColors.dark.withValues(alpha: 0.6)),
                        ),
                      ],
                    ),

                    GestureDetector(
                      onTap: _bisaKirimUlang ? _resendOtp : null,
                      child: _isResending
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.dark,
                              ),
                            )
                          : Text(
                              _resendCooldown > 0
                                  ? "Kirim Ulang (${_resendCooldown}s)"
                                  : "Kirim Ulang",
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _bisaKirimUlang
                                    ? AppColors.dark
                                    : AppColors.dark.withValues(alpha: 0.3),
                                decoration: TextDecoration.underline,
                                decorationColor: _bisaKirimUlang
                                    ? AppColors.dark
                                    : AppColors.dark.withValues(alpha: 0.3),
                              ),
                            ),
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
                onPressed: (_isLoading || _isExpired) ? null : _onKonfirmasi,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.dark,
                  disabledBackgroundColor:
                      AppColors.dark.withValues(alpha: 0.4),
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
                        "Konfirmasi Kode OTP",
                        style: AppText.w600(16, Colors.white),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOtpBox(int index) {
    final isActive = _focusNodes[index].hasFocus;
    final hasValue = _controllers[index].text.isNotEmpty;

    return SizedBox(
      width: 48,
      height: 58,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: _isOtpInvalid
              ? AppColors.dangerDeep.withValues(alpha: 0.08)
              : hasValue
                  ? AppColors.dark.withValues(alpha: 0.08)
                  : AppColors.dark.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _isOtpInvalid
                ? AppColors.dangerDeep
                : isActive
                    ? AppColors.dark
                    : hasValue
                        ? AppColors.dark.withValues(alpha: 0.5)
                        : Colors.transparent,
            width: isActive ? 1.8 : 1.2,
          ),
        ),
        child: TextField(
          controller: _controllers[index],
          focusNode: _focusNodes[index],
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          enabled: !_isLoading,
          onChanged: (val) => _onOtpChanged(val, index),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: AppText.w700(20, AppColors.dark),
          decoration: const InputDecoration(
            border: InputBorder.none,
            counterText: '',
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ),
    );
  }
}
