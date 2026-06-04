import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/penarikan_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/penarikan_nasabah_provider.dart';
import '../../widgets/filter_month_year.dart';
import '../../widgets/navbar.dart';
import '../../widgets/topbar_back.dart';
import 'detail_penarikan_screen.dart';
import 'request_penarikan_screen.dart';

class PenarikanNasabahScreen extends StatefulWidget {
  const PenarikanNasabahScreen({super.key});

  @override
  State<PenarikanNasabahScreen> createState() =>
      _PenarikanNasabahScreenState();
}

class _PenarikanNasabahScreenState extends State<PenarikanNasabahScreen> {
  static const Color primary = Color(0xFF4EA771);
  static const Color dark = Color(0xFF013236);

  // 0=Uang, 1=Sembako
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final prov = context.read<PenarikanNasabahProvider>();
      prov.bind(auth);
      prov.loadInitial();
    });
  }

  Future<void> _openAjukan() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const RequestPenarikanScreen()),
    );
    if (result == true && mounted) {
      context.read<PenarikanNasabahProvider>().loadList(refresh: true);
    }
  }

  void _onTabChanged(int index, PenarikanNasabahProvider prov) {
    setState(() => _tabIndex = index);
    final rewardId = index == 0
        ? prov.rewardUang?.rewardId
        : prov.rewardSembako?.rewardId;
    prov.setFilter(rewardId: rewardId);
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
          child: Consumer<PenarikanNasabahProvider>(
            builder: (_, prov, __) {
              return Column(
                children: [
                  const TopBarBack(title: 'Penarikan Saldo'),
                  Expanded(
                    child: RefreshIndicator(
                      color: primary,
                      onRefresh: () => prov.loadInitial(),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 16),
                            // 1. Ajukan button
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: dark,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 15),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(50),
                                    ),
                                    elevation: 0,
                                  ),
                                  onPressed: _openAjukan,
                                  icon: const Icon(Icons.add_rounded, size: 20),
                                  label: const Text(
                                    'Ajukan Penarikan',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // 3. Tab filter jenis reward
                            MainNavbar(
                              selectedIndex: _tabIndex,
                              tabs: const ['Uang', 'Sembako'],
                              backgroundColor: Colors.white.withOpacity(0.6),
                              border: Border.all(
                                color: const Color(0xFF013236).withOpacity(0.1),
                                width: 1,
                              ),
                              onTabChanged: (i) => _onTabChanged(i, prov),
                            ),
                            const SizedBox(height: 14),
                            // 4. Date filter
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: MonthYearFilterRow(
                                filterStart: prov.filterStart,
                                filterEnd: prov.filterEnd,
                                onChanged: (s, e) => prov.setFilter(start: s, end: e),
                              ),
                            ),
                            const SizedBox(height: 14),

                            // White container for the list
                            Container(
                              width: double.infinity,
                              constraints: BoxConstraints(
                                minHeight: MediaQuery.of(context).size.height,
                              ),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                              ),
                              padding: const EdgeInsets.only(top: 5, bottom: 40),
                              child: Column(
                                children: [
                                  if (prov.loadingList && prov.penarikanList.isEmpty)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 20),
                                      child: Column(
                                        children: List.generate(
                                          5,
                                          (_) => const _ShimmerCard(),
                                        ),
                                      ),
                                    )
                                  else if (prov.errorList != null && prov.penarikanList.isEmpty)
                                    _ErrorState(
                                      message: prov.errorList!,
                                      onRetry: () => prov.loadList(refresh: true),
                                    )
                                  else if (prov.penarikanList.isEmpty)
                                    _EmptyState(tabIndex: _tabIndex)
                                  else
                                    ListView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      padding: const EdgeInsets.symmetric(horizontal: 20),
                                      itemCount: prov.penarikanList.length + 1,
                                      itemBuilder: (ctx, i) {
                                        if (i == prov.penarikanList.length) {
                                          return prov.hasMore
                                              ? const Padding(
                                                  padding: EdgeInsets.symmetric(vertical: 12),
                                                  child: Center(
                                                    child: CircularProgressIndicator(
                                                      color: primary,
                                                      strokeWidth: 2,
                                                    ),
                                                  ),
                                                )
                                              : const SizedBox.shrink();
                                        }
                                        final item = prov.penarikanList[i];
                                        return _PenarikanCard(
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
                                ],
                              ),
                            ),
                          ],
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

// ── Saldo Summary Card ────────────────────────────────────────────────────────

// ── Penarikan Card ────────────────────────────────────────────────────────────

class _PenarikanCard extends StatelessWidget {
  final PenarikanItem item;
  final VoidCallback onTap;

  const _PenarikanCard({required this.item, required this.onTap});

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
    if (item.isUang) return Icons.payments_rounded;
    return Icons.shopping_basket_rounded;
  }

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
        .format(item.updatedAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(22),
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
                  child: Icon(_rewardIcon,
                      color: _statusColor, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.namaReward.isEmpty
                            ? 'Penarikan'
                            : _capitalize(item.namaReward),
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: dark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dateStr,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: Colors.black.withValues(alpha: 0.45),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _nominalText,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: dark,
                      ),
                    ),
                    const SizedBox(height: 4),
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
    final labels = ['Uang', 'Sembako'];
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
              'Belum ada riwayat penarikan ${labels[tabIndex]}',
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
              'Transaksi penarikan kamu akan muncul di sini',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: dark.withValues(alpha: 0.3),
              ),
            ),
          ],
        ),
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
              style: const TextStyle(
                  fontFamily: 'Poppins', fontSize: 13),
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
