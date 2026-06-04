import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/penjualan_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/bagi_hasil_provider.dart' hide FetchStatus;
import '../../providers/penjualan_provider.dart';
import '../../widgets/topbar_back.dart';
import '../lihat_foto_screen.dart';
import '../bagi_hasil/preview_bagi_hasil_screen.dart';
import '../bagi_hasil/struk_detail_bagi_hasil_screen.dart';

// ── Color Palette ─────────────────────────────────────────────────────────────
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
    await context.read<PenjualanProvider>().fetchDetail(widget.penjualanId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bg_struk.webp'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
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
      ),
    );
  }

  // ── Error State ─────────────────────────────────────────────────────────────
  Widget _buildError(String msg) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off_rounded,
                  size: 40, color: _C.danger.withOpacity(0.5)),
              const SizedBox(height: 12),
              Text(
                msg,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: _C.dark.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _load,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _C.dark,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child:
                    const Text('Coba Lagi', style: TextStyle(fontFamily: 'Poppins')),
              ),
            ],
          ),
        ),
      );

  // ── Main Content ────────────────────────────────────────────────────────────
  Widget _buildStruk(DetailPenjualanModel d) {
    final fmtPoin = NumberFormat('#,##0.##########', 'id_ID');
    final fmtQty = NumberFormat('#,##0.##########', 'id_ID');
    final fmtRp = NumberFormat('#,##0', 'id_ID');
    final isSembako = d.namaReward.toLowerCase() == 'sembako';

    String fmtHarga(double val) => isSembako
        ? '${fmtPoin.format(val)} ${d.satuanReward}'
        : 'Rp ${fmtRp.format(val)}';

    final statusBh = d.statusBagiHasil.toLowerCase();
    final Color statusColor;
    final IconData statusIcon;
    final String statusLabel;

    if (statusBh == 'berhasil') {
      statusColor = _C.green;
      statusIcon = Icons.check_circle_rounded;
      statusLabel = 'Terdistribusi';
    } else if (statusBh == 'gagal') {
      statusColor = _C.danger;
      statusIcon = Icons.cancel_rounded;
      statusLabel = 'Gagal';
    } else {
      statusColor = Colors.orange;
      statusIcon = Icons.hourglass_top_rounded;
      statusLabel = 'Menunggu Distribusi';
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      child: Column(
        children: [
          // ── Hero Header ──────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _C.green.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.receipt_long_rounded,
                      color: _C.green, size: 36),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Penjualan Selesai',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    color: Color(0xFF4EA771),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ID: ${d.penjualanId}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: _C.dark.withOpacity(0.45),
                  ),
                ),
                const SizedBox(height: 7),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Text(
                    d.tanggalFormatted,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      color: _C.dark.withOpacity(0.4),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Info Card ───────────────────────────────────────────────────
          _buildInfoCard(d, statusBh, statusLabel),
          const SizedBox(height: 16),

          // ── Total Card ──────────────────────────────────────────────────
          _buildTotalCard(d, fmtHarga),
          const SizedBox(height: 16),

          // ── Items Card ──────────────────────────────────────────────────
          _buildItemsCard(d, fmtQty, fmtHarga),
          const SizedBox(height: 16),

          // ── Harga Nasabah Card ──────────────────────────────────────────
          _buildHargaNasabahCard(d, fmtHarga),
          const SizedBox(height: 16),

          // ── Bukti Foto ──────────────────────────────────────────────────
          _buildFotoCard(d),
          const SizedBox(height: 24),

          // ── CTA Button ──────────────────────────────────────────────────
          _buildCta(d),
        ],
      ),
    );
  }

  // ── Info Card ───────────────────────────────────────────────────────────────
  Widget _buildInfoCard(DetailPenjualanModel d, String statusBh, String statusLabel) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoRow(Icons.person_rounded, 'Pembeli', d.identitasPembeli),
          _divider(),
          _infoRow(Icons.badge_rounded, 'Petugas', d.adminName),
          _divider(),
          _infoRow(Icons.card_giftcard_rounded, 'Jenis Reward', d.namaReward),
          _divider(),
          _infoRow(Icons.inventory_2_rounded, 'Jumlah Item',
              '${d.itemsSampah.length} item sampah'),
          _divider(),
          _infoRow(
            statusBh == 'berhasil'
                ? Icons.check_circle_rounded
                : Icons.hourglass_top_rounded,
            'Status Bagi Hasil',
            statusLabel,
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: _C.green.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 15, color: _C.green),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    color: _C.dark.withOpacity(0.45),
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: _C.dark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() =>
      Divider(color: _C.dark.withOpacity(0.06), height: 1);

  // ── Items Card ──────────────────────────────────────────────────────────────
  Widget _buildItemsCard(
    DetailPenjualanModel d,
    NumberFormat fmtQty,
    String Function(double) fmtHarga,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          Row(
            children: const [
              Icon(Icons.list_alt_rounded, color: _C.green, size: 18),
              SizedBox(width: 8),
              Text(
                'Item Sampah Dijual',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: _C.dark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (d.itemsSampah.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                'Tidak ada item sampah.',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: _C.dark.withOpacity(0.4),
                  fontSize: 12,
                ),
              ),
            )
          else ...[
            // Table header
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _C.dark.withOpacity(0.04),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: const [
                  Expanded(
                    flex: 4,
                    child: Text(
                      'Nama Sampah',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _C.dark,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 80,
                    child: Text(
                      'Qty × Harga',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _C.dark,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 65,
                    child: Text(
                      'Subtotal',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _C.dark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),

            // Table rows
            ...d.itemsSampah.asMap().entries.map((entry) {
              final i = entry.key;
              final s = entry.value;
              final isEven = i % 2 == 0;
              return Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isEven
                      ? Colors.transparent
                      : _C.dark.withOpacity(0.02),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Text(
                        s.namaSampah,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: _C.dark,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 80,
                      child: Text(
                        '${fmtQty.format(s.qty)} × ${fmtHarga(s.hargaJual)}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 9.5,
                          color: _C.dark.withOpacity(0.6),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 65,
                      child: Text(
                        fmtHarga(s.subtotalPenjualan),
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _C.green,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  // ── Harga Nasabah Card ──────────────────────────────────────────────────────
  Widget _buildHargaNasabahCard(
    DetailPenjualanModel d,
    String Function(double) fmtHarga,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.person_pin_rounded, color: _C.green, size: 18),
              SizedBox(width: 8),
              Text(
                'Harga Sampah Nasabah',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: _C.dark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (d.itemsSampah.isEmpty)
            Text(
              'Tidak ada data.',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: _C.dark.withValues(alpha: 0.4),
              ),
            )
          else
            ...d.itemsSampah.asMap().entries.map((entry) {
              final i = entry.key;
              final s = entry.value;
              final isLast = i == d.itemsSampah.length - 1;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            s.namaSampah,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: _C.dark,
                            ),
                          ),
                        ),
                        Text(
                          fmtHarga(s.hargaNasabahSnapshot),
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _C.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isLast) Divider(color: _C.dark.withValues(alpha: 0.06), height: 1),
                ],
              );
            }),
        ],
      ),
    );
  }

  // ── Total Card ──────────────────────────────────────────────────────────────
  Widget _buildTotalCard(
      DetailPenjualanModel d, String Function(double) fmtHarga) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _C.green.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.payments_rounded,
                    color: _C.green, size: 18),
              ),
              const SizedBox(width: 12),
              const Text(
                'Total Penjualan',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: _C.dark,
                ),
              ),
            ],
          ),
          Text(
            fmtHarga(d.totalPenjualan),
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: _C.green,
            ),
          ),
        ],
      ),
    );
  }

  // ── Foto Card ───────────────────────────────────────────────────────────────
  Widget _buildFotoCard(DetailPenjualanModel d) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.photo_camera_rounded, color: _C.green, size: 18),
              SizedBox(width: 8),
              Text(
                'Bukti Serah Terima',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: _C.dark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: d.buktiFoto.isEmpty ? null : () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => LihatFotoScreen(
                  photoUrl: d.buktiFoto,
                  nama: 'Bukti Serah Terima',
                ),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: d.buktiFoto.isEmpty
                  ? Container(
                      color: _C.cardBg,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.image_not_supported_rounded,
                                color: _C.dark.withOpacity(0.2), size: 40),
                            const SizedBox(height: 8),
                            Text(
                              'Tidak ada foto',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                color: _C.dark.withOpacity(0.3),
                              ),
                            ),
                          ],
                        ),
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
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.broken_image_rounded,
                                  color: _C.dark.withOpacity(0.2), size: 40),
                              const SizedBox(height: 8),
                              Text(
                                'Foto tidak dapat dimuat',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  color: _C.dark.withOpacity(0.3),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ),
        ],
      ),
    );
  }

  // ── CTA Buttons ─────────────────────────────────────────────────────────────
  Widget _buildCta(DetailPenjualanModel d) {
    final statusBh = d.statusBagiHasil.toLowerCase();

    if (statusBh == 'pending') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {
            final bankId = context.read<AuthProvider>().bankId ?? '';
            context.read<BagiHasilProvider>().resetPreview();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PreviewBagiHasilScreen(
                  penjualanId: d.penjualanId,
                  bankId: bankId,
                ),
              ),
            ).then((_) => _load());
          },
          icon: const Icon(Icons.calculate_rounded, size: 18),
          label: const Text(
            'Hitung Bagi Hasil',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _C.dark,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(50),
            ),
            elevation: 0,
          ),
        ),
      );
    }

    if (statusBh == 'berhasil') {
      return Consumer<BagiHasilProvider>(
        builder: (_, bagiHasilProv, __) {
          final loading = bagiHasilProv.detailStatus == FetchStatus.loading;
          return SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: loading
                  ? null
                  : () async {
                      await bagiHasilProv.fetchDetail(d.penjualanId);
                      if (!mounted) return;
                      if (bagiHasilProv.detail != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => StrukDetailBagiHasilScreen(
                              detail: bagiHasilProv.detail!,
                            ),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              bagiHasilProv.detailError ??
                                  'Gagal mengambil data bagi hasil',
                              style: const TextStyle(fontFamily: 'Poppins'),
                            ),
                            backgroundColor: _C.danger,
                          ),
                        );
                      }
                    },
              icon: loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.receipt_long_rounded, size: 18),
              label: Text(
                loading ? 'Memuat...' : 'Lihat Detail Bagi Hasil',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _C.green,
                foregroundColor: Colors.white,
                disabledBackgroundColor: _C.green.withValues(alpha: 0.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
                elevation: 0,
              ),
            ),
          );
        },
      );
    }

    return const SizedBox.shrink();
  }
}
