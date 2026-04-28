import 'package:enviroo/providers/auth_provider.dart';
import 'package:enviroo/screens/admin_bsi/scan_petugas_bsu_screen.dart';
import 'package:enviroo/services/pengangkutan_service.dart';
import 'package:enviroo/widgets/topbar_back.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

// ─── Model ──────────────────────────────────────────────────────────────────

class SampahPengangkutan {
  final String sampahId;
  final String namaSampah;
  final String satuan;
  final double nilaiPoin;
  final double stok;

  SampahPengangkutan({
    required this.sampahId,
    required this.namaSampah,
    required this.satuan,
    required this.nilaiPoin,
    required this.stok,
  });

  factory SampahPengangkutan.fromJson(Map<String, dynamic> json) {
    return SampahPengangkutan(
      sampahId: json['sampah_id'] ?? '',
      namaSampah: json['nama_sampah'] ?? '-',
      satuan: json['satuan'] ?? '-',
      nilaiPoin: (json['nilai_poin'] as num? ?? 0).toDouble(),
      stok: (json['stok'] as num? ?? 0).toDouble(),
    );
  }
}

// ─── Screen ─────────────────────────────────────────────────────────────────

class AngkutSetoranBsiScreen extends StatefulWidget {
  final String pengangkutanId;
  final String bsiId;
  final String bsuId;
  final String namaBsu;

  /// admin_bsu_id yang sudah tercatat di sesi pengangkutan (mis. saat sesi
  /// dimulai dari sisi BSU). Jika kosong, scan QR petugas BSU wajib dilakukan
  /// untuk menentukan admin_bsu_id pada saat input.
  final String adminBsuIdAwal;

  const AngkutSetoranBsiScreen({
    super.key,
    required this.pengangkutanId,
    required this.bsiId,
    required this.bsuId,
    required this.namaBsu,
    this.adminBsuIdAwal = '',
  });

  @override
  State<AngkutSetoranBsiScreen> createState() => _AngkutSetoranBsiScreenState();
}

