import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/redeem_models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/penarikan_petugas_provider.dart';
import '../../widgets/redeem_card.dart';
import '../../widgets/topbar_back.dart';

class DetailKonfirmasiPenarikanScreen extends StatefulWidget {
  final String transaksiId;
  const DetailKonfirmasiPenarikanScreen(
      {super.key, required this.transaksiId});

  @override
  State<DetailKonfirmasiPenarikanScreen> createState() =>
      _DetailKonfirmasiPenarikanScreenState();
}

class _DetailKonfirmasiPenarikanScreenState
    extends State<DetailKonfirmasiPenarikanScreen> {
  static const Color primary = Color(0xFF4EA771);
  static const Color dark = Color(0xFF013236);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final prov = context.read<PenarikanPetugasProvider>();
      prov.bind(auth);
      prov.loadDetail(widget.transaksiId);
    });
  }

  String _formatNumber(num n) {
    final f = NumberFormat.decimalPattern('id_ID');
    f.maximumFractionDigits = 4;
    f.minimumFractionDigits = 0;
    return f.format(n);
  }

  String _formatDate(DateTime? d) {
    if (d == null) return '-';
    return DateFormat('dd MMM yyyy • HH:mm', 'id_ID').format(d.toLocal());
  }

  Future<void> _confirmAction({
    required String status,
    required String title,
    required String confirmLabel,
    required Color color,
    required String bodyText,
  }) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          style: const TextStyle(
              fontFamily: 'Poppins', fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              bodyText,
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Catatan (opsional)',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: color, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );

    if (ok != true || !mounted) return;

    final prov = context.read<PenarikanPetugasProvider>();
    final success = await prov.confirm(
      transaksiId: widget.transaksiId,
      statusTransaksi: status,
      catatan: ctrl.text.trim().isEmpty ? null : ctrl.text.trim(),
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: success ? primary : Colors.red,
        content: Text(success
            ? (status == 'success'
                ? 'Penarikan berhasil dikonfirmasi'
                : status == 'approved'
                    ? 'Pengajuan disetujui'
                    : 'Pengajuan ditolak')
            : (prov.error ?? 'Gagal memproses')),
      ),
    );
    if (success) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Consumer<PenarikanPetugasProvider>(
          builder: (context, prov, _) {
            return Stack(
              children: [
                Column(
                  children: [
                    const TopBarBack(title: 'Konfirmasi Penarikan'),
                    Expanded(
                      child: prov.loadingDetail
                          ? const Center(
                              child: CircularProgressIndicator(color: primary),
                            )
                          : prov.detail == null
                              ? _buildError(prov.error)
                              : _buildDetail(prov.detail!),
                    ),
                  ],
                ),
                if (prov.detail != null)
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 24,
                    child: _buildActions(prov.detail!, prov.submitting),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildError(String? error) {
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
              error ?? 'Detail tidak tersedia',
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50)),
              ),
              onPressed: () => context
                  .read<PenarikanPetugasProvider>()
                  .loadDetail(widget.transaksiId),
              child: const Text('Coba lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetail(RedeemTransaksi item) {
    final style = RedeemStatusStyle.of(item.status);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: style.cardBg,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: style.border.withOpacity(0.4)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: style.border.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(style.icon, color: style.fg, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ID Transaksi',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: Colors.black.withOpacity(0.55),
                        ),
                      ),
                      Text(
                        item.transaksiId,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: dark,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: style.bg,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Text(
                    style.label,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: style.fg,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _section('Informasi Transaksi', [
            if (item.nasabahName?.isNotEmpty == true)
              _row('Nasabah', item.nasabahName!),
            if (item.nasabahId?.isNotEmpty == true)
              _row('ID Nasabah', item.nasabahId!),
            _row('Reward', item.reward?.namaReward.toUpperCase() ?? '-'),
            _row('Poin', '${_formatNumber(item.poin)} pts'),
            if (!item.isSembako)
              _row(
                'Nominal',
                item.isEmas
                    ? '${_formatNumber(item.nominal)} gram'
                    : 'Rp ${_formatNumber(item.nominal)}',
              ),
            _row('Diajukan', _formatDate(item.createdAt)),
            if (item.namaPetugas?.isNotEmpty == true)
              _row('Petugas', item.namaPetugas!),
            if (item.catatan != null && item.catatan!.isNotEmpty)
              _row('Catatan', item.catatan!),
          ]),
          if (item.isSembako && item.details.isNotEmpty) ...[
            const SizedBox(height: 16),
            _section('Detail Sembako',
                item.details.map(_buildSembakoDetail).toList()),
          ],
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              title,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.black.withOpacity(0.7),
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
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
                color: Colors.black.withOpacity(0.55),
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
                color: dark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSembakoDetail(RedeemSembakoDetail d) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF6FBF6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 38,
              height: 38,
              child: (d.photoUrl == null || d.photoUrl!.isEmpty)
                  ? Container(
                      color: primary.withOpacity(0.18),
                      child: const Icon(Icons.shopping_basket_rounded,
                          color: primary, size: 18),
                    )
                  : Image.network(
                      d.photoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: primary.withOpacity(0.18),
                        child: const Icon(Icons.shopping_basket_rounded,
                            color: primary, size: 18),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              d.namaSembako ?? d.sembakoId,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: dark,
              ),
            ),
          ),
          Text(
            'x${_formatNumber(d.qty)}',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: primary,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${_formatNumber(d.subtotalPoin)} pts',
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
  }

  Widget _buildActions(RedeemTransaksi item, bool busy) {
    final isApproved = item.status == RedeemStatus.approved;
    final isWaiting = item.status == RedeemStatus.waiting;
    final canAct = isApproved || isWaiting;

    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!canAct)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBF1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: const Color(0xFFFAA324).withOpacity(0.4)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      color: Color(0xFFB07906), size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Transaksi ini sudah final dan tidak bisa diproses lagi.',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 12),
                    ),
                  ),
                ],
              ),
            )
          else if (isWaiting)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50)),
                    ),
                    onPressed: busy
                        ? null
                        : () => _confirmAction(
                              status: 'rejected',
                              title: 'Tolak Penarikan',
                              confirmLabel: 'Tolak',
                              color: Colors.red,
                              bodyText: 'Yakin ingin menolak pengajuan ini?',
                            ),
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: const Text(
                      'Tolak',
                      style: TextStyle(
                          fontFamily: 'Poppins', fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50)),
                    ),
                    onPressed: busy
                        ? null
                        : () => _confirmAction(
                              status: 'approved',
                              title: 'Setujui Penarikan',
                              confirmLabel: 'Setujui',
                              color: primary,
                              bodyText:
                                  'Nasabah akan dapat menampilkan QR setelah disetujui.',
                            ),
                    icon: busy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5),
                          )
                        : const Icon(Icons.check_rounded, size: 18),
                    label: const Text(
                      'Setujui',
                      style: TextStyle(
                          fontFamily: 'Poppins', fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50)),
                ),
                onPressed: busy
                    ? null
                    : () => _confirmAction(
                          status: 'success',
                          title: 'Konfirmasi Penyerahan',
                          confirmLabel: 'Konfirmasi',
                          color: primary,
                          bodyText:
                              'Pastikan reward sudah diserahkan ke nasabah. Saldo poin nasabah akan dipotong. Lanjutkan?',
                        ),
                icon: busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Icon(Icons.handshake_rounded, size: 20),
                label: const Text(
                  'Konfirmasi Penyerahan',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
