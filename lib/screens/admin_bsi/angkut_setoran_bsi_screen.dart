import 'package:enviroo/screens/admin_bsi/detail_pengangkutan_screen.dart';
import 'package:enviroo/screens/admin_bsi/preview_setoran_bsu_screen.dart';
import 'package:enviroo/services/pengangkutan_service.dart';
import 'package:enviroo/widgets/custom_snackbar.dart';
import 'package:enviroo/widgets/filter_chip_row.dart';
import 'package:enviroo/widgets/search.dart';
import 'package:enviroo/widgets/topbar_back.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─── Model ──────────────────────────────────────────────────────────────────

class SampahPengangkutan {
  final String sampahId;
  final String namaSampah;
  final String fotoSampah;
  final String satuan;
  final String namaReward;
  final double stok;

  SampahPengangkutan({
    required this.sampahId,
    required this.namaSampah,
    required this.fotoSampah,
    required this.satuan,
    required this.namaReward,
    required this.stok,
  });

  factory SampahPengangkutan.fromJson(Map<String, dynamic> json) {
    return SampahPengangkutan(
      sampahId: json['sampah_id'] ?? '',
      namaSampah: json['nama_sampah'] ?? '-',
      fotoSampah: json['foto_sampah'] ?? '',
      satuan: json['satuan'] ?? '-',
      namaReward: json['nama_reward'] ?? '',
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
  String _selectedReward = 'Semua';

  final Map<int, TextEditingController> _inputControllers = {};

  List<SampahPengangkutan> _sampah = [];
  bool _isLoading = true;
  bool _isPreviewLoading = false;
  String? _errorMsg;

  List<SampahPengangkutan> get _filtered => _sampah.where((s) {
        final matchSearch =
            s.namaSampah.toLowerCase().contains(_searchQuery.toLowerCase());
        final matchReward = _selectedReward == 'Semua' ||
            s.namaReward.toLowerCase() == _selectedReward.toLowerCase();
        return matchSearch && matchReward;
      }).toList();

  TextEditingController _controllerAt(int index) =>
      _inputControllers.putIfAbsent(index, () => TextEditingController());

  int get _selectedCount {
    int count = 0;
    for (int i = 0; i < _filtered.length; i++) {
      final ctrl = _inputControllers[i];
      if (ctrl == null) continue;
      if ((double.tryParse(ctrl.text) ?? 0) > 0) count++;
    }
    return count;
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

    final res = await PengangkutanService.listSampah(widget.bsiId, widget.bsuId);
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

  Future<void> _lanjutKePreview() async {
    if (!_adaInput || _isPreviewLoading) return;

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
          'satuan': _filtered[i].satuan,
        });
      }
    }

    if (errorItems.isNotEmpty) {
      showCustomSnackBar(context, 'Gagal menyimpan karena input melebihi stok yang tersedia di BSU:\n\n- ${errorItems.join('\n- ')}');
      return;
    }

    if (items.isEmpty) {
      showCustomSnackBar(context, 'Setidaknya isi satu item sampah.');
      return;
    }

    setState(() => _isPreviewLoading = true);
    HapticFeedback.mediumImpact();

    final res = await PengangkutanService.previewPengangkutan(
      widget.pengangkutanId,
      items,
    );

    if (!mounted) return;
    setState(() => _isPreviewLoading = false);

    if (res['success'] != true) {
      showCustomSnackBar(context, res['message'] ?? 'Gagal memuat preview setoran');
      return;
    }

    final previewData = PreviewPengangkutanData.fromJson(
      res['data'] as Map<String, dynamic>,
    );

    final String? pengangkutanId = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => PreviewSetoranBsuScreen(
          data: previewData,
          items: items,
          adminBsuIdAwal: widget.adminBsuIdAwal,
        ),
      ),
    );

    if (!mounted) return;
    if (pengangkutanId != null && pengangkutanId.isNotEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DetailPengangkutanScreen(
            pengangkutanId: pengangkutanId,
            namaBsu: widget.namaBsu,
          ),
        ),
      );
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
                            const SizedBox(height: 13),
                            _buildFilterChips(),
                            const SizedBox(height: 25),
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
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFF94DF0C).withOpacity(0.09),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(
                Icons.local_shipping_rounded,
                color: Color(0xFF94DF0C),
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
          ],
        ),
      ),
    );
  }

  // ── Search ─────────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return CustomSearchBar(
      controller: _searchController,
      hintText: 'Cari jenis sampah...',
      searchQuery: _searchQuery,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      fillColor: Colors.white,
      onChanged: (v) => setState(() {
        _searchQuery = v;
        _inputControllers.clear();
      }),
      onClear: () => setState(() {
        _searchController.clear();
        _searchQuery = '';
        _inputControllers.clear();
      }),
    );
  }

  Widget _buildFilterChips() {
    return FilterChipRow<String>(
      selectedValue: _selectedReward,
      onSelected: (val) => setState(() {
        _selectedReward = val;
        _inputControllers.clear();
      }),
      items: const [
        FilterChipItem(value: 'Semua', label: 'Semua'),
        FilterChipItem(value: 'Uang', label: 'Uang'),
        FilterChipItem(value: 'Sembako', label: 'Sembako'),
      ],
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

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 14, 20, MediaQuery.of(context).padding.bottom + 14),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF013236).withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: AnimatedOpacity(
        opacity: (_adaInput || _isPreviewLoading) ? 1.0 : 0.4,
        duration: const Duration(milliseconds: 200),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color : Color(0xFF013236),
            borderRadius: BorderRadius.circular(30),
          ),
          child: ElevatedButton(
            onPressed: (_adaInput && !_isPreviewLoading) ? _lanjutKePreview : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              disabledBackgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              disabledForegroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: _isPreviewLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Preview Setoran BSU',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
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
                Row(
                  children: [
                    widget.item.fotoSampah.isNotEmpty
                        ? ClipOval(
                            child: Image.network(
                              widget.item.fotoSampah,
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _buildFallbackIcon(),
                            ),
                          )
                        : _buildFallbackIcon(),
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
                        ],
                      ),
                    ),
                    if (widget.item.namaReward.isNotEmpty && !_hasValue)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4EA771).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.item.namaReward,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF4EA771),
                          ),
                        ),
                      ),
                    if (_hasValue && !_expanded)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4EA771).withValues(alpha: 0.13),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${widget.controller.text} ${widget.item.satuan}',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: _isExceedingStok ? Colors.red : const Color(0xFF4EA771),
                          ),
                        ),
                      ),
                    if (!_hasValue || _expanded)
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
                                      : const Color(0xFF4EA771).withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _isExceedingStok
                                        ? Colors.red.withOpacity(0.6)
                                        : _focusNode.hasFocus
                                            ? const Color(0xFF4EA771)
                                            : const Color(0xFF4EA771)
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
                                      color: const Color(0xFF4EA771)
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

  Widget _buildFallbackIcon() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFF4EA771).withOpacity(0.12),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.recycling_rounded, size: 20, color: Color(0xFF4EA771)),
    );
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
