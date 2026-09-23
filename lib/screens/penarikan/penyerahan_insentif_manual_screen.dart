import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../providers/penarikan_petugas_provider.dart';
import '../../widgets/topbar_back.dart';
import '../admin_bsu/inapp_camera_screen.dart';
import '../lihat_foto_screen.dart';

/// Fallback petugas ketika QR nasabah tidak bisa dipindai — konfirmasi
/// penyerahan insentif manual (foto bukti + catatan wajib), pakai jalur
/// manual dari PATCH /penarikan/selesai (nasabah_id + penarikan_id + bukti_foto
/// + catatan, semuanya wajib).
///
/// Pop dengan `true` kalau berhasil diselesaikan.
class PenyerahanInsentifManualScreen extends StatefulWidget {
  final String penarikanId;
  final String nasabahId;

  const PenyerahanInsentifManualScreen({
    super.key,
    required this.penarikanId,
    required this.nasabahId,
  });

  @override
  State<PenyerahanInsentifManualScreen> createState() =>
      _PenyerahanInsentifManualScreenState();
}

class _PenyerahanInsentifManualScreenState
    extends State<PenyerahanInsentifManualScreen> {
  static const Color dark = Color(0xFF013236);

  File? _photo;
  bool _submitting = false;
  final TextEditingController _catatanController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _catatanController.addListener(_onChanged);
  }

  void _onChanged() => setState(() {});

  @override
  void dispose() {
    _catatanController.removeListener(_onChanged);
    _catatanController.dispose();
    super.dispose();
  }

  bool get _isValid => _photo != null && _catatanController.text.trim().isNotEmpty;

  // ── Foto ──────────────────────────────────────────────────────────────────

  Future<void> _ambilFoto() async {
    final file = await Navigator.push<File?>(
      context,
      MaterialPageRoute(
        builder: (_) => const InAppCameraScreen(
          hint: 'Ambil foto sebagai bukti penyerahan insentif',
        ),
      ),
    );
    if (file == null || !mounted) return;
    setState(() => _photo = file);
  }

  void _lihatFotoFull() {
    final photo = _photo;
    if (photo == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LihatFotoScreen(
          photoFile: photo,
          nama: 'Bukti Penyerahan Insentif',
        ),
      ),
    );
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    final photo = _photo;
    if (photo == null) return;
    final catatan = _catatanController.text.trim();
    if (catatan.isEmpty) return;

    setState(() => _submitting = true);

    final bytes = await photo.readAsBytes();
    final base64str = 'data:image/jpeg;base64,${base64Encode(bytes)}';

    if (!mounted) return;
    final prov = context.read<PenarikanPetugasProvider>();
    final ok = await prov.selesaikanManual(
      nasabahId: widget.nasabahId,
      penarikanId: widget.penarikanId,
      buktiFoto: base64str,
      catatan: catatan,
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (ok) {
      HapticFeedback.mediumImpact();
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
          content: Text(
            prov.errorDetail ?? 'Gagal menyelesaikan penarikan',
            style: const TextStyle(fontFamily: 'Poppins'),
          ),
        ),
      );
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      body: SafeArea(
        child: Column(
          children: [
            const TopBarBack(title: 'Konfirmasi Manual'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionLabel('Foto Bukti Penyerahan', required: true),
                    const SizedBox(height: 8),
                    _buildFotoContainer(),
                    const SizedBox(height: 20),
                    const _SectionLabel('Tambahkan Catatan', required: true),
                    const SizedBox(height: 8),
                    _buildCatatanField(),
                  ],
                ),
              ),
            ),
            // ── Bottom bar button ──────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: _buildCTA(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFotoContainer() {
    return GestureDetector(
      onTap: _photo == null ? _ambilFoto : null,
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: Container(
          decoration: BoxDecoration(
            color: _photo == null ? const Color(0xFFF5F7F5) : Colors.black,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _photo == null
                  ? dark.withValues(alpha: 0.15)
                  : Colors.transparent,
              width: 1.5,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: _photo == null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt_rounded,
                        size: 32, color: dark.withValues(alpha: 0.35)),
                    const SizedBox(height: 8),
                    Text(
                      'Ambil Foto Bukti Penyerahan',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: dark.withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                )
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(_photo!, fit: BoxFit.cover),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Row(
                        children: [
                          _overlayIconButton(
                              Icons.fullscreen_rounded, _lihatFotoFull),
                          const SizedBox(width: 8),
                          _overlayIconButton(
                              Icons.replay_rounded, _ambilFoto),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _overlayIconButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }

  Widget _buildCatatanField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withValues(alpha: 0.12)),
      ),
      child: TextField(
        controller: _catatanController,
        maxLines: 5,
        minLines: 5,
        maxLength: 255,
        textInputAction: TextInputAction.done,
        inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\n'))],
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 13,
          color: dark,
          height: 1.5,
        ),
        decoration: InputDecoration(
          hintText: 'Tulis catatan penyerahan insentif untuk nasabah ini',
          hintStyle: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            color: dark.withValues(alpha: 0.35),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          counterStyle: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11,
            color: dark.withValues(alpha: 0.35),
          ),
        ),
      ),
    );
  }

  Widget _buildCTA() {
    final disabled = !_isValid || _submitting;
    return Container(
      decoration: BoxDecoration(
        color: disabled ? Colors.grey.shade400 : dark,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: disabled ? null : _submit,
          borderRadius: BorderRadius.circular(50),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5),
                    )
                  : const Text(
                      'Selesaikan Penarikan',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Section label (icon bintang merah kalau wajib diisi) ───────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  final bool required;
  const _SectionLabel(this.text, {this.required = false});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.black.withValues(alpha: 0.7),
        ),
        children: [
          if (required)
            const TextSpan(
              text: '*',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
        ],
      ),
    );
  }
}
