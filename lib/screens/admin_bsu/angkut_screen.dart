import 'package:enviroo/screens/admin_bsu/QR_angkut_sampah_screen.dart';
import 'package:enviroo/widgets/topbar_back.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Palette
// ─────────────────────────────────────────────────────────────────────────────
class _C {
  static const bg        = Color(0xFFF2FAF0);
  static const dark      = Color(0xFF0D3B3E);
  static const card      = Color(0xFFFFFFFF);
  static const accent    = Color(0xFF4EA771);
  static const lime      = Color(0xFF8ED60A);
}

// ─────────────────────────────────────────────────────────────────────────────
// Dummy data model
// ─────────────────────────────────────────────────────────────────────────────
class _StokSampah {
  final String nama;
  final double stok;
  final String satuan;   // "kg" | "pcs"
  final String kategori; // "uang" | "poin"

  const _StokSampah({
    required this.nama,
    required this.stok,
    required this.satuan,
    required this.kategori,
  });
}

const List<_StokSampah> _dummyStok = [
  _StokSampah(nama: 'Botol Plastik',      stok: 24.5, satuan: 'kg',  kategori: 'uang'),
  _StokSampah(nama: 'Botol Plastik',      stok: 130,  satuan: 'pcs', kategori: 'uang'),
  _StokSampah(nama: 'Kertas Kardus',      stok: 18.0, satuan: 'kg',  kategori: 'poin'),
  _StokSampah(nama: 'Kaleng Aluminium',   stok: 7.2,  satuan: 'kg',  kategori: 'poin'),
  _StokSampah(nama: 'Botol Kaca',         stok: 45,   satuan: 'pcs', kategori: 'uang'),
  _StokSampah(nama: 'Minyak Jelantah',    stok: 12.8, satuan: 'kg',  kategori: 'poin'),
  _StokSampah(nama: 'Besi Tua',           stok: 9.5,  satuan: 'kg',  kategori: 'uang'),
  _StokSampah(nama: 'Kertas HVS',         stok: 15.0, satuan: 'kg',  kategori: 'poin'),
  _StokSampah(nama: 'Gelas Plastik',      stok: 200,  satuan: 'pcs', kategori: 'uang'),
  _StokSampah(nama: 'Ember Plastik',      stok: 8,    satuan: 'pcs', kategori: 'poin'),
];

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────
class PengangkutanBSUkeBSIScreen extends StatefulWidget {
  @override
  State<PengangkutanBSUkeBSIScreen> createState() => _PengangkutanStokState();
}

