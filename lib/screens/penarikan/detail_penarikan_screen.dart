import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/penarikan_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/penarikan_nasabah_provider.dart';
import '../../widgets/topbar_back.dart';

class DetailPenarikanScreen extends StatefulWidget {
  final String penarikanId;

  const DetailPenarikanScreen({super.key, required this.penarikanId});

  @override
  State<DetailPenarikanScreen> createState() =>
      _DetailPenarikanScreenState();
}

class _DetailPenarikanScreenState extends State<DetailPenarikanScreen> {
  static const Color primary = Color(0xFF4EA771);
  static const Color dark = Color(0xFF013236);

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

  // ── Formatters ────────────────────────────────────────────────────────────

  String _fmtDate(DateTime? d) {
    if (d == null) return '-';
    return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(d);
  }

  String _fmtNominal(double v, String satuan) {
    final f = NumberFormat.decimalPattern('id_ID');
    f.maximumFractionDigits = 4;
    f.minimumFractionDigits = 0;
    final lower = satuan.toLowerCase();
    if (lower.contains('rupiah') || lower.contains('uang')) {
      return 'Rp ${f.format(v)}';
    }
    return '${f.format(v)} ${satuan.isEmpty ? 'poin' : satuan}';
  }

  // ── Status styling ────────────────────────────────────────────────────────

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
        return 'Menunggu Konfirmasi';
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
        return Icons.hourglass_empty_rounded;
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

  // ── Batal ─────────────────────────────────────────────────────────────────

