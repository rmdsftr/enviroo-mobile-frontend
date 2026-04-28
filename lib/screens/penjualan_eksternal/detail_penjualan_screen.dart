import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/penjualan_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/penjualan_provider.dart';
import '../../widgets/topbar_back.dart';

class _C {
  static const dark = Color(0xFF013236);
  static const green = Color(0xFF4EA771);
  static const cardBg = Color(0xFFF7FBF5);
  static const muted = Color(0xFF8A9A92);
  static const danger = Color(0xFFD94848);
  static const border = Color(0xFFE6EDE9);
}

class DetailPenjualanScreen extends StatefulWidget {
  final String penjualanId;
  const DetailPenjualanScreen({super.key, required this.penjualanId});

  @override
  State<DetailPenjualanScreen> createState() => _DetailPenjualanScreenState();
}

class _DetailPenjualanScreenState extends State<DetailPenjualanScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    final token = auth.currentUser?.accessToken ?? '';
    await context
        .read<PenjualanProvider>()
        .fetchDetail(widget.penjualanId, token);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const TopBarBack(title: 'Detail Penjualan'),
            Expanded(
              child: Consumer<PenjualanProvider>(
                builder: (_, prov, __) {
                  if (prov.detailStatus == FetchStatus.loading) {
                    return const Center(
                      child: CircularProgressIndicator(color: _C.green),
                    );
                  }
                  if (prov.detailStatus == FetchStatus.error ||
                      prov.detail == null) {
                    return _buildError(
                        prov.detailError ?? 'Gagal memuat detail');
                  }
                  return _buildStruk(prov.detail!);
                },
              ),
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
                    foregroundColor: Colors.white),
                child: const Text('Coba Lagi',
                    style: TextStyle(fontFamily: 'Poppins')),
              ),
            ],
          ),
        ),
      );

  Widget _buildStruk(DetailPenjualanModel d) {
    final fmtPoin = NumberFormat('#,##0.##########', 'id_ID');
    final fmtQty = NumberFormat('#,##0.##########', 'id_ID');

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
      children: [
        // ── Struk Header ─────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _C.cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _C.border),
          ),
          child: Column(
            children: [
              const Icon(Icons.receipt_long_rounded,
                  color: _C.dark, size: 32),
              const SizedBox(height: 6),
              const Text(
                'Struk Penjualan Eksternal',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: _C.dark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'ID: ${d.penjualanId}',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10.5,
                  color: _C.muted,
                ),
              ),
              const SizedBox(height: 14),
              _kv('Pembeli', d.identitasPembeli),
              _kv('Jenis Reward', d.rewardName),
              _kv('Tanggal', d.tanggalFormatted),
              _kv('Petugas', d.adminName),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // ── Items Sampah ─────────────────────────────────────────────────
        const _SectionTitle(title: 'Item Sampah Dijual'),
        const SizedBox(height: 8),
        if (d.itemsSampah.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Text('Tidak ada item sampah.',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    color: _C.muted,
                    fontSize: 12)),
          )
        else
          ...d.itemsSampah.map((s) => _ItemRow(
                title: s.namaSampah,
                subtitle:
                    '${fmtQty.format(s.qty)} × ${fmtPoin.format(s.poinJual)} poin',
                trailing: '${fmtPoin.format(s.subtotalPoin)} poin',
              )),

        // ── Items Sembako (opsional) ─────────────────────────────────────
        if (d.isSembako && (d.itemsSembako?.isNotEmpty ?? false)) ...[
          const SizedBox(height: 18),
          const _SectionTitle(title: 'Sembako Diterima (Barter)'),
          const SizedBox(height: 8),
          ...d.itemsSembako!.map((sm) => _ItemRow(
                title: sm.namaSembako,
                subtitle:
                    '${fmtQty.format(sm.qty)} × ${fmtPoin.format(sm.hargaPoin)} poin',
                trailing: '${fmtPoin.format(sm.subtotalPoin)} poin',
              )),
        ],

        const SizedBox(height: 18),

        // ── Total ────────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _C.dark,
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Nilai Penjualan',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '${fmtPoin.format(d.totalPoin)} Poin',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(color: Colors.white12, height: 1),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Hasil Konversi Akhir',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    d.satuan?.toLowerCase() == 'rupiah' ||
                            d.satuan?.toLowerCase() == 'rp'
                        ? 'Rp ${fmtPoin.format(d.totalKonversi)}'
                        : '${fmtPoin.format(d.totalKonversi)} ${d.satuan ?? ''}',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      color: Color(0xFF94DF0C), // Accent color
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 22),

        // ── Bukti Foto ───────────────────────────────────────────────────
        const _SectionTitle(title: 'Bukti Serah Terima'),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: AspectRatio(
            aspectRatio: 4 / 3,
            child: d.buktiFoto.isEmpty
                ? Container(
                    color: _C.cardBg,
                    child: const Center(
                      child: Icon(Icons.image_not_supported_rounded,
                          color: _C.muted, size: 40),
                    ),
                  )
                : Image.network(
                    d.buktiFoto,
                    fit: BoxFit.cover,
                    loadingBuilder: (_, child, p) => p == null
                        ? child
                        : const Center(
                            child: CircularProgressIndicator(
                                color: _C.green, strokeWidth: 2),
                          ),
                    errorBuilder: (_, __, ___) => Container(
                      color: _C.cardBg,
                      child: const Center(
                        child: Icon(Icons.broken_image_rounded,
                            color: _C.muted, size: 40),
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 90,
              child: Text(
                k,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11.5,
                  color: _C.muted,
                ),
              ),
            ),
            const Text(': ',
                style: TextStyle(
                    fontFamily: 'Poppins', color: _C.muted, fontSize: 11.5)),
            Expanded(
              child: Text(
                v,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _C.dark,
                ),
              ),
            ),
          ],
        ),
      );
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});
  @override
  Widget build(BuildContext context) => Text(
        title,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: _C.dark,
        ),
      );
}

class _ItemRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final String trailing;
  const _ItemRow({
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: _C.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: _C.dark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: _C.muted,
                  ),
                ),
              ],
            ),
          ),
          Text(
            trailing,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _C.green,
            ),
          ),
        ],
      ),
    );
  }
}
