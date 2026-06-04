import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/penjualan_model.dart';
import '../../providers/penjualan_provider.dart';
import '../../widgets/custom_snackbar.dart';
import '../../widgets/topbar_back.dart';
import 'pilih_sampah_screen.dart';

class _C {
  static const dark = Color(0xFF013236);
  static const green = Color(0xFF94DF0C);
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
      final prov = context.read<PenjualanProvider>();
      // Pre-fill kalau user balik ke halaman ini
      _identitasCtrl.text = prov.identitasPembeli;
      prov.fetchRewards();
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
      showCustomSnackBar(context, 'Jenis reward wajib dipilih');
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
                  if (prov.rewardStatus == FetchStatus.error) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.wifi_off_rounded, size: 48, color: _C.muted.withValues(alpha: 0.5)),
                            const SizedBox(height: 12),
                            Text(
                              prov.rewardError ?? 'Gagal memuat data',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontFamily: 'Poppins', fontSize: 12.5, color: _C.muted),
                            ),
                            const SizedBox(height: 20),
                            OutlinedButton.icon(
                              onPressed: () {
                                prov.fetchRewards();
                              },
                              icon: const Icon(Icons.refresh_rounded, size: 16),
                              label: const Text('Coba Lagi', style: TextStyle(fontFamily: 'Poppins')),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _C.dark,
                                side: const BorderSide(color: _C.border),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
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
                          const _LabelField(label: 'Jenis Reward'),
                          const SizedBox(height: 6),
                          _RewardSelector(
                            rewards: prov.rewards,
                            value: prov.selectedReward,
                            onChanged: prov.setReward,
                          ),
                          const SizedBox(height: 18),
                          const _LabelField(label: 'Identitas Pembeli'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _identitasCtrl,
                            decoration: _inputDecoration(
                              hint: 'Contoh: PT Semen Padang',
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
        const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: _C.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: _C.border, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: _C.danger),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
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
              fontSize: 12,
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
    const total = 3; // Jenis → Sampah → Foto
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

class _RewardSelector extends StatelessWidget {
  final List<RewardModel> rewards;
  final RewardModel? value;
  final ValueChanged<RewardModel?> onChanged;
  const _RewardSelector({
    required this.rewards,
    required this.value,
    required this.onChanged,
  });

  // Tambahkan ke _C kalau belum ada
  static const _lime = Color(0xFF94DF0C);
  static const _limeTint = Color(0xFFF4FBE6);
  static const _green = Color(0xFF4EA771);
  static const _iconIdleBg = Color(0xFFEDF4EF);

  IconData _iconFor(RewardModel r) {
    final s = '${r.namaReward} ${r.satuan}'.toLowerCase();
    if (s.contains('uang') || s.contains('rp') || s.contains('rupiah')) {
      return Icons.payments_outlined;
    }
    return Icons.shopping_basket_outlined;
  }

  String _subtitleFor(RewardModel r) {
    final s = r.satuan.toLowerCase();
    if (s.contains('rp') || s.contains('rupiah')) return 'Dibayar Rupiah';
    if (s.contains('poin')) return 'Ditukar dengan poin';
    return 'Satuan ${r.satuan}';
  }

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: rewards.asMap().entries.map((e) {
          final i = e.key;
          final r = e.value;
          final isSelected = value?.rewardId == r.rewardId;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: i == 0 ? 0 : 10),
              child: GestureDetector(
                onTap: () => onChanged(r),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    color: isSelected ? _limeTint : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? _lime : _C.border,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: isSelected ? _lime : _iconIdleBg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Icon(_iconFor(r), size: 20, color: _C.dark),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        r.namaReward,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _C.dark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _subtitleFor(r),
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: isSelected ? Color(0xFF013236).withValues(alpha: 0.75) : _C.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
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
                borderRadius: BorderRadius.circular(50)),
          ),
        ),
      ),
    );
  }
}
