import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/penarikan_petugas_provider.dart';
import '../../widgets/navbar.dart';
import '../../widgets/penarikan_petugas_card.dart';
import '../../widgets/topbar_back.dart';
import 'detail_transaksi_penarikan_screen.dart';

/// Daftar pengajuan penarikan sisi petugas yang masih berjalan — dibuka dari
/// kartu statistik di [PenarikanPetugasScreen]. Struktur & gaya sama persis
/// dengan [PenarikanOngoingScreen] (versi nasabah), cuma sumber data & tujuan
/// tap kartunya beda (sisi petugas).
class PenarikanWaitingScreen extends StatefulWidget {
  /// 0 = Pengajuan (pending), 1 = Siap Dijemput (approved)
  final int initialTab;

  const PenarikanWaitingScreen({super.key, this.initialTab = 0});

  @override
  State<PenarikanWaitingScreen> createState() => _PenarikanWaitingScreenState();
}

class _PenarikanWaitingScreenState extends State<PenarikanWaitingScreen> {
  static const Color primary = Color(0xFF4EA771);
  static const Color dark = Color(0xFF013236);

  late int _tabIndex;

  @override
  void initState() {
    super.initState();
    _tabIndex = widget.initialTab;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PenarikanPetugasProvider>().loadList();
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
          child: Consumer<PenarikanPetugasProvider>(
            builder: (_, prov, __) {
              final visibleList =
                  _tabIndex == 0 ? prov.pendingList : prov.approvedList;

              final tabDescription = _tabIndex == 0
                  ? 'Pengajuan penarikan nasabah yang sedang menunggu persetujuan kamu'
                  : 'Pengajuan yang sudah kamu setujui dan menunggu diambil nasabah ke bank sampah';

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
                        onRefresh: prov.loadList,
                        child: prov.loadingList && visibleList.isEmpty
                            ? ListView(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                children: List.generate(
                                  4,
                                  (_) => const _ShimmerCard(),
                                ),
                              )
                            : prov.errorList != null && visibleList.isEmpty
                                ? _ErrorState(
                                    message: prov.errorList!,
                                    onRetry: prov.loadList,
                                  )
                                : visibleList.isEmpty
                                    ? ListView(
                                        physics: const AlwaysScrollableScrollPhysics(),
                                        children: [_EmptyState(tabIndex: _tabIndex)],
                                      )
                                    : ListView.builder(
                                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                                        itemCount: visibleList.length,
                                        itemBuilder: (ctx, i) {
                                          final item = visibleList[i];
                                          return PenarikanPetugasCard(
                                            item: item,
                                            onTap: () async {
                                              await Navigator.push(
                                                ctx,
                                                MaterialPageRoute(
                                                  builder: (_) => DetailTransaksiPenarikanScreen(
                                                    penarikanId: item.penarikanId,
                                                  ),
                                                ),
                                              );
                                              if (ctx.mounted) {
                                                ctx.read<PenarikanPetugasProvider>().loadList();
                                              }
                                            },
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
  final int tabIndex;
  const _EmptyState({required this.tabIndex});

  @override
  Widget build(BuildContext context) {
    const dark = Color(0xFF013236);
    final label = tabIndex == 0
        ? 'Belum ada pengajuan menunggu persetujuan'
        : 'Belum ada penarikan yang menunggu penjemputan';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_rounded,
              size: 64, color: dark.withValues(alpha: 0.12)),
          const SizedBox(height: 14),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: dark.withValues(alpha: 0.4),
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
