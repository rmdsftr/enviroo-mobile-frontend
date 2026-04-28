import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/penjualan_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/penjualan_provider.dart';
import '../../widgets/topbar_back.dart';
import 'detail_penjualan_screen.dart';
import 'jenis_transaksi_screen.dart';

// ─── Palette ────────────────────────────────────────────────────────────────
class _C {
  static const dark = Color(0xFF013236);
  static const green = Color(0xFF4EA771);
  static const cardBg = Color(0xFFF7FBF5);
  static const muted = Color(0xFF8A9A92);
  static const danger = Color(0xFFD94848);
}

class RiwayatPenjualanScreen extends StatefulWidget {
  const RiwayatPenjualanScreen({super.key});

  @override
  State<RiwayatPenjualanScreen> createState() => _RiwayatPenjualanScreenState();
}

class _RiwayatPenjualanScreenState extends State<RiwayatPenjualanScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    final prov = context.read<PenjualanProvider>();
    final bankId = auth.bankId ?? '';
    final token = auth.currentUser?.accessToken ?? '';
    if (bankId.isEmpty || token.isEmpty) return;
    await prov.fetchRiwayat(bankId, token);
  }

  void _openForm() {
    // Bersihkan state form sebelum mulai alur baru
    context.read<PenjualanProvider>().resetForm();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const JenisTransaksiScreen()),
    ).then((_) => _load()); // refresh saat balik
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const TopBarBack(title: 'Penjualan Eksternal'),
            Expanded(
              child: Consumer<PenjualanProvider>(
                builder: (_, prov, __) {
                  if (prov.riwayatStatus == FetchStatus.loading) {
                    return const Center(
                      child: CircularProgressIndicator(color: _C.green),
                    );
                  }
                  if (prov.riwayatStatus == FetchStatus.error) {
                    return _buildError(prov.riwayatError ?? 'Terjadi kesalahan');
                  }
                  if (prov.riwayat.isEmpty) {
                    return _buildEmpty();
                  }
                  return RefreshIndicator(
                    color: _C.green,
                    onRefresh: _load,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                      itemCount: prov.riwayat.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) => _RiwayatCard(
                        item: prov.riwayat[i],
                        onTap: () => _openDetail(prov.riwayat[i]),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openForm,
        backgroundColor: _C.dark,
        foregroundColor: Colors.white,
        elevation: 3,
        icon: const Icon(Icons.add_rounded, size: 22),
        label: const Text(
          'Jual Sampah ke Pihak Eksternal',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  void _openDetail(RiwayatPenjualanModel item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailPenjualanScreen(penjualanId: item.penjualanId),
      ),
    );
  }

  Widget _buildEmpty() => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 100),
          const Icon(Icons.receipt_long_rounded, size: 64, color: _C.muted),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              'Belum ada riwayat penjualan',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: _C.muted,
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Center(
            child: Text(
              'Tekan tombol di bawah untuk mulai menjual sampah',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                color: _C.muted,
              ),
            ),
          ),
          TextButton(
            onPressed: _load,
            child: const Text(
              'Muat ulang',
              style: TextStyle(
                color: _C.green,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );

  Widget _buildError(String msg) => Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: _C.danger, size: 42),
              const SizedBox(height: 10),
              Text(
                msg,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  color: _C.danger,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _load,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _C.dark,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Coba Lagi',
                    style: TextStyle(fontFamily: 'Poppins')),
              ),
            ],
          ),
        ),
      );
}

// ─── Card item riwayat ──────────────────────────────────────────────────────
class _RiwayatCard extends StatelessWidget {
  final RiwayatPenjualanModel item;
  final VoidCallback onTap;
  const _RiwayatCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final fmtPoin = NumberFormat('#,##0.##########', 'id_ID');
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE6EDE9), width: 1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _C.cardBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.local_shipping_rounded,
                    color: _C.dark, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.identitasPembeli,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: _C.dark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _Chip(label: item.rewardName, color: _C.green),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            item.tanggalFormatted,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              color: _C.muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${fmtPoin.format(item.totalPoin)} Poin',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _C.dark,
                          ),
                        ),
                        Text(
                          item.satuan?.toLowerCase() == 'rupiah' ||
                                  item.satuan?.toLowerCase() == 'rp'
                              ? 'Rp ${fmtPoin.format(item.totalKonversi)}'
                              : '${fmtPoin.format(item.totalKonversi)} ${item.satuan ?? ''}',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: _C.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item.totalItem} item · Admin: ${item.adminName}',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        color: _C.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: _C.muted, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
