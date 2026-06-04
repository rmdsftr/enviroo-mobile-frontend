import 'dart:convert';
import 'package:enviroo/widgets/success_bottom_sheet.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/penarikan_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/penarikan_petugas_provider.dart';
import '../../screens/admin_bsu/inapp_camera_screen.dart';
import '../../widgets/topbar_back.dart';

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

  String _fmtDate(DateTime? d) {
    if (d == null) return '-';
    return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(d);
  }

  String _fmtNum(double n) {
    final f = NumberFormat.decimalPattern('id_ID');
    f.maximumFractionDigits = 4;
    f.minimumFractionDigits = 0;
    return f.format(n);
  }

  String _nominalText(PenarikanDetail d) {
    final lower = d.satuanPenarikan.toLowerCase();
    if (lower.contains('rupiah') || d.namaReward.toLowerCase().contains('uang')) {
      return 'Rp ${_fmtNum(d.nominalPenarikan)}';
    }
    return '${_fmtNum(d.nominalPenarikan)} ${d.satuanPenarikan.isEmpty ? 'poin' : d.satuanPenarikan}';
  }

  Future<void> _handleKonfirmasi(String penarikanId) async {
    final File? photoFile = await Navigator.push<File?>(
      context,
      MaterialPageRoute(
        builder: (_) => const InAppCameraScreen(
          hint: 'Ambil foto nasabah sebagai bukti penarikan',
        ),
      ),
    );
    if (photoFile == null || !mounted) return;

    final bytes = await photoFile.readAsBytes();
    final base64str = base64Encode(bytes);

    if (!mounted) return;
    final success = await context
        .read<PenarikanPetugasProvider>()
        .konfirmasi(penarikanId: penarikanId, buktiFoto: base64str);

    if (!mounted) return;
    if (success) {
      _showSuccessDialog();
    } else {
      final errMsg = context.read<PenarikanPetugasProvider>().errorDetail;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
          content: Text(
            errMsg ?? 'Gagal mengkonfirmasi penarikan',
            style: const TextStyle(fontFamily: 'Poppins'),
          ),
        ),
      );
    }
  }

  Future<void> _showSuccessDialog() async {
    await showSuccessBottomSheet(
      context,
      title: 'Berhasil!',
      message: 'Penarikan berhasil dikonfirmasi.',
      onDismiss: () => Navigator.pop(context),
    );
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
        child: Consumer<PenarikanPetugasProvider>(
          builder: (_, prov, __) {
            return Stack(
              children: [
                Column(
                  children: [
                    const TopBarBack(title: 'Detail Penarikan'),
                    Expanded(
                      child: prov.loadingDetail
                          ? const Center(
                              child: CircularProgressIndicator(color: primary))
                          : prov.detail == null
                              ? _buildError(prov.errorDetail)
                              : _buildBody(prov.detail!),
                    ),
                  ],
                ),
                if (prov.detail?.status == StatusPenarikan.pending)
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 24,
                    child: _buildKonfirmasiButton(prov),
                  ),
              ],
            );
          },
        ),
      ),
      ),
    );
  }

  Widget _buildBody(PenarikanDetail d) {
    final isSembako = d.namaReward.toLowerCase().contains('sembako');
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
          20, 8, 20, d.status == StatusPenarikan.pending ? 100 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusCard(d),
          const SizedBox(height: 16),
          _buildInfoSection(d),
          if (isSembako && d.detailSembako.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildSembakoSection(d.detailSembako),
          ],
          if (d.buktiFoto != null && d.buktiFoto!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildBuktiFoto(d.buktiFoto!),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusCard(PenarikanDetail d) {
    final color = _statusColor(d.status);
    final label = _statusLabel(d.status);
    final icon = _statusIcon(d.status);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          width: 1,
          color: const Color(0xFF013236).withOpacity(0.1), // Brand color dengan opacity cuma 10%
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  d.namaNasabah?.isNotEmpty == true
                      ? d.namaNasabah!
                      : d.nasabahId ?? '-',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: dark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _nominalText(d),
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: Colors.black.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(PenarikanDetail d) {
    return _Section(
      title: 'Informasi Penarikan',
      children: [
        if (d.namaNasabah?.isNotEmpty == true)
          _InfoRow(label: 'Nasabah', value: d.namaNasabah!),
        if (d.nasabahId?.isNotEmpty == true)
          _InfoRow(label: 'ID Nasabah', value: d.nasabahId!),
        _InfoRow(
          label: 'Jenis Reward',
          value: d.namaReward.isEmpty
              ? '-'
              : '${d.namaReward[0].toUpperCase()}${d.namaReward.substring(1).toLowerCase()}',
        ),
        _InfoRow(label: 'Nominal', value: _nominalText(d)),
        _InfoRow(label: 'Diajukan', value: _fmtDate(d.createdAt)),
        if (d.status != StatusPenarikan.pending)
          _InfoRow(label: 'Diperbarui', value: _fmtDate(d.updatedAt)),
      ],
    );
  }

  Widget _buildSembakoSection(List<DetailSembakoItem> items) {
    return _Section(
      title: 'Detail Sembako',
      children: items.map((item) {
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 5),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FAF4),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 38,
                  height: 38,
                  child: (item.photoUrl == null || item.photoUrl!.isEmpty)
                      ? Container(
                          color: primary.withValues(alpha: 0.15),
                          child: const Icon(Icons.shopping_basket_rounded,
                              color: primary, size: 18),
                        )
                      : Image.network(
                          item.photoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: primary.withValues(alpha: 0.15),
                            child: const Icon(Icons.shopping_basket_rounded,
                                color: primary, size: 18),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.namaSembako.isEmpty ? '-' : item.namaSembako,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: dark,
                  ),
                ),
              ),
              Text(
                'x${_fmtNum(item.qty)}',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: Colors.black.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${_fmtNum(item.subtotalPoin)} pts',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: dark,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBuktiFoto(String buktiFoto) {
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

    return _Section(
      title: 'Bukti Foto',
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

  Widget _buildKonfirmasiButton(PenarikanPetugasProvider prov) {
    return SafeArea(
      top: false,
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: dark,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50)),
          ),
          onPressed: prov.submitting
              ? null
              : () => _handleKonfirmasi(widget.penarikanId),
          icon: prov.submitting
              ? const SizedBox(
                  width: 15,
                  height: 15,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5),
                )
              : const Icon(Icons.camera_alt_rounded, size: 17),
          label: Text(
            prov.submitting ? 'Memproses...' : 'Konfirmasi Penarikan',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
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

  Color _statusColor(StatusPenarikan s) {
    switch (s) {
      case StatusPenarikan.pending:
        return const Color(0xFFF59E0B);
      case StatusPenarikan.berhasil:
        return const Color(0xFF4EA771);
      case StatusPenarikan.dibatalkan:
        return const Color(0xFFEF4444);
      case StatusPenarikan.kadaluarsa:
        return const Color(0xFF9CA3AF);
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(StatusPenarikan s) {
    switch (s) {
      case StatusPenarikan.pending:
        return 'Menunggu';
      case StatusPenarikan.berhasil:
        return 'Berhasil';
      case StatusPenarikan.dibatalkan:
        return 'Dibatalkan';
      case StatusPenarikan.kadaluarsa:
        return 'Kadaluarsa';
      default:
        return 'Unknown';
    }
  }

  IconData _statusIcon(StatusPenarikan s) {
    switch (s) {
      case StatusPenarikan.pending:
        return Icons.access_time_rounded;
      case StatusPenarikan.berhasil:
        return Icons.check_circle_rounded;
      case StatusPenarikan.dibatalkan:
        return Icons.cancel_rounded;
      case StatusPenarikan.kadaluarsa:
        return Icons.timer_off_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }
}

// ── Reusable widgets ──────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          width: 1,
          color: const Color(0xFF013236).withOpacity(0.1), // Brand color dengan opacity cuma 10%
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.black.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: Colors.black.withValues(alpha: 0.5),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF013236),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