class _AngkutSetoranBsiScreenState extends State<AngkutSetoranBsiScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final Map<int, TextEditingController> _inputControllers = {};

  List<SampahPengangkutan> _sampah = [];
  bool _isLoading = true;
  String? _errorMsg;

  List<SampahPengangkutan> get _filtered => _sampah
      .where((s) =>
          s.namaSampah.toLowerCase().contains(_searchQuery.toLowerCase()))
      .toList();

  TextEditingController _controllerAt(int index) =>
      _inputControllers.putIfAbsent(index, () => TextEditingController());

  double get _totalPoin {
    double total = 0;
    for (int i = 0; i < _filtered.length; i++) {
      final ctrl = _inputControllers[i];
      if (ctrl == null) continue;
      final val = double.tryParse(ctrl.text) ?? 0;
      total += val * _filtered[i].nilaiPoin;
    }
    return total;
  }

  bool get _adaInput => _inputControllers.values
      .any((c) => c.text.isNotEmpty && (double.tryParse(c.text) ?? 0) > 0);

  @override
  void initState() {
    super.initState();
    _fetchSampah();
  }

  @override
  void dispose() {
    _searchController.dispose();
    for (final ctrl in _inputControllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  Future<void> _fetchSampah() async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final token = auth.currentUser?.accessToken ?? '';

    final res = await PengangkutanService.listSampah(widget.bsiId, widget.bsuId, token);
    if (!mounted) return;

    if (res['success'] == true) {
      final List data = res['data'] ?? [];
      setState(() {
        _sampah = data
            .map((e) => SampahPengangkutan.fromJson(e as Map<String, dynamic>))
            .toList();
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMsg = res['message'] ?? 'Gagal memuat data sampah';
        _isLoading = false;
      });
    }
  }

  void _showError(String msg) {
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
        content: Text(msg,
            style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: Colors.grey[700])),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup',
                style: TextStyle(
                    color: Color(0xFF013236),
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _lanjutKeScan() async {
    if (!_adaInput) return;

    // Kumpulkan items
    final List<Map<String, dynamic>> items = [];
    final List<String> errorItems = [];
    for (int i = 0; i < _filtered.length; i++) {
      final ctrl = _inputControllers[i];
      if (ctrl == null || ctrl.text.isEmpty) continue;
      final qty = double.tryParse(ctrl.text) ?? 0;
      if (qty > 0) {
        if (qty > _filtered[i].stok) {
          final fmtStok = _filtered[i].stok == _filtered[i].stok.truncateToDouble()
              ? _filtered[i].stok.toInt().toString()
              : _filtered[i].stok.toStringAsFixed(2).replaceAll('.', ',');
          errorItems.add('${_filtered[i].namaSampah} (Maks: $fmtStok ${_filtered[i].satuan})');
          continue;
        }
        items.add({
          'sampah_id': _filtered[i].sampahId,
          'qty': qty,
          'nilai_poin': _filtered[i].nilaiPoin,
        });
      }
    }

    if (errorItems.isNotEmpty) {
      _showError('Gagal menyimpan karena input melebihi stok yang tersedia di BSU:\n\n- ${errorItems.join('\n- ')}');
      return;
    }

    if (items.isEmpty) {
      _showError('Setidaknya isi satu item sampah.');
      return;
    }

    HapticFeedback.mediumImpact();

    final hasil = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ScanPetugasBsuScreen(
          pengangkutanId: widget.pengangkutanId,
          namaBsu: widget.namaBsu,
          items: items,
          totalPoin: _totalPoin,
          adminBsuIdAwal: widget.adminBsuIdAwal,
        ),
      ),
    );

    if (!mounted) return;
    // Jika sukses, tutup screen ini juga supaya kembali ke layar daftar
    if (hasil == true) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: SafeArea(
        child: Column(
          children: [
            const TopBarBack(title: 'Input Setoran BSU'),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFF4EA771)))
                  : _errorMsg != null
                      ? _buildErrorView()
                      : ListView(
                          padding: EdgeInsets.zero,
                          children: [
                            const SizedBox(height: 8),
                            _buildBsuCard(),
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
                                    'Sampah tidak ditemukan',
                                    style: TextStyle(
                                        fontFamily: 'Poppins',
                                        color: Colors.grey[400]),
                                  ),
                                ),
                              ),
                            ...List.generate(
                                _filtered.length,
                                (i) => _CardInputSampah(
                                      key: ValueKey(_filtered[i].sampahId),
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
      bottomNavigationBar: _isLoading || _errorMsg != null
          ? null
          : _buildBottomBar(),
    );
  }

  // ── BSU header card ────────────────────────────────────────────────────────
  Widget _buildBsuCard() {
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
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFF06C0C9).withOpacity(0.18),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.local_shipping_rounded,
                color: Color(0xFF06C0C9),
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.namaBsu,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Color(0xFFFFFFFF),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    'Sesi #${widget.pengangkutanId}',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: const Color(0xFFFFFFFF).withOpacity(0.5),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF06C0C9).withOpacity(0.18),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.recycling_rounded, size: 12, color: Color(0xFF06C0C9)),
                  SizedBox(width: 5),
                  Text(
                    'Pengangkutan',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF06C0C9),
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

  // ── Search ─────────────────────────────────────────────────────────────────
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
            hintText: 'Cari jenis sampah...',
            hintStyle: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: const Color(0xFF013236).withOpacity(0.3),
            ),
            prefixIcon: const Padding(
              padding: EdgeInsets.only(left: 16, right: 10),
              child: Icon(Icons.search_rounded,
                  color: Color(0xFF4EA771), size: 20),
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
                      child: Icon(Icons.cancel_rounded,
                          size: 17, color: Color(0xFF4EA771)),
                    ),
                  )
                : null,
            suffixIconConstraints: const BoxConstraints(minWidth: 0),
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildKatalogHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          const Text(
            'Daftar Sampah BSU',
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

  Widget _buildAkumulasiCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF013236),
              Color(0xFF025059),
              Color(0xFF06C0C9),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF013236).withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            children: [
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
                          'Total Poin Setoran',
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
                          _formatRupiah(_totalPoin),
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
      ),
    );
  }

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
              colors: [
                Color(0xFF013236),
                Color(0xFF025059),
                Color(0xFF06C0C9),
              ],
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
                  ]
                : [],
          ),
          child: ElevatedButton(
            onPressed: _adaInput ? _lanjutKeScan : null,
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
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Simpan Setoran BSU',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    letterSpacing: 0.2,
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 56, color: Colors.grey[300]),
            const SizedBox(height: 14),
            Text(
              _errorMsg!,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _fetchSampah,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Coba Lagi',
                  style: TextStyle(fontFamily: 'Poppins')),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4EA771),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatRupiah(double value) {
    if (value == 0) return '0';
    final intVal = value.truncate();
    final dec = value - intVal;
    String result = intVal
        .toString()
        .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
    if (dec > 0) result += dec.toStringAsFixed(2).substring(1);
    return result;
  }
}

// ─── Card Input — expandable ─────────────────────────────────────────────────

class _CardInputSampah extends StatefulWidget {
  final SampahPengangkutan item;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _CardInputSampah({
    super.key,
    required this.item,
    required this.controller,
    required this.onChanged,
  });

  @override
  State<_CardInputSampah> createState() => _CardInputSampahState();
}

