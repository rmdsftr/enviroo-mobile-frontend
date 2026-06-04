import 'package:enviroo/screens/admin_bsi/scan_petugas_bsu_screen.dart';
import 'package:enviroo/widgets/topbar_back.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─── Color palette (shared with bagi_hasil & setoran screens) ────────────────

class _C {
  static const dark    = Color(0xFF013236);
  static const green   = Color(0xFF4EA771);
  static const cyan    = Color(0xFF06C0C9);
  static const accent  = Color(0xFF94DF0C);
  static const cardBg  = Color(0xFFF7FBF5);
  static const muted   = Color(0xFF8A9A92);
  static const danger  = Color(0xFFD94848);
  static const border  = Color(0xFFE6EDE9);
  static const warning = Color(0xFFF59E0B);
}

// ─── Models ──────────────────────────────────────────────────────────────────

class PreviewItemPengangkutan {
  final String sampahId;
  final String namaSampah;
  final String namaReward;
  final double qty;
  final double stokBsuSebelum;
  final double stokBsuSetelah;
  final double stokBsiSebelum;
  final double stokBsiSetelah;
  final bool cukupUntukKirim;

  PreviewItemPengangkutan({
    required this.sampahId,
    required this.namaSampah,
    required this.namaReward,
    required this.qty,
    required this.stokBsuSebelum,
    required this.stokBsuSetelah,
    required this.stokBsiSebelum,
    required this.stokBsiSetelah,
    required this.cukupUntukKirim,
  });

  factory PreviewItemPengangkutan.fromJson(Map<String, dynamic> json) =>
      PreviewItemPengangkutan(
        sampahId: json['sampah_id'] ?? '',
        namaSampah: json['nama_sampah'] ?? '-',
        namaReward: json['nama_reward'] ?? '',
        qty: (json['qty'] as num? ?? 0).toDouble(),
        stokBsuSebelum: (json['stok_bsu_sebelum'] as num? ?? 0).toDouble(),
        stokBsuSetelah: (json['stok_bsu_setelah'] as num? ?? 0).toDouble(),
        stokBsiSebelum: (json['stok_bsi_sebelum'] as num? ?? 0).toDouble(),
        stokBsiSetelah: (json['stok_bsi_setelah'] as num? ?? 0).toDouble(),
        cukupUntukKirim: json['cukup_untuk_kirim'] as bool? ?? true,
      );
}

class PreviewPengangkutanData {
  final String pengangkutanId;
  final String bsiId;
  final String namaBsi;
  final String bsuId;
  final String namaBsu;
  final int totalItem;
  final bool adaStokKurang;
  final List<PreviewItemPengangkutan> items;

  PreviewPengangkutanData({
    required this.pengangkutanId,
    required this.bsiId,
    required this.namaBsi,
    required this.bsuId,
    required this.namaBsu,
    required this.totalItem,
    required this.adaStokKurang,
    required this.items,
  });

