import 'package:enviroo/screens/reset_password_screen.dart';
import 'package:enviroo/widgets/topbar_back.dart';
import 'package:flutter/material.dart';

class LupaPasswordScreen extends StatefulWidget {
  @override
  State<LupaPasswordScreen> createState() => _LupaPasswordState();
}

class _LupaPasswordState extends State<LupaPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isEmailInvalid = false;

  final List<String> _dummyEmails = [
    'ramadhanisgy@gmail.com',
    'annincarista@gmail.com',
  ];

  void _validateEmail() {
    final email = _emailController.text.trim();
    setState(() {
      _isEmailInvalid = email.isNotEmpty && !_dummyEmails.contains(email);
    });
  }

  void _onKonfirmasi() {
    final email = _emailController.text.trim();
    if (!_dummyEmails.contains(email)) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Color(0xFFFFFFFF),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFF4EA771).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.mark_email_read_outlined,
                  size: 40,
                  color: Color(0xFF013236),
                ),
              ),
              SizedBox(height: 16),
              Text(
                "Cek Email Kamu!",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF013236),
                ),
              ),
              SizedBox(height: 10),
              Text(
                "Link verifikasi telah dikirim ke\n$email\n\nBuka email dan klik link tersebut untuk mereset password kamu.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  height: 1.6,
                  color: Color(0xFF2D3748),
                ),
              ),
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  // Simulasi: seolah user sudah buka link dari email
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ResetPasswordScreen(email: email),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF4EA771),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    "Buka Link Verifikasi",
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
      backgroundColor: Color(0xFFFFFFFF),
      body: Container(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TopBarBack(title: ""),
              Padding(
                  padding: EdgeInsets.symmetric(horizontal: 30),
                child: Text(
                  "Lupa Password",
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF013236),
                      fontSize: 20
                  ),
                ),
              ),
              SizedBox(height: 15),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 30),
                child: Text(
                  "Masukkan alamat email yang terdaftar sebagai akun nasabah kamu. Link verifikasi akun akan dikirimkan melalui email tersebut",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    height: 1.5,
                    color: Color(0xFF013236),
                  ),
                  textAlign: TextAlign.justify,
                ),
              ),
              SizedBox(height: 20),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _emailController,
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
                          color: Color(0xFF013236).withOpacity(0.35),
                        ),
                        prefixIcon: Icon(
                          Icons.email_rounded,
                          color: _isEmailInvalid
                          ? Color(0xFFB61E20)
                          : Color(0xFF013236),
                        ),
                        filled: true,
                        fillColor: _isEmailInvalid
                        ? Color(0xFFB61E20).withOpacity(0.1)
                        : Color(0xFF013236).withOpacity(0.1),
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
                          borderSide: _isEmailInvalid
                            ? BorderSide(
                              color: Color(0xFFB61E20),
                              width: 1.5
                          ) : BorderSide(
                              color: Color(0xFF013236),
                              width: 1.5
                          )
                        ),
                      ),
                    ),
                    if (_isEmailInvalid)
                      Padding(
                        padding: const EdgeInsets.only(top: 10, left: 8),
                        child: Text(
                          "Email tidak terdaftar",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: Color(0xFFB61E20),
                            fontWeight: FontWeight.w600
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Color(0xFFFFFFFF),
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
            onPressed: _onKonfirmasi,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF013236),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: Text(
              "Konfirmasi Email",
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
