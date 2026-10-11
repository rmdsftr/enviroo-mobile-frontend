import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/format/app_date.dart';
import '../../core/format/app_number.dart';
import '../../models/penarikan_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/penarikan_nasabah_provider.dart';
import '../../widgets/penarikan_detail_widgets.dart';
import '../../widgets/custom_snackbar.dart';
import '../../widgets/topbar_back.dart';
import 'qr_penarikan_screen.dart';
import 'package:enviroo/core/theme/app_colors.dart';
import 'package:enviroo/core/theme/app_text.dart';
import 'package:enviroo/widgets/state_message.dart';

class DetailPenarikanScreen extends StatefulWidget {
  final String penarikanId;

  const DetailPenarikanScreen({super.key, required this.penarikanId});

  @override
  State<DetailPenarikanScreen> createState() =>
      _DetailPenarikanScreenState();
}

class _DetailPenarikanScreenState extends State<DetailPenarikanScreen> {
  static const Color primary = AppColors.green;
  static const Color dark = AppColors.dark;

  bool _batalExpanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final prov = context.read<PenarikanNasabahProvider>();
      prov.bind(auth);
      if (widget.penarikanId.isNotEmpty) {
        prov.loadDetail(widget.penarikanId);
      }
    });
  }

  String _fmtDeadline(DateTime? dt) {
    if (dt == null) return '-';
    return '${AppDate.tanggalSingkat(dt)}, ${AppDate.jamWib(dt)}';
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1).toLowerCase()}';

  Future<void> _confirmBatal(PenarikanNasabahProvider prov) async {
    final catatanController = TextEditingController();

    final confirm = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: StatefulBuilder(
          builder: (ctx, setSheetState) {
            final catatanFilled = catatanController.text.trim().isNotEmpty;
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.cancel_outlined,
                          color: AppColors.danger, size: 32),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      'Batalkan Pengajuan?',
                      textAlign: TextAlign.center,
                      style: AppText.w700(17, dark),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      'Pengajuan penarikan akan dibatalkan dan saldo akan dikembalikan ke rekeningmu.',
                      textAlign: TextAlign.center,
                      style: AppText.r(13, Colors.black54),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: catatanController,
                    maxLines: 3,
                    minLines: 3,
                    maxLength: 255,
                    textInputAction: TextInputAction.done,
                    inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\n'))],
                    onChanged: (_) => setSheetState(() {}),
                    style: AppText.r(13, dark),
                    decoration: InputDecoration(
                      hintText: 'Isi alasan pembatalan pengajuan penarikan',
                      hintStyle: AppText.r(13, dark.withValues(alpha: 0.35)),
                      filled: true,
                      fillColor: const Color(0xFFF5F7FA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                            color: AppColors.danger, width: 1),
                      ),
                      contentPadding: const EdgeInsets.all(14),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.black54,
                            side: const BorderSide(color: Colors.black12),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50)),
                          ),
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text(
                            'Tidak',
                            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.danger,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey.shade300,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50)),
                          ),
                          onPressed:
                              catatanFilled ? () => Navigator.pop(ctx, true) : null,
                          child: const Text(
                            'Ya, Batalkan',
                            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );

    final catatan = catatanController.text.trim();
    catatanController.dispose();

    if (confirm != true || !mounted) return;

    final ok = await prov.callBatal(widget.penarikanId, catatan: catatan);
    if (!mounted) return;

    if (ok) {
      HapticFeedback.mediumImpact();
      showCustomSnackBar(
          context,
          'Pengajuan penarikan dibatalkan. Saldo sudah dikembalikan ke rekeningmu',
          type: SnackBarType.success);
    } else {
      showCustomSnackBar(context, 'Gagal membatalkan pengajuan');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PenarikanNasabahProvider>(
      builder: (_, prov, __) {
        final detail = prov.detail;
        final qrDetail = !prov.loadingDetail &&
                prov.errorDetail == null &&
                detail?.status == StatusPenarikan.approved
            ? detail
            : null;

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
                  const TopBarBack(title: 'Detail Penarikan'),
                  Expanded(
                    child: prov.loadingDetail
                        ? const Center(
                            child: CircularProgressIndicator(
                                color: primary))
                        : prov.errorDetail != null
                            ? _buildError(prov)
                            : detail == null
                                ? _buildEmpty()
                                : _buildDetail(detail, prov),
                  ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: qrDetail == null ? null : _buildQrCard(qrDetail),
        );
      },
    );
  }

  Widget _buildError(PenarikanNasabahProvider prov) => StateMessage(
        illustration: StateArt.error,
        message: prov.errorDetail ?? 'Terjadi kesalahan',
        action: StateRetryButton(
          onPressed: () => prov.loadDetail(widget.penarikanId),
          label: 'Coba lagi',
          color: primary,
          radius: 50,
        ),
      );

  Widget _buildEmpty() => const StateMessage(
        illustration: StateArt.emptyMoney,
        message: 'Detail tidak ditemukan',
      );

  Widget _buildDetail(
      PenarikanDetail detail, PenarikanNasabahProvider prov) {
    final isPending = detail.status == StatusPenarikan.pending;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(detail),
                const SizedBox(height: 20),
                _buildInfoSection(detail),
                if (detail.isBarang && detail.detailBarang.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildBarangCard(detail),
                ],
                const SizedBox(height: 12),
                _buildEstimasiCard(detail),
                if (detail.buktiFoto != null && detail.buktiFoto!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildBuktiFotoCard(detail),
                ],
                const SizedBox(height: 12),
                PenarikanRiwayatCard(riwayat: detail.riwayat),
                if (isPending) ...[
                  const SizedBox(height: 16),
                  _buildBatalCard(prov),
                ],
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(PenarikanDetail detail) {
    return PenarikanDetailHeader(
      nominal: detail.nominalPenarikan,
      satuan: detail.satuanPenarikan,
      isUang: detail.isUang,
      status: detail.status,
      penarikanId: detail.penarikanId,
    );
  }

  Widget _buildInfoSection(PenarikanDetail detail) {
    return SectionCard(
      icon: Icons.receipt_long_rounded,
      title: 'Informasi Penarikan',
      children: [
        PenarikanInfoRow(label: 'Insentif', value: _capitalize(detail.namaReward)),
        PenarikanInfoRow(label: 'ID Transaksi', value: detail.penarikanId),
        PenarikanInfoRow(
          label: 'Nominal',
          value: AppNumber.nominal(detail.nominalPenarikan,
              satuan: detail.satuanPenarikan, isUang: detail.isUang),
        ),
        PenarikanInfoRow(label: 'Status', value: detail.status.label),
      ],
    );
  }

  Widget _buildBarangCard(PenarikanDetail detail) {
    final items = detail.detailBarang;

    return SectionCard(
      icon: Icons.shopping_basket_rounded,
      title: 'Detail Barang',
      children: [
        for (int i = 0; i < items.length; i++) ...[
          if (i > 0) const Divider(height: 1, color: AppColors.divider),
          DetailBarangRow(item: items[i]),
        ],
      ],
    );
  }

  Widget _buildEstimasiCard(PenarikanDetail detail) {
    return SectionCard(
      icon: Icons.event_available_rounded,
      title: 'Estimasi Konfirmasi',
      children: [
        PenarikanInfoRow(
          label: 'Pengajuan',
          value: _fmtDeadline(detail.deadlineKonfirmasi),
        ),
        PenarikanInfoRow(
          label: 'Pengambilan',
          value: _fmtDeadline(detail.deadlineJemput),
        ),
      ],
    );
  }

  Widget _buildBuktiFotoCard(PenarikanDetail detail) {
    return SectionCard(
      icon: Icons.photo_camera_rounded,
      title: 'Bukti Penyerahan Insentif',
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: AspectRatio(
            aspectRatio: 4 / 3,
            child: Image.network(
              detail.buktiFoto!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: Colors.grey.shade200,
                child: const Center(
                  child: Icon(Icons.broken_image_rounded,
                      color: Colors.grey, size: 40),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQrCard(PenarikanDetail detail) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(
            width: 1,
            color: AppColors.dark.withValues(alpha: 0.1),
          ),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
          18, 16, 18, MediaQuery.of(context).padding.bottom + 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Tunjukkan QR code berikut pada petugas saat pengambilan insentif '
            'sebelum ${_fmtDeadline(detail.deadlineJemput)}',
            textAlign: TextAlign.center,
            style: AppText.p(11, color: dark.withValues(alpha: 0.6), height: 1.45),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: dark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50)),
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => QrPenarikanScreen(
                    transaksiId: detail.penarikanId,
                    nasabahId: detail.nasabahId ?? '',
                    deadline: detail.deadlineJemput ?? DateTime.now(),
                  ),
                ),
              ),
              icon: const Icon(Icons.qr_code_rounded, size: 16),
              label: Text(
                'QR Penerimaan Insentif',
                style: AppText.w600(13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBatalCard(PenarikanNasabahProvider prov) {
    return GestureDetector(
      onTap: () => setState(() => _batalExpanded = !_batalExpanded),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            width: 1,
            color: AppColors.dark.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.help_outline_rounded,
                    color: Colors.black45, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Ingin membatalkan pengajuan?',
                    style: AppText.w500(12, AppColors.dark),
                  ),
                ),
                Icon(
                  _batalExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: Colors.black45,
                  size: 20,
                ),
              ],
            ),
            if (_batalExpanded) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger, width: 1.5),
                    backgroundColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50)),
                  ),
                  onPressed: prov.canceling ? null : () => _confirmBatal(prov),
                  icon: prov.canceling
                      ? const SizedBox(
                          width: 15,
                          height: 15,
                          child: CircularProgressIndicator(
                              color: AppColors.danger, strokeWidth: 2.5),
                        )
                      : const Icon(Icons.cancel_outlined, size: 15),
                  label: Text(
                    'Batalkan Pengajuan',
                    style: AppText.w600(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