  Future<void> _confirmBatal(PenarikanNasabahProvider prov) async {
    final confirm = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cancel_outlined,
                  color: Color(0xFFEF4444), size: 32),
            ),
            const SizedBox(height: 16),
            const Text(
              'Batalkan Pengajuan?',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: dark,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Pengajuan penarikan akan dibatalkan dan saldo akan dikembalikan ke rekeningmu.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black54,
                      side: const BorderSide(color: Colors.black12),
                      padding: const EdgeInsets.symmetric(vertical: 14),
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
                      backgroundColor: const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50)),
                    ),
                    onPressed: () => Navigator.pop(ctx, true),
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
      ),
    );

    if (confirm != true || !mounted) return;

    final ok = await prov.callBatal(widget.penarikanId);
    if (!mounted) return;

    if (ok) {
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            'Pengajuan penarikan dibatalkan. Saldo sudah dikembalikan ke rekeningmu',
            style: TextStyle(fontFamily: 'Poppins'),
          ),
          backgroundColor: primary,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            'Gagal membatalkan pengajuan',
            style: TextStyle(fontFamily: 'Poppins'),
          ),
          backgroundColor: Colors.red,
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
          child: Consumer<PenarikanNasabahProvider>(
            builder: (_, prov, __) {
              return Column(
                children: [
                  const TopBarBack(title: 'Detail Penarikan'),
                  Expanded(
                    child: prov.loadingDetail
                        ? const Center(
                            child: CircularProgressIndicator(
                                color: primary))
                        : prov.errorDetail != null
                            ? _buildError(prov)
                            : prov.detail == null
                                ? _buildEmpty()
                                : _buildDetail(prov.detail!, prov),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildError(PenarikanNasabahProvider prov) {
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
              prov.errorDetail ?? 'Terjadi kesalahan',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontFamily: 'Poppins', fontSize: 13),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50)),
              ),
              onPressed: () => prov.loadDetail(widget.penarikanId),
              child: const Text('Coba lagi',
                  style: TextStyle(fontFamily: 'Poppins')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Text(
        'Detail tidak ditemukan',
        style: TextStyle(fontFamily: 'Poppins', fontSize: 14),
      ),
    );
  }

  Widget _buildDetail(
      PenarikanDetail detail, PenarikanNasabahProvider prov) {
    final isPending = detail.status == StatusPenarikan.pending;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusCard(detail),
          const SizedBox(height: 16),
          _buildInfoSection(detail),
          const SizedBox(height: 16),
          _buildTimeline(detail),
          if (detail.isSembako && detail.detailSembako.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildSembakoDetail(detail),
          ],
          if (isPending) ...[
            const SizedBox(height: 24),
            _buildBatalCard(prov),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusCard(PenarikanDetail detail) {
    final color = _statusColor(detail.status);
    final label = _statusLabel(detail.status);
    final icon = _statusIcon(detail.status);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Baris 1: icon (kiri) + badge (kanan)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
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
          const SizedBox(height: 14),
          // Baris 2: judul
          Text(
            'Penarikan ${_capitalize(detail.namaReward)}',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: dark,
            ),
          ),
          const SizedBox(height: 4),
          // Baris 3: ID transaksi
          Text(
            detail.penarikanId,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              color: Colors.black.withValues(alpha: 0.38),
            ),
          ),
          if (detail.status == StatusPenarikan.berhasil) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_rounded, size: 16, color: primary),
                  SizedBox(width: 8),
                  Text(
                    'Penarikan telah berhasil diproses',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (detail.status == StatusPenarikan.kadaluarsa) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.timer_off_rounded, size: 16, color: Colors.grey),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pengajuan kadaluarsa karena tidak dikonfirmasi dalam 2 jam. Saldo sudah dikembalikan.',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoSection(PenarikanDetail detail) {
    final f = NumberFormat.decimalPattern('id_ID');
    f.maximumFractionDigits = 4;
    f.minimumFractionDigits = 0;

    return _SectionCard(
      title: 'Informasi Penarikan',
      children: [
        _InfoRow(
            label: 'ID Transaksi',
            value: detail.penarikanId),
        _InfoRow(
            label: 'Jenis Reward',
            value: _capitalize(detail.namaReward)),
        if (!detail.isSembako)
          _InfoRow(
            label: 'Nominal',
            value: _fmtNominal(
                detail.nominalPenarikan, detail.satuanPenarikan),
          ),
        if (detail.isSembako)
          _InfoRow(
            label: 'Total Poin',
            value: '${f.format(detail.nominalPenarikan)} poin',
          ),
        _InfoRow(
            label: 'Tanggal Pengajuan',
            value: _fmtDate(detail.createdAt)),
        if (detail.status == StatusPenarikan.pending && detail.kadaluarsaAt != null)
          _InfoRow(
            label: 'Batas Konfirmasi',
            value: _fmtDate(detail.kadaluarsaAt),
          ),
        if (detail.status != StatusPenarikan.pending)
          _InfoRow(
            label: 'Update Terakhir',
            value: _fmtDate(detail.updatedAt)),
      ],
    );
  }

  Widget _buildTimeline(PenarikanDetail detail) {
    final steps = _buildTimelineSteps(detail);

    return _SectionCard(
      title: 'Progres Transaksi',
      children: List.generate(steps.length, (i) {
        final step = steps[i];
        final isLast = i == steps.length - 1;
        return _TimelineItem(
          label: step['label'] as String,
          sub: step['sub'] as String?,
          isDone: step['done'] as bool,
          isCurrent: step['current'] as bool,
          isError: step['error'] as bool? ?? false,
          showLine: !isLast,
        );
      }),
    );
  }

  List<Map<String, dynamic>> _buildTimelineSteps(
      PenarikanDetail detail) {
    final status = detail.status;
    final isDone = status == StatusPenarikan.berhasil;
    final isCanceled = status == StatusPenarikan.dibatalkan;
    final isExpired = status == StatusPenarikan.kadaluarsa;
    final isPending = status == StatusPenarikan.pending;

    return [
      {
        'label': 'Pengajuan Dibuat',
        'sub': _fmtDate(detail.createdAt),
        'done': true,
        'current': false,
        'error': false,
      },
      {
        'label': 'Menunggu Konfirmasi Petugas',
        'sub': isPending ? 'Sedang menunggu...' : null,
        'done': isDone || isCanceled || isExpired,
        'current': isPending,
        'error': false,
      },
      {
        'label': isCanceled
            ? 'Pengajuan Dibatalkan'
            : isExpired
                ? 'Kadaluarsa'
                : 'Diproses',
        'sub': isCanceled
            ? _fmtDate(detail.updatedAt)
            : isExpired
                ? 'Tidak dikonfirmasi dalam 2 jam'
                : isDone
                    ? _fmtDate(detail.updatedAt)
                    : null,
        'done': isDone || isCanceled || isExpired,
        'current': false,
        'error': isCanceled || isExpired,
      },
      if (isDone || (!isCanceled && !isExpired))
        {
          'label': 'Selesai',
          'sub': isDone ? _fmtDate(detail.updatedAt) : null,
          'done': isDone,
          'current': false,
          'error': false,
        },
    ];
  }

  Widget _buildSembakoDetail(PenarikanDetail detail) {
    final f = NumberFormat.decimalPattern('id_ID');
    f.maximumFractionDigits = 2;
    f.minimumFractionDigits = 0;

    return _SectionCard(
      title: 'Detail Sembako',
      children: detail.detailSembako.map((d) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FAF3),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              const Icon(Icons.shopping_basket_rounded,
                  size: 18, color: primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d.namaSembako,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: dark,
                      ),
                    ),
                    Text(
                      '${f.format(d.nilaiPoin)} poin/item',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: Colors.black.withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'x${f.format(d.qty)}',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: Colors.black.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${f.format(d.subtotalPoin)} poin',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: primary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
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
            color: const Color(0xFF013236).withOpacity(0.1), // Brand color dengan opacity cuma 10%
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
                const Expanded(
                  child: Text(
                    'Ingin membatalkan pengajuan?',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF013236),
                    ),
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
                    foregroundColor: const Color(0xFFEF4444),
                    side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
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
                              color: Color(0xFFEF4444), strokeWidth: 2.5),
                        )
                      : const Icon(Icons.cancel_outlined, size: 15),
                  label: const Text(
                    'Batalkan Pengajuan',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1).toLowerCase()}';
}

// ── Section Card ──────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF013236),
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

// ── Info Row ──────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                color: Colors.black.withValues(alpha: 0.5),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
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

// ── Timeline Item ─────────────────────────────────────────────────────────────

class _TimelineItem extends StatelessWidget {
  final String label;
  final String? sub;
  final bool isDone;
  final bool isCurrent;
  final bool isError;
  final bool showLine;

  const _TimelineItem({
    required this.label,
    this.sub,
    required this.isDone,
    required this.isCurrent,
    this.isError = false,
    required this.showLine,
  });

  @override
  Widget build(BuildContext context) {
    final color = isError
        ? const Color(0xFFEF4444)
        : isDone
            ? const Color(0xFF4EA771)
            : isCurrent
                ? const Color(0xFFF59E0B)
                : const Color(0xFFD1D5DB);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isError
                      ? Icons.close_rounded
                      : isDone
                          ? Icons.check_rounded
                          : isCurrent
                              ? Icons.more_horiz_rounded
                              : Icons.circle,
                  color: Colors.white,
                  size: isError || isDone ? 14 : 8,
                ),
              ),
              if (showLine)
                Expanded(
                  child: Container(
                    width: 2,
                    color: color.withValues(alpha: 0.3),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      fontWeight: isCurrent
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: isDone || isCurrent
                          ? const Color(0xFF013236)
                          : Colors.grey,
                    ),
                  ),
                  if (sub != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      sub!,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        color: Colors.black.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
