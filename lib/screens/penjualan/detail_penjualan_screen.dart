import 'package:flutter/material.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:provider/provider.dart';

import '../../core/format/app_number.dart';
import '../../models/penjualan_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/bagi_hasil_provider.dart';
import '../../providers/penjualan_provider.dart';
import '../../services/bukti_penjualan_pdf_service.dart';
import '../../widgets/custom_snackbar.dart';
import '../../widgets/topbar_back.dart';
import '../lihat_foto_screen.dart';
import '../bagi_hasil/preview_bagi_hasil_screen.dart';
import '../bagi_hasil/struk_detail_bagi_hasil_screen.dart';
import 'package:enviroo/core/theme/app_colors.dart';
import 'package:enviroo/core/theme/app_text.dart';
import 'package:enviroo/widgets/state_message.dart';

class DetailPenjualanScreen extends StatefulWidget {
  final String penjualanId;
  const DetailPenjualanScreen({super.key, required this.penjualanId});

  @override
  State<DetailPenjualanScreen> createState() => _DetailPenjualanScreenState();
}

class _DetailPenjualanScreenState extends State<DetailPenjualanScreen> {
  bool _hargaNasabahExpanded = false;
  bool _unduhLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    await context.read<PenjualanProvider>().fetchDetail(widget.penjualanId);
  }

  Future<void> _unduhBukti(DetailPenjualanModel d) async {
    if (_unduhLoading) return;
    setState(() => _unduhLoading = true);

    try {
      final bytes = await BuktiPenjualanPdfService.generate(d, context: context);
      if (!mounted) return;

      final tujuan = await FlutterFileDialog.saveFile(
        params: SaveFileDialogParams(
          data: bytes,
          fileName: BuktiPenjualanPdfService.namaFile(d),
          mimeTypesFilter: const ['application/pdf'],
        ),
      );
      if (!mounted) return;

      if (tujuan != null) {
        _snack('Bukti penjualan berhasil disimpan', sukses: true);
      }
    } catch (e) {
      if (!mounted) return;
      _snack('Gagal membuat bukti penjualan: $e');
    } finally {
      if (mounted) setState(() => _unduhLoading = false);
    }
  }

  void _snack(String pesan, {bool sukses = false}) {
    showCustomSnackBar(context, pesan,
        type: sukses ? SnackBarType.success : SnackBarType.error);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
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
                        child: CircularProgressIndicator(color: AppColors.green),
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

  Widget _buildError(String msg) => StateMessage(
        illustration: StateArt.error,
        message: msg,
        action: StateRetryButton(onPressed: _load),
      );

  Widget _buildStruk(DetailPenjualanModel d) {
    final isBarang = d.namaReward.toLowerCase() == 'barang';

    String fmtHarga(double val) =>
        AppNumber.nominalSatuan(val, d.satuanReward, isUang: !isBarang);

    final statusBh = d.statusBagiHasil.toLowerCase();
    final Color statusColor;
    final IconData statusIcon;
    final String statusLabel;

    if (statusBh == 'berhasil') {
      statusColor = AppColors.green;
      statusIcon = Icons.check_circle_rounded;
      statusLabel = 'Terdistribusi';
    } else if (statusBh == 'gagal') {
      statusColor = AppColors.dangerSoft;
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
                    color: AppColors.green.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.receipt_long_rounded,
                      color: AppColors.green, size: 36),
                ),
                const SizedBox(height: 12),
                Text(
                  'Penjualan Selesai',
                  style: AppText.w700(17, AppColors.green),
                ),
                const SizedBox(height: 4),
                Text(
                  'ID: ${d.penjualanId}',
                  textAlign: TextAlign.center,
                  style: AppText.r(11, AppColors.dark.withValues(alpha: 0.45)),
                ),
                const SizedBox(height: 7),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Text(
                    d.tanggalFormatted,
                    textAlign: TextAlign.center,
                    style: AppText.r(10, AppColors.dark.withValues(alpha: 0.4)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          _buildInfoCard(d, statusIcon, statusLabel),
          const SizedBox(height: 16),

          _buildTotalCard(d, fmtHarga),
          const SizedBox(height: 16),

          _buildItemsCard(d, fmtHarga),
          const SizedBox(height: 16),

          _buildHargaNasabahCard(d, fmtHarga),
          const SizedBox(height: 16),

          _buildFotoCard(d),
          const SizedBox(height: 24),

          _buildCta(d),
          const SizedBox(height: 12),

          _buildUnduhButton(d),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
      DetailPenjualanModel d, IconData statusIcon, String statusLabel) {
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
          _infoRow(Icons.person_rounded, 'Mitra Pengepul', d.namaMitra),
          _divider(),
          _infoRow(Icons.badge_rounded, 'Petugas', d.adminName),
          _divider(),
          _infoRow(Icons.card_giftcard_rounded, 'Jenis Reward', d.namaReward),
          _divider(),
          _infoRow(Icons.inventory_2_rounded, 'Jumlah Item',
              '${d.itemsSampah.length} item sampah'),
          _divider(),
          _infoRow(statusIcon, 'Status Bagi Hasil', statusLabel),
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
              color: AppColors.green.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 15, color: AppColors.green),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppText.r(10, AppColors.dark.withValues(alpha: 0.45)),
                ),
                Text(
                  value,
                  style: AppText.w600(12, AppColors.dark),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() =>
      Divider(color: AppColors.dark.withValues(alpha: 0.06), height: 1);

  Widget _buildItemsCard(
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
            children: [
              Icon(Icons.list_alt_rounded, color: AppColors.green, size: 18),
              SizedBox(width: 8),
              Text(
                'Item Sampah Dijual',
                style: AppText.w700(13, AppColors.dark),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (d.itemsSampah.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                'Tidak ada item sampah.',
                style: AppText.r(12, AppColors.dark.withValues(alpha: 0.4)),
              ),
            )
          else ...[
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.dark.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Text(
                      'Nama Sampah',
                      style: AppText.w600(10, AppColors.dark),
                    ),
                  ),
                  SizedBox(
                    width: 80,
                    child: Text(
                      'Qty × Harga',
                      textAlign: TextAlign.center,
                      style: AppText.w600(10, AppColors.dark),
                    ),
                  ),
                  SizedBox(
                    width: 65,
                    child: Text(
                      'Subtotal',
                      textAlign: TextAlign.right,
                      style: AppText.w600(10, AppColors.dark),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),

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
                      : AppColors.dark.withValues(alpha: 0.02),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Text(
                        s.namaSampah,
                        style: AppText.w500(11, AppColors.dark),
                      ),
                    ),
                    SizedBox(
                      width: 80,
                      child: Text(
                        '${AppNumber.desimal(s.qty)} ${s.satuan} × ${fmtHarga(s.hargaJual)}',
                        textAlign: TextAlign.center,
                        style: AppText.r(9.5, AppColors.dark.withValues(alpha: 0.6)),
                      ),
                    ),
                    SizedBox(
                      width: 65,
                      child: Text(
                        fmtHarga(s.subtotalPenjualan),
                        textAlign: TextAlign.right,
                        style: AppText.w600(11, AppColors.green),
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
          InkWell(
            onTap: () =>
                setState(() => _hargaNasabahExpanded = !_hargaNasabahExpanded),
            child: Row(
              children: [
                const Icon(Icons.person_pin_rounded, color: AppColors.green, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Harga Sampah Nasabah',
                    style: AppText.w700(13, AppColors.dark),
                  ),
                ),
                AnimatedRotation(
                  turns: _hargaNasabahExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.dark.withValues(alpha: 0.5),
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            sizeCurve: Curves.easeInOut,
            crossFadeState: _hargaNasabahExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox(width: double.infinity, height: 0),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (d.itemsSampah.isEmpty)
                    Text(
                      'Tidak ada data.',
                      style: AppText.r(12, AppColors.dark.withValues(alpha: 0.4)),
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
                                    style: AppText.w500(12, AppColors.dark),
                                  ),
                                ),
                                Text(
                                  fmtHarga(s.hargaNasabahSnapshot),
                                  style: AppText.w600(12, AppColors.green),
                                ),
                              ],
                            ),
                          ),
                          if (!isLast) Divider(color: AppColors.dark.withValues(alpha: 0.06), height: 1),
                        ],
                      );
                    }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

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
                  color: AppColors.green.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.payments_rounded,
                    color: AppColors.green, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                'Total Penjualan',
                style: AppText.w600(13, AppColors.dark),
              ),
            ],
          ),
          Text(
            fmtHarga(d.totalPenjualan),
            style: AppText.w800(16, AppColors.green),
          ),
        ],
      ),
    );
  }

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
            children: [
              Icon(Icons.photo_camera_rounded, color: AppColors.green, size: 18),
              SizedBox(width: 8),
              Text(
                'Bukti Serah Terima',
                style: AppText.w700(13, AppColors.dark),
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
                      color: AppColors.surfaceMint,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.image_not_supported_rounded,
                                color: AppColors.dark.withValues(alpha: 0.2), size: 40),
                            const SizedBox(height: 8),
                            Text(
                              'Tidak ada foto',
                              style: AppText.r(12, AppColors.dark.withValues(alpha: 0.3)),
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
                                  color: AppColors.green, strokeWidth: 2),
                            ),
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.surfaceMint,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.broken_image_rounded,
                                  color: AppColors.dark.withValues(alpha: 0.2), size: 40),
                              const SizedBox(height: 8),
                              Text(
                                'Foto tidak dapat dimuat',
                                style: AppText.r(12, AppColors.dark.withValues(alpha: 0.3)),
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
          label: Text(
            'Hitung Bagi Hasil',
            style: AppText.w600(13),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.dark,
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
                        showCustomSnackBar(
                            context,
                            bagiHasilProv.detailError ?? 'Gagal mengambil data bagi hasil');
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
                style: AppText.w600(13),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.green.withValues(alpha: 0.5),
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

  Widget _buildUnduhButton(DetailPenjualanModel d) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _unduhLoading ? null : () => _unduhBukti(d),
        icon: _unduhLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.dark),
              )
            : const Icon(Icons.download_rounded, size: 18),
        label: Text(
          _unduhLoading ? 'Menyiapkan PDF...' : 'Unduh Bukti Penjualan',
          style: AppText.w600(13),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.dark,
          side: BorderSide(color: AppColors.dark.withValues(alpha: 0.25)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
        ),
      ),
    );
  }
}
