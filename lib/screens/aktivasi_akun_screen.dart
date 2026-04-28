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
  final TextEditingController _nikController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _isNikInvalid = false;
  bool _isOtpInvalid = false;
  bool _isPasswordInvalid = false;
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isReactivating = false;

  void _onKonfirmasi() async {
    final nik = _nikController.text.trim();
    final otp = _otpController.text.trim();
    final password = _passwordController.text;
    
    bool isValid = true;

    if (nik.isEmpty || !RegExp(r'^[0-9]+$').hasMatch(nik)) {
      _isNikInvalid = true;
      isValid = false;
    } else {
      _isNikInvalid = false;
    }

    if (otp.length != 6 || !RegExp(r'^[a-zA-Z0-9]{6}$').hasMatch(otp)) {
      _isOtpInvalid = true;
      isValid = false;
    } else {
      _isOtpInvalid = false;
    }

    if (!_isReactivating) {
      if (password.length < 8) {
        _isPasswordInvalid = true;
        isValid = false;
      } else {
        _isPasswordInvalid = false;
      }
    }
    
    setState(() {});

    if (!isValid) return;

    setState(() {
      _isLoading = true;
    });

    final Map<String, dynamic> result;
    if (_isReactivating) {
      result = await AuthService.reactivateAkun(nik, otp);
    } else {
      result = await AuthService.aktivasiAkun(nik, otp, password);
    }

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (result['success'] == true) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: const Color(0xFFFFFFFF),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4EA771).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_outline,
                    size: 40,
                    color: Color(0xFF013236),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Aktivasi Berhasil!",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF013236),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  result['message'] ?? "Akun kamu telah berhasil diaktivasi.\nSilakan login menggunakan email dan password yang terdaftar.",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    height: 1.6,
                    color: Color(0xFF2D3748),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Tutup dialog
                      Navigator.pop(context); // Kembali ke login screen
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4EA771),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      "Kembali ke Login",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFFFFFFF),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      // Tampilkan notifikasi gagal
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Aktivasi gagal'),
          backgroundColor: const Color(0xFFB61E20),
        ),
      );
    }
  }

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
      if (_isPasswordInvalid) setState(() => _isPasswordInvalid = false);
    });
  }

  @override
  void dispose() {
    _nikController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const TopBarBack(title: ""),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 30),
              child: Text(
                "Aktivasi Akun",
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF013236),
                    fontSize: 20
                ),
              ),
            ),
            const SizedBox(height: 15),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Text(
                _isReactivating 
                  ? "Masukkan NIK dan kode aktivasi baru untuk mengaktifkan kembali akunmu."
                  : "Masukkan NIK, kode aktivasi dari Admin, dan buat password baru agar akunmu bisa digunakan.",
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  height: 1.5,
                  color: Color(0xFF013236),
                ),
                textAlign: TextAlign.justify,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // NIK Field
                      TextField(
                        controller: _nikController,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          color: Color(0xFF2D3748),
                          fontWeight: FontWeight.w600,
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 18, horizontal: 20),
                          hintText: "Masukkan NIK / ID User",
                          counterText: "",
                          hintStyle: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            color: const Color(0xFF013236).withOpacity(0.35),
                          ),
                          prefixIcon: Icon(
                            Icons.badge_rounded,
                            color: _isNikInvalid
                                ? const Color(0xFFB61E20)
                                : const Color(0xFF013236),
                          ),
                          filled: true,
                          fillColor: _isNikInvalid
                              ? const Color(0xFFB61E20).withOpacity(0.1)
                              : const Color(0xFF013236).withOpacity(0.1),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide.none
                          ),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: _isNikInvalid
                                  ? const BorderSide(
                                  color: Color(0xFFB61E20),
                                  width: 1.5
                              ) : const BorderSide(
                                  color: Color(0xFF013236),
                                  width: 1.5
                              )
                          ),
                        ),
                      ),
                      if (_isNikInvalid)
                        const Padding(
                          padding: EdgeInsets.only(top: 8, left: 8),
                          child: Text(
                            "NIK wajib diisi dengan angka",
                            style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                color: Color(0xFFB61E20),
                                fontWeight: FontWeight.w600
                            ),
                          ),
                        ),
                      const SizedBox(height: 15),

                      // OTP Field
                      TextField(
                        controller: _otpController,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          color: Color(0xFF2D3748),
                          fontWeight: FontWeight.w600,
                        ),
                        maxLength: 6,
                        textCapitalization: TextCapitalization.characters,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                        ],
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 18, horizontal: 20),
                          hintText: "Kode OTP: H5YUIO",
                          counterText: "",
                          hintStyle: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            color: const Color(0xFF013236).withOpacity(0.35),
                          ),
                          prefixIcon: Icon(
                            Icons.vpn_key_rounded,
                            color: _isOtpInvalid
                                ? const Color(0xFFB61E20)
                                : const Color(0xFF013236),
                          ),
                          filled: true,
                          fillColor: _isOtpInvalid
                              ? const Color(0xFFB61E20).withOpacity(0.1)
                              : const Color(0xFF013236).withOpacity(0.1),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide.none
                          ),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: _isOtpInvalid
                                  ? const BorderSide(
                                  color: Color(0xFFB61E20),
                                  width: 1.5
                              ) : const BorderSide(
                                  color: Color(0xFF013236),
                                  width: 1.5
                              )
                          ),
                        ),
                      ),
                      if (_isOtpInvalid)
                        const Padding(
                          padding: EdgeInsets.only(top: 8, left: 8),
                          child: Text(
                            "Kode aktivasi harus berupa 6 karakter alfanumerik",
                            style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                color: Color(0xFFB61E20),
                                fontWeight: FontWeight.w600
                            ),
                          ),
                        ),
                      const SizedBox(height: 15),
                      // Password Field (Conditionally shown)
                      if (!_isReactivating) ...[
                        TextField(
                          controller: _passwordController,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            color: Color(0xFF2D3748),
                            fontWeight: FontWeight.w600,
                          ),
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 18, horizontal: 20),
                            hintText: "Buat Password Baru",
                            hintStyle: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              color: const Color(0xFF013236).withOpacity(0.35),
                            ),
                            prefixIcon: Icon(
                              Icons.lock_rounded,
                              color: _isPasswordInvalid
                                  ? const Color(0xFFB61E20)
                                  : const Color(0xFF013236),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                color: const Color(0xFF013236).withOpacity(0.6),
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            filled: true,
                            fillColor: _isPasswordInvalid
                                ? const Color(0xFFB61E20).withOpacity(0.1)
                                : const Color(0xFF013236).withOpacity(0.1),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide.none
                            ),
                            focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: _isPasswordInvalid
                                    ? const BorderSide(
                                    color: Color(0xFFB61E20),
                                    width: 1.5
                                ) : const BorderSide(
                                    color: Color(0xFF013236),
                                    width: 1.5
                                )
                            ),
                          ),
                        ),
                        if (_isPasswordInvalid)
                          const Padding(
                            padding: EdgeInsets.only(top: 8, left: 8),
                            child: Text(
                              "Password minimal harus 8 karakter",
                              style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  color: Color(0xFFB61E20),
                                  fontWeight: FontWeight.w600
                              ),
                            ),
                          ),
                        const SizedBox(height: 10),
                      ],

                      SizedBox(height: 10),
                      // Toggle Button Text
                      Align(
                        alignment: Alignment.center,
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              _isReactivating = !_isReactivating;
                              // Clear password field and errors when switching
                              _passwordController.clear();
                              _isPasswordInvalid = false;
                            });
                          },
                          child: Text(
                            _isReactivating
                                ? "Cek kembali ke Aktivasi Akun Baru? Klik di sini"
                                : "Akun sudah ada dan hanya perlu aktivasi ulang? klik di sini",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF013236).withOpacity(0.7),
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: const Color(0xFFFFFFFF),
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
              disabledBackgroundColor: const Color(0xFF013236).withOpacity(0.6),
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
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFFFFF)),
                  ),
                )
              : const Text(
                  "Konfirmasi Kode",
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
    );
  }
}
