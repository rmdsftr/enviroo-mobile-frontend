import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/penjualan_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/penjualan_provider.dart';
import '../../services/katalog_service.dart';
import '../../widgets/topbar_back.dart';
import 'bukti_foto_screen.dart';

class _C {
  static const dark = Color(0xFF013236);
  static const green = Color(0xFF4EA771);
  static const accent = Color(0xFF94DF0C);
  static const cardBg = Color(0xFFF7FBF5);
  static const muted = Color(0xFF8A9A92);
  static const danger = Color(0xFFD94848);
  static const border = Color(0xFFE6EDE9);
}

class BarterSembakoScreen extends StatefulWidget {
  const BarterSembakoScreen({super.key});

  @override
  State<BarterSembakoScreen> createState() => _BarterSembakoScreenState();
}

class _BarterSembakoScreenState extends State<BarterSembakoScreen> {
  bool _loading = true;
  String? _error;
  List<SembakoListingModel> _sembako = [];
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final auth = context.read<AuthProvider>();
    final res = await KatalogService.getKatalogSembako(
      auth.bankId ?? '',
      auth.currentUser?.accessToken ?? '',
    );
    if (!mounted) return;
    if (res['success'] == true) {
      final List data = res['data'] ?? [];
      setState(() {
        _sembako =
            data.map((e) => SembakoListingModel.fromJson(e)).toList();
        _loading = false;
      });
    } else {
      setState(() {
        _error = res['message'] ?? 'Gagal mengambil katalog sembako';
        _loading = false;
      });
    }
  }

  List<SembakoListingModel> get _filtered => _sembako
      .where(
          (s) => s.namaSembako.toLowerCase().contains(_query.toLowerCase()))
      .toList();

  void _next() {
    final prov = context.read<PenjualanProvider>();
    if (prov.itemsSembako.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: _C.danger,
          content: Text('Pilih minimal satu sembako',
              style: TextStyle(fontFamily: 'Poppins')),
        ),
      );
      return;
    }
    final invalid = prov.itemsSembako.where((e) => e.qty <= 0).toList();
    if (invalid.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: _C.danger,
          content: Text(
            'Masukkan qty untuk: ${invalid.map((e) => e.namaSembako).join(', ')}',
            style: const TextStyle(fontFamily: 'Poppins'),
          ),
        ),
      );
      return;
    }

    if (prov.totalPoinSembako > prov.totalPoin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: _C.danger,
          content: Text('Total poin sembako melebihi nilai sampah',
              style: TextStyle(fontFamily: 'Poppins')),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BuktiFotoScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<PenjualanProvider>();
    final fmt = NumberFormat('#,##0.##########', 'id_ID');

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const TopBarBack(title: 'Barter Sembako'),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: _C.green))
                  : _error != null
                      ? _buildError(_error!)
                      : Column(
                          children: [
                            const Padding(
                              padding:
                                  EdgeInsets.fromLTRB(20, 4, 20, 6),
                              child: _StepIndicator(currentStep: 3),
                            ),
                            // Card Validasi Poin
                            _RingkasanPoinCard(prov: prov, fmt: fmt),
                            // Info banner
                            Container(
                              margin: const EdgeInsets.fromLTRB(
                                  20, 6, 20, 0),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _C.cardBg,
                                borderRadius:
                                    BorderRadius.circular(12),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.shopping_basket_rounded,
                                      color: _C.green, size: 18),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Pilih sembako yang diterima dari pihak eksternal sebagai barter penjualan sampah.',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 11.5,
                                        color: _C.dark,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Search
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                  20, 12, 20, 8),
                              child: TextField(
                                onChanged: (v) =>
                                    setState(() => _query = v),
                                decoration: InputDecoration(
                                  hintText: 'Cari sembako…',
                                  hintStyle: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 12,
                                      color: _C.muted),
                                  prefixIcon: const Icon(
                                      Icons.search_rounded,
                                      color: _C.muted),
                                  filled: true,
                                  fillColor: _C.cardBg,
                                  contentPadding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 0),
                                  border: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12.5),
                              ),
                            ),
                            Expanded(
                              child: _filtered.isEmpty
                                  ? const Center(
                                      child: Text(
                                        'Sembako tidak ditemukan',
                                        style: TextStyle(
                                            fontFamily: 'Poppins',
                                            color: _C.muted,
                                            fontSize: 12),
                                      ),
                                    )
                                  : ListView.separated(
                                      padding:
                                          const EdgeInsets.fromLTRB(
                                              20, 4, 20, 14),
                                      itemCount: _filtered.length,
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(height: 10),
                                      itemBuilder: (_, i) => _SembakoCard(
                                        item: _filtered[i],
                                        prov: prov,
                                        fmt: fmt,
                                      ),
                                    ),
                            ),
                          ],
                        ),
            ),
            _BottomBar(
              total: prov.itemsSembako.length,
              onNext: _next,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(String msg) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  color: _C.danger, size: 42),
              const SizedBox(height: 10),
              Text(msg,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontFamily: 'Poppins',
                      color: _C.danger,
                      fontSize: 12)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _fetch,
                style: ElevatedButton.styleFrom(
                    backgroundColor: _C.dark,
                    foregroundColor: Colors.white),
                child: const Text('Coba Lagi',
                    style: TextStyle(fontFamily: 'Poppins')),
              ),
            ],
          ),
        ),
      );
}

