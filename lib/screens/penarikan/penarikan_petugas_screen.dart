import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/redeem_models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/penarikan_petugas_provider.dart';
import '../../widgets/redeem_card.dart';
import '../../widgets/topbar_back.dart';
import 'detail_konfirmasi_penarikan_screen.dart';
import 'scan_penarikan_screen.dart';

class PenarikanPetugasScreen extends StatefulWidget {
  const PenarikanPetugasScreen({super.key});

  @override
  State<PenarikanPetugasScreen> createState() =>
      _PenarikanPetugasScreenState();
}

class _PenarikanPetugasScreenState extends State<PenarikanPetugasScreen> {
  static const Color primary = Color(0xFF4EA771);
  static const Color dark = Color(0xFF013236);

  String _filter = 'waiting'; // waiting | approved | history

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final prov = context.read<PenarikanPetugasProvider>();
      prov.bind(auth);
      prov.loadList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const TopBarBack(title: 'Penarikan Nasabah'),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: dark.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Row(
                  children: [
                    _segment('waiting', 'Menunggu'),
                    _segment('approved', 'Disetujui'),
                    _segment('history', 'Riwayat'),
                  ],
                ),
              ),
            ),
            Expanded(child: _buildList()),
          ],
        ),
      ),
    );
  }

  Widget _segment(String value, String label) {
    final selected = _filter == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _filter = value);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? dark : Colors.transparent,
            borderRadius: BorderRadius.circular(40),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : dark.withOpacity(0.75),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildList() {
    return Consumer<PenarikanPetugasProvider>(
      builder: (context, prov, _) {
        if (prov.loadingList && prov.list.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: primary));
        }
        if (prov.error != null && prov.list.isEmpty) {
          return _buildError(prov.error!);
        }
        final filtered = _filter == 'waiting'
            ? prov.waitingList
            : _filter == 'approved'
                ? prov.approvedList
                : prov.historyList;
        if (filtered.isEmpty) {
          return _buildEmpty();
        }
        return RefreshIndicator(
          color: primary,
          onRefresh: prov.loadList,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
            itemCount: filtered.length,
            itemBuilder: (context, i) {
              final item = filtered[i];
              return RedeemCard(
                data: item,
                hideId: _filter != 'history',
                showNasabah: true,
                onTap: () => _onTapCard(item),
                trailing: item.status == RedeemStatus.waiting
                    ? const Text(
                        'Tap untuk respon',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: Color(0xFF4EA771),
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    : item.status == RedeemStatus.approved
                        ? const Text(
                            'Tap untuk scan',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              color: Color(0xFF1F6F3A),
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        : null,
              );
            },
          ),
        );
      },
    );
  }

  void _onTapCard(RedeemTransaksi item) {
    if (item.status == RedeemStatus.waiting) {
      _showWaitingActions(item);
    } else if (item.status == RedeemStatus.approved) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ScanPenarikanScreen()),
      ).then((_) => context.read<PenarikanPetugasProvider>().loadList());
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              DetailKonfirmasiPenarikanScreen(transaksiId: item.transaksiId),
        ),
      ).then((_) => context.read<PenarikanPetugasProvider>().loadList());
    }
  }

  void _showWaitingActions(RedeemTransaksi item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WaitingActionSheet(item: item),
    ).then((_) => context.read<PenarikanPetugasProvider>().loadList());
  }

  Widget _buildEmpty() {
    final label = _filter == 'waiting'
        ? 'Belum ada pengajuan menunggu'
        : _filter == 'approved'
            ? 'Belum ada pengajuan disetujui'
            : 'Belum ada riwayat';
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_rounded, size: 56, color: dark.withOpacity(0.25)),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: dark.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String message) {
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
              message,
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
              onPressed: () =>
                  context.read<PenarikanPetugasProvider>().loadList(),
              child: const Text('Coba lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

class _WaitingActionSheet extends StatefulWidget {
  final RedeemTransaksi item;
  const _WaitingActionSheet({required this.item});

  @override
  State<_WaitingActionSheet> createState() => _WaitingActionSheetState();
}

class _WaitingActionSheetState extends State<_WaitingActionSheet> {
  static const Color primary = Color(0xFF4EA771);
  static const Color dark = Color(0xFF013236);

  bool _busy = false;

  String _formatNumber(num n) {
    final format = NumberFormat.decimalPattern('id_ID');
    format.maximumFractionDigits = 4;
    format.minimumFractionDigits = 0;
    return format.format(n);
  }

  Future<void> _act(String status, {String? catatan}) async {
    setState(() => _busy = true);
    final prov = context.read<PenarikanPetugasProvider>();
    final ok = await prov.confirm(
      transaksiId: widget.item.transaksiId,
      statusTransaksi: status,
      catatan: catatan,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: ok ? primary : Colors.red,
        content: Text(ok
            ? (status == 'approved'
                ? 'Pengajuan disetujui'
                : 'Pengajuan ditolak')
            : (prov.error ?? 'Gagal memproses')),
      ),
    );
  }

  Future<String?> _askCatatan({required String title}) async {
    final ctrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title,
            style: const TextStyle(
                fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Catatan (opsional)',
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            child: const Text('Kirim'),
          ),
        ],
      ),
    );
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 14),
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.15),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pengajuan Penarikan',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: Colors.black.withOpacity(0.55),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '***',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: dark,
                  ),
                ),
                const SizedBox(height: 14),
                _row('Reward',
                    item.reward?.namaReward.toUpperCase() ?? '-'),
                _row('Nasabah', item.nasabahName ?? '-'),
                _row('Poin', item.poin.toStringAsFixed(0)),
                if (!item.isSembako)
                  _row('Nominal', item.isEmas ? '${_formatNumber(item.nominal)} gram' : 'Rp ${_formatNumber(item.nominal)}'),
                if (item.isSembako)
                  _row('Item', '${item.details.length} item sembako'),
                const SizedBox(height: 18),
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
                        onPressed: _busy
                            ? null
                            : () async {
                                final note =
                                    await _askCatatan(title: 'Tolak Pengajuan');
                                if (note == null) return;
                                _act('rejected',
                                    catatan: note.isEmpty ? null : note);
                              },
                        icon: const Icon(Icons.close_rounded, size: 18),
                        label: const Text(
                          'Tolak',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                          ),
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
                        onPressed: _busy ? null : () => _act('approved'),
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: _busy
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                'Setujui',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
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
}
