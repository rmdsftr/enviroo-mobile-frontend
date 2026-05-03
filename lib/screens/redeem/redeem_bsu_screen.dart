import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/redeem_models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/redeem_bsu_provider.dart';
import '../../widgets/redeem_card.dart';
import '../../widgets/topbar_back.dart';
import 'input_request_redeem_screen.dart';
import 'qr_code_redeem_screen.dart';

class RedeemBsuScreen extends StatefulWidget {
  const RedeemBsuScreen({super.key});

  @override
  State<RedeemBsuScreen> createState() => _RedeemBsuScreenState();
}

class _RedeemBsuScreenState extends State<RedeemBsuScreen> {
  static const Color primary = Color(0xFF4EA771);
  static const Color dark = Color(0xFF013236);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final prov = context.read<RedeemBsuProvider>();
      prov.bind(auth);
      prov.loadList();
    });
  }

  Future<void> _openForm() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const InputRequestRedeemScreen()),
    );
    if (result == true && mounted) {
      context.read<RedeemBsuProvider>().loadList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const TopBarBack(title: 'Redeem Saldo BSU'),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _openForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: const Text(
                    'Ajukan Redeem Saldo Bank',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(child: _buildList()),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    return Consumer<RedeemBsuProvider>(
      builder: (context, prov, _) {
        if (prov.loadingList && prov.list.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: primary));
        }
        if (prov.error != null && prov.list.isEmpty) {
          return _buildError(prov.error!);
        }
        if (prov.list.isEmpty) {
          return _buildEmpty();
        }
        return RefreshIndicator(
          color: primary,
          onRefresh: prov.loadList,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
            itemCount: prov.list.length,
            itemBuilder: (context, i) {
              final item = prov.list[i];
              Widget? trailing;
              if (item.status == RedeemStatus.approved) {
                trailing = _qrButton(item);
              }
              return RedeemCard(
                data: item,
                trailing: trailing,
                onTap: () => _onTapCard(item),
              );
            },
          ),
        );
      },
    );
  }

  Widget _qrButton(RedeemTransaksi item) {
    return ElevatedButton.icon(
      onPressed: () => _openQr(item.transaksiId),
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        elevation: 0,
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      icon: const Icon(Icons.qr_code_2_rounded, size: 16),
      label: const Text(
        'Tampilkan QR',
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _openQr(String transaksiId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QrCodeRedeemScreen(transaksiId: transaksiId),
      ),
    );
  }

  void _onTapCard(RedeemTransaksi item) {
    if (item.status == RedeemStatus.waiting) {
      _showWaitingDetail(item);
    } else if (item.status == RedeemStatus.approved) {
      _openQr(item.transaksiId);
    } else {
      _showReadOnlyDetail(item);
    }
  }

  void _showWaitingDetail(RedeemTransaksi item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WaitingDetailSheet(
        item: item,
        onCancel: () async {
          Navigator.pop(context);
          final ok = await context
              .read<RedeemBsuProvider>()
              .cancelRedeem(item.transaksiId);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              content: Text(ok
                  ? 'Pengajuan berhasil dibatalkan'
                  : 'Gagal membatalkan pengajuan'),
              backgroundColor: ok ? primary : Colors.red,
            ),
          );
        },
      ),
    );
  }

  void _showReadOnlyDetail(RedeemTransaksi item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReadOnlySheet(item: item),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_rounded, size: 56, color: dark.withOpacity(0.25)),
          const SizedBox(height: 12),
          Text(
            'Belum ada pengajuan redeem',
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
              onPressed: () => context.read<RedeemBsuProvider>().loadList(),
              child: const Text('Coba lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

class _WaitingDetailSheet extends StatelessWidget {
  final RedeemTransaksi item;
  final VoidCallback onCancel;
  const _WaitingDetailSheet({required this.item, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return _DetailSheet(
      item: item,
      footer: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50)),
            ),
            onPressed: onCancel,
            icon: const Icon(Icons.cancel_outlined, size: 18),
            label: const Text(
              'Batalkan Pengajuan',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReadOnlySheet extends StatelessWidget {
  final RedeemTransaksi item;
  const _ReadOnlySheet({required this.item});

  @override
  Widget build(BuildContext context) {
    return _DetailSheet(item: item);
  }
}

class _DetailSheet extends StatelessWidget {
  final RedeemTransaksi item;
  final Widget? footer;
  const _DetailSheet({required this.item, this.footer});

  String _formatNumber(num n) {
    final format = NumberFormat.decimalPattern('id_ID');
    format.maximumFractionDigits = 4;
    format.minimumFractionDigits = 0;
    return format.format(n);
  }

  @override
  Widget build(BuildContext context) {
    final style = RedeemStatusStyle.of(item.status);
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 12),
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.15),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
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
                        'Pengajuan Redeem',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: Colors.black.withOpacity(0.6),
                        ),
                      ),
                      Text(
                        item.transaksiId,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF013236),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _row('Reward',
                    item.reward?.namaReward.toUpperCase() ?? '-'),
                _row('Poin', _formatNumber(item.poin)),
                if (!item.isSembako)
                  _row('Nominal', item.isEmas ? '${_formatNumber(item.nominal)} gram' : 'Rp ${_formatNumber(item.nominal)}'),
                if (item.catatan != null && item.catatan!.isNotEmpty)
                  _row('Catatan', item.catatan!),
              ],
            ),
          ),
          if (item.isSembako && item.details.isNotEmpty) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Detail Sembako',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black.withOpacity(0.7),
                  ),
                ),
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: item.details.length,
                itemBuilder: (_, i) {
                  final d = item.details[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6FBF6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            d.namaSembako ?? d.sembakoId,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          'x${_formatNumber(d.qty)}',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF4EA771),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${_formatNumber(d.subtotalPoin)} pts',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: Color(0xFF013236),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (footer != null) footer!,
          const SizedBox(height: 8),
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
            width: 90,
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
                color: Color(0xFF013236),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
