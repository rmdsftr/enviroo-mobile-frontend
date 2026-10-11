import 'package:enviroo/models/katalog_model.dart';
import 'package:enviroo/providers/katalog_provider.dart';
import 'package:enviroo/widgets/foto_thumbnail.dart';
import 'package:flutter/material.dart';
import 'package:enviroo/core/format/app_date.dart';
import 'package:enviroo/core/format/app_number.dart';
import 'package:provider/provider.dart';
import 'package:enviroo/core/theme/app_colors.dart';
import 'package:enviroo/core/theme/app_text.dart';


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

  List<String> get _visibleLevelsHargaSaatIni {
    if (widget.role == 'nasabah') return ['nasabah', 'eksternal'];
    return _visibleLevels;
  }

  String _hargaLevelLabel(String level) {
    if (level.toLowerCase() == 'eksternal') {
      return 'Pengepul';
    }
    return _capLevel(level);
  }

  String _historyLevelLabel(String level) {
    switch (level.toLowerCase()) {
      case 'nasabah':
        return 'Harga untuk Nasabah';
      case 'eksternal':
        return 'Harga dari Pengepul';
      default:
        return 'Harga untuk ${_capLevel(level)}';
    }
  }

  Color _levelColor(String level) {
    switch (level.toLowerCase()) {
      case 'bsu':       return AppColors.dark;
      case 'nasabah':   return AppColors.green;
      case 'eksternal': return const Color(0xFFE65100);
      default:          return AppColors.darkAlt;
    }
  }

  String _capLevel(String level) =>
      level.isEmpty ? '' : level[0].toUpperCase() + level.substring(1);

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
                    child: CircularProgressIndicator(color: AppColors.green),
                  ),
                ),
              ] else if (katalog.currentDetail == null) ...[
                Expanded(
                  child: Center(
                    child: Text(
                      'Data tidak tersedia',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: AppColors.darkAlt.withValues(alpha: 0.4),
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
    final hargaLevels = _visibleLevelsHargaSaatIni;
    final filteredHarga = detail.hargaPerLevel
        .where((h) => hargaLevels.contains(h.levelUser.toLowerCase()))
        .toList()
      ..sort((a, b) => hargaLevels
          .indexOf(a.levelUser.toLowerCase())
          .compareTo(hargaLevels.indexOf(b.levelUser.toLowerCase())));
    final filteredHistory = detail.historyHarga
        .where((h) => levels.contains(h.levelUser.toLowerCase()))
        .toList();

    return Expanded(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Row(
              children: [
                FotoThumbnail(
                  photoUrl: detail.photoUrl,
                  nama: detail.namaSampah,
                  fallbackIcon: Icons.recycling_rounded,
                  accent: AppColors.green,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        detail.namaSampah,
                        style: AppText.w700(15, AppColors.darkAlt),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (detail.kategori != null)
                        Text(
                          detail.kategori!.kategori,
                          style: AppText.w500(11, AppColors.green),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Container(
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(50),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppColors.green,
                borderRadius: BorderRadius.circular(50),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.darkAlt.withValues(alpha: 0.5),
              labelStyle: AppText.w600(13),
              unselectedLabelStyle: AppText.w500(13),
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
                _buildHistoryTab(filteredHistory, detail.hargaPerLevel),
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

        if (detail.syaratPemilahan.isNotEmpty) ...[
          const SizedBox(height: 20),
          _sectionTitle('Syarat Pemilahan'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.green.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.green.withValues(alpha: 0.15)),
            ),
            child: Text(
              detail.syaratPemilahan,
              style: AppText.p(12.5, color: AppColors.darkAlt.withValues(alpha: 0.75), height: 1.6),
            ),
          ),
        ],

        const SizedBox(height: 20),
        _sectionTitle('Harga Saat Ini'),
        const SizedBox(height: 8),

        if (harga.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                'Harga belum ditetapkan',
                style: AppText.r(13, AppColors.darkAlt.withValues(alpha: 0.4)),
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
                color: color.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text(
                      _hargaLevelLabel(h.levelUser),
                      style: AppText.w700(10, color),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    h.satuanReward.toLowerCase() == 'poin'
                        ? '${AppNumber.desimal(h.harga)} poin/${detail.satuan}'
                        : 'Rp ${AppNumber.desimal(h.harga)}/${detail.satuan}',
                    style: AppText.w600(13, color),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  String _satuanForSchema(String schemaId, List<HargaPerLevelModel> hargaPerLevel) {
    for (final h in hargaPerLevel) {
      if (h.schemaId == schemaId) return h.satuanReward;
    }
    return 'Rp';
  }

  String _formatHarga(double value, String satuan) {
    final formatted = AppNumber.desimal(value);
    return satuan.toLowerCase() == 'poin' ? '$formatted poin' : 'Rp$formatted';
  }

  Widget _buildHistoryTab(
      List<HistoryHargaModel> history, List<HargaPerLevelModel> hargaPerLevel) {
    if (history.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history_rounded,
                size: 40, color: AppColors.darkAlt.withValues(alpha: 0.15)),
            const SizedBox(height: 8),
            Text(
              'Belum ada riwayat perubahan',
              style: AppText.r(13, AppColors.darkAlt.withValues(alpha: 0.4)),
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
        final satuan = _satuanForSchema(entry.schemaId, hargaPerLevel);

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
                        color: index == 0 ? AppColors.green : Colors.grey.shade300,
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
                        ? AppColors.green.withValues(alpha: 0.06)
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: index == 0
                          ? AppColors.green.withValues(alpha: 0.15)
                          : Colors.grey.shade200,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.calendar_today_rounded,
                              size: 13, color: AppColors.darkAlt.withValues(alpha: 0.4)),
                          const SizedBox(width: 6),
                          Text(
                            AppDate.tanggalSingkatJam(entry.changedAt),
                            style: AppText.r(10, AppColors.darkAlt.withValues(alpha: 0.5)),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _historyLevelLabel(entry.levelUser),
                              style: AppText.w700(8, color),
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
                                  style: AppText.r(9.5, AppColors.darkAlt.withValues(alpha: 0.4)),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _formatHarga(entry.hargaLama, satuan),
                                  style: AppText.w600(13, AppColors.darkAlt.withValues(alpha: 0.7)),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: isIncrease
                                  ? AppColors.green.withValues(alpha: 0.12)
                                  : AppColors.dangerAlt.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isIncrease
                                  ? Icons.trending_up_rounded
                                  : Icons.trending_down_rounded,
                              size: 16,
                              color: isIncrease
                                  ? AppColors.green
                                  : AppColors.dangerAlt,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Sesudah',
                                  style: AppText.r(9.5, AppColors.darkAlt.withValues(alpha: 0.4)),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _formatHarga(entry.hargaBaru, satuan),
                                  style: AppText.w700(13, isIncrease
                                        ? AppColors.green
                                        : AppColors.dangerAlt),
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
        style: AppText.w700(12.5, AppColors.darkAlt),
      );

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.green),
          const SizedBox(width: 10),
          Text(
            label,
            style: AppText.r(12, AppColors.darkAlt.withValues(alpha: 0.55)),
          ),
          const Spacer(),
          Text(
            value,
            style: AppText.w600(12, AppColors.darkAlt),
          ),
        ],
      ),
    );
  }
}
