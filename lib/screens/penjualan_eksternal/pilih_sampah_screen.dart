import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/katalog_model.dart';
import '../../models/penjualan_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/penjualan_provider.dart';
import '../../services/katalog_service.dart';
import '../../widgets/custom_snackbar.dart';
import '../../widgets/search.dart';
import '../../widgets/topbar_back.dart';
import 'hitung_penjualan_screen.dart';

class _C {
  static const dark = Color(0xFF013236);
  static const green = Color(0xFF94DF0C);
  static const teal = Color(0xFF4EA771);
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
  bool _previewing = false;
  String? _error;
  List<KatalogSampahModel> _katalog = [];
  String _query = '';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final auth = context.read<AuthProvider>();
    final bankId = auth.bankId ?? '';

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _fetchKatalog(bankId);
    } catch (e) {
      if (mounted) setState(() => _error = 'Terjadi kesalahan saat memuat data');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _fetchKatalog(String bankId) async {
    final res = await KatalogService.getKatalogSampah(bankId);
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

  /// Filter katalog: search query + hanya tampilkan sampah yang reward_id-nya
  /// sesuai dengan reward yang dipilih user di step sebelumnya.
  List<KatalogSampahModel> _filteredKatalog(PenjualanProvider prov) {
    final selectedRewardId = prov.selectedReward?.rewardId;
    return _katalog.where((k) {
      final matchQuery =
          k.namaSampah.toLowerCase().contains(_query.toLowerCase());
      final matchReward =
          selectedRewardId == null || k.rewardId == selectedRewardId;
      return matchQuery && matchReward;
    }).toList();
  }

  Future<void> _next() async {
    final prov = context.read<PenjualanProvider>();
    if (prov.itemsSampah.isEmpty) {
      _showSnack('Pilih minimal satu sampah');
      return;
    }
    final invalidQty = prov.itemsSampah.where((e) => e.qty <= 0).toList();
    if (invalidQty.isNotEmpty) {
      _showSnack(
          'Masukkan qty untuk: ${invalidQty.map((e) => e.namaSampah).join(', ')}');
      return;
    }
    final invalidHarga =
        prov.itemsSampah.where((e) => e.hargaJual <= 0).toList();
    if (invalidHarga.isNotEmpty) {
      _showSnack(
          'Masukkan harga jual untuk: ${invalidHarga.map((e) => e.namaSampah).join(', ')}');
      return;
    }

    final auth = context.read<AuthProvider>();
    setState(() => _previewing = true);
    final ok = await prov.fetchPreview(
      bankId: auth.bankId ?? '',
    );
    if (!mounted) return;
    setState(() => _previewing = false);

    if (ok) {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const HitungPenjualanScreen()));
    } else {
      _showSnack(prov.previewError ?? 'Gagal menghitung penjualan');
    }
  }

  void _showSnack(String msg) => showCustomSnackBar(context, msg);

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<PenjualanProvider>();
    final filtered = _filteredKatalog(prov);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const TopBarBack(title: 'Pilih Sampah'),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: _C.teal))
                  : _error != null
                      ? _buildError(_error!)
                      : _buildContent(prov, filtered),
            ),
            _BottomBar(
              total: prov.itemsSampah.length,
              loading: _previewing,
              onNext: _next,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
      PenjualanProvider prov, List<KatalogSampahModel> filtered) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 4, 20, 6),
          child: Align(
            alignment: Alignment.centerLeft,
            child: _StepIndicator(currentStep: 2),
          ),
        ),

        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 15),
          child: CustomSearchBar(
            controller: _searchCtrl,
            hintText: 'Cari nama sampah...',
            searchQuery: _query,
            onChanged: (v) => setState(() => _query = v),
            onClear: () {
              _searchCtrl.clear();
              setState(() => _query = '');
            },
          ),
        ),
        Expanded(
          child: filtered.isEmpty
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
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) =>
                      _SampahCard(item: filtered[i], prov: prov),
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
              const Icon(Icons.error_outline, color: _C.danger, size: 42),
              const SizedBox(height: 10),
              Text(
                msg,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontFamily: 'Poppins', color: _C.danger, fontSize: 12),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _init,
                style: ElevatedButton.styleFrom(
                    backgroundColor: _C.dark, foregroundColor: Colors.white),
                child: const Text('Coba Lagi',
                    style: TextStyle(fontFamily: 'Poppins')),
              ),
            ],
          ),
        ),
      );
}

