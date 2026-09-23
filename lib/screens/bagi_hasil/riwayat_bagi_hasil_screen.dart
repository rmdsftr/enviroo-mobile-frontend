import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/bagi_hasil_bank_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/bagi_hasil_bank_provider.dart';
import '../../providers/reward_provider.dart';
import '../../providers/penjualan_provider.dart' show FetchStatus;
import '../../widgets/filter_chip_row.dart';
import '../../widgets/topbar_back.dart';
import '../../widgets/filter_month_year.dart';
import '../../screens/penjualan/riwayat_penjualan_screen.dart';
import 'detail_bagi_hasil_screen.dart';

class _C {
  static const dark = Color(0xFF013236);
  static const green = Color(0xFF4EA771);
  static const muted = Color(0xFF8A9A92);
  static const accent = Color(0xFF94DF0C);
}

class RiwayatBagiHasilScreen extends StatefulWidget {
  const RiwayatBagiHasilScreen({super.key});

  @override
  State<RiwayatBagiHasilScreen> createState() => _RiwayatBagiHasilScreenState();
}

class _RiwayatBagiHasilScreenState extends State<RiwayatBagiHasilScreen> {
  String _rewardFilter = 'semua';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final auth = context.read<AuthProvider>();
    final prov = context.read<BagiHasilBankProvider>();
    final bankId = auth.bankId ?? '';
    if (bankId.isEmpty) return;
    final now = DateTime.now();
    final filterEnd = DateTime(now.year, now.month);
    final startMonth = now.month - 2;
    final filterStart = startMonth <= 0
        ? DateTime(now.year - 1, 12 + startMonth)
        : DateTime(now.year, startMonth);
    prov.setDateFilter(filterStart, filterEnd, bankId);
    context.read<RewardProvider>().fetchNilaiReward(bankId);
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
          child: Column(
            children: [
              const TopBarBack(title: 'Bagi Hasil'),
              Expanded(
                child: Consumer<BagiHasilBankProvider>(
                  builder: (_, prov, __) => _buildBody(prov),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BagiHasilBankProvider prov) {
    return CustomScrollView(
      slivers: [
        // Bagian atas — kena background, scroll away normally
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 8, 28, 12),
                child: Text(
                  'Pada menu ini kamu bisa melihat semua riwayat bagi hasil yang pernah dilakukan bank sampah',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: Color(0xFF013236).withValues(alpha: 0.8),
                    height: 1.5,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildLakukanBagiHasilCard(),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Consumer<RewardProvider>(
                  builder: (_, reward, __) =>
                      _buildPersenBagiHasilCard(reward),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
        // Sticky: "Riwayat Bagi Hasil" + filter bulan + filter reward,
        // pin di bawah TopBarBack
        SliverPersistentHeader(
          pinned: true,
          delegate: _StickyHeaderDelegate(
            height: 145,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                      padding : const EdgeInsets.symmetric(horizontal: 5),
                      child : Text(
                        "Riwayat Bagi Hasil",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: _C.dark,
                        ),
                      )
                  ),
                  const SizedBox(height: 12),
                  _buildFilterRow(prov),
                  const SizedBox(height: 10),
                  _buildRewardChipFilter(),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ),
        // List — cuma ini yang scroll di bawah sticky header
        SliverToBoxAdapter(
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height,
            ),
            decoration: const BoxDecoration(color: Colors.white),
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 40),
            child: _buildList(prov),
          ),
        ),
      ],
    );
  }

  /// Jenis saldo untuk satu baris persentase: 'saldo rupiah' / 'saldo poin'.
  ///
  /// Sumber utamanya `satuan` ("Rp" / "poin"). Kalau kosong atau tak dikenal,
  /// jatuh ke `namaReward` ("Uang" / "Barang") yang masih dipakai backend.
  /// Dua-duanya istilah mentah backend, jadi tidak ada yang boleh tampil apa
  /// adanya ke nasabah.
  String _labelSaldo(PersenBagiHasilReward r) {
    final s = r.satuan.toLowerCase();
    if (s.contains('poin')) return 'saldo poin';
    if (s.contains('rp') || s.contains('rupiah')) return 'saldo rupiah';
    return r.namaReward.toLowerCase().contains('barang')
        ? 'saldo poin'
        : 'saldo rupiah';
  }

