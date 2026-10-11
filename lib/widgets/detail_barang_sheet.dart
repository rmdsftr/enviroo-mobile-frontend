import 'package:enviroo/models/katalog_model.dart';
import 'package:enviroo/providers/barang_provider.dart';
import 'package:enviroo/widgets/foto_thumbnail.dart';
import 'package:flutter/material.dart';
import 'package:enviroo/core/format/app_date.dart';
import 'package:enviroo/core/format/app_number.dart';
import 'package:provider/provider.dart';
import 'package:enviroo/core/theme/app_colors.dart';
import 'package:enviroo/core/theme/app_text.dart';


class DetailBarangSheet extends StatefulWidget {
  final String role;
  final bool showRiwayat;
  const DetailBarangSheet({super.key, required this.role, this.showRiwayat = true});

  @override
  State<DetailBarangSheet> createState() => _DetailBarangSheetState();
}

class _DetailBarangSheetState extends State<DetailBarangSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool get _hasTabs => widget.role != 'petugas_bsm' && widget.showRiwayat;

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

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Consumer<BarangProvider>(
        builder: (context, barang, _) {
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
              if (barang.isDetailLoading)
                const Expanded(
                  child: Center(child: CircularProgressIndicator(color: AppColors.green)),
                )
              else if (barang.currentDetail == null)
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
                )
              else
                _buildContent(barang.currentDetail!),
            ],
          );
        },
      ),
    );
  }

  Widget _buildContent(DetailBarangWithRiwayat detail) {
    return Expanded(
      child: Column(
        children: [
          _buildHeader(detail.barang),

          if (_hasTabs) ...[
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
                  Tab(height: 34, text: 'Informasi'),
                  Tab(height: 34, text: 'Riwayat'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildInfoTab(detail.barang),
                  _buildRiwayatTab(detail.riwayatDistribusi),
                ],
              ),
            ),
          ] else ...[
            Expanded(child: _buildInfoTab(detail.barang)),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(KatalogBarangModel item) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: Row(
        children: [
          FotoThumbnail(
            photoUrl: item.photoUrl,
            nama: item.namaBarang,
            fallbackIcon: Icons.storefront_rounded,
            accent: AppColors.green,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.namaBarang,
                  style: AppText.w700(15, AppColors.darkAlt),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'ID: ${item.produkId}',
                  style: AppText.r(10, AppColors.darkAlt.withValues(alpha: 0.4)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTab(KatalogBarangModel item) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              _infoRow('Nama Barang', item.namaBarang),
              Divider(height: 1, color: Colors.grey.shade200),
              _infoRow('ID Barang', item.produkId),
              Divider(height: 1, color: Colors.grey.shade200),
              _infoRow('Nilai Poin per Item', '${AppNumber.desimal(item.nilaiPoin)} poin'),
              Divider(height: 1, color: Colors.grey.shade200),
              _infoRow('Stok Tersedia', '${AppNumber.desimal(item.stok)} item'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRiwayatTab(List<RiwayatDistribusiBarangModel> riwayat) {
    if (riwayat.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_shipping_rounded,
                size: 40, color: AppColors.darkAlt.withValues(alpha: 0.15)),
            const SizedBox(height: 8),
            Text(
              'Belum ada riwayat distribusi',
              style: AppText.r(13, AppColors.darkAlt.withValues(alpha: 0.4)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      itemCount: riwayat.length,
      itemBuilder: (ctx, index) {
        final entry = riwayat[index];
        final isFirst = index == 0;
        final isLast = index == riwayat.length - 1;

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
                        color: isFirst ? AppColors.green : Colors.grey.shade300,
                        shape: BoxShape.circle,
                      ),
                    ),
                    if (!isLast)
                      Expanded(child: Container(width: 2, color: Colors.grey.shade200)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isFirst
                        ? AppColors.green.withValues(alpha: 0.06)
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isFirst
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
                            AppDate.tanggalSingkatJam(entry.tanggalKirim),
                            style: AppText.r(10, AppColors.darkAlt.withValues(alpha: 0.5)),
                          ),
                          const Spacer(),
                          Builder(builder: (_) {
                            final isBsi = widget.role == 'petugas_bsi';
                            final badgeColor = isBsi ? AppColors.dangerAlt : AppColors.green;
                            final prefix = isBsi ? '-' : '+';
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: badgeColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '$prefix${AppNumber.desimal(entry.item)} item',
                                style: AppText.w700(10, badgeColor),
                              ),
                            );
                          }),
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
                                  'Stok Sebelum',
                                  style: AppText.r(9.5, AppColors.darkAlt.withValues(alpha: 0.4)),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  AppNumber.desimal(entry.stokSebelum),
                                  style: AppText.w600(13, AppColors.darkAlt.withValues(alpha: 0.7)),
                                ),
                              ],
                            ),
                          ),
                          Builder(builder: (_) {
                            final arrowColor = widget.role == 'petugas_bsi' ? AppColors.dangerAlt : AppColors.green;
                            return Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: arrowColor.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.arrow_forward_rounded,
                                  size: 16, color: arrowColor),
                            );
                          }),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Stok Sesudah',
                                  style: AppText.r(9.5, AppColors.darkAlt.withValues(alpha: 0.4)),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  AppNumber.desimal(entry.stokSesudah),
                                  style: AppText.w700(13, widget.role == 'petugas_bsi' ? AppColors.dangerAlt : AppColors.green),
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

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Text(
            label,
            style: AppText.r(13, AppColors.darkAlt.withValues(alpha: 0.5)),
          ),
          const Spacer(),
          Text(
            value,
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.w600(13, AppColors.darkAlt),
          ),
        ],
      ),
    );
  }
}
