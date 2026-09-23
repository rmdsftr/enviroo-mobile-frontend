import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/penjualan_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/penjualan_provider.dart';
import '../../providers/reward_provider.dart';
import '../../widgets/custom_snackbar.dart';
import '../../widgets/filter_chip_row.dart';
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

enum _MitraInputMode { baru, pilih }

class JenisTransaksiScreen extends StatefulWidget {
  const JenisTransaksiScreen({super.key});

  @override
  State<JenisTransaksiScreen> createState() => _JenisTransaksiScreenState();
}

class _JenisTransaksiScreenState extends State<JenisTransaksiScreen> {
  final _formKey = GlobalKey<FormState>();
  final _namaMitraCtrl = TextEditingController();
  _MitraInputMode _mitraMode = _MitraInputMode.baru;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prov = context.read<PenjualanProvider>();
      final bankId = context.read<AuthProvider>().bankId ?? '';
      // Pre-fill kalau user balik ke halaman ini
      _namaMitraCtrl.text = prov.namaMitra;
      // Kalau sebelumnya udah milih mitra existing (misal dari shortcut
      // "Mitra Pengepul Langganan"), langsung buka di mode "Pilih Mitra".
      if (prov.selectedMitraId != null) {
        setState(() => _mitraMode = _MitraInputMode.pilih);
      }
      context.read<RewardProvider>().fetchAllReward();
      if (bankId.isNotEmpty) prov.fetchMitra(bankId);
    });
  }

  @override
  void dispose() {
    _namaMitraCtrl.dispose();
    super.dispose();
  }

  void _next() {
    final prov = context.read<PenjualanProvider>();

    if (prov.selectedReward == null) {
      showCustomSnackBar(context, 'Jenis reward wajib dipilih');
      return;
    }

    if (_mitraMode == _MitraInputMode.baru) {
      if (!_formKey.currentState!.validate()) return;
      prov.setNamaMitra(_namaMitraCtrl.text.trim());
    } else {
      if (prov.selectedMitraId == null) {
        showCustomSnackBar(context, 'Pilih salah satu mitra dari daftar');
        return;
      }
    }

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
              child: Consumer2<PenjualanProvider, RewardProvider>(
                builder: (_, prov, reward, __) {
                  if (reward.allStatus == FetchStatus.loading) {
                    return const Center(
                      child: CircularProgressIndicator(color: _C.green),
                    );
                  }
                  if (reward.allStatus == FetchStatus.error) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.error_outline_rounded, size: 48, color: _C.muted.withValues(alpha: 0.5)),
                            const SizedBox(height: 12),
                            Text(
                              reward.allError ?? 'Gagal memuat data',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontFamily: 'Poppins', fontSize: 12.5, color: _C.muted),
                            ),
                            const SizedBox(height: 20),
                            OutlinedButton.icon(
                              onPressed: () {
                                reward.fetchAllReward();
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
                            rewards: reward.allReward,
                            value: prov.selectedReward,
                            onChanged: prov.setReward,
                          ),
                          const SizedBox(height: 18),
                          const _LabelField(label: 'Nama Mitra'),
                          const SizedBox(height: 8),
                          FilterChipRow<_MitraInputMode>(
                            padding: EdgeInsets.zero,
                            colorMode: FilterChipColorMode.dark,
                            selectedValue: _mitraMode,
                            items: const [
                              FilterChipItem(
                                value: _MitraInputMode.baru,
                                label: 'Input Baru',
                              ),
                              FilterChipItem(
                                value: _MitraInputMode.pilih,
                                label: 'Pilih Mitra',
                              ),
                            ],
                            onSelected: (mode) =>
                                setState(() => _mitraMode = mode),
                          ),
                          const SizedBox(height: 12),
                          if (_mitraMode == _MitraInputMode.baru)
                            TextFormField(
                              controller: _namaMitraCtrl,
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
                                  return 'Nama mitra wajib diisi';
                                }
                                if (v.trim().length < 3) {
                                  return 'Minimal 3 karakter';
                                }
                                return null;
                              },
                            )
                          else
                            _MitraPicker(
                              status: prov.mitraStatus,
                              error: prov.mitraError,
                              mitraList: prov.mitraList,
                              selectedMitraId: prov.selectedMitraId,
                              onSelect: prov.selectMitra,
                              onRetry: () {
                                final bankId =
                                    context.read<AuthProvider>().bankId ?? '';
                                if (bankId.isNotEmpty) prov.fetchMitra(bankId);
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
        ? Icon(icon, color: _C.dark, size: 20)
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

class _MitraPicker extends StatelessWidget {
  final FetchStatus status;
  final String? error;
  final List<MitraModel> mitraList;
  final String? selectedMitraId;
  final ValueChanged<MitraModel> onSelect;
  final VoidCallback onRetry;

  const _MitraPicker({
    required this.status,
    required this.error,
    required this.mitraList,
    required this.selectedMitraId,
    required this.onSelect,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (status == FetchStatus.loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: CircularProgressIndicator(color: _C.green),
        ),
      );
    }

    if (status == FetchStatus.error) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Text(
              error ?? 'Gagal memuat daftar mitra',
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 12.5, color: _C.muted),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
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
      );
    }

    if (mitraList.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: _C.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _C.border),
        ),
        child: const Text(
          'Belum ada mitra terdaftar. Gunakan "Input Baru" untuk mendaftarkan mitra ini.',
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: 'Poppins', fontSize: 12.5, color: _C.muted),
        ),
      );
    }

    return Column(
      children: mitraList.map((m) {
        final isSelected = m.mitraId == selectedMitraId;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: isSelected ? const Color(0xFFF4FBE6) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => onSelect(m),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? _C.green : _C.border,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.storefront_rounded,
                      size: 20,
                      color: isSelected ? _C.green : _C.dark,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        m.namaMitra,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _C.dark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
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
