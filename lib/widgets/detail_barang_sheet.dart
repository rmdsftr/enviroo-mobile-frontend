import 'package:enviroo/models/katalog_model.dart';
import 'package:enviroo/providers/sembako_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class _C {
  static const dark   = Color(0xFF0D3B3E);
  static const accent = Color(0xFF4EA771);
  static const red    = Color(0xFFE53935);
}

class DetailSembakoSheet extends StatefulWidget {
  final String role;
  final bool showRiwayat;
  const DetailSembakoSheet({super.key, required this.role, this.showRiwayat = true});

  @override
  State<DetailSembakoSheet> createState() => _DetailSembakoSheetState();
}

class _DetailSembakoSheetState extends State<DetailSembakoSheet>
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
      child: Consumer<SembakoProvider>(
        builder: (context, sembako, _) {
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
              if (sembako.isDetailLoading)
                const Expanded(
                  child: Center(child: CircularProgressIndicator(color: _C.accent)),
                )
              else if (sembako.currentDetail == null)
                Expanded(
                  child: Center(
                    child: Text(
                      'Data tidak tersedia',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: _C.dark.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                )
              else
                _buildContent(sembako.currentDetail!),
            ],
          );
        },
      ),
    );
  }

  Widget _buildContent(DetailSembakoWithRiwayat detail) {
    return Expanded(
      child: Column(
        children: [
          _buildHeader(detail.sembako),

          if (_hasTabs) ...[
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
                unselectedLabelColor: _C.dark.withValues(alpha: 0.5),
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
                  Tab(height: 34, text: 'Informasi'),
                  Tab(height: 34, text: 'Riwayat'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildInfoTab(detail.sembako),
                  _buildRiwayatTab(detail.riwayatDistribusi),
                ],
              ),
            ),
          ] else ...[
            Expanded(child: _buildInfoTab(detail.sembako)),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(KatalogSembakoModel item) {
    return Padding(
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
            child: item.photoUrl.isNotEmpty
                ? Image.network(
                    item.photoUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.storefront_rounded,
                      color: _C.accent.withValues(alpha: 0.4),
                      size: 22,
                    ),
                  )
                : Icon(
                    Icons.storefront_rounded,
                    color: _C.accent.withValues(alpha: 0.4),
                    size: 22,
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.namaSembako,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _C.dark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'ID: ${item.sembakoId}',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    color: _C.dark.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTab(KatalogSembakoModel item) {
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
              _infoRow('Nama Barang', item.namaSembako),
              Divider(height: 1, color: Colors.grey.shade200),
              _infoRow('ID Barang', item.sembakoId),
              Divider(height: 1, color: Colors.grey.shade200),
              _infoRow('Nilai Poin per Item', '${_formatDouble(item.nilaiPoin)} poin'),
              Divider(height: 1, color: Colors.grey.shade200),
              _infoRow('Stok Tersedia', '${_formatDouble(item.stok)} item'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRiwayatTab(List<RiwayatDistribusiSembakoModel> riwayat) {
    if (riwayat.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_shipping_rounded,
                size: 40, color: _C.dark.withValues(alpha: 0.15)),
            const SizedBox(height: 8),
            Text(
              'Belum ada riwayat distribusi',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: _C.dark.withValues(alpha: 0.4),
              ),
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
                        color: isFirst ? _C.accent : Colors.grey.shade300,
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
                        ? _C.accent.withValues(alpha: 0.06)
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isFirst
                          ? _C.accent.withValues(alpha: 0.15)
                          : Colors.grey.shade200,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.calendar_today_rounded,
                              size: 13, color: _C.dark.withValues(alpha: 0.4)),
                          const SizedBox(width: 6),
                          Text(
                            DateFormat('dd MMM yyyy, HH:mm')
                                .format(entry.tanggalKirim),
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 10,
                              color: _C.dark.withValues(alpha: 0.5),
                            ),
                          ),
                          const Spacer(),
                          Builder(builder: (_) {
                            final isBsi = widget.role == 'petugas_bsi';
                            final badgeColor = isBsi ? _C.red : _C.accent;
                            final prefix = isBsi ? '-' : '+';
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: badgeColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '$prefix${_formatDouble(entry.item)} item',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: badgeColor,
                                ),
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
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 9.5,
                                    color: _C.dark.withValues(alpha: 0.4),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _formatDouble(entry.stokSebelum),
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: _C.dark.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Builder(builder: (_) {
                            final arrowColor = widget.role == 'petugas_bsi' ? _C.red : _C.accent;
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
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 9.5,
                                    color: _C.dark.withValues(alpha: 0.4),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _formatDouble(entry.stokSesudah),
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: widget.role == 'petugas_bsi' ? _C.red : _C.accent,
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

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: _C.dark.withValues(alpha: 0.5),
            ),
          ),
          const Spacer(),
          Text(
            value,
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _C.dark,
            ),
          ),
        ],
      ),
    );
  }
}