class _PengangkutanStokState extends State<PengangkutanBSUkeBSIScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final Map<int, TextEditingController> _inputControllers = {};

  List<_StokSampah> get _filtered => _dummyStok
      .where((s) => s.nama.toLowerCase().contains(_searchQuery.toLowerCase()))
      .toList();

  TextEditingController _controllerAt(int index) =>
      _inputControllers.putIfAbsent(index, () => TextEditingController());

  int get _selectedCount {
    int count = 0;
    for (final entry in _inputControllers.entries) {
      final val = double.tryParse(entry.value.text) ?? 0;
      if (val > 0) count++;
    }
    return count;
  }

  bool get _adaInput =>
      _inputControllers.values.any((c) => c.text.isNotEmpty && (double.tryParse(c.text) ?? 0) > 0);

  int get _totalJenis => _dummyStok.length;

  String get _totalStokLabel {
    // Gabungkan stok yang satuan "kg"
    double totalKg = 0;
    int totalPcs = 0;
    for (final s in _dummyStok) {
      if (s.satuan == 'kg') {
        totalKg += s.stok;
      } else {
        totalPcs += s.stok.toInt();
      }
    }
    final parts = <String>[];
    if (totalKg > 0) parts.add('${totalKg.toStringAsFixed(1)} kg');
    if (totalPcs > 0) parts.add('$totalPcs pcs');
    return parts.join(' · ');
  }

  double get _totalKg {
    double total = 0;
    for (final s in _dummyStok) {
      if (s.satuan == 'kg') total += s.stok;
    }
    return total;
  }

  int get _totalPcs {
    int total = 0;
    for (final s in _dummyStok) {
      if (s.satuan == 'pcs') total += s.stok.toInt();
    }
    return total;
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
      backgroundColor: Color(0xFFFFFFFF),
      body: SafeArea(
        child: Column(
          children: [
            TopBarBack(title: "Stok dan Angkut"),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildHeader(),
                  _buildSummaryCard(),
                  _buildSearchBar(),
                  _buildListHeader(),
                  const SizedBox(height: 4),
                  ...List.generate(_filtered.length, (i) => _StokCard(
                    key: ValueKey('${_filtered[i].nama}-${_filtered[i].satuan}-$i'),
                    item: _filtered[i],
                    controller: _controllerAt(i),
                    onChanged: (_) => setState(() {}),
                  )),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 6, 28, 0),
      child: Text(
        "Stok sampah dihitung dari setoran nasabah. Pilih sampah yang ingin diangkut ke BSI dan masukkan jumlahnya.",
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12.5,
          height: 1.6,
          color: _C.dark.withOpacity(0.7),
        ),
      ),
    );
  }

  // ── Summary stat card ─────────────────────────────────────────────────────
  Widget _buildSummaryCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0D3B3E), Color(0xFF1A5C61)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: _C.dark.withOpacity(0.25),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildStatPill(
                icon: Icons.scale_rounded,
                value: '${_totalKg.toStringAsFixed(1)}',
                unit: 'kg',
                iconColor: const Color(0xFF06C0C9),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildStatPill(
                icon: Icons.format_list_numbered_rounded,
                value: '$_totalPcs',
                unit: 'pcs',
                iconColor: _C.lime,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatPill({
    required IconData icon,
    required String value,
    required String unit,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: iconColor),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.1,
                ),
              ),
              Text(
                unit,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Search bar ────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() {
          _searchQuery = v;
          _inputControllers.clear();
        }),
        style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: _C.dark),
        decoration: InputDecoration(
          hintText: "Cari nama sampah...",
          hintStyle: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            color: _C.dark.withOpacity(0.3),
          ),
          prefixIcon: const Icon(Icons.search_rounded, color: _C.accent, size: 22),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
            icon: Icon(Icons.close_rounded, size: 18, color: _C.dark.withOpacity(0.35)),
            onPressed: () {
              _searchController.clear();
              setState(() {
                _searchQuery = '';
                _inputControllers.clear();
              });
            },
          )
              : null,
          filled: true,
          fillColor: Colors.white,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(50),
            borderSide: BorderSide(color: _C.accent.withOpacity(0.3), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(50),
            borderSide: const BorderSide(color: _C.accent, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
    );
  }

  // ── List header ───────────────────────────────────────────────────────────
  Widget _buildListHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 0),
      child: Row(
        children: [
          const Text(
            'Daftar Stok Sampah',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: _C.dark,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _C.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_filtered.length} item',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: _C.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom bar ────────────────────────────────────────────────────────────
  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 14, 20, MediaQuery.of(context).padding.bottom + 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: _C.dark.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Selected count info
          if (_adaInput)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_rounded, size: 14, color: _C.accent),
                  const SizedBox(width: 6),
                  Text(
                    '$_selectedCount jenis sampah dipilih',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: _C.accent,
                    ),
                  ),
                ],
              ),
            ),

          // Button
          AnimatedOpacity(
            opacity: _adaInput ? 1.0 : 0.4,
            duration: const Duration(milliseconds: 200),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0D3B3E), Color(0xFF1A5C45), Color(0xFF2D7D52)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: _adaInput
                    ? [
                  BoxShadow(
                    color: _C.dark.withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
                    : [],
              ),
              child: ElevatedButton(
                onPressed: _adaInput
                    ? () {
                        HapticFeedback.mediumImpact();
                        // Collect selected items
                        final selectedItems = <Map<String, dynamic>>[];
                        final filtered = _filtered;
                        for (final entry in _inputControllers.entries) {
                          final val = double.tryParse(entry.value.text) ?? 0;
                          if (val > 0 && entry.key < filtered.length) {
                            selectedItems.add({
                              'nama': filtered[entry.key].nama,
                              'jumlah': val,
                              'satuan': filtered[entry.key].satuan,
                            });
                          }
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => QRAngkutSampahScreen(
                              selectedItems: selectedItems,
                            ),
                          ),
                        );
                      }
                    : null,
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
                      'Angkut Sampah Terpilih',
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
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stok Card — expandable with input
// ─────────────────────────────────────────────────────────────────────────────
class _StokCard extends StatefulWidget {
  final _StokSampah item;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _StokCard({
    super.key,
    required this.item,
    required this.controller,
    required this.onChanged,
  });

  @override
  State<_StokCard> createState() => _StokCardState();
}

class _StokCardState extends State<_StokCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _animCtrl;
  late Animation<double> _expandAnim;
  late Animation<double> _fadeAnim;
  final FocusNode _focusNode = FocusNode();

  bool get _hasValue =>
      (double.tryParse(widget.controller.text) ?? 0) > 0;

  _BadgeStyle get _badgeStyle {
    if (widget.item.kategori.toLowerCase() == 'uang') {
      return const _BadgeStyle(
        bg: Color(0xFFD6F0E8),
        text: Color(0xFF006644),
        icon: Icons.payments_rounded,
        label: 'uang',
      );
    } else {
      return const _BadgeStyle(
        bg: Color(0xFFE8F4D6),
        text: Color(0xFF2D5A1D),
        icon: Icons.stars_rounded,
        label: 'poin',
      );
    }
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: GestureDetector(
        onTap: _toggle,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: _expanded ? Colors.white : _C.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _hasValue
                  ? _C.accent.withOpacity(0.6)
                  : _expanded
                      ? _C.accent.withOpacity(0.25)
                      : Colors.transparent,
              width: 1,
            ),
            boxShadow: _expanded
                ? [
                    BoxShadow(
                      color: _C.dark.withOpacity(0.08),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : [],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header row ────────────────────────────────────────────
                Row(
                  children: [
                    // Icon
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: _C.accent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.recycling_rounded,
                        size: 20,
                        color: _C.accent,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Nama & stok
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.item.nama,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: _C.dark,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Text(
                                'Stok: ',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 11,
                                  color: _C.dark.withOpacity(0.4),
                                ),
                              ),
                              Text(
                                '${_fmtStok(widget.item.stok)} ${widget.item.satuan}',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _C.accent,
                                ),
                              ),
                            ],
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

                    // Nilai pill atau chevron
                    if (_hasValue && !_expanded)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _C.accent.withOpacity(0.13),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${widget.controller.text} ${widget.item.satuan}',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: _C.accent,
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
                          color: _C.dark.withOpacity(0.3),
                        ),
                      ),
                  ],
                ),

                // ── Expanded: input area ──────────────────────────────────
                SizeTransition(
                  sizeFactor: _expandAnim,
                  axisAlignment: -1,
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 14),
                        Divider(height: 1, color: _C.dark.withOpacity(0.07)),
                        const SizedBox(height: 14),

                        Row(
                          children: [
                            // Keterangan
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Jumlah angkut',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 11,
                                      color: _C.dark.withOpacity(0.45),
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    'Masukkan dalam ${widget.item.satuan}',
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: _C.dark,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Input field
                            GestureDetector(
                              onTap: () {},
                              child: Container(
                                width: 120,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF4FCF4),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _focusNode.hasFocus
                                        ? _C.accent
                                        : _C.accent.withOpacity(0.2),
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
                                    color: _C.dark,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: '0',
                                    hintStyle: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      color: _C.dark.withOpacity(0.18),
                                    ),
                                    suffixText: widget.item.satuan,
                                    suffixStyle: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: _C.accent.withOpacity(0.7),
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

                        // Info stok tersedia
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                          decoration: BoxDecoration(
                            color: _C.dark.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                size: 13,
                                color: _C.dark.withOpacity(0.35),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Stok tersedia: ${_fmtStok(widget.item.stok)} ${widget.item.satuan}',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 11,
                                  color: _C.dark.withOpacity(0.45),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                'Bebas input',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: _C.accent.withOpacity(0.7),
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

  String _fmtStok(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }
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
