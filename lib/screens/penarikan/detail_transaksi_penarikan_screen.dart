import 'dart:convert';
import 'package:enviroo/widgets/success_bottom_sheet.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format/app_date.dart';
import '../../core/format/app_number.dart';
import '../../models/penarikan_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/penarikan_petugas_provider.dart';
import '../../widgets/penarikan_detail_widgets.dart';
import '../../widgets/custom_snackbar.dart';
import '../../widgets/topbar_back.dart';
import 'deadline_penarikan_screen.dart';
import 'scanner_penarikan_screen.dart';
import 'package:enviroo/core/theme/app_colors.dart';
import 'package:enviroo/core/theme/app_text.dart';
import 'package:enviroo/widgets/state_message.dart';

class DetailTransaksiPenarikanScreen extends StatefulWidget {
  final String penarikanId;
  const DetailTransaksiPenarikanScreen({super.key, required this.penarikanId});

  @override
  State<DetailTransaksiPenarikanScreen> createState() =>
      _DetailTransaksiPenarikanScreenState();
}

class _DetailTransaksiPenarikanScreenState
    extends State<DetailTransaksiPenarikanScreen> {
  static const Color primary = AppColors.green;
  static const Color dark = AppColors.dark;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prov = context.read<PenarikanPetugasProvider>();
      prov.bind(context.read<AuthProvider>());
      prov.loadDetail(widget.penarikanId);
    });
  }

  String _fmtDeadline(DateTime? dt) {
    if (dt == null) return '-';
    return '${AppDate.tanggalSingkat(dt)}, ${AppDate.jamWib(dt)}';
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1).toLowerCase()}';

  Future<void> _handleKonfirmasiFlow(String penarikanId, String nasabahId) async {
    final completed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ScannerPenarikanScreen(
          penarikanId: penarikanId,
          nasabahId: nasabahId,
        ),
      ),
    );
    if (completed != true || !mounted) return;

    await context.read<PenarikanPetugasProvider>().loadDetail(penarikanId);
    if (mounted) _showSuccessDialog();
  }

  Future<void> _showSuccessDialog() async {
    await showSuccessBottomSheet(
      context,
      title: 'Berhasil!',
      message: 'Penyerahan insentif pada nasabah berhasil dilakukan',
      onDismiss: () => Navigator.pop(context),
    );
  }

  Future<void> _openTolak(String penarikanId) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => DeadlinePenarikanScreen.tolak(penarikanId: penarikanId),
      ),
    );
    if (!mounted) return;
    context.read<PenarikanPetugasProvider>().loadDetail(penarikanId);
    if (result == true) {
      showCustomSnackBar(context, 'Pengajuan penarikan berhasil ditolak',
          type: SnackBarType.success);
    }
  }

  Future<void> _openSetujui(String penarikanId) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => DeadlinePenarikanScreen.setujui(penarikanId: penarikanId),
      ),
    );
    if (!mounted) return;
    context.read<PenarikanPetugasProvider>().loadDetail(penarikanId);
    if (result == true) {
      showCustomSnackBar(context, 'Pengajuan penarikan berhasil disetujui',
          type: SnackBarType.success);
    }
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
          child: Consumer<PenarikanPetugasProvider>(
            builder: (_, prov, __) {
              return Column(
                children: [
                  const TopBarBack(title: 'Detail Penarikan'),
                  Expanded(
                    child: prov.loadingDetail
                        ? const Center(
                            child: CircularProgressIndicator(color: primary))
                        : prov.detail == null
                            ? _buildError(prov.errorDetail)
                            : _buildBody(prov.detail!, prov),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBody(PenarikanDetail d, PenarikanPetugasProvider prov) {
    final hasAction = d.status == StatusPenarikan.pending ||
        d.status == StatusPenarikan.approved;

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
                PenarikanDetailHeader(
                  nominal: d.nominalPenarikan,
                  satuan: d.satuanPenarikan,
                  isUang: d.isUang,
                  status: d.status,
                  penarikanId: d.penarikanId,
                ),
                const SizedBox(height: 20),
                _buildNasabahCard(d),
                const SizedBox(height: 12),
                _buildInfoSection(d),
                if (d.isBarang && d.detailBarang.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildBarangCard(d),
                ],
                const SizedBox(height: 12),
                _buildEstimasiCard(d),
                if (d.buktiFoto != null && d.buktiFoto!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildBuktiFotoCard(d.buktiFoto!),
                ],
                const SizedBox(height: 12),
                PenarikanRiwayatCard(riwayat: d.riwayat),
                if (!hasAction) const SizedBox(height: 24),
              ],
            ),
          ),
          if (hasAction) ...[
            const SizedBox(height: 20),
            _buildActionBar(d, prov),
          ],
        ],
      ),
    );
  }

  Widget _buildActionBar(PenarikanDetail d, PenarikanPetugasProvider prov) {
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
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: _buildActionButtons(d, prov),
    );
  }

  Widget _buildActionButtons(PenarikanDetail d, PenarikanPetugasProvider prov) {
    if (d.status == StatusPenarikan.pending) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                backgroundColor: AppColors.danger.withValues(alpha: 0.06),
                side: const BorderSide(color: AppColors.danger, width: 1.2),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50)),
              ),
              onPressed: () => _openTolak(d.penarikanId),
              child: Text(
                'Tolak Pengajuan',
                style: AppText.w600(13),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50)),
              ),
              onPressed: () => _openSetujui(d.penarikanId),
              child: Text(
                'Setujui Pengajuan',
                style: AppText.w600(13),
              ),
            ),
          ),
        ],
      );
    }

    return _buildKonfirmasiButton(d, prov);
  }

  Widget _buildNasabahCard(PenarikanDetail d) {
    return SectionCard(
      icon: Icons.person_rounded,
      title: 'Informasi Nasabah',
      children: [
        PenarikanInfoRow(
          label: 'Nama Nasabah',
          value: d.namaNasabah?.isNotEmpty == true ? d.namaNasabah! : '-',
        ),
        PenarikanInfoRow(
          label: 'ID Nasabah',
          value: d.nasabahId?.isNotEmpty == true ? d.nasabahId! : '-',
        ),
      ],
    );
  }

  Widget _buildInfoSection(PenarikanDetail d) {
    return SectionCard(
      icon: Icons.receipt_long_rounded,
      title: 'Informasi Penarikan',
      children: [
        PenarikanInfoRow(label: 'Insentif', value: _capitalize(d.namaReward)),
        PenarikanInfoRow(label: 'ID Transaksi', value: d.penarikanId),
        PenarikanInfoRow(
          label: 'Nominal',
          value: AppNumber.nominal(d.nominalPenarikan,
              satuan: d.satuanPenarikan, isUang: d.isUang),
        ),
        PenarikanInfoRow(label: 'Status', value: d.status.label),
      ],
    );
  }

  Widget _buildBarangCard(PenarikanDetail d) {
    final items = d.detailBarang;
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

  Widget _buildEstimasiCard(PenarikanDetail d) {
    return SectionCard(
      icon: Icons.event_available_rounded,
      title: 'Estimasi Konfirmasi',
      children: [
        PenarikanInfoRow(
          label: 'Pengajuan',
          value: _fmtDeadline(d.deadlineKonfirmasi),
        ),
        PenarikanInfoRow(
          label: 'Pengambilan',
          value: _fmtDeadline(d.deadlineJemput),
        ),
      ],
    );
  }

  Widget _buildBuktiFotoCard(String buktiFoto) {
    Widget imgWidget;
    if (buktiFoto.startsWith('http')) {
      imgWidget = Image.network(
        buktiFoto,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Center(
          child: Icon(Icons.broken_image_rounded, color: Colors.grey, size: 40),
        ),
      );
    } else {
      try {
        final bytes = base64Decode(buktiFoto);
        imgWidget = Image.memory(bytes, fit: BoxFit.cover);
      } catch (_) {
        imgWidget = const Center(
          child: Icon(Icons.broken_image_rounded, color: Colors.grey, size: 40),
        );
      }
    }

    return SectionCard(
      icon: Icons.photo_camera_rounded,
      title: 'Bukti Penyerahan Insentif',
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: AspectRatio(
            aspectRatio: 4 / 3,
            child: imgWidget,
          ),
        ),
      ],
    );
  }

  Widget _buildKonfirmasiButton(PenarikanDetail d, PenarikanPetugasProvider prov) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: dark,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(50)),
        ),
        onPressed: prov.submitting
            ? null
            : () => _handleKonfirmasiFlow(d.penarikanId, d.nasabahId ?? ''),
        child: prov.submitting
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Memproses...',
                    style: AppText.w600(13),
                  ),
                ],
              )
            : Text(
                'Konfirmasi Penyerahan Insentif',
                style: AppText.w600(13),
              ),
      ),
    );
  }

  Widget _buildError(String? message) => StateMessage(
        illustration: StateArt.error,
        message: message ?? 'Detail tidak tersedia',
        action: StateRetryButton(
          onPressed: () => context
              .read<PenarikanPetugasProvider>()
              .loadDetail(widget.penarikanId),
          label: 'Coba lagi',
          color: primary,
          radius: 50,
        ),
      );
}
