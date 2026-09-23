import 'dart:convert';
import 'package:enviroo/widgets/success_bottom_sheet.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/penarikan_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/penarikan_petugas_provider.dart';
import '../../widgets/penarikan_detail_widgets.dart';
import '../../widgets/topbar_back.dart';
import 'deadline_penarikan_screen.dart';
import 'scanner_penarikan_screen.dart';

class DetailTransaksiPenarikanScreen extends StatefulWidget {
  final String penarikanId;
  const DetailTransaksiPenarikanScreen({super.key, required this.penarikanId});

  @override
  State<DetailTransaksiPenarikanScreen> createState() =>
      _DetailTransaksiPenarikanScreenState();
}

class _DetailTransaksiPenarikanScreenState
    extends State<DetailTransaksiPenarikanScreen> {
  static const Color primary = Color(0xFF4EA771);
  static const Color dark = Color(0xFF013236);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prov = context.read<PenarikanPetugasProvider>();
      prov.bind(context.read<AuthProvider>());
      prov.loadDetail(widget.penarikanId);
    });
  }

  // ── Formatters ────────────────────────────────────────────────────────────

  String _fmtNominal(double v, String satuan, {bool isUang = false}) {
    final f = NumberFormat.decimalPattern('id_ID');
    f.maximumFractionDigits = 4;
    f.minimumFractionDigits = 0;
    if (isUang) return 'Rp ${f.format(v)}';
    return '${f.format(v)} ${satuan.isEmpty ? 'poin' : satuan}';
  }

  String _fmtDeadline(DateTime? dt) {
    if (dt == null) return '-';
    final dateStr = DateFormat('d MMMM yyyy', 'id_ID').format(dt);
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$dateStr, $h.$m WIB';
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1).toLowerCase()}';

  // ── Konfirmasi ────────────────────────────────────────────────────────────

  /// Buka scanner QR nasabah — begitu QR cocok, penarikan langsung
  /// diselesaikan di dalam scanner (atau lewat konfirmasi manual di sana).
  /// Di sini tinggal refresh & kasih feedback sukses.
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
      message: 'Penarikan berhasil dikonfirmasi.',
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFFEF4444),
          content: Text(
            'Pengajuan penarikan berhasil ditolak',
            style: TextStyle(fontFamily: 'Poppins'),
          ),
        ),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: primary,
          content: Text(
            'Pengajuan penarikan berhasil disetujui',
            style: TextStyle(fontFamily: 'Poppins'),
          ),
        ),
      );
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

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
                if (d.isSembako && d.detailSembako.isNotEmpty) ...[
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

  // ── Bar tombol aksi: full-bleed, rounded di atas, mentok ke bawah layar ──

  Widget _buildActionBar(PenarikanDetail d, PenarikanPetugasProvider prov) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(
            width: 1,
            color: const Color(0xFF013236).withValues(alpha: 0.1),
          ),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: _buildActionButtons(d, prov),
    );
  }

  // ── Tombol aksi (tergantung status terkini) ──────────────────────────────

  Widget _buildActionButtons(PenarikanDetail d, PenarikanPetugasProvider prov) {
    if (d.status == StatusPenarikan.pending) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFEF4444),
                backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.06),
                side: const BorderSide(color: Color(0xFFEF4444), width: 1.2),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50)),
              ),
              onPressed: () => _openTolak(d.penarikanId),
              child: const Text(
                'Tolak Pengajuan',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 13),
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
              child: const Text(
                'Setujui Pengajuan',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 13),
              ),
            ),
          ),
        ],
      );
    }

    // status == approved
    return _buildKonfirmasiButton(d, prov);
  }

  // ── Informasi Nasabah ────────────────────────────────────────────────────

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

  // ── Informasi Penarikan ──────────────────────────────────────────────────

  Widget _buildInfoSection(PenarikanDetail d) {
    return SectionCard(
      icon: Icons.receipt_long_rounded,
      title: 'Informasi Penarikan',
      children: [
        PenarikanInfoRow(label: 'Insentif', value: _capitalize(d.namaReward)),
        PenarikanInfoRow(label: 'ID Transaksi', value: d.penarikanId),
        PenarikanInfoRow(
          label: 'Nominal',
          value: _fmtNominal(d.nominalPenarikan, d.satuanPenarikan,
              isUang: d.isUang),
        ),
        PenarikanInfoRow(label: 'Status', value: d.status.label),
      ],
    );
  }

  // ── Detail Barang (sembako) ──────────────────────────────────────────────

  Widget _buildBarangCard(PenarikanDetail d) {
    final items = d.detailSembako;
    return SectionCard(
      icon: Icons.shopping_basket_rounded,
      title: 'Detail Barang',
      children: [
        for (int i = 0; i < items.length; i++) ...[
          if (i > 0) const Divider(height: 1, color: Color(0xFFF0F0F0)),
          DetailBarangRow(item: items[i]),
        ],
      ],
    );
  }

  // ── Estimasi Konfirmasi ──────────────────────────────────────────────────

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

  // ── Bukti Penyerahan Insentif ────────────────────────────────────────────

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
            ? const Row(
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
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 13),
                  ),
                ],
              )
            : const Text(
                'Konfirmasi Penyerahan Insentif',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 13),
              ),
      ),
    );
  }

  Widget _buildError(String? message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: Colors.redAccent, size: 48),
            const SizedBox(height: 12),
            Text(
              message ?? 'Detail tidak tersedia',
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50)),
              ),
              onPressed: () => context
                  .read<PenarikanPetugasProvider>()
                  .loadDetail(widget.penarikanId),
              child: const Text('Coba lagi',
                  style: TextStyle(fontFamily: 'Poppins')),
            ),
          ],
        ),
      ),
    );
  }
}
