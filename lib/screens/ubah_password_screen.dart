import 'package:enviroo/providers/auth_provider.dart';
import 'package:enviroo/services/auth_service.dart';
import 'package:enviroo/widgets/success_bottom_sheet.dart';
import 'package:enviroo/widgets/topbar_back.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

  void _onSimpanPassword() async {
    final passwordLama = _passwordLamaController.text.trim();
    final passwordBaru = _passwordBaruController.text.trim();
    final konfirmasiPassword = _konfirmasiPasswordController.text.trim();

    if (passwordLama.isEmpty || passwordBaru.isEmpty || konfirmasiPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua field harus diisi')),
      );
      return;
    }

    if (passwordBaru != konfirmasiPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Konfirmasi password baru tidak cocok')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final token = Provider.of<AuthProvider>(context, listen: false)
        .currentUser?.accessToken ?? '';

    final response = await AuthService.changePassword(
      passwordLama,
      passwordBaru,
      konfirmasiPassword,
      token,
    );

    setState(() {
      _isLoading = false;
    });

    if (response['success']) {
      if (mounted) {
        await showSuccessBottomSheet(
          context,
          title: 'Berhasil!',
          message: 'Password kamu berhasil diperbarui.',
          buttonLabel: 'Kembali',
          onDismiss: () => Navigator.pop(context), // Kembali ke profil screen
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'])),
        );
      }
    }
  }

  @override
  void dispose() {
    _passwordLamaController.dispose();
    _passwordBaruController.dispose();
    _konfirmasiPasswordController.dispose();
    super.dispose();
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hintText,
    required bool obscureText,
    required VoidCallback toggleObscure,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 14,
        color: Color(0xFF2D3748),
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        hintText: hintText,
        hintStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          color: const Color(0xFF013236).withOpacity(0.35),
        ),
        prefixIcon: const Icon(
          Icons.lock_rounded,
          color: Color(0xFF013236),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility_off : Icons.visibility,
            color: const Color(0xFF013236).withOpacity(0.5),
          ),
          onPressed: toggleObscure,
        ),
        filled: true,
        fillColor: const Color(0xFF013236).withOpacity(0.1),
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
          borderSide: const BorderSide(
            color: Color(0xFF013236),
            width: 1.5,
          ),
        ),
      ),
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
                  "Ubah Password",
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
                  "Masukkan password lama dan password baru kamu untuk meningkatkan keamanan akun.",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    height: 1.5,
                    color: Color(0xFF013236),
                  ),
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
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: const Color(0xFFFFFFFF),
        child: Container(
          margin: const EdgeInsets.all(16),
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
            onPressed: _isLoading ? null : _onSimpanPassword,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: const Color(0xFF013236),
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
                : const Text(
                    "Simpan Password",
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