// ─── Card Sampah ─────────────────────────────────────────────────────────────
class _SampahCard extends StatefulWidget {
  final KatalogSampahModel item;
  final PenjualanProvider prov;
  const _SampahCard({required this.item, required this.prov});

  @override
  State<_SampahCard> createState() => _SampahCardState();
}

class _SampahCardState extends State<_SampahCard>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _qtyCtrl;
  late final TextEditingController _hargaCtrl;
  late AnimationController _animCtrl;
  late Animation<double> _expandAnim;

  @override
  void initState() {
    super.initState();
    _qtyCtrl = TextEditingController();
    _hargaCtrl = TextEditingController();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 220));
    _expandAnim = CurvedAnimation(
        parent: _animCtrl, curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _hargaCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  bool get selected =>
      widget.prov.isSampahSelected(widget.item.sampahId);

  void _onToggle(bool? checked) {
    final item = ItemSampahPilihan(
      sampahId: widget.item.sampahId,
      namaSampah: widget.item.namaSampah,
      satuan: widget.item.satuan,
      stokTersedia: widget.item.stok,
    );
    widget.prov.toggleSampah(item, selected: checked ?? false);
    if (checked == true) {
      _animCtrl.forward();
    } else {
      _animCtrl.reverse();
      _qtyCtrl.clear();
      _hargaCtrl.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.##', 'id_ID');
    final stok = widget.item.stok;
    final isSelected = selected;

    // sync animCtrl bila state berubah dari luar (e.g. reset)
    if (isSelected && _animCtrl.status == AnimationStatus.dismissed) {
      _animCtrl.forward();
    } else if (!isSelected && _animCtrl.status == AnimationStatus.completed) {
      _animCtrl.reverse();
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: isSelected ? _C.teal : _C.border),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row: foto + info + checkbox ──────────────────────────
          Row(
            children: [
              // Foto sampah
              widget.item.photoUrl.isNotEmpty
                  ? ClipOval(
                      child: Image.network(
                        widget.item.photoUrl,
                        width: 52,
                        height: 52,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _photoPlaceholder(),
                      ),
                    )
                  : _photoPlaceholder(),
              const SizedBox(width: 12),
              // Nama + stok
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
                    Row(
                      children: [
                        Icon(Icons.inventory_2_outlined,
                            size: 12, color: stok > 0 ? _C.teal : _C.danger),
                        const SizedBox(width: 4),
                        Text(
                          'Stok: ${fmt.format(stok)} ${widget.item.satuan}',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: stok > 0 ? _C.teal : _C.danger,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _ModernCheckbox(
                value: isSelected,
                enabled: stok > 0,
                onChanged: stok <= 0 ? null : (_) => _onToggle(!isSelected),
              ),
            ],
          ),

          // ── Expanded: input qty + harga jual ────────────────────────────
          SizeTransition(
            sizeFactor: _expandAnim,
            axisAlignment: -1,
            child: Column(
              children: [
                const SizedBox(height: 12),
                Divider(height: 1, color: _C.border),
                const SizedBox(height: 12),
                Builder(builder: (context) {
                  final reward = widget.prov.selectedReward;
                  final isSembako =
                      reward?.namaReward.toLowerCase() == 'sembako';
                  final rewardSatuan = reward?.satuan ?? '';
                  return Row(
                    children: [
                      // Qty
                      Expanded(
                        child: _InputField(
                          controller: _qtyCtrl,
                          label: 'Qty',
                          suffix: widget.item.satuan,
                          onChanged: (v) {
                            final qty =
                                double.tryParse(v.replaceAll(',', '.')) ?? 0;
                            if (qty > stok) {
                              showCustomSnackBar(context,
                                  'Qty melebihi stok (${fmt.format(stok)})');
                            }
                            widget.prov.updateQtySampah(
                                widget.item.sampahId, qty);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Harga jual
                      Expanded(
                        child: _InputField(
                          controller: _hargaCtrl,
                          label: 'Harga Jual',
                          prefix: isSembako ? null : 'Rp',
                          suffix: isSembako ? rewardSatuan : null,
                          onChanged: (v) {
                            final harga = double.tryParse(v
                                    .replaceAll(',', '.')
                                    .replaceAll('.', '')) ??
                                0;
                            widget.prov.updateHargaJualSampah(
                                widget.item.sampahId, harga);
                          },
                        ),
                      ),
                    ],
                  );
                }),
                const SizedBox(height: 8),
                // Subtotal preview
                _SubtotalRow(
                  prov: widget.prov,
                  sampahId: widget.item.sampahId,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _photoPlaceholder() => Container(
        width: 52,
        height: 52,
        decoration: const BoxDecoration(
          color: _C.cardBg,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.recycling_rounded, size: 24, color: _C.teal),
      );
}

// ─── Subtotal per Item ───────────────────────────────────────────────────────
class _SubtotalRow extends StatelessWidget {
  final PenjualanProvider prov;
  final String sampahId;
  const _SubtotalRow({required this.prov, required this.sampahId});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0', 'id_ID');
    final idx = prov.itemsSampah.indexWhere((e) => e.sampahId == sampahId);
    if (idx == -1) return const SizedBox.shrink();
    final item = prov.itemsSampah[idx];
    final subtotal = item.qty * item.hargaJual;

    final isSembako =
        prov.selectedReward?.namaReward.toLowerCase() == 'sembako';
    final rewardSatuan = prov.selectedReward?.satuan ?? '';
    final hargaStr = isSembako
        ? '${fmt.format(item.hargaJual)} $rewardSatuan'
        : 'Rp ${fmt.format(item.hargaJual)}';
    final subtotalStr = isSembako
        ? '= ${fmt.format(subtotal)} $rewardSatuan'
        : '= Rp ${fmt.format(subtotal)}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _C.cardBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${_fmtQty(item.qty)} ${item.satuan} × $hargaStr',
            style: const TextStyle(
                fontFamily: 'Poppins', fontSize: 11, color: _C.muted),
          ),
          Text(
            subtotalStr,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _C.dark,
            ),
          ),
        ],
      ),
    );
  }

  String _fmtQty(double v) =>
      v == v.toInt() ? v.toInt().toString() : v.toString();
}

// ─── Reusable Input Field ────────────────────────────────────────────────────
class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? suffix;
  final String? prefix;
  final ValueChanged<String> onChanged;

  const _InputField({
    required this.controller,
    required this.label,
    required this.onChanged,
    this.suffix,
    this.prefix,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
              fontFamily: 'Poppins', fontSize: 10.5, color: _C.muted),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
          ],
          onChanged: onChanged,
          decoration: InputDecoration(
            prefixText: prefix != null ? '$prefix ' : null,
            prefixStyle: const TextStyle(
                fontFamily: 'Poppins', fontSize: 12, color: _C.dark),
            suffixText: suffix,
            suffixStyle: const TextStyle(
                fontFamily: 'Poppins', fontSize: 11, color: _C.muted),
            hintText: '0',
            hintStyle: const TextStyle(
                fontFamily: 'Poppins', fontSize: 12, color: _C.muted),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _C.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _C.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _C.teal, width: 1.5),
            ),
          ),
          style: const TextStyle(
              fontFamily: 'Poppins', fontSize: 13, color: _C.dark),
        ),
      ],
    );
  }
}