class _CardInputSampahState extends State<_CardInputSampah>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _animCtrl;
  late Animation<double> _expandAnim;
  late Animation<double> _fadeAnim;
  final FocusNode _focusNode = FocusNode();

  bool get _hasValue => (double.tryParse(widget.controller.text) ?? 0) > 0;
  bool get _isExceedingStok => (double.tryParse(widget.controller.text) ?? 0) > widget.item.stok;

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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: GestureDetector(
        onTap: _toggle,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _isExceedingStok
                  ? Colors.red.withOpacity(0.8)
                  : _hasValue
                      ? const Color(0xFF06C0C9).withOpacity(0.6)
                      : _expanded
                          ? const Color(0xFF06C0C9).withOpacity(0.25)
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
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF06C0C9).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Icon(Icons.recycling_rounded,
                          size: 20, color: Color(0xFF06C0C9)),
                    ),
                    const SizedBox(width: 12),
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
                            '${_fmt(widget.item.nilaiPoin)} Poin / ${widget.item.satuan}',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              color: const Color(0xFF013236).withOpacity(0.45),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_hasValue && !_expanded)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF06C0C9).withOpacity(0.13),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${widget.controller.text} ${widget.item.satuan}',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: _isExceedingStok ? Colors.red : const Color(0xFF06C0C9),
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
                SizeTransition(
                  sizeFactor: _expandAnim,
                  axisAlignment: -1,
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),
                        Divider(
                            height: 1,
                            color: const Color(0xFF013236).withOpacity(0.07)),
                        const SizedBox(height: 10),
                        // Stok BSU info row
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                          decoration: BoxDecoration(
                            color: widget.item.stok > 0
                                ? const Color(0xFF4EA771).withOpacity(0.07)
                                : Colors.orange.withOpacity(0.07),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.inventory_2_rounded,
                                size: 13,
                                color: widget.item.stok > 0
                                    ? const Color(0xFF4EA771)
                                    : Colors.orange,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Stok tersedia di BSU:',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 11,
                                  color: const Color(0xFF013236).withOpacity(0.5),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${_fmtStok(widget.item.stok)} ${widget.item.satuan}',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: widget.item.stok > 0
                                      ? const Color(0xFF4EA771)
                                      : Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Jumlah diangkut',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 11,
                                      color: const Color(0xFF013236)
                                          .withOpacity(0.45),
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
                            GestureDetector(
                              onTap: () {},
                              child: Container(
                                width: 120,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: _isExceedingStok
                                      ? Colors.red.withOpacity(0.05)
                                      : const Color(0xFFE0F8FA),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _isExceedingStok
                                        ? Colors.red.withOpacity(0.6)
                                        : _focusNode.hasFocus
                                            ? const Color(0xFF06C0C9)
                                            : const Color(0xFF06C0C9)
                                                .withOpacity(0.2),
                                    width: 1.5,
                                  ),
                                ),
                                child: TextField(
                                  controller: widget.controller,
                                  focusNode: _focusNode,
                                  onChanged: widget.onChanged,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                        RegExp(r'^\d*\.?\d*')),
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
                                      color: const Color(0xFF013236)
                                          .withOpacity(0.18),
                                    ),
                                    suffixText: widget.item.satuan,
                                    suffixStyle: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF06C0C9)
                                          .withOpacity(0.7),
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
                        if (_isExceedingStok)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                const Icon(Icons.error_outline_rounded, size: 12, color: Colors.red),
                                const SizedBox(width: 4),
                                Text(
                                  'Melebihi stok BSU',
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (_hasValue && !_isExceedingStok) ...[
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 9),
                            decoration: BoxDecoration(
                              color: const Color(0xFF013236).withOpacity(0.05),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calculate_rounded,
                                  size: 13,
                                  color:
                                      const Color(0xFF013236).withOpacity(0.4),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${widget.controller.text} ${widget.item.satuan}  ×  ${_fmt(widget.item.nilaiPoin)}',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 11,
                                    color: const Color(0xFF013236)
                                        .withOpacity(0.5),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${_fmt(_calcNilai())} Poin',
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

  double _calcNilai() {
    final val = double.tryParse(widget.controller.text) ?? 0;
    return val * widget.item.nilaiPoin;
  }

  String _fmt(double value) {
    final intPart = value.truncate();
    final dec = value - intPart;
    final formatted = intPart
        .toString()
        .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
    if (dec > 0) return '$formatted${dec.toStringAsFixed(2).substring(1)}';
    return formatted;
  }

  String _fmtStok(double value) {
    final intPart = value.truncate();
    final dec = value - intPart;
    final formatted = intPart
        .toString()
        .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
    if (dec > 0) return '$formatted${dec.toStringAsFixed(2).substring(1)}';
    return formatted;
  }
}
