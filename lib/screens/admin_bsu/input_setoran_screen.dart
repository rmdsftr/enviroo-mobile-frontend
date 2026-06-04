import 'dart:io';
import 'package:enviroo/models/katalog_model.dart';
import 'package:enviroo/providers/auth_provider.dart';
import 'package:enviroo/screens/admin_bsu/inapp_camera_screen.dart';
import 'package:enviroo/screens/petugas/preview_setoran_screen.dart';
import 'package:enviroo/screens/petugas/struk_setoran_nasabah.dart';
import 'package:enviroo/services/katalog_service.dart';
import 'package:enviroo/widgets/confirm_bottom_sheet.dart';
import 'package:enviroo/widgets/custom_snackbar.dart';
import 'package:enviroo/widgets/filter_chip_row.dart';
import 'package:enviroo/widgets/search.dart';
import 'package:enviroo/widgets/topbar_back.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class InputSetoranScreen extends StatefulWidget {
  final String penimbanganId;
  final String nasabahId;
  final String nasabahName;
  final String photoUrl;
  final bool dariQr;

  const InputSetoranScreen({
    super.key,
    required this.penimbanganId,
    required this.nasabahId,
    required this.nasabahName,
    required this.photoUrl,
    required this.dariQr,
  });

  @override
  State<InputSetoranScreen> createState() => _InputSetoranState();
}

