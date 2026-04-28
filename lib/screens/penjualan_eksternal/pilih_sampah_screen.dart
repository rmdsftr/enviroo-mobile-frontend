import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/katalog_model.dart';
import '../../models/penjualan_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/penjualan_provider.dart';
import '../../services/katalog_service.dart';
import '../../widgets/topbar_back.dart';
import 'barter_sembako_screen.dart';
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

class PilihSampahScreen extends StatefulWidget {
  const PilihSampahScreen({super.key});

  @override
  State<PilihSampahScreen> createState() => _PilihSampahScreenState();
}

class _PilihSampahScreenState extends State<PilihSampahScreen> {
  bool _loading = true;
  String? _error;
  List<KatalogSampahModel> _katalog = [];
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    final auth = context.read<AuthProvider>();
    final prov = context.read<PenjualanProvider>();
    final bankId = auth.bankId ?? '';
    final token = auth.currentUser?.accessToken ?? '';

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Fetch katalog & nilai konversi paralel
      await Future.wait([
        _fetchKatalog(bankId, token),
        if (!prov.isSembako) prov.fetchNilaiReward(bankId, token),
      ]);
    } catch (e) {
      _error = 'Terjadi kesalahan saat memuat data';
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _fetchKatalog(String bankId, String token) async {
    final res = await KatalogService.getKatalogSampah(bankId, token);
    if (!mounted) return;
    if (res['success'] == true) {
      final List data = res['data'] ?? [];
      setState(() {
        _katalog = data.map((e) => KatalogSampahModel.fromJson(e)).toList();
      });
    } else {
      setState(() {
        _error = res['message'] ?? 'Gagal mengambil katalog';
      });
    }
  }

  List<KatalogSampahModel> get _filtered => _katalog
      .where((k) => k.namaSampah.toLowerCase().contains(_query.toLowerCase()))
      .toList();

  void _next() {
    final prov = context.read<PenjualanProvider>();
    if (prov.itemsSampah.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: _C.danger,
          content: Text('Pilih minimal satu sampah',
              style: TextStyle(fontFamily: 'Poppins')),
        ),
      );
      return;
    }
    // Validasi qty > 0
    final invalid =
        prov.itemsSampah.where((e) => e.qty <= 0).toList();
    if (invalid.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: _C.danger,
          content: Text(
            'Masukkan qty untuk: ${invalid.map((e) => e.namaSampah).join(', ')}',
            style: const TextStyle(fontFamily: 'Poppins'),
          ),
        ),
      );
      return;
    }

    if (prov.isSembako) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const BarterSembakoScreen()),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const BuktiFotoScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<PenjualanProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const TopBarBack(title: 'Pilih Sampah'),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: _C.green))
                  : _error != null
                      ? _buildError(_error!)
                      : _buildList(prov),
            ),
            _BottomBar(
              total: prov.itemsSampah.length,
              isSembako: prov.isSembako,
              onNext: _next,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(PenjualanProvider prov) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 4, 20, 6),
          child: Align(
            alignment: Alignment.centerLeft,
            child: _StepIndicator(currentStep: 2),
          ),
        ),
        // Card Nilai Konversi (kalau bukan sembako)
        if (!prov.isSembako) _NilaiKonversiCard(prov: prov),

        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: TextField(
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: 'Cari nama sampah…',
              hintStyle: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: _C.muted),
              prefixIcon:
                  const Icon(Icons.search_rounded, color: _C.muted),
              filled: true,
              fillColor: _C.cardBg,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            style: const TextStyle(
                fontFamily: 'Poppins', fontSize: 12.5),
          ),
        ),
        Expanded(
          child: _filtered.isEmpty
              ? const Center(
                  child: Text(
                    'Sampah tidak ditemukan',
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        color: _C.muted,
                        fontSize: 12),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
                  itemCount: _filtered.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 10),
                  itemBuilder: (_, i) =>
                      _SampahCard(item: _filtered[i], prov: prov),
                ),
        ),
      ],
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
              Text(
                msg,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontFamily: 'Poppins',
                    color: _C.danger,
                    fontSize: 12),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _init,
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

// ─── Card Nilai Konversi ────────────────────────────────────────────────────
class _NilaiKonversiCard extends StatelessWidget {
  final PenjualanProvider prov;
  const _NilaiKonversiCard({required this.prov});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.##########', 'id_ID');
    final reward = prov.selectedReward;
    final nilai = prov.nilaiUntukRewardTerpilih;