// ─── Step Indicator ──────────────────────────────────────────────────────────
class _StepIndicator extends StatelessWidget {
  final int currentStep;
  const _StepIndicator({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    const total = 3;
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

// ─── Bottom Bar ──────────────────────────────────────────────────────────────
class _BottomBar extends StatelessWidget {
  final int total;
  final bool loading;
  final VoidCallback onNext;
  const _BottomBar({
    required this.total,
    required this.loading,
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
            child: Text(
              '$total item dipilih',
              style: const TextStyle(
                  fontFamily: 'Poppins', fontSize: 12, color: _C.muted),
            ),
          ),
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: loading ? null : onNext,
              icon: loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.calculate_rounded, size: 18),
              label: Text(
                loading ? 'Menghitung…' : 'Hitung Penjualan',
                style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _C.dark,
                foregroundColor: Colors.white,
                disabledBackgroundColor: _C.muted.withValues(alpha: 0.5),
                disabledForegroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 22),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Modern Checkbox ─────────────────────────────────────────────────────────
class _ModernCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool enabled;
  const _ModernCheckbox({
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  static const _green  = Color(0xFF4EA771);
  static const _border = Color(0xFFD8E0DA);

  @override
  Widget build(BuildContext context) {
    final disabled = !enabled || onChanged == null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: disabled ? null : () => onChanged!(!value),
      child: Opacity(
        opacity: disabled ? 0.4 : 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: value ? _green : Colors.white,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(
              color: value ? _green : _border,
              width: 1.5,
            ),
          ),
          alignment: Alignment.center,
          child: AnimatedScale(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutBack,
            scale: value ? 1 : 0,
            child: const Icon(Icons.check_rounded, size: 13, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
