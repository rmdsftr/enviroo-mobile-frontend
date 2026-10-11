import 'package:enviroo/core/format/app_number.dart';
import 'package:enviroo/models/pengangkutan_bsi_model.dart';
import 'package:enviroo/screens/pengangkutan/scan_petugas_bsu_screen.dart';
import 'package:enviroo/widgets/topbar_back.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:enviroo/core/theme/app_colors.dart';
import 'package:enviroo/core/theme/app_text.dart';


class PreviewSetoranBsuScreen extends StatelessWidget {
  final PreviewPengangkutanData data;
  final List<Map<String, dynamic>> items;
  final String adminBsuIdAwal;

  const PreviewSetoranBsuScreen({
    super.key,
    required this.data,
    required this.items,
    this.adminBsuIdAwal = '',
  });

  String _fmt(double v) => AppNumber.desimal(v);

  String _satuanFor(String sampahId) {
    for (final item in items) {
      if (item['sampah_id'] == sampahId) return item['satuan'] as String? ?? '';
    }
    return '';
  }

  Future<void> _simpan(BuildContext context) async {
    HapticFeedback.mediumImpact();
    final hasil = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ScanPetugasBsuScreen(
          pengangkutanId: data.pengangkutanId,
          namaBsu: data.namaBsu,
          bsuId: data.bsuId,
          items: items,
          adminBsuIdAwal: adminBsuIdAwal,
        ),
      ),
    );
    if (!context.mounted) return;
    if (hasil == true) Navigator.pop(context, data.pengangkutanId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          image: DecorationImage(
            image: AssetImage('assets/images/bg_struk.webp'),
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const TopBarBack(title: 'Preview Setoran BSU'),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Column(
                    children: [
                      _buildHeroCard(),
                      const SizedBox(height: 16),
                      if (data.adaStokKurang) ...[
                        _buildWarningBanner(),
                        const SizedBox(height: 12),
                      ],
                      _buildStrukCard(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          width: 1,
          color: AppColors.dark.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.local_shipping_rounded,
              color: AppColors.dark.withValues(alpha: 0.3), size: 26),
          const SizedBox(height: 6),
          Text(
            'PREVIEW PENGANGKUTAN SAMPAH',
            style: AppText.w700(12, AppColors.dark.withValues(alpha: 0.4)),
          ),
          const SizedBox(height: 3),
          Text(
            data.pengangkutanId,
            style: AppText.r(10, AppColors.muted),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _heroInfoCol(
                  label: 'DARI',
                  value: data.namaBsu,
                  align: CrossAxisAlignment.start,
                  textAlign: TextAlign.left,
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.dark.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.east_rounded,
                      size: 14, color: AppColors.dark),
                ),
              ),
              Expanded(
                child: _heroInfoCol(
                  label: 'KE',
                  value: data.namaBsi,
                  align: CrossAxisAlignment.end,
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroInfoCol({
    required String label,
    required String value,
    required CrossAxisAlignment align,
    required TextAlign textAlign,
  }) {
    return Column(
      crossAxisAlignment: align,
      children: [
        Text(
          label,
          style: AppText.p(8, color: AppColors.muted, letterSpacing: 1.4),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppText.w700(13, AppColors.dark),
          textAlign: textAlign,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildWarningBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.warning_amber_rounded,
                size: 14, color: AppColors.warning),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Ada stok BSU yang tidak mencukupi untuk dikirim',
              style: AppText.w500(11.5, AppColors.warning),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStrukCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _buildCardHeader(),
          _buildColHeaders(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Divider(height: 1, color: AppColors.divider),
          ),
          ...data.items.asMap().entries.expand((e) => [
                _buildItemRow(e.key + 1, e.value),
                if (e.key < data.items.length - 1)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Divider(height: 1, color: Color(0xFFF5F5F5)),
                  ),
              ]),
          _buildPerforated(),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildCardHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.dark.withValues(alpha: 0.05),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.dark.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.receipt_long_rounded,
                color: AppColors.dark, size: 16),
          ),
          const SizedBox(width: 12),
          Text(
            'Rincian Setoran',
            style: AppText.w600(14, AppColors.dark),
          ),
          const Spacer(),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.green.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${data.totalItem} jenis',
              style: AppText.w700(10, AppColors.green),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColHeaders() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            child: Text('#',
                style: AppText.w600(10, AppColors.muted)),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text('Nama Sampah',
                style: AppText.w600(10, AppColors.muted)),
          ),
          Text('Qty',
              style: AppText.w600(10, AppColors.muted)),
        ],
      ),
    );
  }

  Widget _buildItemRow(int no, PreviewItemPengangkutan item) {
    final satuan = _satuanFor(item.sampahId);
    final kurang = !item.cukupUntukKirim;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 22,
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    '$no.',
                    style: AppText.r(11, AppColors.muted),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.namaSampah,
                      style: AppText.w600(13, AppColors.dark),
                    ),
                    if (item.namaReward.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          item.namaReward,
                          style: AppText.w600(9, AppColors.green),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _fmt(item.qty),
                    style: AppText.w700(15, kurang ? AppColors.dangerSoft : AppColors.dark),
                  ),
                  if (satuan.isNotEmpty)
                    Text(satuan,
                        style: AppText.r(9, AppColors.muted)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const SizedBox(width: 28),
              Expanded(
                child: _buildStokChip(
                  label: 'Stok BSU',
                  before: item.stokBsuSebelum,
                  after: item.stokBsuSetelah,
                  satuan: satuan,
                  down: true,
                  insufficient: kurang,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStokChip(
                  label: 'Stok BSI',
                  before: item.stokBsiSebelum,
                  after: item.stokBsiSetelah,
                  satuan: satuan,
                  down: false,
                  insufficient: false,
                ),
              ),
            ],
          ),
          if (kurang) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const SizedBox(width: 28),
                const Icon(Icons.error_outline_rounded,
                    size: 12, color: AppColors.dangerSoft),
                const SizedBox(width: 4),
                Text(
                  'Stok BSU tidak mencukupi',
                  style: AppText.w500(10.5, AppColors.dangerSoft),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStokChip({
    required String label,
    required double before,
    required double after,
    required String satuan,
    required bool down,
    required bool insufficient,
  }) {
    final Color color = insufficient
        ? AppColors.dangerSoft
        : down
            ? AppColors.muted
            : AppColors.green;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppText.p(8.5, weight: FontWeight.w700, color: color.withValues(alpha: 0.6), letterSpacing: 0.5),
          ),
          const SizedBox(height: 3),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _fmt(before),
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    color: AppColors.muted,
                    decoration: TextDecoration.lineThrough,
                    decorationColor: AppColors.muted),
              ),
              const SizedBox(width: 4),
              Icon(
                  down ? Icons.south_rounded : Icons.north_rounded,
                  size: 9,
                  color: color),
              const SizedBox(width: 2),
              Text(
                _fmt(after),
                style: AppText.w700(11, color),
              ),
              if (satuan.isNotEmpty) ...[
                const SizedBox(width: 2),
                Text(satuan,
                    style: AppText.r(9, color.withValues(alpha: 0.6))),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPerforated() {
    return Row(
      children: [
        _halfCircle(left: true),
        Expanded(
          child: LayoutBuilder(
            builder: (_, c) => Flex(
              direction: Axis.horizontal,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                (c.maxWidth / 10).floor(),
                (_) => SizedBox(
                  width: 5,
                  height: 1,
                  child: DecoratedBox(
                      decoration:
                          BoxDecoration(color: AppColors.border)),
                ),
              ),
            ),
          ),
        ),
        _halfCircle(left: false),
      ],
    );
  }

  Widget _halfCircle({required bool left}) {
    return Container(
      width: 16,
      height: 28,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.only(
          topRight: left ? const Radius.circular(14) : Radius.zero,
          bottomRight: left ? const Radius.circular(14) : Radius.zero,
          topLeft: left ? Radius.zero : const Radius.circular(14),
          bottomLeft: left ? Radius.zero : const Radius.circular(14),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Total Jenis Sampah',
            style: AppText.r(12, AppColors.muted),
          ),
          Text(
            '${data.totalItem} item',
            style: AppText.w700(14, AppColors.dark),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 14, 20, MediaQuery.of(context).padding.bottom + 14),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.dark.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color : AppColors.dark,
          borderRadius: BorderRadius.circular(30),
        ),
        child: ElevatedButton(
          onPressed: () => _simpan(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 13),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.save_rounded, size: 18),
              SizedBox(width: 8),
              Text(
                'Simpan Setoran BSU',
                style: AppText.p(13, weight: FontWeight.w600, color: Colors.white, letterSpacing: 0.2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
