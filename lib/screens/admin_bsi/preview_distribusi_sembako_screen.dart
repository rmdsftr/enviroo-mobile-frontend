import 'package:enviroo/models/katalog_model.dart';
import 'package:enviroo/providers/sembako_provider.dart';
import 'package:enviroo/screens/admin_bsi/scanner_distribusi_bsu_screen.dart';
import 'package:enviroo/widgets/topbar_back.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class _C {
  static const dark  = Color(0xFF013236);
  static const green = Color(0xFF4EA771);
  static const cyan  = Color(0xFF06C0C9);
}

class PreviewDistribusiSembakoScreen extends StatelessWidget {
  final String bsiId;
  final String bsuId;
  final String namaBsu;

  const PreviewDistribusiSembakoScreen({
    super.key,
    required this.bsiId,
    required this.bsuId,
    required this.namaBsu,
  });

  String _fmt(int v) =>
      v.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');

  Future<void> _lanjutScan(BuildContext context) async {
    HapticFeedback.mediumImpact();
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => ScannerDistribusiBsuScreen(
          bsiId: bsiId,
          bsuId: bsuId,
          namaBsu: namaBsu,
        ),
      ),
    );
    if (!context.mounted) return;
    if (result != null) Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SembakoProvider>(
      builder: (context, sembako, _) {
        return Scaffold(
          bottomNavigationBar: _buildBottomBar(context),
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
                  const TopBarBack(title: 'Preview Distribusi Sembako'),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 30),
                      child: Column(
                        children: [
                          _buildHeroCard(),
                          const SizedBox(height: 16),
                          _buildItemsCard(sembako.previewItems),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF013236).withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _C.green.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.inventory_2_rounded, color: _C.green, size: 36),
          ),
          const SizedBox(height: 12),
          const Text(
            'Preview Distribusi Sembako',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              fontSize: 17,
              color: _C.green,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Didistribusikan ke',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              color: Color(0xFF888888),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
            decoration: BoxDecoration(
              color: Color(0xFF4EA771).withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    namaBsu,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4EA771),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsCard(List<PreviewDistribusiItemModel> items) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF013236).withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Daftar Item',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: _C.dark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: _C.dark.withValues(alpha: 0.07), height: 1),
          const SizedBox(height: 12),
          ...items.asMap().entries.map((entry) {
            final isLast = entry.key == items.length - 1;
            return Column(
              children: [
                _buildItemRow(entry.value),
                if (!isLast) ...[
                  const SizedBox(height: 12),
                  Divider(color: _C.dark.withValues(alpha: 0.06), height: 1),
                  const SizedBox(height: 12),
                ],
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildItemRow(PreviewDistribusiItemModel item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.namaSembako,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _C.dark,
                    ),
                  ),
                  if (item.bsuItemBaru) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Color(0xFF4EA771).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Item baru di BSU',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4EA771),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _fmt(item.stokKirim),
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF4EA771),
                    height: 1.0,
                  ),
                ),
                const Text(
                  'item',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    color: Color(0xFF999999),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _buildStokChip(label: 'Stok BSI', before: item.stokBsiSebelum, after: item.stokBsiSesudah, down: true)),
            const SizedBox(width: 8),
            Expanded(child: _buildStokChip(label: 'Stok BSU', before: item.stokBsuSebelum, after: item.stokBsuSesudah, down: false)),
          ],
        ),
      ],
    );
  }

  Widget _buildStokChip({
    required String label,
    required int before,
    required int after,
    required bool down,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7F5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: Color(0xFFAAAAAA),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _fmt(before),
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  color: Color(0xFFBBBBBB),
                  decoration: TextDecoration.lineThrough,
                  decorationColor: Color(0xFFBBBBBB),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                down ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                size: 10,
                color: down ? Colors.red.shade300 : _C.green,
              ),
              const SizedBox(width: 3),
              Text(
                _fmt(after),
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _C.dark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 14, 20, MediaQuery.of(context).padding.bottom + 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: _C.dark.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: () => _lanjutScan(context),
        icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
        label: const Text(
          'Kirim Distribusi Sembako',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _C.dark,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
          elevation: 0,
        ),
      ),
    );
  }
}
