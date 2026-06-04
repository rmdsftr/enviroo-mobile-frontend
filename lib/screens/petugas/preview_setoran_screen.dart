import 'dart:io';
import 'package:enviroo/providers/auth_provider.dart';
import 'package:enviroo/providers/katalog_provider.dart';
import 'package:enviroo/services/setoran_service.dart';
import 'package:enviroo/widgets/custom_snackbar.dart';
import 'package:enviroo/widgets/topbar_back.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class PreviewSetoranScreen extends StatefulWidget {
  final String penimbanganId;
  final String nasabahId;
  final String nasabahName;
  final String photoUrl;
  final bool dariQr;
  final List<Map<String, dynamic>> items;
  final File? fotoFile;

  const PreviewSetoranScreen({
    super.key,
    required this.penimbanganId,
    required this.nasabahId,
    required this.nasabahName,
    required this.photoUrl,
    required this.dariQr,
    required this.items,
    this.fotoFile,
  });

  @override
  State<PreviewSetoranScreen> createState() => _PreviewSetoranScreenState();
}

class _PreviewSetoranScreenState extends State<PreviewSetoranScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMsg;
  Map<String, dynamic>? _previewData;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchPreview());
  }

  Future<void> _fetchPreview() async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    final res = await SetoranService.previewSetoran(
      widget.penimbanganId,
      widget.nasabahId,
      widget.items,
    );

    if (!mounted) return;

    if (res['success'] == true) {
      setState(() {
        _previewData = res['data'] as Map<String, dynamic>?;
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMsg = res['message'] ?? 'Gagal memuat preview setoran';
        _isLoading = false;
      });
    }
  }

  Future<void> _simpanSetoran() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final adminId = auth.identityId ?? '';

    final res = await SetoranService.inputSetoran(
      widget.penimbanganId,
      widget.nasabahId,
      adminId,
      widget.items,
      viaManual: !widget.dariQr,
      fotoFile: widget.fotoFile,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (res['success'] == true) {
      final setoranId = res['setoran_id'] as String? ?? '';
      Provider.of<KatalogProvider>(context, listen: false)
          .silentRefresh(auth.bankId ?? '');
      Navigator.of(context).pop(setoranId);
    } else {
      showCustomSnackBar(context, res['message'] ?? 'Gagal menyimpan setoran');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F8),
      body: SafeArea(
        child: Column(
          children: [
            TopBarBack(title: 'Preview Setoran'),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFF4EA771)))
                  : _errorMsg != null
                      ? _buildError()
                      : _buildContent(),
            ),
          ],
        ),
      ),
      bottomNavigationBar:
          (_isLoading || _errorMsg != null) ? null : _buildBottomBar(),
    );
  }

  Widget _buildContent() {
    final data = _previewData!;
    final items =
        (data['items'] as List? ?? []).cast<Map<String, dynamic>>();
    final totalItem = (data['total_item'] as num? ?? 0).toInt();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        children: [
          _buildNasabahCard(),
          const SizedBox(height: 16),
          _buildPreviewCard(items, totalItem),
          if (widget.fotoFile != null) ...[
            const SizedBox(height: 16),
            _buildFotoCard(),
          ],
        ],
      ),
    );
  }

  Widget _buildNasabahCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: const Color(0xFF4EA771).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFF4EA771).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
              image: widget.photoUrl.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(widget.photoUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: widget.photoUrl.isEmpty
                ? const Icon(Icons.person_rounded,
                    color: Color(0xFF4EA771), size: 24)
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.nasabahName,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Color(0xFF013236),
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  widget.nasabahId,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: const Color(0xFF013236).withValues(alpha: 0.45),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF4EA771).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.dariQr
                      ? Icons.qr_code_rounded
                      : Icons.person_search_rounded,
                  size: 12,
                  color: const Color(0xFF4EA771),
                ),
                const SizedBox(width: 5),
                Text(
                  widget.dariQr ? 'Via QR' : 'Manual',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4EA771),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFotoCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF4EA771).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF013236).withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.camera_alt_rounded,
                      color: Color(0xFF013236), size: 16),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Bukti Foto Nasabah',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF013236),
                  ),
                ),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(22)),
            child: Image.file(
              widget.fotoFile!,
              width: double.infinity,
              height: 220,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewCard(List<Map<String, dynamic>> items, int totalItem) {
    String fmtQty(double v) {
      if (v == v.truncateToDouble()) return v.toInt().toString();
      return v.toStringAsFixed(2).replaceAll('.', ',');
    }

    Color rewardColor(String jenis) {
      switch (jenis.toLowerCase()) {
        case 'uang':
          return const Color(0xFF27AE60);
        case 'sembako':
          return const Color(0xFF2F80ED);
        default:
          return const Color(0xFF013236);
      }
    }

    return Container(
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
          // ── Header ───────────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(22),
                topRight: Radius.circular(22),
              ),
              border: Border(
                bottom: BorderSide(
                  color: const Color(0xFF013236).withOpacity(0.04),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF013236).withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.receipt_long_rounded,
                      color: Color(0xFF013236), size: 16),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Rincian Setoran',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF013236),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4EA771).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$totalItem jenis',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF013236),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Column headers ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                Expanded(
                    child: Text('Jenis Sampah',
                        style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[500]))),
                SizedBox(
                    width: 72,
                    child: Text('Qty',
                        style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[500]),
                        textAlign: TextAlign.center)),
                SizedBox(
                    width: 66,
                    child: Text('Reward',
                        style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[500]),
                        textAlign: TextAlign.right)),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Divider(height: 12, color: Color(0xFFEEEEEE)),
          ),

          // ── Item rows ─────────────────────────────────────────────────────
          ...items.asMap().entries.map((entry) {
            final i = entry.key;
            final item = entry.value;
            final qty = (item['qty'] as num? ?? 0).toDouble();
            final satuan = item['satuan'] as String? ?? '';
            final jenisReward = item['jenis_reward'] as String? ?? '-';
            final rewardBadgeColor = rewardColor(jenisReward);
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item['nama_sampah'] as String? ?? '-',
                          style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color: Color(0xFF013236)),
                        ),
                      ),
                      SizedBox(
                        width: 72,
                        child: Text(
                          '${fmtQty(qty)} $satuan',
                          style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF013236)),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SizedBox(
                        width: 66,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: rewardBadgeColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              jenisReward,
                              style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: rewardBadgeColor),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (i < items.length - 1)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Divider(height: 1, color: Color(0xFFF5F5F5)),
                  ),
              ],
            );
          }),

          // ── Separator ─────────────────────────────────────────────────────
          _buildPerforated(),

          // ── Total ─────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total Item',
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: Colors.grey[500])),
                Text(
                  '$totalItem jenis',
                  style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF013236)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerforated() {
    return Row(
      children: [
        _halfCircle(isLeft: true),
        Expanded(
          child: LayoutBuilder(
            builder: (_, c) => Flex(
              direction: Axis.horizontal,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                (c.maxWidth / 10).floor(),
                (i) => SizedBox(
                  width: 5,
                  height: 1,
                  child: DecoratedBox(
                      decoration:
                          BoxDecoration(color: Colors.grey[300])),
                ),
              ),
            ),
          ),
        ),
        _halfCircle(isLeft: false),
      ],
    );
  }

  Widget _halfCircle({required bool isLeft}) {
    return Container(
      width: 16,
      height: 32,
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9F8),
        borderRadius: BorderRadius.only(
          topRight:
              isLeft ? const Radius.circular(16) : Radius.zero,
          bottomRight:
              isLeft ? const Radius.circular(16) : Radius.zero,
          topLeft:
              isLeft ? Radius.zero : const Radius.circular(16),
          bottomLeft:
              isLeft ? Radius.zero : const Radius.circular(16),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 56, color: Colors.grey[300]),
            const SizedBox(height: 14),
            Text(
              _errorMsg!,
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _fetchPreview,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Coba Lagi',
                  style: TextStyle(fontFamily: 'Poppins')),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4EA771),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 14, 20, MediaQuery.of(context).padding.bottom + 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF013236).withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Color(0xFF4EA771),
          borderRadius: BorderRadius.circular(30),
        ),
        child: ElevatedButton(
          onPressed: _isSaving ? null : _simpanSetoran,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            disabledForegroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30)),
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5),
                )
              : const Text(
                  'Simpan Setoran Nasabah',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    letterSpacing: 0.2,
                    color: Colors.white
                  ),
                ),
        ),
      ),
    );
  }
}
