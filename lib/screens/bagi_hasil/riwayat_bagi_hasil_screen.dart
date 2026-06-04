import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/bagi_hasil_bank_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/bagi_hasil_bank_provider.dart';
import '../../widgets/topbar_back.dart';
import '../../widgets/filter_month_year.dart';
import '../../screens/penjualan_eksternal/riwayat_penjualan_screen.dart';
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
    prov.fetchList(bankId);
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
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // Bagian atas — kena background
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
        const SizedBox(height: 16),

        // Container putih — filter + list sampai bawah
        Container(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height,
          ),
          decoration: const BoxDecoration(color: Colors.white),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFilterRow(prov),
              const SizedBox(height: 14),
              _buildList(prov),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLakukanBagiHasilCard() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const RiwayatPenjualanScreen(),
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
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: Colors.white60),
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

    final items = prov.listData?.riwayatBagiHasil ?? [];
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
                color: rewardColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(rewardIcon, color: rewardColor, size: 22),
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
            const Icon(Icons.chevron_right_rounded,
                size: 20, color: _C.muted),
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
