import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/penjualan_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/penjualan_provider.dart';
import '../../widgets/topbar_back.dart';
import '../../widgets/filter_month_year.dart';
import '../../widgets/filter_chip_row.dart';
import '../../widgets/navbar.dart';
import 'detail_penjualan_screen.dart';
import 'jenis_transaksi_screen.dart';

class _C {
  static const dark = Color(0xFF013236);
  static const green = Color(0xFF4EA771);
  static const cardBg = Color(0xFFF7FBF5);
  static const muted = Color(0xFF8A9A92);
  static const danger = Color(0xFFD94848);
  static const sectionBg = Color(0xFFF2F3F2);
}

class RiwayatPenjualanScreen extends StatefulWidget {
  const RiwayatPenjualanScreen({super.key});

  @override
  State<RiwayatPenjualanScreen> createState() => _RiwayatPenjualanScreenState();
}

class _RiwayatPenjualanScreenState extends State<RiwayatPenjualanScreen> {
  DateTime _filterStart =
      DateTime(DateTime.now().year, DateTime.now().month - 2);
  DateTime _filterEnd = DateTime.now();
  String _filterReward = 'Semua';
  int _tabIndex = 0; // 0 = Pending, 1 = Terdistribusi

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    final prov = context.read<PenjualanProvider>();
    final bankId = auth.bankId ?? '';
    if (bankId.isEmpty) return;
    await Future.wait([
      prov.fetchRiwayat(bankId),
      prov.fetchRewards(),
      prov.fetchMitra(bankId),
    ]);
  }

  void _openForm({String? initialMitraName}) {
    final prov = context.read<PenjualanProvider>();
    prov.resetForm();
    if (initialMitraName != null) {
      prov.setIdentitasPembeli(initialMitraName);
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const JenisTransaksiScreen()),
    ).then((_) => _load());
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
            alignment: Alignment.topCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const TopBarBack(title: 'Penjualan Sampah'),
              Expanded(
                child: RefreshIndicator(
                  color: _C.green,
                  onRefresh: _load,
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      // ── Bagian atas ────────────────────────────
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => _openForm(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF013236),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                  elevation: 0,
                                ),
                                icon: const Icon(Icons.add_rounded, size: 18),
                                label: const Text(
                                  'Jual Sampah ke Pihak Eksternal',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Consumer<PenjualanProvider>(
                            builder: (_, prov, __) =>
                                _buildRiwayatMitraSection(prov),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),

                      Consumer<PenjualanProvider>(
                        builder: (_, prov, __) {
                          if (prov.riwayatStatus == FetchStatus.idle ||
                              prov.riwayatStatus == FetchStatus.loading) {
                            return const Padding(
                              padding: EdgeInsets.only(top: 40),
                              child: Center(
                                child:
                                    CircularProgressIndicator(color: _C.green),
                              ),
                            );
                          }
                          if (prov.riwayatStatus == FetchStatus.error) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 40),
                              child: _buildError(
                                  prov.riwayatError ?? 'Terjadi kesalahan'),
                            );
                          }

                          final filtered =
                              _getFilteredList(prov.riwayat, prov.rewards);

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ── Section List (Putih) ─────────
                              Container(
                                width: double.infinity,
                                constraints: BoxConstraints(
                                  minHeight: MediaQuery.of(context).size.height,
                                ),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                ),
                                padding: const EdgeInsets.only(top: 10, bottom: 100),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    // Tab Pending / Terdistribusi (Glassmorphism)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      child: MainNavbar(
                                        selectedIndex: _tabIndex,
                                        onTabChanged: (i) =>
                                            setState(() => _tabIndex = i),
                                        tabs: const ['Pending', 'Terdistribusi'],
                                        backgroundColor: Colors.white.withValues(alpha: 0.6),
                                        border: Border.all(
                                          color: const Color(0xFF013236).withValues(alpha: 0.1),
                                          width: 1,
                                        ),
                                      ),
                                    ),

                                    // Filter Bulan & Reward
                                    const SizedBox(height: 8),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 20),
                                      child: MonthYearFilterRow(
                                        filterStart: _filterStart,
                                        filterEnd: _filterEnd,
                                        onChanged: (start, end) =>
                                            setState(() {
                                          _filterStart = start;
                                          _filterEnd = end;
                                        }),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    _buildFilterChips(
                                        prov.riwayat, prov.rewards),
                                    const SizedBox(height: 20),

                                    if (filtered.isEmpty)
                                      _buildEmpty()
                                    else
                                      ListView.separated(
                                        shrinkWrap: true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 20),
                                        itemCount: filtered.length,
                                        separatorBuilder: (_, __) =>
                                            const SizedBox(height: 12),
                                        itemBuilder: (_, i) => _RiwayatCard(
                                          item: filtered[i],
                                          onTap: () =>
                                              _openDetail(filtered[i]),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<RiwayatPenjualanModel> _getFilteredList(
    List<RiwayatPenjualanModel> list,
    List<RewardModel> rewards,
  ) {
    return list.where((item) {
      // Filter tanggal
      final d = item.createdAt;
      final start = DateTime(_filterStart.year, _filterStart.month);
      final end =
          DateTime(_filterEnd.year, _filterEnd.month + 1, 0, 23, 59, 59);
      if (d.isBefore(start) || d.isAfter(end)) return false;

      // Filter tab: Pending (0) vs Terdistribusi (1)
      final sudah = item.statusBagiHasil.toLowerCase() == 'berhasil';
      if (_tabIndex == 0 && sudah) return false;
      if (_tabIndex == 1 && !sudah) return false;

      // Filter jenis reward berdasarkan namaReward
      if (_filterReward != 'Semua') {
        if (item.namaReward != _filterReward) return false;
      }

      return true;
    }).toList();
  }

  Widget _buildRiwayatMitraSection(PenjualanProvider prov) {
    if (prov.mitraStatus == FetchStatus.loading) {
      return const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator(color: _C.green)),
      );
    }
    if (prov.mitraList.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 27, vertical: 8),
          child: Text(
            'Mitra Pengepul Langganan',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _C.dark,
            ),
          ),
        ),
        SizedBox(
          height: 90,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: prov.mitraList.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final mitraName = prov.mitraList[i];
              return Container(
                width: 140,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: const Color(0xFFE6EDE9), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(5),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _openForm(initialMitraName: mitraName),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: _C.cardBg,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.storefront_rounded,
                                size: 20, color: _C.green),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            mitraName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _C.dark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips(
      List<RiwayatPenjualanModel> riwayat, List<RewardModel> rewards) {
    // Ambil namaReward unik dari data aktual
    final uniqueNama = riwayat
        .map((e) => e.namaReward)
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList();

    if (_filterReward != 'Semua' && !uniqueNama.contains(_filterReward)) {
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => setState(() => _filterReward = 'Semua'));
    }

    final items = <FilterChipItem<String>>[
      const FilterChipItem(value: 'Semua', label: 'Semua'),
      ...uniqueNama.map((nama) => FilterChipItem<String>(value: nama, label: nama)),
    ];

    return FilterChipRow<String>(
      items: items,
      selectedValue: _filterReward,
      onSelected: (v) => setState(() => _filterReward = v),
      padding: const EdgeInsets.symmetric(horizontal: 20),
    );
  }

  void _openDetail(RiwayatPenjualanModel item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            DetailPenjualanScreen(penjualanId: item.penjualanId),
      ),
    );
  }

  Widget _buildEmpty() => Center(
        child: Padding(
          padding:
              const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.receipt_long_rounded,
                  size: 64, color: _C.muted),
              const SizedBox(height: 12),
              const Text(
                'Belum ada riwayat penjualan',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: _C.muted,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Tekan tombol di atas untuk mulai menjual sampah',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  color: _C.muted,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildError(String msg) => Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: _C.danger, size: 42),
              const SizedBox(height: 10),
              Text(
                msg,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  color: _C.danger,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _load,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _C.dark,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Coba Lagi',
                    style: TextStyle(fontFamily: 'Poppins')),
              ),
            ],
          ),
        ),
      );
}

// ─── Card item riwayat ──────────────────────────────────────────────────────
class _RiwayatCard extends StatelessWidget {
  final RiwayatPenjualanModel item;
  final VoidCallback onTap;
  const _RiwayatCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final fmtPoin = NumberFormat('#,##0.##########', 'id_ID');
    final isBerhasil = item.statusBagiHasil.toLowerCase() == 'berhasil';
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.5),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              width: 1,
              color: const Color(0xFF013236).withOpacity(0.1), // Brand color dengan opacity cuma 10%
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _C.cardBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  item.satuanReward.toLowerCase() == 'rp' ||
                          item.satuanReward.toLowerCase() == 'rupiah'
                      ? Icons.payments_rounded
                      : Icons.shopping_basket_rounded,
                  color: _C.green,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.identitasPembeli,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: _C.dark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.tanggalFormatted,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              color: _C.muted,
                            ),
                          )
                        ]
                    ),
                    Text(
                      item.satuanReward.toLowerCase() == 'rupiah' ||
                          item.satuanReward.toLowerCase() == 'rp'
                          ? 'Rp ${fmtPoin.format(item.totalPenjualan)}'
                          : '${fmtPoin.format(item.totalPenjualan)} ${item.satuanReward}',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _C.green,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

