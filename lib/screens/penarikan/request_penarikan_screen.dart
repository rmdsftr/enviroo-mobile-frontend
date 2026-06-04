import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/katalog_model.dart';
import '../../models/penarikan_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/penarikan_nasabah_provider.dart';
import '../../widgets/search.dart';
import '../../widgets/topbar_back.dart';
import 'preview_request_penarikan_screen.dart';

// ── Thousands formatter for Rupiah ─────────────────────────────────────────────

class _ThousandsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitsOnly = newValue.text.replaceAll('.', '');
    if (digitsOnly.isEmpty) return newValue.copyWith(text: '');

    final number = int.tryParse(digitsOnly);
    if (number == null) return oldValue;

    final formatted = NumberFormat('#,###', 'id_ID').format(number);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class RequestPenarikanScreen extends StatefulWidget {
  const RequestPenarikanScreen({super.key});

  @override
  State<RequestPenarikanScreen> createState() =>
      _RequestPenarikanScreenState();
}

class _RequestPenarikanScreenState extends State<RequestPenarikanScreen> {
  static const Color primary = Color(0xFF4EA771);
  static const Color dark = Color(0xFF013236);

  // 0=Uang, 1=Sembako
  int _tabIndex = 0;

  final TextEditingController _nominalController = TextEditingController();
  final FocusNode _nominalFocus = FocusNode();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final Map<String, double> _sembakoQty = {};
  String? _inlineError;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _nominalController.addListener(_onNominalChanged);
    _nominalFocus.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final prov = context.read<PenarikanNasabahProvider>();
      prov.bind(auth);
      prov.loadFormData();
    });
  }

  @override
  void dispose() {
    _nominalController.removeListener(_onNominalChanged);
    _nominalController.dispose();
    _nominalFocus.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onNominalChanged() {
    // Hanya validasi saldo melebihi (bukan "lebih dari 0") saat mengetik
    setState(() {
      final prov = context.read<PenarikanNasabahProvider>();
      final saldo = _currentSaldo(prov);
      final nominal = _parseNominal();
      if (saldo != null && nominal > 0 && nominal > saldo.nominal) {
        _inlineError = 'Nominal melebihi saldo tersedia';
      } else {
        _inlineError = null;
      }
    });
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  NilaiRewardBank? _currentReward(PenarikanNasabahProvider prov) =>
      _tabIndex == 0 ? prov.rewardUang : prov.rewardSembako;

  SaldoReward? _currentSaldo(PenarikanNasabahProvider prov) =>
      _tabIndex == 0 ? prov.saldo?.saldoUang : prov.saldo?.saldoSembako;

  double _parseNominal() {
    return double.tryParse(_nominalController.text.replaceAll('.', '')) ?? 0;
  }

  double _totalPoinSembako(List<KatalogSembakoModel> items) {
    double total = 0;
    _sembakoQty.forEach((id, qty) {
      final idx = items.indexWhere((s) => s.sembakoId == id);
      if (idx >= 0) total += items[idx].nilaiPoin * qty;
    });
    return total;
  }

  String? _validateNominal() {
    final prov = context.read<PenarikanNasabahProvider>();
    final saldo = _currentSaldo(prov);
    final nominal = _parseNominal();
    if (nominal <= 0) return 'Nominal harus lebih dari 0';
    if (saldo != null && nominal > saldo.nominal) {
      return 'Nominal melebihi saldo tersedia';
    }
    return null;
  }

  String? _validateSembako(List<KatalogSembakoModel> items) {
    final prov = context.read<PenarikanNasabahProvider>();
    final hasItem = _sembakoQty.values.any((q) => q > 0);
    if (!hasItem) return 'Pilih minimal satu sembako';
    final saldo = prov.saldo?.saldoSembako;
    final total = _totalPoinSembako(items);
    if (saldo != null && total > saldo.nominal) {
      return 'Total poin melebihi saldo sembako';
    }
    return null;
  }

  String _fmtSaldo(SaldoReward? s) {
    if (s == null) return '--';
    final f = NumberFormat.decimalPattern('id_ID');
    f.maximumFractionDigits = 4;
    f.minimumFractionDigits = 0;
    final lower = s.satuan.toLowerCase();
    if (lower.contains('rupiah') || s.isUang) return 'Rp ${f.format(s.nominal)}';
    return '${f.format(s.nominal)} ${s.satuan.isEmpty ? 'poin' : s.satuan}';
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  Future<void> _lanjutkan() async {
    final prov = context.read<PenarikanNasabahProvider>();
    final reward = _currentReward(prov);

    if (reward == null) {
      _showSnack('Jenis reward tidak tersedia', error: true);
      return;
    }

    double? nominal;
    List<Map<String, dynamic>> itemSembako = [];

    if (_tabIndex == 1) {
      final err = _validateSembako(prov.sembakoList);
      if (err != null) {
        setState(() => _inlineError = err);
        return;
      }
      itemSembako = _sembakoQty.entries
          .where((e) => e.value > 0)
          .map((e) => {'sembako_id': e.key, 'qty': e.value})
          .toList();
    } else {
      final err = _validateNominal();
      if (err != null) {
        setState(() => _inlineError = err);
        return;
      }
      nominal = _parseNominal();
    }

    setState(() => _submitting = true);

    final formData = PenarikanFormData(
      rewardId: reward.rewardId,
      namaReward: reward.namaReward,
      nominalPenarikan: nominal,
      itemSembako: itemSembako,
    );

    setState(() => _submitting = false);

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PreviewRequestPenarikanScreen(formData: formData),
      ),
    );
  }

  void _showSnack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      content: Text(msg, style: const TextStyle(fontFamily: 'Poppins')),
      backgroundColor: error ? Colors.redAccent : primary,
    ));
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      body: SafeArea(
        child: Consumer<PenarikanNasabahProvider>(
          builder: (_, prov, __) {
            final loading = prov.loadingSaldo ||
                prov.loadingRewards ||
                prov.loadingSembako;
            return Stack(
              children: [
                Column(
                  children: [
                    const TopBarBack(title: 'Ajukan Penarikan'),
                    _buildTabs(prov),
                    Expanded(
                      child: loading
                          ? const Center(
                              child: CircularProgressIndicator(
                                  color: primary))
                          : SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(
                                  20, 16, 20, 24),
                              child: _buildContent(prov),
                            ),
                    ),
                    // ── Bottom bar button ────────────────────────────────
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
                      child: _buildCTA(prov),
                    ),
                  ],
                ),
                if (_submitting)
                  Container(
                    color: Colors.black.withValues(alpha: 0.3),
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── Tab bar ───────────────────────────────────────────────────────────────

  Widget _buildTabs(PenarikanNasabahProvider prov) {
    final tabs = ['Uang', 'Sembako'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: List.generate(2, (i) {
            final selected = _tabIndex == i;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _tabIndex = i;
                    _nominalController.clear();
                    _sembakoQty.clear();
                    _inlineError = null;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFF94DF0C)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Center(
                    child: Text(
                      tabs[i],
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: selected
                            ? dark
                            : dark.withValues(alpha: 0.45),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // ── Content ───────────────────────────────────────────────────────────────

  Widget _buildContent(PenarikanNasabahProvider prov) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSaldoCard(prov),
        const SizedBox(height: 20),
        if (_tabIndex == 1)
          _buildSembakoForm(prov)
        else
          _buildNominalForm(prov),
      ],
    );
  }

  Widget _buildSaldoCard(PenarikanNasabahProvider prov) {
    final saldo = _currentSaldo(prov);
    final saldoText = _fmtSaldo(saldo);
    final tabLabels = ['Uang', 'Sembako'];

    double? estimasiSisa;
    if (saldo != null) {
      if (_tabIndex < 1) {
        final nominal = _parseNominal();
        estimasiSisa = saldo.nominal - nominal;
      } else {
        final total = _totalPoinSembako(prov.sembakoList);
        estimasiSisa = saldo.nominal - total;
      }
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: Container(
        color: const Color(0xFF013236),
        child: Stack(
          children: [
            // ── Decorative bubbles ────────────────────────────────────────────
            Positioned(
              right: -30,
              top: -30,
              child: _Bubble(size: 100, opacity: 0.05),
            ),
            Positioned(
              right: 30,
              bottom: -35,
              child: _Bubble(size: 80, opacity: 0.05),
            ),
            // ── Content ───────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.account_balance_wallet_rounded,
                          color: Colors.white54, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Saldo ${tabLabels[_tabIndex]} Tersedia',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    saldoText,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  if (estimasiSisa != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.info_outline_rounded,
                              size: 14, color: Colors.white60),
                          const SizedBox(width: 6),
                          Text(
                            'Estimasi sisa: ${_fmtSaldoVal(estimasiSisa, saldo!.satuan)}',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  String _fmtSaldoVal(double val, String satuan) {
    final f = NumberFormat.decimalPattern('id_ID');
    f.maximumFractionDigits = 4;
    f.minimumFractionDigits = 0;
    final lower = satuan.toLowerCase();
    if (lower.contains('rupiah')) return 'Rp ${f.format(val)}';
    return '${f.format(val)} ${satuan.isEmpty ? 'poin' : satuan}';
  }

  // ── Nominal form ──────────────────────────────────────────────────────────

  Widget _buildNominalForm(PenarikanNasabahProvider prov) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('Nominal Penarikan'),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: _inlineError != null
                  ? Colors.red
                  : (_nominalFocus.hasFocus
                      ? primary
                      : Colors.black.withValues(alpha: 0.15)),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(50),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            children: [
              const Text(
                'Rp',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  color: primary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _nominalController,
                  focusNode: _nominalFocus,
                  keyboardType: TextInputType.number,
                  inputFormatters: [_ThousandsFormatter()],
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: const InputDecoration(
                    hintText: '0',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_inlineError != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Text(
              _inlineError!,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                color: Colors.red,
              ),
            ),
          ),
        ] else ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Text(
              'Masukkan nominal dalam Rupiah',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                color: Colors.black.withValues(alpha: 0.4),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ── Sembako form ─────────────────────────────────────────────────────────

  Widget _buildSembakoForm(PenarikanNasabahProvider prov) {
    final allItems = prov.sembakoList;
    final total = _totalPoinSembako(allItems);
    final saldo = prov.saldo?.saldoSembako;
    final exceeded = saldo != null && total > saldo.nominal;

    final items = allItems.where((item) {
      if (_searchQuery.isEmpty) return true;
      return item.namaSembako.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const _SectionLabel('Pilih Sembako'),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: exceeded
                    ? Colors.red.withValues(alpha: 0.1)
                    : primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Text(
                'Total ${NumberFormat.decimalPattern('id_ID').format(total)} poin',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: exceeded ? Colors.red : primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        CustomSearchBar(
          controller: _searchController,
          hintText: 'Cari nama sembako...',
          searchQuery: _searchQuery,
          onChanged: (val) {
            setState(() {
              _searchQuery = val;
            });
          },
          onClear: () {
            setState(() {
              _searchQuery = '';
              _searchController.clear();
            });
          },
        ),
        const SizedBox(height: 16),
        if (_inlineError != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              _inlineError!,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                color: Colors.red,
              ),
            ),
          ),
        if (items.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBF1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: const Color(0xFFFAA324).withValues(alpha: 0.3)),
            ),
            child: const Text(
              'Belum ada sembako tersedia.',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 12),
            ),
          )
        else
          _SembakoExpandableList(
            items: items,
            sembakoQty: _sembakoQty,
            onChanged: (id, qty) {
              setState(() {
                if (qty <= 0) {
                  _sembakoQty.remove(id);
                } else {
                  _sembakoQty[id] = qty;
                }
                _inlineError = null;
              });
            },
          ),
      ],
    );
  }

  // ── CTA Button ────────────────────────────────────────────────────────────

  Widget _buildCTA(PenarikanNasabahProvider prov) {
    final loading = prov.loadingSaldo ||
        prov.loadingRewards ||
        prov.loadingSembako;
    final disabled = loading || _submitting;

    return Container(
      decoration: BoxDecoration(
        color: disabled ? Colors.grey.shade400 : dark,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: disabled ? null : _lanjutkan,
          borderRadius: BorderRadius.circular(50),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: _submitting
                  ? const SizedBox(
                      width: 22,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5),
                    )
                  : const Text(
                      'Lanjutkan',
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

// ── Bubble Decorative Widget ──────────────────────────────────────────────

class _Bubble extends StatelessWidget {
  final double size;
  final double opacity;

  const _Bubble({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(opacity),
      ),
    );
  }
}

// ── Expandable Sembako List ───────────────────────────────────────────────────

class _SembakoExpandableList extends StatefulWidget {
  final List<KatalogSembakoModel> items;
  final Map<String, double> sembakoQty;
  final void Function(String id, double qty) onChanged;

  const _SembakoExpandableList({
    required this.items,
    required this.sembakoQty,
    required this.onChanged,
  });

  @override
  State<_SembakoExpandableList> createState() =>
      _SembakoExpandableListState();
}

class _SembakoExpandableListState extends State<_SembakoExpandableList> {
  String? _expandedId;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: widget.items.map((item) {
        return _SembakoTile(
          item: item,
          qty: widget.sembakoQty[item.sembakoId] ?? 0,
          isExpanded: _expandedId == item.sembakoId,
          onTap: () {
            setState(() {
              _expandedId =
                  _expandedId == item.sembakoId ? null : item.sembakoId;
            });
          },
          onQtyChanged: (qty) => widget.onChanged(item.sembakoId, qty),
        );
      }).toList(),
    );
  }
}

class _SembakoTile extends StatelessWidget {
  final KatalogSembakoModel item;
  final double qty;
  final bool isExpanded;
  final VoidCallback onTap;
  final void Function(double qty) onQtyChanged;

  const _SembakoTile({
    required this.item,
    required this.qty,
    required this.isExpanded,
    required this.onTap,
    required this.onQtyChanged,
  });

  static const Color primary = Color(0xFF4EA771);
  static const Color dark = Color(0xFF013236);

  String _fmt(num n) => NumberFormat.decimalPattern('id_ID').format(n);

  @override
  Widget build(BuildContext context) {
    final selected = qty > 0;
    final poin = item.nilaiPoin;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: selected
            ? primary.withValues(alpha: 0.05)
            : Colors.white,
        border: Border.all(
          color: selected
              ? primary.withValues(alpha: 0.4)
              : Colors.black.withValues(alpha: 0.1),
        ),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        children: [
          // Header row (always visible)
          InkWell(
            onTap: onTap,
            borderRadius: isExpanded
                ? const BorderRadius.vertical(top: Radius.circular(16))
                : BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(50),
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: item.photoUrl.isEmpty
                          ? Container(
                              color: primary.withValues(alpha: 0.15),
                              child: const Icon(
                                  Icons.shopping_basket_rounded,
                                  color: primary,
                                  size: 22),
                            )
                          : Image.network(
                              item.photoUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: primary.withValues(alpha: 0.15),
                                child: const Icon(
                                    Icons.shopping_basket_rounded,
                                    color: primary,
                                    size: 22),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.namaSembako,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: dark,
                          ),
                        ),
                        Text(
                          '${_fmt(poin)} poin',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            color: Colors.black.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (qty > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Text(
                        'x${qty.toInt()}',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: primary,
                        ),
                      ),
                    ),
                  const SizedBox(width: 6),
                  Icon(
                    isExpanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: dark.withValues(alpha: 0.4),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          // Expanded qty selector
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            child: isExpanded
                ? Container(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Divider(
                            color: Colors.black.withValues(alpha: 0.08)),
                        Row(
                          children: [
                            Text(
                              'Subtotal: ${_fmt(poin * qty)} poin',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                color: Colors.black.withValues(alpha: 0.5),
                              ),
                            ),
                            const Spacer(),
                            _QtyButton(
                              icon: Icons.remove_rounded,
                              onTap: qty > 0
                                  ? () {
                                      HapticFeedback.selectionClick();
                                      onQtyChanged(qty - 1);
                                    }
                                  : null,
                            ),
                            SizedBox(
                              width: 36,
                              child: Center(
                                child: Text(
                                  '${qty.toInt()}',
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: dark,
                                  ),
                                ),
                              ),
                            ),
                            _QtyButton(
                              icon: Icons.add_rounded,
                              filled: true,
                              onTap: qty < item.stok
                                  ? () {
                                      HapticFeedback.selectionClick();
                                      onQtyChanged(qty + 1);
                                    }
                                  : null,
                            ),
                          ],
                        ),
                        if (qty >= item.stok)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              'Stok maksimum tercapai',
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 10,
                                color: Colors.orange,
                              ),
                            ),
                          ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool filled;

  const _QtyButton({
    required this.icon,
    this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF4EA771);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 25,
        height: 25,
        decoration: BoxDecoration(
          color: onTap == null
              ? Colors.grey.shade200
              : filled
                  ? primary
                  : Colors.white,
          border: Border.all(
            color: onTap == null
                ? Colors.grey.shade300
                : filled
                    ? primary
                    : Colors.black.withValues(alpha: 0.15),
          ),
          borderRadius: BorderRadius.circular(50),
        ),
        child: Icon(
          icon,
          size: 16,
          color: onTap == null
              ? Colors.grey
              : filled
                  ? Colors.white
                  : Colors.black.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Colors.black.withValues(alpha: 0.7),
      ),
    );
  }
}
