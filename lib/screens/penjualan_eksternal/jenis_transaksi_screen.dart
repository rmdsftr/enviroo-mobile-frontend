import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/penjualan_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/penjualan_provider.dart';
import '../../widgets/topbar_back.dart';
import 'pilih_sampah_screen.dart';

class _C {
  static const dark = Color(0xFF013236);
  static const green = Color(0xFF4EA771);
  static const cardBg = Color(0xFFF7FBF5);
  static const muted = Color(0xFF8A9A92);
  static const danger = Color(0xFFD94848);
  static const border = Color(0xFFE6EDE9);
}

class JenisTransaksiScreen extends StatefulWidget {
  const JenisTransaksiScreen({super.key});

  @override
  State<JenisTransaksiScreen> createState() => _JenisTransaksiScreenState();
}

class _JenisTransaksiScreenState extends State<JenisTransaksiScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identitasCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final prov = context.read<PenjualanProvider>();
      // Pre-fill kalau user balik ke halaman ini
      _identitasCtrl.text = prov.identitasPembeli;
      prov.fetchRewards(auth.currentUser?.accessToken ?? '');
    });
  }

  @override
  void dispose() {
    _identitasCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (!_formKey.currentState!.validate()) return;
    final prov = context.read<PenjualanProvider>();
    if (prov.selectedReward == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: _C.danger,
          content: Text('Jenis reward wajib dipilih',
              style: TextStyle(fontFamily: 'Poppins')),
        ),
      );
      return;
    }
    prov.setIdentitasPembeli(_identitasCtrl.text.trim());

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PilihSampahScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const TopBarBack(title: 'Jenis Transaksi'),
            Expanded(
              child: Consumer<PenjualanProvider>(
                builder: (_, prov, __) {
                  if (prov.rewardStatus == FetchStatus.loading) {
                    return const Center(
                      child: CircularProgressIndicator(color: _C.green),
                    );
                  }
                  return SingleChildScrollView(
                    padding:
                        const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _StepIndicator(currentStep: 1),
                          const SizedBox(height: 20),
                          const _Heading(
                            title: 'Informasi Transaksi',
                            subtitle:
                                'Masukkan jenis reward dan identitas pihak yang membeli sampah dari bank.',
                          ),
                          const SizedBox(height: 24),

                          // ── Dropdown Jenis Reward ──────────────────
                          const _LabelField(label: 'Jenis Reward'),
                          const SizedBox(height: 6),
                          _RewardDropdown(
                            rewards: prov.rewards,
                            value: prov.selectedReward,
                            onChanged: prov.setReward,
                            errorText: prov.rewardError,
                          ),
                          const SizedBox(height: 18),

                          // ── Identitas Pembeli ──────────────────────
                          const _LabelField(label: 'Identitas Pembeli'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _identitasCtrl,
                            decoration: _inputDecoration(
                              hint: 'Contoh: Pabrik Kertas Sumbar',
                              icon: Icons.store_rounded,
                            ),
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              color: _C.dark,
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Identitas pembeli wajib diisi';
                              }
                              if (v.trim().length < 3) {
                                return 'Minimal 3 karakter';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _C.cardBg,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.info_outline_rounded,
                                    size: 16, color: _C.green),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Jika reward "Sembako", langkah berikutnya akan menampilkan pilihan barter sembako.',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 11,
                                      color: _C.dark,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            _BottomBar(onNext: _next),
          ],
        ),
      ),
    );
  }
}

// ─── Helper widgets ─────────────────────────────────────────────────────────
InputDecoration _inputDecoration({String? hint, IconData? icon}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(
        fontFamily: 'Poppins', fontSize: 12.5, color: _C.muted),
    prefixIcon: icon != null
        ? Icon(icon, color: _C.green, size: 20)
        : null,
    filled: true,
    fillColor: Colors.white,
    contentPadding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _C.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _C.green, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _C.danger),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _C.danger, width: 1.5),
    ),
  );
}

class _LabelField extends StatelessWidget {
  final String label;
  const _LabelField({required this.label});
  @override
  Widget build(BuildContext context) => Text(
        label,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _C.dark,
        ),
      );
}

class _Heading extends StatelessWidget {
  final String title;
  final String subtitle;
  const _Heading({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _C.dark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11.5,
              color: _C.muted,
            ),
          ),
        ],
      );
}

class _StepIndicator extends StatelessWidget {
  final int currentStep;
  const _StepIndicator({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    const total = 4; // Jenis → Sampah → (Sembako) → Foto
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

class _RewardDropdown extends StatelessWidget {
  final List<RewardModel> rewards;
  final RewardModel? value;
  final ValueChanged<RewardModel?> onChanged;
  final String? errorText;
  const _RewardDropdown({
    required this.rewards,
    required this.value,
    required this.onChanged,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonHideUnderline(
          child: DropdownButton2<RewardModel>(
            isExpanded: true,
            hint: const Text('Pilih jenis reward',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12.5,
                    color: _C.muted)),
            value: rewards.contains(value) ? value : null,
            items: rewards
                .map((r) => DropdownMenuItem<RewardModel>(
                      value: r,
                      child: Row(
                        children: [
                          Icon(
                            r.isSembako
                                ? Icons.shopping_basket_rounded
                                : Icons.account_balance_wallet_rounded,
                            size: 16,
                            color: _C.green,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            r.namaReward,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: _C.dark,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '(${r.satuan})',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              color: _C.muted,
                            ),
                          ),
                        ],
                      ),
                    ))
                .toList(),
            onChanged: onChanged,
            buttonStyleData: ButtonStyleData(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: _C.border),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            iconStyleData: const IconStyleData(
              icon: Icon(Icons.expand_more_rounded, color: _C.muted),
            ),
            dropdownStyleData: DropdownStyleData(
              maxHeight: 280,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            menuItemStyleData: const MenuItemStyleData(height: 44),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Text(errorText!,
              style: const TextStyle(
                  fontFamily: 'Poppins',
                  color: _C.danger,
                  fontSize: 11)),
        ],
      ],
    );
  }
}

class _BottomBar extends StatelessWidget {
  final VoidCallback onNext;
  const _BottomBar({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _C.border)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton.icon(
          onPressed: onNext,
          icon: const Icon(Icons.arrow_forward_rounded, size: 18),
          label: const Text(
            'Selanjutnya',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 13.5,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _C.dark,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
    );
  }
}