  Widget _buildPersenBagiHasilCard(RewardProvider reward) {
    if (reward.nilaiStatus == FetchStatus.loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator(color: _C.green)),
      );
    }
    if (reward.persenNasabah.isEmpty) return const SizedBox.shrink();

    final items = reward.persenNasabah;

    // Satu kartu per jenis saldo, berdampingan dan sama tinggi walau teks
    // salah satunya melipat lebih panjang.
    //
    // IntrinsicHeight wajib di sini: Row ini hidup di dalam area scroll, jadi
    // tingginya tidak terbatas. Tanpa pembatas itu, CrossAxisAlignment.stretch
    // meneruskan tinggi tak hingga ke kartunya dan seluruh layar gagal
    // di-layout ("BoxConstraints forces an infinite height").
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            Expanded(child: _kartuPersen(items[i])),
          ],
        ],
      ),
    );
  }

  Widget _kartuPersen(PersenBagiHasilReward r) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _C.dark.withValues(alpha: 0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            '${r.persenBagiHasil.toStringAsFixed(0)}%',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              height: 1.1,
              color: _C.green,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'bagi hasil ${_labelSaldo(r)} nasabah',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 9.5,
                height: 1.35,
                color: _C.dark.withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLakukanBagiHasilCard() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const RiwayatPenjualanScreen(
              initialStatusFilter: 'Menunggu Bagi Hasil',
            ),
          ),
        ).then((_) => _load());
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _C.dark,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _C.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(25),
              ),
              child: const Icon(Icons.payments_rounded,
                  color: _C.accent, size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lakukan Bagi Hasil',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Distribusikan hasil penjualan ke nasabah',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: Colors.white60,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterRow(BagiHasilBankProvider prov) {
    final auth = context.read<AuthProvider>();
    return MonthYearFilterRow(
      filterStart: prov.filterStart,
      filterEnd: prov.filterEnd,
      onChanged: (start, end) {
        prov.setDateFilter(
          start,
          end,
          auth.bankId ?? '',
        );
      },
    );
  }

  Widget _buildRewardChipFilter() {
    return FilterChipRow<String>(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      // Label memakai jenis SALDO. Nilainya tetap 'uang'/'barang' karena itu
      // yang dicocokkan ke namaReward dari backend di _buildList() -- jangan
      // ikut diubah.
      items: const [
        FilterChipItem(value: 'semua', label: 'Semua'),
        FilterChipItem(value: 'uang', label: 'Rupiah'),
        FilterChipItem(value: 'barang', label: 'Poin'),
      ],
      selectedValue: _rewardFilter,
      onSelected: (v) => setState(() => _rewardFilter = v),
    );
  }

  Widget _buildList(BagiHasilBankProvider prov) {
    if (prov.listStatus == BhBankStatus.loading) {
      return Column(
        children: List.generate(
          4,
          (_) => _SkeletonCard(),
        ),
      );
    }

    if (prov.listStatus == BhBankStatus.error) {
      return _buildError(prov.listError ?? 'Gagal memuat data', _load);
    }

    final raw = prov.listData?.riwayatBagiHasil ?? [];
    final items = _rewardFilter == 'semua'
        ? raw
        : raw.where((item) {
            final lower = item.namaReward.toLowerCase();
            if (_rewardFilter == 'uang') return lower.contains('uang');
            if (_rewardFilter == 'barang') return lower.contains('barang');
            return true;
          }).toList();

    if (items.isEmpty) {
      return _buildEmpty();
    }

    return Column(
      children: items
          .map((item) => _BagiHasilCard(
                item: item,
                onTap: () => _openDetail(item.bagiHasilId),
              ))
          .toList(),
    );
  }

  void _openDetail(String bagiHasilId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailBagiHasilScreen(bagiHasilId: bagiHasilId),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Column(
          children: [
            Icon(Icons.receipt_long_rounded, size: 52, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(
              'Belum ada riwayat bagi hasil',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(String msg, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Column(
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 10),
            Text(
              msg,
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: onRetry,
              child: const Text('Coba Lagi',
                  style: TextStyle(fontFamily: 'Poppins', color: _C.green)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sticky header delegate ───────────────────────────────────────────────────
// Bikin "Riwayat Bagi Hasil" + filter bulan + filter reward nempel (pinned) di
// bawah TopBarBack saat di-scroll, sementara cuma list riwayat yang ikut bergerak.
class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  _StickyHeaderDelegate({required this.child, required this.height});

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(covariant _StickyHeaderDelegate oldDelegate) {
    return oldDelegate.child != child || oldDelegate.height != height;
  }
}

class _BagiHasilCard extends StatelessWidget {
  final BagiHasilBankItem item;
  final VoidCallback onTap;

  const _BagiHasilCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tanggal =
        DateFormat('d MMMM yyyy', 'id_ID').format(item.tanggalBagiHasil);
    final jam =
        DateFormat('HH:mm', 'id_ID').format(item.tanggalBagiHasil);

    Color rewardColor;
    IconData rewardIcon;
    switch (item.rewardId) {
      case 2:
        rewardColor = const Color(0xFFFFC107);
        rewardIcon = Icons.stars_rounded;
        break;
      case 3:
        rewardColor = const Color(0xFF9B51E0);
        rewardIcon = Icons.toll_rounded;
        break;
      default:
        rewardColor = const Color(0xFF4EA771);
        rewardIcon = Icons.payments_rounded;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF013236).withOpacity(0.08),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _C.dark.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(rewardIcon, color: _C.dark, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$tanggal · $jam',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _C.dark,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'ID : ${item.bagiHasilId}',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: _C.muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                    height: 13,
                    width: 140,
                    decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(6))),
                const SizedBox(height: 6),
                Container(
                    height: 11,
                    width: 100,
                    decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(6))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
