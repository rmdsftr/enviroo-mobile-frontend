import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/redeem_models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/redeem_nasabah_provider.dart';
import '../../widgets/topbar_back.dart';

class RequestPenarikanScreen extends StatefulWidget {
  const RequestPenarikanScreen({super.key});

  @override
  State<RequestPenarikanScreen> createState() =>
      _RequestPenarikanScreenState();
}

class _RequestPenarikanScreenState extends State<RequestPenarikanScreen> {
  static const Color primary = Color(0xFF4EA771);
  static const Color dark = Color(0xFF013236);

  NilaiRewardBank? _selectedReward;
  final TextEditingController _poinController = TextEditingController();
  final Map<String, double> _sembakoQty = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final prov = context.read<RedeemNasabahProvider>();
      prov.bind(auth);
      prov.loadFormData();
    });
  }

  @override
  void dispose() {
    _poinController.dispose();
    super.dispose();
  }

  String _formatNumber(num n) => NumberFormat.decimalPattern('id_ID').format(n);

  double get _poinInput {
    final raw = _poinController.text.replaceAll('.', '').replaceAll(',', '');
    return double.tryParse(raw) ?? 0;
  }

  double _totalPoinSembako(List<SembakoItem> items) {
    double total = 0;
    _sembakoQty.forEach((id, qty) {
      final item = items.firstWhere(
        (s) => s.sembakoId == id,
        orElse: () => SembakoItem(
          sembakoId: id,
          namaSembako: '',
          photoUrl: '',
          stok: 0,
          schemaHarga: const [],
        ),
      );
      total += item.poinHargaNasabah * qty;
    });
    return total;
  }

  Future<void> _submit() async {
    final prov = context.read<RedeemNasabahProvider>();
    final reward = _selectedReward;
    if (reward == null) {
      _toast('Pilih jenis reward terlebih dahulu', error: true);
      return;
    }

    bool ok;
    if (reward.isSembako) {
      final items = _sembakoQty.entries
          .where((e) => e.value > 0)
          .map((e) => {'sembako_id': e.key, 'qty': e.value})
          .toList();
      if (items.isEmpty) {
        _toast('Pilih minimal satu sembako', error: true);
        return;
      }
      final totalPoin = _totalPoinSembako(prov.sembakoList);
      if (prov.saldo != null && totalPoin > prov.saldo!.saldoPoin) {
        _toast('Total poin sembako melebihi saldo Anda', error: true);
        return;
      }
      ok = await prov.submitRequest(
        rewardId: reward.rewardId,
        poinRedeem: totalPoin,
        redeemSembakoItem: items,
      );
    } else {
      final poin = _poinInput;
      if (poin <= 0) {
        _toast('Masukkan jumlah poin yang valid', error: true);
        return;
      }
      if (prov.saldo != null && poin > prov.saldo!.saldoPoin) {
        _toast('Poin melebihi saldo Anda', error: true);
        return;
      }
      ok = await prov.submitRequest(
        rewardId: reward.rewardId,
        poinRedeem: poin,
      );
    }

    if (!mounted) return;
    if (ok) {
      _toast('Pengajuan penarikan berhasil dikirim');
      Navigator.pop(context, true);
    } else {
      _toast(prov.error ?? 'Gagal mengirim pengajuan', error: true);
    }
  }

  void _toast(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(message),
        backgroundColor: error ? Colors.redAccent : primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Consumer<RedeemNasabahProvider>(
          builder: (context, prov, _) {
            return Stack(
              children: [
                Column(
                  children: [
                    const TopBarBack(title: 'Ajukan Penarikan'),
                    Expanded(
                      child: prov.loadingForm
                          ? const Center(
                              child: CircularProgressIndicator(color: primary))
                          : SingleChildScrollView(
                              padding:
                                  const EdgeInsets.fromLTRB(20, 0, 20, 110),
                              child: _buildContent(prov),
                            ),
                    ),
                  ],
                ),
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 24,
                  child: _buildSubmitButton(prov),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(RedeemNasabahProvider prov) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSaldoCard(prov.saldo),
        const SizedBox(height: 20),
        const _SectionLabel('Jenis Reward'),
        const SizedBox(height: 8),
        _buildRewardSelector(prov.nilaiRewards),
        const SizedBox(height: 20),
        if (_selectedReward != null) _buildDynamicForm(prov),
      ],
    );
  }

  Widget _buildSaldoCard(SaldoNasabah? saldo) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            dark.withOpacity(0.95),
            const Color(0xFF2D5A1D).withOpacity(0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.account_balance_wallet_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Saldo Poin Anda',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  saldo == null
                      ? '— poin'
                      : '${_formatNumber(saldo.saldoPoin)} poin',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.4,
                  ),
                ),
                if (saldo != null && saldo.namaNasabah.isNotEmpty)
                  Text(
                    saldo.namaNasabah,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardSelector(List<NilaiRewardBank> rewards) {
    if (rewards.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF5F5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: const Text(
          'Bank belum menyediakan jenis reward.',
          style: TextStyle(fontFamily: 'Poppins', fontSize: 12),
        ),
      );
    }
    return Column(
      children: rewards.map((r) {
        final selected = _selectedReward?.rewardId == r.rewardId;
        final deskripsi = r.reward?.deskripsi;
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() {
              _selectedReward = r;
              _poinController.clear();
              _sembakoQty.clear();
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: selected ? primary.withOpacity(0.06) : Colors.white,
              border: Border.all(
                color: selected ? primary : Colors.black.withOpacity(0.1),
                width: selected ? 1.5 : 1,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: selected
                        ? primary.withOpacity(0.15)
                        : Colors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _iconForReward(r.namaReward),
                    size: 22,
                    color: selected ? primary : dark.withOpacity(0.5),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.namaReward.isEmpty ? 'Reward' : _capitalize(r.namaReward),
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: selected ? primary : dark,
                        ),
                      ),
                      if (deskripsi != null && deskripsi.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          deskripsi,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: Colors.black.withOpacity(0.5),
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 3),
                        Text(
                          _defaultDeskripsi(r.namaReward),
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: Colors.black.withOpacity(0.4),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? primary : Colors.transparent,
                    border: Border.all(
                      color: selected ? primary : Colors.black.withOpacity(0.2),
                      width: 2,
                    ),
                  ),
                  child: selected
                      ? const Icon(Icons.check_rounded,
                          size: 14, color: Colors.white)
                      : null,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  String _defaultDeskripsi(String namaReward) {
    final n = namaReward.toLowerCase();
    if (n.contains('uang')) return 'Tukarkan poin menjadi uang tunai';
    if (n.contains('emas')) return 'Tukarkan poin menjadi emas (gram)';
    if (n.contains('sembako')) return 'Tukarkan poin menjadi sembako pilihan';
    return 'Tukarkan poin dengan reward ini';
  }

  IconData _iconForReward(String name) {
    final n = name.toLowerCase();
    if (n.contains('uang')) return Icons.payments_rounded;
    if (n.contains('emas')) return Icons.diamond_rounded;
    if (n.contains('sembako')) return Icons.shopping_basket_rounded;
    return Icons.card_giftcard_rounded;
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1).toLowerCase()}';

  Widget _buildDynamicForm(RedeemNasabahProvider prov) {
    final reward = _selectedReward!;
    if (reward.isSembako) {
      return _buildSembakoForm(prov);
    }
    return _buildPoinForm(reward);
  }

  Widget _buildPoinForm(NilaiRewardBank reward) {
    final poin = _poinInput;
    final konversi = reward.convertPoin(poin);

    // Format nilai estimasi — Rp di kiri untuk uang tunai
    final String estimasiValue;
    if (reward.isUang) {
      estimasiValue = 'Rp ${_formatNumber(konversi.round())}';
    } else if (reward.isEmas) {
      estimasiValue = '${konversi.toStringAsFixed(4)} ${reward.satuan}';
    } else {
      estimasiValue = '${konversi.toStringAsFixed(2)} ${reward.satuan}';
    }

    // Format rate konversi
    final String rateText;
    if (reward.isUang) {
      rateText = '${_formatNumber(reward.nilaiPoin)} pts = Rp ${_formatNumber(reward.nilaiKonversi.round())}';
    } else {
      rateText = '${_formatNumber(reward.nilaiPoin)} pts = ${reward.nilaiKonversi} ${reward.satuan}';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('Jumlah Poin'),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.black.withOpacity(0.15)),
            borderRadius: BorderRadius.circular(50),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            children: [
              const Icon(Icons.bolt_rounded, color: primary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _poinController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Masukkan jumlah poin',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const Text(
                'pts',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFEFFBF0),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: primary.withOpacity(0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Rate konversi ─────────────────────────────────
              Row(
                children: [
                  const Icon(Icons.swap_horiz_rounded, color: primary, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Nilai tukar: $rateText',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: Colors.black.withOpacity(0.55),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(height: 1, color: Color(0xFFD4EDD9)),
              const SizedBox(height: 10),
              // ── Estimasi ────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: primary,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: const Text(
                      'Estimasi',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    estimasiValue,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: dark,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSembakoForm(RedeemNasabahProvider prov) {
    final items = prov.sembakoList;
    final total = _totalPoinSembako(items);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const _SectionLabel('Pilih Sembako'),
            const Spacer(),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Text(
                'Total ${_formatNumber(total)} pts',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (items.isEmpty)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBF1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: const Color(0xFFFAA324).withOpacity(0.3)),
            ),
            child: const Text(
              'Belum ada sembako tersedia.',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 12),
            ),
          )
        else
          ...items.map((item) => _buildSembakoTile(item)),
      ],
    );
  }

  Widget _buildSembakoTile(SembakoItem item) {
    final qty = _sembakoQty[item.sembakoId] ?? 0;
    final isSelected = qty > 0;
    final harga = item.poinHargaNasabah;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isSelected ? primary.withOpacity(0.06) : Colors.white,
        border: Border.all(
          color: isSelected
              ? primary.withOpacity(0.4)
              : Colors.black.withOpacity(0.1),
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 48,
              height: 48,
              child: item.photoUrl.isEmpty
                  ? Container(
                      color: primary.withOpacity(0.18),
                      child: const Icon(Icons.shopping_basket_rounded,
                          color: primary, size: 22),
                    )
                  : Image.network(
                      item.photoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: primary.withOpacity(0.18),
                        child: const Icon(Icons.shopping_basket_rounded,
                            color: primary, size: 22),
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
                  '${_formatNumber(harga)} pts • Stok ${_formatNumber(item.stok)}',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: Colors.black.withOpacity(0.55),
                  ),
                ),
              ],
            ),
          ),
          if (isSelected) ...[
            _qtyButton(
              icon: Icons.remove_rounded,
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  if (qty > 1) {
                    _sembakoQty[item.sembakoId] = qty - 1;
                  } else {
                    _sembakoQty.remove(item.sembakoId);
                  }
                });
              },
              filled: false,
            ),
            SizedBox(
              width: 32,
              child: Center(
                child: Text(
                  '${qty.toInt()}',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    color: dark,
                  ),
                ),
              ),
            ),
            _qtyButton(
              icon: Icons.add_rounded,
              onTap: () {
                if (qty + 1 > item.stok) {
                  _toast('Stok tidak mencukupi', error: true);
                  return;
                }
                HapticFeedback.selectionClick();
                setState(() => _sembakoQty[item.sembakoId] = qty + 1);
              },
              filled: true,
            ),
          ] else
            GestureDetector(
              onTap: () {
                if (item.stok < 1) {
                  _toast('Stok habis', error: true);
                  return;
                }
                HapticFeedback.selectionClick();
                setState(() => _sembakoQty[item.sembakoId] = 1);
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Text(
                  'Pilih',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: primary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _qtyButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool filled,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: filled ? primary : Colors.white,
          border: Border.all(
            color: filled ? primary : Colors.black.withOpacity(0.15),
          ),
          borderRadius: BorderRadius.circular(50),
        ),
        child: Icon(
          icon,
          size: 16,
          color: filled ? Colors.white : Colors.black.withOpacity(0.6),
        ),
      ),
    );
  }

  Widget _buildSubmitButton(RedeemNasabahProvider prov) {
    final disabled = prov.submitting || prov.loadingForm;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(50),
        color: disabled ? Colors.grey.shade400 : dark,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: disabled ? null : _submit,
          borderRadius: BorderRadius.circular(50),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: prov.submitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Text(
                      'Kirim Pengajuan',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.white,
                        fontSize: 15,
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

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.black.withOpacity(0.7),
        ),
      ),
    );
  }
}
