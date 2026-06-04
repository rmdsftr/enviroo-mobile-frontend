import 'dart:async';
import 'package:enviroo/screens/reset_password_screen.dart';
import 'package:enviroo/services/auth_service.dart';
import 'package:enviroo/widgets/topbar_back.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class VerifikasiOtpScreen extends StatefulWidget {
  final String email;
  const VerifikasiOtpScreen({Key? key, required this.email}) : super(key: key);

  @override
  State<VerifikasiOtpScreen> createState() => _VerifikasiOtpScreenState();
}

class _VerifikasiOtpScreenState extends State<VerifikasiOtpScreen> {
  // 6 controller & focusNode untuk setiap kotak OTP
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isOtpInvalid = false;
  String _errorMessage = '';
  bool _isLoading = false;

  // Timer countdown 10 menit (backend menetapkan expiry, timer ini hanya UI)
  late Timer _timer;
  int _secondsRemaining = 10 * 60;
  bool _isExpired = false;
  bool _isResending = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
    for (final f in _focusNodes) {
      f.addListener(() => setState(() {}));
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining == 0) {
        timer.cancel();
        setState(() => _isExpired = true);
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  Future<void> _resendOtp() async {
    setState(() => _isResending = true);

    final result = await AuthService.sendEmailForgetPassword(widget.email);

    if (!mounted) return;
    setState(() => _isResending = false);

    if (result['success'] == true) {
      // Reset timer dan bersihkan seluruh kotak OTP
      _timer.cancel();
      for (final c in _controllers) {
        c.clear();
      }
      setState(() {
        _secondsRemaining = 10 * 60;
        _isExpired = false;
        _isOtpInvalid = false;
        _errorMessage = '';
      });
      // Fokuskan kursor ke kotak pertama
      FocusScope.of(context).requestFocus(_focusNodes[0]);
      _startTimer();

      // Tampilkan snackbar sukses yang informatif
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: const Color(0xFF013236),
            duration: const Duration(seconds: 4),
            content: Row(
              children: [
                const Icon(Icons.mark_email_read_outlined,
                    color: Color(0xFF4EA771), size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Kode OTP baru telah dikirim!',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: Color(0xFFFFFFFF),
                        ),
                      ),
                      Text(
                        'Cek email ${widget.email}. Berlaku 10 menit.',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: Color(0xFFFFFFFF),
                          height: 1.4,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
    } else {
      // Tampilkan snackbar error
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: const Color(0xFFB61E20),
            duration: const Duration(seconds: 4),
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded,
                    color: Color(0xFFFFFFFF), size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    result['message'] ?? 'Gagal mengirim ulang OTP',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      color: Color(0xFFFFFFFF),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
    }
  }

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
        _errorMessage = 'Kode OTP harus diisi lengkap (6 karakter)';
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

    final result = await AuthService.verifikasiOtpForgetPassword(
        widget.email, otp);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      // Lanjut ke reset password — kirim email & otp agar bisa dipakai di step 3
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
    if (value.isNotEmpty) {
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

    if (_isOtpInvalid) {
      setState(() {
        _isOtpInvalid = false;
        _errorMessage = '';
      });
    }
  }

  @override
  void dispose() {
    _timer.cancel();
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
                  "Verifikasi Kode OTP",
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
                  "Masukkan 6 karakter kode OTP yang telah dikirim ke ${widget.email} agar bisa melakukan reset password. Kode OTP hanya berlaku selama 10 menit",
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    height: 1.5,
                    color: Color(0xFF013236),
                  ),
                  textAlign: TextAlign.justify,
                ),
              ),
              const SizedBox(height: 28),

              // ── 6 Kotak OTP ────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(6, (index) => _buildOtpBox(index)),
                ),
              ),

              // Pesan error
              if (_isOtpInvalid)
                Padding(
                  padding: const EdgeInsets.only(top: 10, left: 33),
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: Color(0xFFB61E20),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              // ── Timer & Kirim Ulang ─────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Timer countdown
                    Row(
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 18,
                          color: _isExpired
                              ? const Color(0xFFB61E20)
                              : const Color(0xFF013236).withOpacity(0.6),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _isExpired ? "Kode kadaluarsa" : _formattedTime,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _isExpired
                                ? const Color(0xFFB61E20)
                                : const Color(0xFF013236).withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),

                    // Tombol kirim ulang
                    GestureDetector(
                      onTap: (_isExpired && !_isResending) ? _resendOtp : null,
                      child: _isResending
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF013236),
                              ),
                            )
                          : Text(
                              "Kirim Ulang",
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _isExpired
                                    ? const Color(0xFF013236)
                                    : const Color(0xFF013236).withOpacity(0.3),
                                decoration: TextDecoration.underline,
                                decorationColor: _isExpired
                                    ? const Color(0xFF013236)
                                    : const Color(0xFF013236).withOpacity(0.3),
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

      // ── Bottom Button ─────────────────────────────────────────────────
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
                onPressed: (_isLoading || _isExpired) ? null : _onKonfirmasi,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF013236),
                  disabledBackgroundColor:
                      const Color(0xFF013236).withOpacity(0.4),
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
                        "Konfirmasi Kode OTP",
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
              ? const Color(0xFFB61E20).withOpacity(0.08)
              : hasValue
                  ? const Color(0xFF013236).withOpacity(0.08)
                  : const Color(0xFF013236).withOpacity(0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _isOtpInvalid
                ? const Color(0xFFB61E20)
                : isActive
                    ? const Color(0xFF013236)
                    : hasValue
                        ? const Color(0xFF013236).withOpacity(0.5)
                        : Colors.transparent,
            width: isActive ? 1.8 : 1.2,
          ),
        ),
        child: TextField(
          controller: _controllers[index],
          focusNode: _focusNodes[index],
          textAlign: TextAlign.center,
          keyboardType: TextInputType.text,
          textCapitalization: TextCapitalization.characters,
          maxLength: 1,
          enabled: !_isLoading,
          onChanged: (val) => _onOtpChanged(val, index),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
            LengthLimitingTextInputFormatter(1),
          ],
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF013236),
          ),
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
