import 'dart:io';
import 'package:enviroo/services/profil_service.dart';
import 'package:enviroo/widgets/topbar_back.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class EditProfilScreen extends StatefulWidget {
  final String userId;
  final String role;
  final String initialNama;
  final String initialNoWhatsapp;
  final String? initialPhotoUrl;
  final bool hasOtherAccount;

  const EditProfilScreen({
    super.key,
    required this.userId,
    required this.role,
    required this.initialNama,
    required this.initialNoWhatsapp,
    this.initialPhotoUrl,
    this.hasOtherAccount = false,
  });

  @override
  State<EditProfilScreen> createState() => _EditProfilScreenState();
}

class _EditProfilScreenState extends State<EditProfilScreen> {
  late final TextEditingController _namaController;
  late final TextEditingController _waController;
  File? _pickedPhoto;
  bool _isSaving = false;

  static const _dark      = Color(0xFF0D3B3E);
  static const _green     = Color(0xFF4EA771);
  static const _softGreen = Color(0xFFD8F0D0);
  static const _midGreen  = Color(0xFF4B9E6B);

  @override
  void initState() {
    super.initState();
    _namaController = TextEditingController(text: widget.initialNama);
    _waController   = TextEditingController(text: widget.initialNoWhatsapp);
  }

  @override
  void dispose() {
    _namaController.dispose();
    _waController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1024,
    );
    if (file != null) setState(() => _pickedPhoto = File(file.path));
  }

  Future<void> _save() async {
    final nama = _namaController.text.trim();
    final wa   = _waController.text.trim();
    if (nama.isEmpty && wa.isEmpty && _pickedPhoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minimal satu field harus diubah')),
      );
      return;
    }

    setState(() => _isSaving = true);
    final result = await ProfilService.updateProfil(
      userId: widget.userId,
      nama: nama.isNotEmpty ? nama : null,
      noWhatsapp: wa.isNotEmpty ? wa : null,
      photo: _pickedPhoto,
    );
    if (!mounted) return;
    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(result['message']),
      backgroundColor: result['success'] == true ? _green : Colors.red,
    ));

    if (result['success'] == true) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            TopBarBack(title: "Edit Profil"),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                child: Column(
                  children: [
                    const SizedBox(height: 28),
                    _buildAvatar(),
                    const SizedBox(height: 28),
                    if (widget.hasOtherAccount) ...[
                      _buildBanner(),
                      const SizedBox(height: 20),
                    ],
                    _buildFields(),
                    const SizedBox(height: 28),
                    _buildSaveButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildAvatar() {
    Widget photo;
    if (_pickedPhoto != null) {
      photo = ClipOval(child: Image.file(_pickedPhoto!, width: 96, height: 96, fit: BoxFit.cover));
    } else if (widget.initialPhotoUrl != null && widget.initialPhotoUrl!.isNotEmpty) {
      photo = ClipOval(
        child: Image.network(
          widget.initialPhotoUrl!,
          width: 96, height: 96, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _initialsCircle(),
        ),
      );
    } else {
      photo = _initialsCircle();
    }

    return GestureDetector(
      onTap: _pickPhoto,
      child: Stack(
        children: [
          Container(
            width: 96, height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _softGreen, width: 3),
            ),
            child: photo,
          ),
          Positioned(
            bottom: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _green,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _initialsCircle() {
    final initials = widget.initialNama
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();
    return Container(
      width: 96, height: 96,
      decoration: const BoxDecoration(color: _softGreen, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        initials.isEmpty ? '?' : initials,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.bold,
          fontSize: 28,
          color: _midGreen,
        ),
      ),
    );
  }

  Widget _buildBanner() {
    final isPetugas = widget.role.startsWith('petugas_');
    final msg = isPetugas
        ? 'Anda memiliki akun nasabah. Mengubah info profil pada akun petugas juga akan mengubah info profil Anda di akun nasabah.'
        : 'Anda memiliki akun petugas. Mengubah info profil pada akun nasabah juga akan mengubah info profil Anda di akun petugas.';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFCC02).withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFFE6A817)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              msg,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                height: 1.6,
                color: Color(0xFF7A5C00),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFields() {
    return Column(
      children: [
        _buildField(
          controller: _namaController,
          label: 'Nama',
          icon: Icons.person_outline_rounded,
          hint: 'Masukkan nama lengkap',
        ),
        const SizedBox(height: 16),
        _buildField(
          controller: _waController,
          label: 'Nomor WhatsApp',
          icon: Icons.phone_outlined,
          hint: '08xxxxxxxxxx',
          keyboardType: TextInputType.phone,
        ),
      ],
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: _dark.withValues(alpha: 0.55),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _dark.withValues(alpha: 0.1)),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: _dark),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: _dark.withValues(alpha: 0.3),
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 14, right: 10),
                child: Icon(icon, size: 18, color: _green),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _save,
        style: ElevatedButton.styleFrom(
          backgroundColor: _dark,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        ),
        child: _isSaving
            ? const SizedBox(
                width: 18, height: 18,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : const Text(
                'Simpan Perubahan',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }
}
