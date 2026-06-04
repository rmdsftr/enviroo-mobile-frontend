import 'package:enviroo/screens/verifikasi_otp_screen.dart';
import 'package:enviroo/services/auth_service.dart';
import 'package:enviroo/widgets/success_bottom_sheet.dart';
import 'package:enviroo/widgets/topbar_back.dart';
import 'package:flutter/material.dart';

class LupaPasswordScreen extends StatefulWidget {
  const LupaPasswordScreen({Key? key}) : super(key: key);

  @override
  State<LupaPasswordScreen> createState() => _LupaPasswordState();
}

class _LupaPasswordState extends State<LupaPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isEmailInvalid = false;
  String _errorMessage = '';
  bool _isLoading = false;

  void _validateEmail() {
    final email = _emailController.text.trim();
    final isValid = RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$').hasMatch(email);
    setState(() {
      _isEmailInvalid = email.isNotEmpty && !isValid;
      if (!_isEmailInvalid) _errorMessage = '';
    });
  }

  Future<void> _onKonfirmasi() async {
    final email = _emailController.text.trim();

    // Validasi format email
    final isValid = RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$').hasMatch(email);
    if (email.isEmpty || !isValid) {
      setState(() {
        _isEmailInvalid = true;
        _errorMessage = 'Masukkan alamat email yang valid';
      });
      return;
    }

    setState(() => _isLoading = true);

    final result = await AuthService.sendEmailForgetPassword(email);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      // Tampilkan bottom sheet sukses lalu navigasi ke verifikasi OTP
      await showSuccessBottomSheet(
        context,
        title: 'Cek Email Kamu!',
        message: 'Kode OTP untuk reset password telah dikirim ke\n$email',
        buttonLabel: 'Masukkan Kode OTP',
        onDismiss: () {},
      );

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VerifikasiOtpScreen(email: email),
        ),
      );
    } else {
      // Tampilkan error dari backend
      setState(() {
        _isEmailInvalid = true;
        _errorMessage = result['message'] ?? 'Email tidak terdaftar';
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_validateEmail);
  }

  @override
  void dispose() {
    _emailController.dispose();
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
                  "Lupa Password",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF013236),
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(height: 15),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 30),
                child: Text(
                  "Masukkan alamat email yang terdaftar sebagai akun nasabah ataupun akun petugas kamu. Kode OTP untuk melakukan reset password akan dikirimkan melalui email tersebut",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    height: 1.5,
                    color: Color(0xFF013236),
                  ),
                  textAlign: TextAlign.justify,
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      enabled: !_isLoading,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        color: Color(0xFF2D3748),
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 18, horizontal: 20),
                        hintText: "example@gmail.com",
                        hintStyle: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          color: const Color(0xFF013236).withOpacity(0.35),
                        ),
                        prefixIcon: Icon(
                          Icons.email_rounded,
                          color: _isEmailInvalid
                              ? const Color(0xFFB61E20)
                              : const Color(0xFF013236),
                        ),
                        filled: true,
                        fillColor: _isEmailInvalid
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
                          borderSide: _isEmailInvalid
                              ? const BorderSide(color: Color(0xFFB61E20), width: 1.5)
                              : const BorderSide(color: Color(0xFF013236), width: 1.5),
                        ),
                      ),
                    ),
                    if (_isEmailInvalid)
                      Padding(
                        padding: const EdgeInsets.only(top: 10, left: 8),
                        child: Text(
                          _errorMessage.isNotEmpty
                              ? _errorMessage
                              : 'Email tidak valid',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: Color(0xFFB61E20),
                            fontWeight: FontWeight.w600,
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
                onPressed: _isLoading ? null : _onKonfirmasi,
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
                        "Dapatkan Kode OTP",
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
}