  factory PreviewPengangkutanData.fromJson(Map<String, dynamic> json) =>
      PreviewPengangkutanData(
        pengangkutanId: json['pengangkutan_id'] ?? '',
        bsiId: json['bsi_id'] ?? '',
        namaBsi: json['nama_bsi'] ?? '-',
        bsuId: json['bsu_id'] ?? '',
        namaBsu: json['nama_bsu'] ?? '-',
        totalItem: (json['total_item'] as num? ?? 0).toInt(),
        adaStokKurang: json['ada_stok_kurang'] as bool? ?? false,
        items: (json['items'] as List? ?? [])
            .map((e) =>
                PreviewItemPengangkutan.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

// ─── Screen ──────────────────────────────────────────────────────────────────

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

  String _fmt(double v) => v == v.truncateToDouble()
      ? v.toInt().toString()
      : v.toStringAsFixed(2).replaceAll('.', ',');

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
          color: Color(0xFFF5F7F5),
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

  // ── Hero card (dark, mirip preview_setoran_screen) ────────────────────────

  Widget _buildHeroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          width: 1,
          color: const Color(0xFF013236).withOpacity(0.1), // Brand color dengan opacity cuma 10%
        ),
      ),
      child: Column(
        children: [
          // Label atas
          Icon(Icons.local_shipping_rounded,
              color: _C.dark.withOpacity(0.3), size: 26),
          const SizedBox(height: 6),
          Text(
            'PREVIEW PENGANGKUTAN SAMPAH',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _C.dark.withOpacity(0.4),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            data.pengangkutanId,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10,
              color: _C.muted,
            ),
          ),
          // DARI → KE
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
                    color: _C.dark.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.east_rounded,
                      size: 14, color: _C.dark),
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
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 8,
            color: _C.muted,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: _C.dark,
          ),
          textAlign: textAlign,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // ── Warning banner ────────────────────────────────────────────────────────

  Widget _buildWarningBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _C.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.warning.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _C.warning.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.warning_amber_rounded,
                size: 14, color: _C.warning),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Ada stok BSU yang tidak mencukupi untuk dikirim',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: _C.warning,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Struk card (putih, gaya receipt) ─────────────────────────────────────

  Widget _buildStrukCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _C.border),
      ),
      child: Column(
        children: [
          // ── Card header
          _buildCardHeader(),
          // ── Column headers
          _buildColHeaders(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Divider(height: 1, color: Color(0xFFF0F0F0)),
          ),
          // ── Item rows
          ...data.items.asMap().entries.expand((e) => [
                _buildItemRow(e.key + 1, e.value),
                if (e.key < data.items.length - 1)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Divider(height: 1, color: Color(0xFFF5F5F5)),
                  ),
              ]),
          // ── Perforated separator
          _buildPerforated(),
          // ── Footer
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
            color: _C.dark.withOpacity(0.05),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _C.dark.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.receipt_long_rounded,
                color: _C.dark, size: 16),
          ),
          const SizedBox(width: 12),
          const Text(
            'Rincian Setoran',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _C.dark,
            ),
          ),
          const Spacer(),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _C.green.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${data.totalItem} jenis',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: _C.green,
              ),
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
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _C.muted)),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text('Nama Sampah',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _C.muted)),
          ),
          Text('Qty',
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: _C.muted)),
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
          // Baris 1: nomor + nama + qty
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 22,
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    '$no.',
                    style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: _C.muted),
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
                      style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _C.dark),
                    ),
                    if (item.namaReward.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _C.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          item.namaReward,
                          style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: _C.green),
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
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: kurang ? _C.danger : _C.dark,
                    ),
                  ),
                  if (satuan.isNotEmpty)
                    Text(satuan,
                        style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 9,
                            color: _C.muted)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Baris 2: stok chip BSU & BSI
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
                    size: 12, color: _C.danger),
                const SizedBox(width: 4),
                const Text(
                  'Stok BSU tidak mencukupi',
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                      color: _C.danger),
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
        ? _C.danger
        : down
            ? _C.muted
            : _C.green;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 8.5,
              fontWeight: FontWeight.w700,
              color: color.withOpacity(0.6),
              letterSpacing: 0.5,
            ),
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
                    color: _C.muted,
                    decoration: TextDecoration.lineThrough,
                    decorationColor: _C.muted),
              ),
              const SizedBox(width: 4),
              Icon(
                  down ? Icons.south_rounded : Icons.north_rounded,
                  size: 9,
                  color: color),
              const SizedBox(width: 2),
              Text(
                _fmt(after),
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color),
              ),
              if (satuan.isNotEmpty) ...[
                const SizedBox(width: 2),
                Text(satuan,
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 9,
                        color: color.withOpacity(0.6))),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ── Perforated separator ──────────────────────────────────────────────────

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
                          BoxDecoration(color: _C.border)),
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
        color: const Color(0xFFF5F7F5),
        borderRadius: BorderRadius.only(
          topRight: left ? const Radius.circular(14) : Radius.zero,
          bottomRight: left ? const Radius.circular(14) : Radius.zero,
          topLeft: left ? Radius.zero : const Radius.circular(14),
          bottomLeft: left ? Radius.zero : const Radius.circular(14),
        ),
      ),
    );
  }

  // ── Footer ────────────────────────────────────────────────────────────────

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Total Jenis Sampah',
            style: TextStyle(
                fontFamily: 'Poppins', fontSize: 12, color: _C.muted),
          ),
          Text(
            '${data.totalItem} item',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _C.dark,
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom bar ────────────────────────────────────────────────────────────

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 14, 20, MediaQuery.of(context).padding.bottom + 14),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: _C.dark.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color : Color(0xFF013236),
          borderRadius: BorderRadius.circular(30),
          // boxShadow: [
          //   BoxShadow(
          //     color: _C.dark.withOpacity(0.3),
          //     blurRadius: 16,
          //     offset: const Offset(0, 6),
          //   ),
          // ],
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
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.save_rounded, size: 18),
              SizedBox(width: 8),
              Text(
                'Simpan Setoran BSU',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  letterSpacing: 0.2,
                  color : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