// ─── Card Sembako ──────────────────────────────────────────────────────────
class _SembakoCard extends StatefulWidget {
  final SembakoListingModel item;
  final PenjualanProvider prov;
  final NumberFormat fmt;
  const _SembakoCard({
    required this.item,
    required this.prov,
    required this.fmt,
  });

  @override
  State<_SembakoCard> createState() => _SembakoCardState();
}

class _SembakoCardState extends State<_SembakoCard> {
  late final TextEditingController _qtyCtrl;

  @override
  void initState() {
    super.initState();
    final existing = widget.prov.qtySembakoOf(widget.item.sembakoId);
    _qtyCtrl = TextEditingController(
        text: existing > 0 ? _fmtQty(existing) : '');
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    super.dispose();
  }

  String _fmtQty(double v) =>
      v == v.toInt() ? v.toInt().toString() : v.toString();

  @override
  Widget build(BuildContext context) {
    final selected =
        widget.prov.isSembakoSelected(widget.item.sembakoId);
    final harga = widget.item.hargaEksternal;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: selected ? _C.green : _C.border),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: selected,
            activeColor: _C.green,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4)),
            onChanged: harga <= 0
                ? null
                : (v) {
                    final pilihan = ItemSembakoPilihan(
                      sembakoId: widget.item.sembakoId,
                      namaSembako: widget.item.namaSembako,
                      hargaEksternal: harga,
                    );
                    widget.prov.toggleSembako(pilihan,
                        selected: v ?? false);
                    if (v == false) _qtyCtrl.clear();
                  },
          ),
          const SizedBox(width: 4),
          // Photo thumb
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 50,
              height: 50,
              child: widget.item.photoUrl.isEmpty
                  ? Container(
                      color: _C.cardBg,
                      child: const Icon(
                          Icons.shopping_basket_rounded,
                          color: _C.muted),
                    )
                  : Image.network(
                      widget.item.photoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: _C.cardBg,
                        child: const Icon(
                            Icons.shopping_basket_rounded,
                            color: _C.muted),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.item.namaSembako,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _C.dark,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: harga > 0
                        ? _C.green.withOpacity(0.1)
                        : _C.danger.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    harga > 0
                        ? 'Harga: ${widget.fmt.format(harga)} pts/unit'
                        : 'Harga eksternal belum diatur',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: harga > 0 ? _C.green : _C.danger,
                    ),
                  ),
                ),
                if (selected) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _qtyCtrl,
                          keyboardType:
                              const TextInputType.numberWithOptions(
                                  decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9.,]')),
                          ],
                          onChanged: (v) {
                            final cleaned = v.replaceAll(',', '.');
                            final qty =
                                double.tryParse(cleaned) ?? 0;
                            widget.prov.updateQtySembako(
                                widget.item.sembakoId, qty);
                          },
                          decoration: InputDecoration(
                            hintText: 'Qty',
                            hintStyle: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                color: _C.muted),
                            isDense: true,
                            contentPadding:
                                const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(10),
                              borderSide:
                                  const BorderSide(color: _C.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(10),
                              borderSide:
                                  const BorderSide(color: _C.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                  color: _C.green, width: 1.5),
                            ),
                          ),
                          style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              color: _C.dark),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 10),
                        decoration: BoxDecoration(
                          color: _C.cardBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Subtotal: ${widget.fmt.format(widget.prov.qtySembakoOf(widget.item.sembakoId) * harga)} pts',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: _C.dark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int currentStep;
  const _StepIndicator({required this.currentStep});
  @override
  Widget build(BuildContext context) {
    const total = 4;
    return Row(
      children: List.generate(total, (i) {
        final isActive = i + 1 <= currentStep;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i == total - 1 ? 0 : 6),
            height: 5,
            decoration: BoxDecoration(
              color: isActive ? _C.green : _C.border,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      }),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final int total;
  final VoidCallback onNext;
  const _BottomBar({required this.total, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _C.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$total sembako dipilih',
                  style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: _C.muted),
                ),
                const Text(
                  'Lanjut Ambil Foto',
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: _C.dark),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: onNext,
              icon: const Icon(Icons.camera_alt_rounded, size: 18),
              label: const Text('Lanjut',
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _C.dark,
                foregroundColor: Colors.white,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 22),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Card Ringkasan Poin ───────────────────────────────────────────────────
class _RingkasanPoinCard extends StatelessWidget {
  final PenjualanProvider prov;
  final NumberFormat fmt;
  const _RingkasanPoinCard({required this.prov, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final sisa = prov.totalPoin - prov.totalPoinSembako;
    final isMinus = sisa < 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 6, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isMinus
              ? [_C.danger, const Color(0xFF902A2A)]
              : [_C.dark, const Color(0xFF02484E)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isMinus ? _C.danger : _C.dark).withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Nilai Sampah',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      color: Colors.white60,
                    ),
                  ),
                  Text(
                    '${fmt.format(prov.totalPoin)} Pts',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 15,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const Icon(Icons.arrow_forward_rounded,
                  color: Colors.white24, size: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Total Nilai Sembako',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      color: Colors.white60,
                    ),
                  ),
                  Text(
                    '${fmt.format(prov.totalPoinSembako)} Pts',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 15,
                      color: isMinus ? Colors.white : _C.accent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isMinus
                      ? Icons.warning_amber_rounded
                      : Icons.account_balance_wallet_rounded,
                  color: Colors.white,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  isMinus
                      ? 'Sembako melebihi batas (-${fmt.format(sisa.abs())} Pts)'
                      : 'Sisa Saldo Poin: ${fmt.format(sisa)} Pts',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
