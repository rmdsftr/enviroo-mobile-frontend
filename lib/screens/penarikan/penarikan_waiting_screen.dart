import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/penarikan_petugas_provider.dart';
import '../../widgets/navbar.dart';
import '../../widgets/penarikan_petugas_card.dart';
import '../../widgets/topbar_back.dart';
import 'detail_transaksi_penarikan_screen.dart';
import 'package:enviroo/core/theme/app_colors.dart';
import 'package:enviroo/core/theme/app_text.dart';
import 'package:enviroo/widgets/state_message.dart';

class PenarikanWaitingScreen extends StatefulWidget {
  final int initialTab;

  const PenarikanWaitingScreen({super.key, this.initialTab = 0});

  @override
  State<PenarikanWaitingScreen> createState() => _PenarikanWaitingScreenState();
}

class _PenarikanWaitingScreenState extends State<PenarikanWaitingScreen> {
  static const Color primary = AppColors.green;
  static const Color dark = AppColors.dark;

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
      backgroundColor: AppColors.surface,
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
                      color: AppColors.dark.withValues(alpha: 0.1),
                      width: 1,
                    ),
                    onTabChanged: (i) => setState(() => _tabIndex = i),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(28, 12, 28, 4),
                    child: Text(
                      tabDescription,
                      style: AppText.p(12.5, color: dark.withValues(alpha: 0.65), height: 1.6),
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

class _EmptyState extends StatelessWidget {
  final int tabIndex;
  const _EmptyState({required this.tabIndex});

  @override
  Widget build(BuildContext context) {
    final label = tabIndex == 0
        ? 'Belum ada pengajuan'
        : 'Belum ada penjemputan';
    final keterangan = tabIndex ==0
        ? 'Belum ada penarikan saldo nasabah yang menunggu persetujuan'
        : 'Belum ada penarikan saldo nasabah yang menunggu penjemputan';
    return StateMessage(
      illustration: StateArt.empty,
      message: label,
      subtitle: keterangan,
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return StateMessage(
      illustration: StateArt.error,
      message: message,
      action: StateRetryButton(
        onPressed: onRetry,
        label: 'Coba lagi',
        color: AppColors.green,
        radius: 50,
      ),
    );
  }
}
