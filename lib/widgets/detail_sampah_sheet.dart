import 'package:enviroo/models/katalog_model.dart';
import 'package:enviroo/providers/katalog_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class _C {
  static const dark   = Color(0xFF0D3B3E);
  static const accent = Color(0xFF4EA771);
  static const teal   = Color(0xFF013236);
}

class DetailSampahSheet extends StatefulWidget {
  final String role;
  const DetailSampahSheet({super.key, required this.role});

  @override
  State<DetailSampahSheet> createState() => _DetailSampahSheetState();
}

class _DetailSampahSheetState extends State<DetailSampahSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<String> get _visibleLevels {
    switch (widget.role) {
      case 'petugas_bsi':
        return ['nasabah', 'bsu', 'eksternal'];
      case 'petugas_bsu':
        return ['nasabah', 'bsu'];
      case 'petugas_bsm':
        return ['nasabah', 'eksternal'];
      default:
        return ['nasabah'];
    }
  }

  Color _levelColor(String level) {
    switch (level.toLowerCase()) {
      case 'bsu':       return _C.teal;
      case 'nasabah':   return _C.accent;
      case 'eksternal': return const Color(0xFFE65100);
      default:          return _C.dark;
    }
  }

  String _capLevel(String level) =>
      level.isEmpty ? '' : level[0].toUpperCase() + level.substring(1);

  String _formatDouble(double value) {
    if (value == value.truncateToDouble()) {
      return value
          .toInt()
          .toString()
          .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
    }
    return value
        .toStringAsFixed(2)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '')
        .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Consumer<KatalogProvider>(
        builder: (context, katalog, _) {
          return Column(
            children: [
              // Handle
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              if (katalog.isDetailLoading) ...[
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(color: _C.accent),
                  ),
                ),
              ] else if (katalog.currentDetail == null) ...[
                Expanded(
                  child: Center(
                    child: Text(
                      'Data tidak tersedia',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: _C.dark.withOpacity(0.4),
                      ),
                    ),
                  ),
                ),
              ] else ...[
                _buildContent(katalog.currentDetail!),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildContent(DetailSampahModel detail) {
    final levels = _visibleLevels;
    final filteredHarga = detail.hargaPerLevel
        .where((h) => levels.contains(h.levelUser.toLowerCase()))
        .toList();
    final filteredHistory = detail.historyHarga
        .where((h) => levels.contains(h.levelUser.toLowerCase()))
        .toList();

    return Expanded(
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: const Color(0xFFF2F2F2),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: detail.photoUrl.isNotEmpty
                      ? Image.network(
                          detail.photoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.recycling_rounded,
                            color: _C.accent.withOpacity(0.4),
                            size: 22,
                          ),
                        )
                      : Icon(
                          Icons.recycling_rounded,
                          color: _C.accent.withOpacity(0.4),
                          size: 22,
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        detail.namaSampah,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _C.dark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (detail.kategori != null)
                        Text(
                          detail.kategori!.kategori,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            color: _C.accent,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tab bar
          Container(
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(50),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: _C.accent,
                borderRadius: BorderRadius.circular(50),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: _C.dark.withOpacity(0.5),
              labelStyle: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              dividerColor: Colors.transparent,
              indicatorSize: TabBarIndicatorSize.tab,
              tabAlignment: TabAlignment.fill,
              tabs: const [
                Tab(height: 34, text: 'Info'),
                Tab(height: 34, text: 'Perubahan Harga'),
              ],
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildInfoTab(detail, filteredHarga),
                _buildHistoryTab(filteredHistory),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTab(DetailSampahModel detail, List<HargaPerLevelModel> harga) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      children: [
        if (detail.syaratPemilahan.isNotEmpty) ...[
          _sectionTitle('Syarat Pemilahan'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _C.accent.withOpacity(0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _C.accent.withOpacity(0.15)),
            ),
            child: Text(
              detail.syaratPemilahan,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12.5,
                height: 1.6,
                color: _C.dark.withOpacity(0.75),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],

        _sectionTitle('Informasi'),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              _infoRow(Icons.category_rounded, 'Kategori',
                  detail.kategori?.kategori ?? '-'),
              if (detail.reward != null) ...[
                Divider(height: 1, color: Colors.grey.shade200),
                _infoRow(Icons.card_giftcard_rounded, 'Jenis Reward',
                    detail.reward!.namaReward),
                Divider(height: 1, color: Colors.grey.shade200),
                _infoRow(Icons.payments_rounded, 'Satuan Reward',
                    detail.reward!.satuan),
              ],
              Divider(height: 1, color: Colors.grey.shade200),
              _infoRow(Icons.straighten_rounded, 'Satuan Item Sampah', detail.satuan),
            ],
          ),
        ),

        const SizedBox(height: 20),
        _sectionTitle('Harga Saat Ini'),
        const SizedBox(height: 8),

        if (harga.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                'Harga belum ditetapkan',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: _C.dark.withOpacity(0.4),
                ),
              ),
            ),
          )
        else
          ...harga.map((h) {
            final color = _levelColor(h.levelUser);
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withOpacity(0.15)),
              ),
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text(
                      _capLevel(h.levelUser),
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    h.satuanReward.toLowerCase() == 'poin'
                        ? '${_formatDouble(h.harga)} poin/${detail.satuan}'
                        : 'Rp ${_formatDouble(h.harga)}/${detail.satuan}',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildHistoryTab(List<HistoryHargaModel> history) {
    if (history.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history_rounded,
                size: 40, color: _C.dark.withOpacity(0.15)),
            const SizedBox(height: 8),
            Text(
              'Belum ada riwayat perubahan',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: _C.dark.withOpacity(0.4),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      itemCount: history.length,
      itemBuilder: (ctx, index) {
        final entry = history[index];
        final isIncrease = entry.hargaBaru >= entry.hargaLama;
        final isLast = index == history.length - 1;
        final color = _levelColor(entry.levelUser);

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 28,
                child: Column(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: index == 0 ? _C.accent : Colors.grey.shade300,
                        shape: BoxShape.circle,
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(width: 2, color: Colors.grey.shade200),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: index == 0
                        ? _C.accent.withOpacity(0.06)
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: index == 0
                          ? _C.accent.withOpacity(0.15)
                          : Colors.grey.shade200,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.calendar_today_rounded,
                              size: 13, color: _C.dark.withOpacity(0.4)),
                          const SizedBox(width: 6),
                          Text(
                            DateFormat('dd MMM yyyy, HH:mm')
                                .format(entry.changedAt),
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 10,
                              color: _C.dark.withOpacity(0.5),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            margin: const EdgeInsets.only(right: 4),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _capLevel(entry.levelUser),
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                                color: color,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _C.accent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              entry.changedByNama,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: _C.accent,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Sebelum',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 9.5,
                                    color: _C.dark.withOpacity(0.4),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _formatDouble(entry.hargaLama),
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: _C.dark.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: isIncrease
                                  ? const Color(0xFF4EA771).withOpacity(0.12)
                                  : const Color(0xFFE53935).withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isIncrease
                                  ? Icons.trending_up_rounded
                                  : Icons.trending_down_rounded,
                              size: 16,
                              color: isIncrease
                                  ? const Color(0xFF4EA771)
                                  : const Color(0xFFE53935),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Sesudah',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 9.5,
                                    color: _C.dark.withOpacity(0.4),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _formatDouble(entry.hargaBaru),
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: isIncrease
                                        ? const Color(0xFF4EA771)
                                        : const Color(0xFFE53935),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sectionTitle(String title) => Text(
        title,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: _C.dark,
        ),
      );

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: _C.accent),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: _C.dark.withOpacity(0.55),
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _C.dark,
            ),
          ),
        ],
      ),
    );
  }
}
