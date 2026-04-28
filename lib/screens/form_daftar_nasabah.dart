import 'package:enviroo/providers/auth_provider.dart';
import 'package:enviroo/widgets/topbar_back.dart';
import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:provider/provider.dart';

class FormDaftarNasabahScreen extends StatefulWidget{
  @override
  State<FormDaftarNasabahScreen> createState() => _FormDaftarNasabahState();
}

class _FormDaftarNasabahState extends State<FormDaftarNasabahScreen>{
  String? selectedGender;

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    return Scaffold(
      backgroundColor: Color(0xFFFFFFFF),
      body: Container(
        child: SafeArea(
            child: SingleChildScrollView(
              child: Expanded(
                  child: Column(
                    children: [
                      TopBarBack(title: "Pendaftaran Nasabah"),
                      SizedBox(height: 20),
                      // Improved description section with card styling
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 30),
                        child: Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Color(0xFF4EA771).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                color: Color(0xFF4EA771),
                                size: 24,
                              ),
                              SizedBox(height: 12),
                              Text(
                                "Sebagai Admin Bank Sampah, kamu bisa mendaftarkan akun nasabah baru. Satu email hanya berlaku untuk satu akun nasabah. Akun baru akan aktif jika nasabah baru terkait melakukan verifikasi melalui email yang dikirim.",
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  height: 1.5,
                                  color: Color(0xFF013236).withOpacity(0.75),
                                ),
                                textAlign: TextAlign.justify,
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 30),
                      // NIK Field
                      Padding(
                          padding: EdgeInsets.symmetric(horizontal: 30),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: EdgeInsets.only(left: 8),
                                child: Text(
                                  "NIK calon nasabah",
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 11,
                                    color: Color(0xFF013236),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              SizedBox(height: 5),
                              TextField(
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 15,
                                  color: Color(0xFF2D3748),
                                  fontWeight: FontWeight.w600,
                                ),
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(
                                      vertical: 22, horizontal: 20),
                                  hintText: "NIK sesuai KK",
                                  hintStyle: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 14,
                                    color: Color(0xFF013236).withOpacity(0.5),
                                  ),
                                  prefixIcon: Icon(
                                    Icons.credit_card_rounded,
                                    size: 25,
                                    color: Color(0xFF013236),
                                  ),
                                  filled: true,
                                  fillColor: Color(0xFF013236).withOpacity(0.15),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15),
                                    borderSide: BorderSide(
                                      color: Color(0xFF013236),
                                      width: 1.5,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15),
                                    borderSide: BorderSide.none
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15),
                                    borderSide: BorderSide(
                                      color: Color(0xFF013236),
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                      ),
                      SizedBox(height: 17),
                      // Email Field
                      Padding(
                          padding: EdgeInsets.symmetric(horizontal: 30),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: EdgeInsets.only(left: 8),
                                child: Text(
                                  "Email calon nasabah",
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 11,
                                    color: Color(0xFF013236),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              SizedBox(height: 5),
                              TextField(
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 15,
                                  color: Color(0xFF2D3748),
                                  fontWeight: FontWeight.w600,
                                ),
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(
                                      vertical: 22, horizontal: 20),
                                  hintText: "example@gmail.com",
                                  hintStyle: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 14,
                                    color: Color(0xFF013236).withOpacity(0.5),
                                  ),
                                  prefixIcon: Icon(
                                    Icons.email_rounded,
                                    size: 23,
                                    color: Color(0xFF013236),
                                  ),
                                  filled: true,
                                  fillColor: Color(0xFF013236).withOpacity(0.15),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15),
                                    borderSide: BorderSide(
                                      color: Color(0xFF013236),
                                      width: 1.5,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15),
                                    borderSide: BorderSide.none
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15),
                                    borderSide: BorderSide(
                                      color: Color(0xFF013236),
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                      ),
                      SizedBox(height: 17),
                      // Name Field
                      Padding(
                          padding: EdgeInsets.symmetric(horizontal: 30),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: EdgeInsets.only(left: 8),
                                child: Text(
                                  "Nama lengkap calon nasabah",
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 11,
                                    color: Color(0xFF013236),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              SizedBox(height: 5),
                              TextField(
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 15,
                                  color: Color(0xFF2D3748),
                                  fontWeight: FontWeight.w600,
                                ),
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(
                                      vertical: 22, horizontal: 20),
                                  hintText: "Nama lengkap sesuai KK",
                                  hintStyle: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 14,
                                    color: Color(0xFF013236).withOpacity(0.5),
                                  ),
                                  prefixIcon: Icon(
                                    Icons.person,
                                    size: 25,
                                    color: Color(0xFF013236),
                                  ),
                                  filled: true,
                                  fillColor: Color(0xFF013236).withOpacity(0.15),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15),
                                    borderSide: BorderSide(
                                      color: Color(0xFF013236),
                                      width: 1.5,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15),
                                    borderSide: BorderSide.none
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15),
                                    borderSide: BorderSide(
                                      color: Color(0xFF013236),
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                      ),
                      SizedBox(height: 17),
                      // Gender Dropdown with custom styling
                      Padding(
                          padding: EdgeInsets.symmetric(horizontal: 30),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: EdgeInsets.only(left: 8),
                                child: Text(
                                  "Gender calon nasabah",
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 11,
                                    color: Color(0xFF013236),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              SizedBox(height: 5),
                              DropdownButtonFormField2<String>(
                                value: selectedGender,
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.only(
                                    top: 22,
                                    bottom: 22,
                                    left: 10,
                                    right: 10,
                                  ),

                                  prefixIcon: Padding(
                                    padding: const EdgeInsets.only(left: 15),
                                    child: Icon(
                                      Icons.wc_rounded,
                                      size: 23,
                                      color: Color(0xFF013236),
                                    ),
                                  ),

                                  prefixIconConstraints: const BoxConstraints(
                                    minWidth: 30,
                                    minHeight: 30,
                                  ),
                                  filled: true,
                                  fillColor: Color(0xFF013236).withOpacity(0.15),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15),
                                    borderSide: BorderSide(
                                      color: Color(0xFF013236),
                                      width: 1.5,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15),
                                    borderSide: BorderSide.none
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15),
                                    borderSide: BorderSide(
                                      color: Color(0xFF013236),
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                                hint: Text(
                                  'Pilih gender',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 14,
                                    color: Color(0xFF013236).withOpacity(0.5),
                                  ),
                                ),
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 15,
                                  color: Color(0xFF2D3748),
                                  fontWeight: FontWeight.w600,
                                ),
                                iconStyleData: IconStyleData(
                                  icon: Icon(
                                    Icons.arrow_drop_down_rounded,
                                    color: Color(0xFF013236),
                                  ),
                                ),
                                dropdownStyleData: DropdownStyleData(
                                  decoration: BoxDecoration(
                                    color: Color(0xFFFFFFFF),
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  offset: const Offset(0, -5),
                                  maxHeight: 200,
                                ),
                                menuItemStyleData: MenuItemStyleData(
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                ),
                                items: [
                                  DropdownMenuItem(
                                    value: "Perempuan",
                                    child: Text("Perempuan"),
                                  ),
                                  DropdownMenuItem(
                                    value: "Laki-laki",
                                    child: Text("Laki-laki"),
                                  ),
                                ],
                                onChanged: (String? newValue) {
                                  setState(() {
                                    selectedGender = newValue;
                                  });
                                },
                              ),
                            ],
                          )
                      ),
                      SizedBox(height: 17),
                      if(auth.role == "admin_bsi")
                        Padding(
                            padding: EdgeInsets.symmetric(horizontal: 30),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: EdgeInsets.only(left: 8),
                                  child: Text(
                                    "BSU yang diasosiasikan",
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 11,
                                      color: Color(0xFF013236),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 5),
                                DropdownButtonFormField2<String>(
                                  value: selectedGender,
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.only(
                                      top: 22,
                                      bottom: 22,
                                      left: 10,
                                      right: 10,
                                    ),

                                    prefixIcon: Padding(
                                      padding: const EdgeInsets.only(left: 15),
                                      child: Icon(
                                        Icons.house_rounded,
                                        size: 23,
                                        color: Color(0xFF013236),
                                      ),
                                    ),

                                    prefixIconConstraints: const BoxConstraints(
                                      minWidth: 30,
                                      minHeight: 30,
                                    ),
                                    filled: true,
                                    fillColor: Color(0xFF013236).withOpacity(0.15),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(15),
                                      borderSide: BorderSide(
                                        color: Color(0xFF013236),
                                        width: 1.5,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(15),
                                        borderSide: BorderSide.none
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(15),
                                      borderSide: BorderSide(
                                        color: Color(0xFF013236),
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                  hint: Text(
                                    'Pilih BSU',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 14,
                                      color: Color(0xFF013236).withOpacity(0.5),
                                    ),
                                  ),
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 15,
                                    color: Color(0xFF2D3748),
                                    fontWeight: FontWeight.w600,
                                  ),
                                  iconStyleData: IconStyleData(
                                    icon: Icon(
                                      Icons.arrow_drop_down_rounded,
                                      color: Color(0xFF013236),
                                    ),
                                  ),
                                  dropdownStyleData: DropdownStyleData(
                                    decoration: BoxDecoration(
                                      color: Color(0xFFFFFFFF),
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    offset: const Offset(0, -5),
                                    maxHeight: 200,
                                  ),
                                  menuItemStyleData: MenuItemStyleData(
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                  ),
                                  items: [
                                    DropdownMenuItem(
                                      value: "Perempuan",
                                      child: Text("Perempuan"),
                                    ),
                                    DropdownMenuItem(
                                      value: "Laki-laki",
                                      child: Text("Laki-laki"),
                                    ),
                                  ],
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      selectedGender = newValue;
                                    });
                                  },
                                ),
                              ],
                            )
                        ),
                      SizedBox(height: 30)
                    ],
                  )
              ),
            )
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
            onPressed: (){},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF013236),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: Text(
              "Daftarkan Nasabah",
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