    if (prov.nilaiStatus == FetchStatus.loading) {
      return Container(
        margin: const EdgeInsets.fromLTRB(20, 6, 20, 0),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _C.cardBg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child:
                  CircularProgressIndicator(strokeWidth: 2, color: _C.green),
            ),
            SizedBox(width: 10),
            Text('Memuat nilai konversi…',
                style: TextStyle(
                    fontFamily: 'Poppins', fontSize: 12, color: _C.dark)),
          ],
        ),
      );
    }

    if (nilai == null) {
      return Container(
        margin: const EdgeInsets.fromLTRB(20, 6, 20, 0),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _C.danger.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _C.danger.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: _C.danger, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Nilai konversi untuk reward "${reward?.namaReward ?? '-'}" belum diatur untuk bank ini.',
                style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11.5,
                    color: _C.danger),
              ),
            ),
          ],
        ),
      );
    }

    final totalPoin = prov.totalPoin;
    final totalResult = nilai.nilaiPoin > 0
        ? (totalPoin * nilai.nilaiKonversi) / nilai.nilaiPoin
        : 0.0;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 6, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_C.dark, Color(0xFF02484E)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _C.dark.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.swap_horiz_rounded,
                    color: _C.accent, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rate Konversi: ${reward?.namaReward ?? '-'}',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      reward?.satuan.toLowerCase() == 'rupiah' ||
                              reward?.satuan.toLowerCase() == 'rp'
                          ? '${fmt.format(nilai.nilaiPoin)} poin = Rp ${fmt.format(nilai.nilaiKonversi)}'
                          : '${fmt.format(nilai.nilaiPoin)} poin = ${fmt.format(nilai.nilaiKonversi)} ${reward?.satuan ?? ''}',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
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
                      '${fmt.format(totalPoin)} Poin',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
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
                    Text(
                      'Total Estimasi ${reward?.namaReward ?? ''}',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        color: Colors.white60,
                      ),
                    ),
                    Text(
                      reward?.satuan.toLowerCase() == 'rupiah' ||
                              reward?.satuan.toLowerCase() == 'rp'
                          ? 'Rp ${fmt.format(totalResult)}'
                          : '${fmt.format(totalResult)} ${reward?.satuan ?? ''}',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        color: _C.accent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Card Sampah ───────────────────────────────────────────────────────────
class _SampahCard extends StatefulWidget {
  final KatalogSampahModel item;
  final PenjualanProvider prov;
  const _SampahCard({required this.item, required this.prov});

  @override
  State<_SampahCard> createState() => _SampahCardState();
}

class _SampahCardState extends State<_SampahCard> {
  late final TextEditingController _qtyCtrl;

  @override
  void initState() {
    super.initState();
    final existing =
        widget.prov.qtySampahOf(widget.item.sampahId);
    _qtyCtrl = TextEditingController(
        text: existing > 0 ? _fmtQty(existing) : '');
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    super.dispose();
  }

  String _fmtQty(double v) {
    if (v == v.toInt()) return v.toInt().toString();
    return v.toString();
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.##########', 'id_ID');
    final selected =
        widget.prov.isSampahSelected(widget.item.sampahId);
    final harga = widget.item.poinEksternal;
    final stok = widget.item.stok;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border:
            Border.all(color: selected ? _C.green : _C.border),
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
                    final pilihan = ItemSampahPilihan(
                      sampahId: widget.item.sampahId,
                      namaSampah: widget.item.namaSampah,
                      satuan: widget.item.satuan,
                      hargaEksternal: harga,
                      stokTersedia: stok,
                    );
                    widget.prov.toggleSampah(pilihan,
                        selected: v ?? false);
                    if (v == false) _qtyCtrl.clear();
                  },
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.item.namaSampah,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _C.dark,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _Chip(
                      icon: Icons.payments_rounded,
                      label: harga > 0
                          ? '${fmt.format(harga)} pts/${widget.item.satuan}'
                          : 'Harga eksternal belum diatur',
                      color: harga > 0 ? _C.green : _C.danger,
                    ),
                    _Chip(
                      icon: Icons.inventory_rounded,
                      label:
                          'Stok ${fmt.format(stok)} ${widget.item.satuan}',
                      color: stok > 0 ? _C.dark : _C.danger,
                    ),
                  ],
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
                            if (qty > stok) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: _C.danger,
                                  duration:
                                      const Duration(seconds: 2),
                                  content: Text(
                                    'Qty melebihi stok (${fmt.format(stok)})',
                                    style: const TextStyle(
                                        fontFamily: 'Poppins'),
                                  ),
                                ),
                              );
                            }
                            widget.prov.updateQtySampah(
                                widget.item.sampahId, qty);
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
                            suffixText: widget.item.satuan,
                            suffixStyle: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 11,
                                color: _C.muted),
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
                          borderRadius:
                              BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Subtotal: ${fmt.format(widget.prov.qtySampahOf(widget.item.sampahId) * harga)} pts',
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

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _Chip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      );
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
  final bool isSembako;
  final VoidCallback onNext;
  const _BottomBar({
    required this.total,
    required this.isSembako,
    required this.onNext,
  });

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
                  '$total item dipilih',
                  style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: _C.muted),
                ),
                Text(
                  isSembako ? 'Lanjut: Barter Sembako' : 'Lanjut: Bukti Foto',
                  style: const TextStyle(
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
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
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
