import 'dart:io';
import 'package:enviroo/models/katalog_model.dart';
import 'package:enviroo/providers/auth_provider.dart';
import 'package:enviroo/screens/admin_bsu/inapp_camera_screen.dart';
import 'package:enviroo/services/katalog_service.dart';
import 'package:enviroo/services/setoran_service.dart';
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
  final bool dariQr;

  const InputSetoranScreen({
    super.key,
    required this.penimbanganId,
    required this.nasabahId,
    required this.nasabahName,
    required this.dariQr,
  });

  @override
  State<InputSetoranScreen> createState() => _InputSetoranState();
}

class _InputSetoranState extends State<InputSetoranScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final Map<int, TextEditingController> _inputControllers = {};
  
  List<KatalogSampahModel> _katalog = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  File? _fotoFile;

  List<KatalogSampahModel> get _filtered => _katalog
      .where((item) =>
          item.poinNasabah > 0 &&
          item.namaSampah.toLowerCase().contains(_searchQuery.toLowerCase()))
      .toList();

  TextEditingController _controllerAt(int index) =>
      _inputControllers.putIfAbsent(index, () => TextEditingController());

  // Total khusus kategori "poin" -> di backend ini semua point base
  double get _totalPoin {
    double total = 0;
    for (int i = 0; i < _filtered.length; i++) {
      final ctrl = _inputControllers[i];
      if (ctrl == null) continue;
      final val = double.tryParse(ctrl.text) ?? 0;
      total += (val * _filtered[i].poinNasabah);
    }
    return total;
  }

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
    final token = auth.currentUser?.accessToken ?? '';

    final res = await KatalogService.getKatalogSampah(bankId, token);

    if (!mounted) return;

    if (res['success'] == true) {
      final List data = res['data'] ?? [];
      setState(() {
        _katalog = data.map((e) => KatalogSampahModel.fromJson(e)).toList();
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      _showErrorDialog(res['message'] ?? 'Gagal mengambil katalog sampah');
    }
  }

  void _showErrorDialog(String msg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Terjadi Kesalahan',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: Colors.red,
          ),
        ),
        content: Text(
          msg,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            color: Colors.grey[700],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup', style: TextStyle(color: Color(0xFF013236), fontFamily: 'Poppins')),
          ),
        ],
      ),
    );
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

  Future<void> _simpanSetoran() async {
    if (!_adaInput) return;

    // ── Jalur manual: wajib ambil foto dulu sebelum submit ──────────────────
    if (!widget.dariQr) {
      // Tampilkan dialog konfirmasi foto
      final konfirmasi = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Foto Bukti Nasabah',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Color(0xFF013236),
            ),
          ),
          content: const Text(
            'Karena setoran ini dilakukan secara manual, harap ambil foto nasabah sebagai bukti kehadiran sebelum menyimpan data.',
            style: TextStyle(fontFamily: 'Poppins', fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal',
                  style: TextStyle(color: Colors.grey, fontFamily: 'Poppins')),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(ctx, true),
              icon: const Icon(Icons.camera_alt_rounded, size: 16),
              label: const Text('Ambil Foto',
                  style: TextStyle(fontFamily: 'Poppins')),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF013236),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      );

      if (konfirmasi != true || !mounted) return;

      // Buka kamera
      final foto = await _ambilFoto();
      if (!mounted) return;

      if (foto == null) {
        // User membatalkan kamera
        _showErrorDialog('Foto nasabah wajib diambil untuk setoran manual.');
        return;
      }
      setState(() => _fotoFile = foto);
    }

    setState(() => _isSubmitting = true);
    HapticFeedback.mediumImpact();

    List<Map<String, dynamic>> items = [];
    for (int i = 0; i < _filtered.length; i++) {
      final ctrl = _inputControllers[i];
      if (ctrl == null || ctrl.text.isEmpty) continue;
      final qty = double.tryParse(ctrl.text) ?? 0;
      if (qty > 0) {
        items.add({
          'sampah_id': _filtered[i].sampahId,
          'qty': qty,
          'nilai_poin': _filtered[i].poinNasabah,
        });
      }
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final adminId = auth.identityId ?? '';
    final token = auth.currentUser?.accessToken ?? '';

    final res = await SetoranService.inputSetoran(
      widget.penimbanganId,
      widget.nasabahId,
      adminId,
      items,
      token,
      viaManual: !widget.dariQr,
      fotoFile: _fotoFile,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (res['success'] == true) {
      _showSuccessDialog(res['total_item'] ?? 0, (res['total_poin'] as num?)?.toDouble() ?? 0.0);
    } else {
      _showErrorDialog(res['message'] ?? 'Gagal menyimpan setoran');
    }
  }

  void _showSuccessDialog(int totalItem, double totalPoin) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF4EA771).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF4EA771),
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Setoran Berhasil!',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: Color(0xFF013236),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tercatat $totalItem item dengan total:',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${_fmtDoubleFromDouble(totalPoin)} Poin',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w800,
                fontSize: 22,
                color: Color(0xFF4EA771),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx); // Tutup dialog
                  Navigator.pop(context); // Kembali ke halaman penimbangan
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF013236),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Tutup', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
              ),
            )
          ],
        ),
      ),
    );
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
                  const SizedBox(height: 16),
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
                    key: ValueKey('${_filtered[i].namaSampah}-${_filtered[i].satuan}-$i'),
                    item: _filtered[i],
                    controller: _controllerAt(i),
                    onChanged: (_) => setState(() {}),
                  )),
                  const SizedBox(height: 12),
                  _buildAkumulasiCard(),
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
          color: const Color(0xFF013236),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF013236).withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFF4EA771).withOpacity(0.18),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.person_rounded,
                color: Color(0xFF4EA771),
                size: 24,
              ),
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
                      color: Color(0xFFFFFFFF),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    widget.nasabahId,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: const Color(0xFFFFFFFF).withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
            // Badge QR / Manual
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF4EA771).withOpacity(0.15),
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF013236).withOpacity(0.07),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (v) => setState(() {
            _searchQuery = v;
            _inputControllers.clear();
          }),
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            color: Color(0xFF013236),
          ),
          decoration: InputDecoration(
            hintText: 'Cari sampah dari katalog...',
            hintStyle: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: const Color(0xFF013236).withOpacity(0.3),
            ),
            prefixIcon: const Padding(
              padding: EdgeInsets.only(left: 16, right: 10),
              child: Icon(Icons.search_rounded, color: Color(0xFF4EA771), size: 20),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 0),
            suffixIcon: _searchQuery.isNotEmpty
                ? GestureDetector(
              onTap: () => setState(() {
                _searchController.clear();
                _searchQuery = '';
                _inputControllers.clear();
              }),
              child: const Padding(
                padding: EdgeInsets.only(right: 14),
                child: Icon(Icons.cancel_rounded, size: 17, color: Color(0xFF4EA771)),
              ),
            )
                : null,
            suffixIconConstraints: const BoxConstraints(minWidth: 0),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
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
              color: Colors.white.withOpacity(0.65),
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

  // ── Card akumulasi total poin ─────────────────────────────────────
  Widget _buildAkumulasiCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2D7D52), Color(0xFF58AD74), Color(0xFF4EA771)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2D7D52).withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: const Color(0xFF4EA771).withOpacity(0.2),
              blurRadius: 40,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Lingkaran dekoratif background — memberi kedalaman
            Positioned(
              top: -24,
              right: -24,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
            ),
            Positioned(
              bottom: -18,
              left: 60,
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.06),
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 90,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),

            // Konten
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Row(
                children: [
                  // ── Total Poin ──────────────────────────────────────────
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(9),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.15),
                                  width: 1,
                                ),
                              ),
                              child: const Icon(
                                Icons.stars_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Total Poin',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _fmtDoubleFromDouble(_totalPoin),
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w800,
                                fontSize: 24,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Padding(
                              padding: EdgeInsets.only(bottom: 4),
                              child: Text(
                                'poin',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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
            color: const Color(0xFF013236).withOpacity(0.08),
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
            gradient: const LinearGradient(
              colors: [Color(0xFF013236), Color(0xFF1A5C45), Color(0xFF2D7D52)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: _adaInput
                ? [
              BoxShadow(
                color: const Color(0xFF013236).withOpacity(0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: const Color(0xFF4EA771).withOpacity(0.2),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ]
                : [],
          ),
          child: ElevatedButton(
            onPressed: _adaInput && !_isSubmitting ? _simpanSetoran : null,
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
            child: _isSubmitting 
              ? const SizedBox(
                  width: 20, height: 20, 
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)
                )
              : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Simpan Setoran Nasabah',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatRupiah(int value) {
    if (value == 0) return '0';
    return value
        .toString()
        .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
  }

  String _fmtDoubleFromDouble(double value) {
    if (value == value.truncateToDouble()) {
      return value.toInt().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
    }
    return value.toStringAsFixed(2).replaceAll(RegExp(r'0*$'), '').replaceAll(RegExp(r'\.$'), '').replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Card Input — expandable
// ─────────────────────────────────────────────────────────────────────────────

class _CardInput extends StatefulWidget {
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
  State<_CardInput> createState() => _CardInputState();
}

class _CardInputState extends State<_CardInput>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _animCtrl;
  late Animation<double> _expandAnim;
  late Animation<double> _fadeAnim;
  final FocusNode _focusNode = FocusNode();

  bool get _hasValue =>
      (double.tryParse(widget.controller.text) ?? 0) > 0;

  // ── Style badge kategori — poin only ──────
  _BadgeStyle get _badgeStyle {
    return const _BadgeStyle(
      bg: Color(0xFFE8F4D6),      // olive muda
      text: Color(0xFF2D5A1D),    // olive tua
      icon: Icons.stars_rounded,
      label: 'poin',
    );
  }

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
    _expandAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);

    _focusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    if (_expanded) {
      _animCtrl.forward();
      Future.delayed(const Duration(milliseconds: 180), () {
        if (mounted) _focusNode.requestFocus();
      });
    } else {
      _animCtrl.reverse();
      _focusNode.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final badge = _badgeStyle;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: GestureDetector(
        onTap: _toggle,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            // Collapsed = light green card, expanded = white
            color: _expanded ? Colors.white : const Color(0xFFFFFFFF),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              // Border hijau tipis kalau ada nilai, transparan kalau kosong
              color: _hasValue
                  ? const Color(0xFF4EA771).withOpacity(0.6)
                  : _expanded
                  ? const Color(0xFF4EA771).withOpacity(0.25)
                  : Colors.transparent,
              width: 1,
            ),
            boxShadow: _expanded
                ? [
              BoxShadow(
                color: const Color(0xFF013236).withOpacity(0.08),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ]
                : [],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Header row ──────────────────────────────────────────────
                Row(
                  children: [
                    // Ikon gambar sampah
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4EA771).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: widget.item.photoUrl.isNotEmpty 
                          ? Image.network(widget.item.photoUrl, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.recycling_rounded, size: 20, color: Color(0xFF4EA771)))
                          : const Icon(Icons.recycling_rounded, size: 20, color: Color(0xFF4EA771)),
                    ),
                    const SizedBox(width: 12),

                    // Nama & harga
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.item.namaSampah,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: Color(0xFF013236),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_fmtDouble(widget.item.poinNasabah)} Poin / ${widget.item.satuan}',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              color: const Color(0xFF013236).withOpacity(0.45),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Badge kategori
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: badge.bg,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(badge.icon, size: 11, color: badge.text),
                          const SizedBox(width: 4),
                          Text(
                            badge.label,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: badge.text,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 6),

                    // Nilai pill (collapsed + ada nilai) atau chevron
                    if (_hasValue && !_expanded)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4EA771).withOpacity(0.13),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${widget.controller.text} ${widget.item.satuan}',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF4EA771),
                          ),
                        ),
                      )
                    else
                      AnimatedRotation(
                        turns: _expanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 220),
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 20,
                          color: const Color(0xFF013236).withOpacity(0.3),
                        ),
                      ),
                  ],
                ),

                // ── Expanded: input area ────────────────────────────────────
                SizeTransition(
                  sizeFactor: _expandAnim,
                  axisAlignment: -1,
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),
                        Divider(height: 1, color: const Color(0xFF013236).withOpacity(0.07)),
                        const SizedBox(height: 14),

                        Row(
                          children: [
                            // Keterangan satuan
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Jumlah setoran',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 11,
                                      color: const Color(0xFF013236).withOpacity(0.45),
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    'Masukkan dalam ${widget.item.satuan}',
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF013236),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Input field
                            GestureDetector(
                              onTap: () {}, // cegah bubble ke card toggle
                              child: Container(
                                width: 120,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF4FCF4),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _focusNode.hasFocus
                                        ? const Color(0xFF4EA771)
                                        : const Color(0xFF4EA771).withOpacity(0.2),
                                    width: 1.5,
                                  ),
                                ),
                                child: TextField(
                                  controller: widget.controller,
                                  focusNode: _focusNode,
                                  onChanged: widget.onChanged,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                                  ],
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: Color(0xFF013236),
                                  ),
                                  decoration: InputDecoration(
                                    hintText: '0',
                                    hintStyle: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      color: const Color(0xFF013236).withOpacity(0.18),
                                    ),
                                    suffixText: widget.item.satuan,
                                    suffixStyle: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF4EA771).withOpacity(0.7),
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Preview kalkulasi — hanya muncul kalau ada nilai
                        if (_hasValue) ...[
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 9),
                            decoration: BoxDecoration(
                              // Warna preview selaras palet hijau, bukan kuning/ungu
                              color: const Color(0xFF013236).withOpacity(0.05),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calculate_rounded,
                                  size: 13,
                                  color: const Color(0xFF013236).withOpacity(0.4),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${widget.controller.text} ${widget.item.satuan}  ×  ${_fmtDouble(widget.item.poinNasabah)}',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 11,
                                    color: const Color(0xFF013236).withOpacity(0.5),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${_calcNilai()} Poin',
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                    color: Color(0xFF013236),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _calcNilai() {
    final val = double.tryParse(widget.controller.text) ?? 0;
    return _fmtDouble(val * widget.item.poinNasabah);
  }

  String _fmtDouble(double value) {
    if (value == value.truncateToDouble()) {
      return value.toInt().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
    }
    // format as decimal e.g. 2.5
    final str = value.toStringAsFixed(2).replaceAll(RegExp(r'0*$'), '').replaceAll(RegExp(r'\.$'), '');
    return str.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.'); // not perfect for decimals but ok for now, or just return str
  }

  String _fmt(int value) =>
      value.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
}

// ─────────────────────────────────────────────────────────────────────────────
// Badge style helper
// ─────────────────────────────────────────────────────────────────────────────

class _BadgeStyle {
  final Color bg;
  final Color text;
  final IconData icon;
  final String label;

  const _BadgeStyle({
    required this.bg,
    required this.text,
    required this.icon,
    required this.label,
  });
}