class _InputSetoranState extends State<InputSetoranScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedReward = 'Semua';
  final Map<String, TextEditingController> _inputControllers = {};

  List<KatalogSampahModel> _katalog = [];
  bool _isLoading = true;

  List<KatalogSampahModel> get _filtered => _katalog.where((item) {
        final matchSearch = item.namaSampah
            .toLowerCase()
            .contains(_searchQuery.toLowerCase());
        final matchReward = _selectedReward == 'Semua' ||
            (item.reward?.namaReward ?? '') == _selectedReward;
        return matchSearch && matchReward;
      }).toList();

  List<String> get _rewardOptions {
    final seen = <String>{};
    final result = <String>['Semua'];
    for (final item in _katalog) {
      final name = item.reward?.namaReward ?? '';
      if (name.isNotEmpty && seen.add(name)) result.add(name);
    }
    return result;
  }

  TextEditingController _controllerFor(String sampahId) =>
      _inputControllers.putIfAbsent(sampahId, () => TextEditingController());

  bool get _adaInput => _inputControllers.values
      .any((c) => c.text.isNotEmpty && (double.tryParse(c.text) ?? 0) > 0);

  @override
  void initState() {
    super.initState();
    _fetchKatalog();
  }

  Future<void> _fetchKatalog() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final bankId = auth.bankId ?? '';

    final res = await KatalogService.getKatalogSampah(bankId);

    if (!mounted) return;

    if (res['success'] == true) {
      final List data = res['data'] ?? [];
      setState(() {
        _katalog = data.map((e) => KatalogSampahModel.fromJson(e)).toList();
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      showCustomSnackBar(context, res['message'] ?? 'Gagal mengambil katalog sampah');
    }
  }

  // ── Ambil foto nasabah via kamera in-app (tidak membuka Activity baru) ────────
  Future<File?> _ambilFoto() async {
    final File? result = await Navigator.push<File?>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const InAppCameraScreen(),
      ),
    );
    return result;
  }

  Future<void> _goToPreview() async {
    if (!_adaInput) return;

    File? fotoFile;

    if (!widget.dariQr) {
      final konfirmasi = await showConfirmBottomSheet(
        context,
        icon: Icons.camera_alt_rounded,
        title: 'Foto Bukti Nasabah',
        message: 'Karena setoran ini dilakukan secara manual, harap ambil foto nasabah sebagai bukti kehadiran sebelum melanjutkan.',
        cancelLabel: 'Batal',
        confirmLabel: 'Ambil Foto',
      );

      if (!konfirmasi || !mounted) return;

      fotoFile = await _ambilFoto();
      if (!mounted) return;

      if (fotoFile == null) {
        showCustomSnackBar(context, 'Foto nasabah wajib diambil untuk setoran manual.');
        return;
      }
    }

    List<Map<String, dynamic>> items = [];
    for (final sampah in _katalog) {
      final ctrl = _inputControllers[sampah.sampahId];
      if (ctrl == null || ctrl.text.isEmpty) continue;
      final qty = double.tryParse(ctrl.text) ?? 0;
      if (qty > 0) {
        items.add({'sampah_id': sampah.sampahId, 'qty': qty});
      }
    }

    if (!mounted) return;

    final setoranId = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => PreviewSetoranScreen(
          penimbanganId: widget.penimbanganId,
          nasabahId: widget.nasabahId,
          nasabahName: widget.nasabahName,
          photoUrl: widget.photoUrl,
          dariQr: widget.dariQr,
          items: items,
          fotoFile: fotoFile,
        ),
      ),
    );

    if (setoranId != null && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => StrukSetoranNasabahScreen(
            setoranId: setoranId,
            namaNasabah: widget.nasabahName,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    for (final ctrl in _inputControllers.values) ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: SafeArea(
        child: Column(
          children: [
            TopBarBack(title: "Input Setoran"),
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF4EA771)))
                : ListView(
                padding: EdgeInsets.zero,
                children: [
                  const SizedBox(height: 8),
                  _buildNasabahCard(),
                  const SizedBox(height: 20),
                  _buildSearchBar(),
                  const SizedBox(height: 15),
                  _buildRewardFilter(),
                  const SizedBox(height: 20),
                  _buildKatalogHeader(),
                  const SizedBox(height: 8),
                  if (_filtered.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 40),
                        child: Text(
                          'Katalog tidak ditemukan',
                          style: TextStyle(fontFamily: 'Poppins', color: Colors.grey[400]),
                        ),
                      ),
                    ),
                  ...List.generate(_filtered.length, (i) => _CardInput(
                    key: ValueKey(_filtered[i].sampahId),
                    item: _filtered[i],
                    controller: _controllerFor(_filtered[i].sampahId),
                    onChanged: (_) => setState(() {}),
                  )),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  // ── Nasabah card ──────────────────────────────────────────────────────────
  Widget _buildNasabahCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: const Color(0xFF4EA771).withValues(alpha:0.3)),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFF4EA771).withValues(alpha:0.12),
                borderRadius: BorderRadius.circular(13),
                image: widget.photoUrl.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(widget.photoUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: widget.photoUrl.isEmpty
                  ? const Icon(
                      Icons.person_rounded,
                      color: Color(0xFF4EA771),
                      size: 24,
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            // Nama + ID
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.nasabahName,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Color(0xFF013236),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    widget.nasabahId,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: const Color(0xFF013236).withValues(alpha:0.45),
                    ),
                  ),
                ],
              ),
            ),
            // Badge QR / Manual
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF4EA771).withValues(alpha:0.12),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.dariQr ? Icons.qr_code_rounded : Icons.person_search_rounded,
                    size: 12,
                    color: const Color(0xFF4EA771),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    widget.dariQr ? 'Via QR' : 'Manual',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4EA771),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Search bar ────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha:0.5),
          borderRadius: BorderRadius.circular(50),
        ),
        child: CustomSearchBar(
          controller: _searchController,
          hintText: 'Cari sampah dari katalog...',
          onChanged: (v) => setState(() => _searchQuery = v),
          searchQuery: _searchQuery,
          onClear: () {
            setState(() {
              _searchController.clear();
              _searchQuery = '';
            });
          },
        ),
      ),
    );
  }

  // ── Reward filter chips ───────────────────────────────────────────────────
  Widget _buildRewardFilter() {
    final options = _rewardOptions;
    return FilterChipRow<String>(
      items: options
          .map((n) => FilterChipItem<String>(value: n, label: n))
          .toList(),
      selectedValue: _selectedReward,
      onSelected: (v) => setState(() => _selectedReward = v),
    );
  }

  // ── Header katalog ────────────────────────────────────────────────────────
  Widget _buildKatalogHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          const Text(
            'Katalog Sampah',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: Color(0xFF013236),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha:0.65),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_filtered.length} item',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Color(0xFF4EA771),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom bar — tombol simpan saja ───────────────────────────────────────
  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 14, 20, MediaQuery.of(context).padding.bottom + 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF013236).withValues(alpha:0.08),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: AnimatedOpacity(
        opacity: _adaInput ? 1.0 : 0.4,
        duration: const Duration(milliseconds: 200),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Color(0xFF013236),
            borderRadius: BorderRadius.circular(30),
          ),
          child: ElevatedButton(
            onPressed: _adaInput ? _goToPreview : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              disabledBackgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              foregroundColor: Colors.white,
              disabledForegroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Preview Setoran Nasabah',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    letterSpacing: 0.2,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}

// ─────────────────────────────────────────────────────────────────────────────
// Card Input — flat row: [foto] [nama sampah]  [input] [satuan]
// ─────────────────────────────────────────────────────────────────────────────

class _CardInput extends StatelessWidget {
  final KatalogSampahModel item;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _CardInput({
    super.key,
    required this.item,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha:0.5),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            width: 1,
            color: const Color(0xFF013236).withValues(alpha:0.1), // Brand color dengan opacity cuma 10%
          ),
        ),
        child: Row(
          children: [
            // Foto sampah
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF4EA771).withValues(alpha:0.12),
                borderRadius: BorderRadius.circular(11),
              ),
              clipBehavior: Clip.antiAlias,
              child: item.photoUrl.isNotEmpty
                  ? Image.network(
                      item.photoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.recycling_rounded,
                        size: 20,
                        color: Color(0xFF4EA771),
                      ),
                    )
                  : const Icon(
                      Icons.recycling_rounded,
                      size: 20,
                      color: Color(0xFF4EA771),
                    ),
            ),
            const SizedBox(width: 12),

            // Nama sampah + reward badge
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.namaSampah,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Color(0xFF013236),
                    ),
                  ),
                  const SizedBox(height: 4),
                  _RewardBadge(namaReward: item.reward?.namaReward ?? ''),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Input qty
            SizedBox(
              width: 70,
              height: 42,
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Color(0xFF013236),
                ),
                decoration: InputDecoration(
                  hintText: '0',
                  hintStyle: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: const Color(0xFF013236).withValues(alpha:0.18),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF4FCF4),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(
                      color: const Color(0xFF4EA771).withValues(alpha:0.2),
                      width: 1,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(
                      color: const Color(0xFF4EA771).withValues(alpha:0.2),
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(
                      color: Color(0xFF4EA771),
                      width: 1,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Satuan
            Text(
              item.satuan,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF013236).withValues(alpha:0.55),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reward badge
// ─────────────────────────────────────────────────────────────────────────────

class _RewardBadge extends StatelessWidget {
  final String namaReward;

  const _RewardBadge({required this.namaReward});

  Color get _color {
    switch (namaReward.toLowerCase()) {
      case 'uang':
        return const Color(0xFF4EA771);
      case 'sembako':
        return const Color(0xFFE57C2C);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (namaReward.isEmpty) return const SizedBox.shrink();
    final color = _color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        namaReward,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
