import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/penarikan_model.dart';
import '../../providers/penarikan_nasabah_provider.dart';
import '../../widgets/navbar.dart';
import '../../widgets/topbar_back.dart';
import 'detail_penarikan_screen.dart';

class PenarikanOngoingScreen extends StatefulWidget {
  const PenarikanOngoingScreen({super.key});

  @override
  State<PenarikanOngoingScreen> createState() =>
      _PenarikanOngoingScreenState();
}

class _PenarikanOngoingScreenState extends State<PenarikanOngoingScreen> {
  static const Color primary = Color(0xFF4EA771);
  static const Color dark = Color(0xFF013236);

  // 0 = Pengajuan (pending), 1 = Siap Dijemput (approved)
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prov = context.read<PenarikanNasabahProvider>();
      if (prov.penarikanList.isEmpty) {
        prov.loadList(refresh: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bg_struk2.webp'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Consumer<PenarikanNasabahProvider>(
            builder: (_, prov, __) {
              final targetStatus = _tabIndex == 0
                  ? StatusPenarikan.pending
                  : StatusPenarikan.approved;
              final visibleList = prov.penarikanList
                  .where((i) => i.status == targetStatus)
                  .toList();

              final tabDescription = _tabIndex == 0
                  ? 'Transaksi pengajuan penarikan yang sedang menunggu konfirmasi dari petugas bank sampah'
                  : 'Pengajuan penarikan yang telah disetujui petugas dan sudah bisa kamu jemput ke bank sampah';

              return Column(
                children: [
                  const TopBarBack(title: 'Penarikan masih dalam proses'),
                  const SizedBox(height: 12),
                  MainNavbar(
                    selectedIndex: _tabIndex,
                    tabs: const ['Pengajuan', 'Siap Dijemput'],
                    backgroundColor: Colors.white.withValues(alpha: 0.6),
                    border: Border.all(
                      color: const Color(0xFF013236).withValues(alpha: 0.1),
                      width: 1,
                    ),
                    onTabChanged: (i) => setState(() => _tabIndex = i),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(28, 12, 28, 4),
                    child: Text(
                      tabDescription,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12.5,
                        height: 1.6,
                        color: dark.withValues(alpha: 0.65),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                      ),
                      padding: const EdgeInsets.only(top: 17),
                      child: RefreshIndicator(
                        color: primary,
                        onRefresh: () => prov.loadList(refresh: true),
                        child: prov.loadingList && prov.penarikanList.isEmpty
                            ? ListView(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                children: List.generate(
                                  4,
                                  (_) => const _ShimmerCard(),
                                ),
                              )
                            : prov.errorList != null && prov.penarikanList.isEmpty
                                ? _ErrorState(
                                    message: prov.errorList!,
                                    onRetry: () => prov.loadList(refresh: true),
                                  )
                                : visibleList.isEmpty
                                    ? ListView(
                                        physics: const AlwaysScrollableScrollPhysics(),
                                        children: const [_EmptyState()],
                                      )
                                    : ListView.builder(
                                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                                        itemCount: visibleList.length,
                                        itemBuilder: (ctx, i) {
                                          final item = visibleList[i];
                                          return _OngoingPenarikanCard(
                                            item: item,
                                            onTap: () => Navigator.push(
                                              ctx,
                                              MaterialPageRoute(
                                                builder: (_) => DetailPenarikanScreen(
                                                  penarikanId: item.penarikanId,
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// ── Card ──────────────────────────────────────────────────────────────────────

class _OngoingPenarikanCard extends StatelessWidget {
  final PenarikanItem item;
  final VoidCallback onTap;

  const _OngoingPenarikanCard({required this.item, required this.onTap});

  static const Color dark = Color(0xFF013236);

  Color get _statusColor => item.status.color;

  String get _statusLabel => item.status.label;

  String get _nominalText {
    final f = NumberFormat.decimalPattern('id_ID');
    f.maximumFractionDigits = 4;
    f.minimumFractionDigits = 0;
    final lower = item.satuanPenarikan.toLowerCase();
    if (lower.contains('rupiah') || item.isUang) {
      return 'Rp ${f.format(item.nominalPenarikan)}';
    }
    return '${f.format(item.nominalPenarikan)} ${item.satuanPenarikan.isEmpty ? 'poin' : item.satuanPenarikan}';
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd MMM yyyy, HH:mm', 'id_ID')
        .format(item.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          width: 1,
          color: const Color(0xFF013236).withValues(alpha: 0.1),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dateStr,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: dark,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Text(
                          _statusLabel,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: _statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _nominalText,
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
        ),
      ),
    );
  }
}

// ── Shimmer placeholder ───────────────────────────────────────────────────────

class _ShimmerCard extends StatelessWidget {
  const _ShimmerCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      height: 76,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(18),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    const dark = Color(0xFF013236);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_rounded,
              size: 64, color: dark.withValues(alpha: 0.12)),
          const SizedBox(height: 14),
          Text(
            'Belum ada transaksi di sini',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: dark.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Transaksi penarikan yang masih dalam proses akan muncul di sini',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: dark.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Error state ───────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
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
                backgroundColor: const Color(0xFF4EA771),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50)),
              ),
              onPressed: onRetry,
              child: const Text('Coba lagi',
                  style: TextStyle(fontFamily: 'Poppins')),
            ),
          ],
        ),
      ),
    );
  }
}
