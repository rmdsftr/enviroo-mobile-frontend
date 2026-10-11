import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../providers/penarikan_petugas_provider.dart';
import '../../widgets/custom_snackbar.dart';
import '../../widgets/topbar_back.dart';
import '../petugas/inapp_camera_screen.dart';
import '../lihat_foto_screen.dart';
import 'package:enviroo/core/theme/app_colors.dart';
import 'package:enviroo/core/theme/app_text.dart';

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
  static const Color dark = AppColors.dark;

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

  Future<void> _submit() async {
    final photo = _photo;
    if (photo == null) return;
    final catatan = _catatanController.text.trim();
    if (catatan.isEmpty) return;

    setState(() => _submitting = true);

    final prov = context.read<PenarikanPetugasProvider>();
    final ok = await prov.selesaikanManual(
      nasabahId: widget.nasabahId,
      penarikanId: widget.penarikanId,
      buktiFoto: photo,
      catatan: catatan,
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (ok) {
      HapticFeedback.mediumImpact();
      Navigator.pop(context, true);
    } else {
      showCustomSnackBar(
          context, prov.errorDetail ?? 'Gagal menyelesaikan penarikan');
    }
  }

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
            color: _photo == null ? AppColors.surface : Colors.black,
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
                      style: AppText.w600(12.5, dark.withValues(alpha: 0.45)),
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
        style: AppText.p(13, color: dark, height: 1.5),
        decoration: InputDecoration(
          hintText: 'Tulis catatan penyerahan insentif untuk nasabah ini',
          hintStyle: AppText.r(13, dark.withValues(alpha: 0.35)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          counterStyle: AppText.r(11, dark.withValues(alpha: 0.35)),
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
                  : Text(
                      'Selesaikan Penarikan',
                      style: AppText.w600(14, Colors.white),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final bool required;
  const _SectionLabel(this.text, {this.required = false});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        text: text,
        style: AppText.w600(12, Colors.black.withValues(alpha: 0.7)),
        children: [
          if (required)
            TextSpan(
              text: '*',
              style: AppText.w600(12, Colors.red),
            ),
        ],
      ),
    );
  }
}
