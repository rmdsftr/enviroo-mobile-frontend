import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/penarikan_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/penarikan_petugas_provider.dart';
import '../../widgets/filter_chip_row.dart';
import '../../widgets/filter_month_year.dart';
import '../../widgets/navbar.dart';
import '../../widgets/topbar_back.dart';
import 'detail_transaksi_penarikan_screen.dart';

class PenarikanPetugasScreen extends StatefulWidget {
  const PenarikanPetugasScreen({super.key});

  @override
  State<PenarikanPetugasScreen> createState() => _PenarikanPetugasScreenState();
}

class _PenarikanPetugasScreenState extends State<PenarikanPetugasScreen> {
  static const Color primary = Color(0xFF4EA771);
  static const Color dark = Color(0xFF013236);

  int _tabIndex = 0;

  static const _rewardOptions = ['Semua', 'Uang', 'Sembako'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prov = context.read<PenarikanPetugasProvider>();
      prov.bind(context.read<AuthProvider>());
      prov.loadList();
    });
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
              final displayList = _tabIndex == 0 ? prov.pengajuanList : prov.selesaiList;

              return Column(
                children: [
                  const TopBarBack(title: 'Penarikan Nasabah'),
                  // Tab (glassmorphism)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: MainNavbar(
                      selectedIndex: _tabIndex,
                      onTabChanged: (i) => setState(() => _tabIndex = i),
                      tabs: const ['Pengajuan', 'Selesai'],
                      backgroundColor: Colors.white.withValues(alpha: 0.6),
                      border: Border.all(
                        color: const Color(0xFF013236).withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                  ),
                  // White container: filter + list
                  Expanded(
                    child: Container(
                      color: Colors.white,
                      child: Column(
                        children: [
                          const SizedBox(height: 12),
                          // Date filter
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: MonthYearFilterRow(
                              filterStart: prov.filterStart,
                              filterEnd: prov.filterEnd,
                              onChanged: (s, e) => prov.setDateFilter(s, e),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Reward filter chips
                          FilterChipRow<String>(
                            items: _rewardOptions
                                .map((v) => FilterChipItem<String>(value: v, label: v))
                                .toList(),
                            selectedValue: prov.rewardFilter,
                            onSelected: prov.setRewardFilter,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                          ),
                          const SizedBox(height: 12),
                          // List
                          Expanded(
                            child: prov.loadingList
                                ? const Center(child: CircularProgressIndicator(color: primary))
                                : prov.errorList != null && _allEmpty(prov)
                                    ? _ErrorState(
                                        message: prov.errorList!,
                                        onRetry: prov.loadList,
                                      )
                                    : displayList.isEmpty
                                        ? _EmptyState(tabIndex: _tabIndex)
                                        : RefreshIndicator(
                                            color: primary,
                                            onRefresh: prov.loadList,
                                            child: ListView.builder(
                                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                                              itemCount: displayList.length,
                                              itemBuilder: (ctx, i) {
                                                final item = displayList[i];
                                                return _PenarikanPetugasCard(
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
                        ],
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

  bool _allEmpty(PenarikanPetugasProvider prov) =>
      prov.pengajuanList.isEmpty && prov.selesaiList.isEmpty;
}

// ── Card ──────────────────────────────────────────────────────────────────────

class _PenarikanPetugasCard extends StatelessWidget {
  final PenarikanItem item;
  final VoidCallback onTap;

  const _PenarikanPetugasCard({required this.item, required this.onTap});

  static const Color dark = Color(0xFF013236);

  Color get _statusColor {
    switch (item.status) {
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

  String get _statusLabel {
    switch (item.status) {
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

  IconData get _rewardIcon {
    final lower = item.namaReward.toLowerCase();
    if (lower.contains('uang')) return Icons.payments_rounded;
    return Icons.shopping_basket_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd MMM yyyy, HH:mm', 'id_ID')
        .format(item.createdAt);
    final nasabah = item.namaNasabah?.isNotEmpty == true
        ? item.namaNasabah!
        : item.nasabahId ?? '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          width: 1,
          color: const Color(0xFF013236).withOpacity(0.1), // Brand color dengan opacity cuma 10%
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
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_rewardIcon, color: _statusColor, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nasabah,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: dark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.namaReward.isEmpty
                            ? '-'
                            : _capitalize(item.namaReward),
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: Colors.black.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dateStr,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: Colors.black.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
        ),
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1).toLowerCase()}';
}

// ── Empty ─────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final int tabIndex;
  const _EmptyState({required this.tabIndex});

  @override
  Widget build(BuildContext context) {
    const dark = Color(0xFF013236);
    final label = tabIndex == 0
        ? 'Belum ada pengajuan menunggu'
        : 'Belum ada riwayat selesai';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
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
      ),
    );
  }
}

// ── Error ─────────────────────────────────────────────────────────────────────

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
