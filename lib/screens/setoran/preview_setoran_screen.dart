import 'package:enviroo/core/format/app_number.dart';
import 'dart:io';
import 'package:enviroo/providers/auth_provider.dart';
import 'package:enviroo/providers/katalog_provider.dart';
import 'package:enviroo/screens/petugas/inapp_camera_screen.dart';
import 'package:enviroo/screens/lihat_foto_screen.dart';
import 'package:enviroo/providers/setoran_provider.dart';
import 'package:enviroo/providers/penjualan_provider.dart' show FetchStatus;
import 'package:enviroo/widgets/custom_snackbar.dart';
import 'package:enviroo/widgets/state_message.dart';
import 'package:enviroo/widgets/topbar_back.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:enviroo/core/theme/app_colors.dart';
import 'package:enviroo/core/theme/app_text.dart';

class PreviewSetoranScreen extends StatefulWidget {
  final String penimbanganId;
  final String nasabahId;
  final String nasabahName;
  final String photoUrl;
  final bool dariQr;
  final List<Map<String, dynamic>> items;

  const PreviewSetoranScreen({
    super.key,
    required this.penimbanganId,
    required this.nasabahId,
    required this.nasabahName,
    required this.photoUrl,
    required this.dariQr,
    required this.items,
  });

  @override
  State<PreviewSetoranScreen> createState() => _PreviewSetoranScreenState();
}

class _PreviewSetoranScreenState extends State<PreviewSetoranScreen> {

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMsg;
  Map<String, dynamic>? _previewData;
  File? _fotoBukti;

  bool get _bisaSimpan => widget.dariQr || _fotoBukti != null;

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

    final prov = context.read<SetoranProvider>();
    await prov.fetchPreview(
      widget.penimbanganId,
      widget.nasabahId,
      widget.items,
    );

    if (!mounted) return;

    if (prov.previewStatus == FetchStatus.success) {
      setState(() {
        _previewData = prov.preview;
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMsg = prov.previewError ?? 'Gagal memuat preview setoran';
        _isLoading = false;
      });
    }
  }

  Future<void> _ambilFoto() async {
    final file = await Navigator.push<File?>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const InAppCameraScreen(
          hint: 'Ambil foto nasabah sebagai bukti kehadiran',
        ),
      ),
    );
    if (file == null || !mounted) return;
    setState(() => _fotoBukti = file);
  }

  void _lihatFotoFull() {
    final foto = _fotoBukti;
    if (foto == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LihatFotoScreen(
          photoFile: foto,
          nama: 'Bukti Foto Nasabah',
        ),
      ),
    );
  }

  Future<void> _simpanSetoran() async {
    if (_isSaving || !_bisaSimpan) return;
    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final adminId = auth.identityId ?? '';

    final res = await context.read<SetoranProvider>().inputSetoran(
          widget.penimbanganId,
          widget.nasabahId,
          adminId,
          widget.items,
          viaManual: !widget.dariQr,
          fotoFile: _fotoBukti,
        );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (res['success'] == true) {
      final setoranId = res['setoran_id'] as String? ?? '';
      Provider.of<KatalogProvider>(context, listen: false)
          .silentRefresh(auth.bankId ?? '');

      showCustomSnackBar(context, 'Setoran sampah nasabah berhasil disimpan',
          type: SnackBarType.success);

      Navigator.of(context).pop(setoranId);
    } else {
      showCustomSnackBar(context, res['message'] ?? 'Gagal menyimpan setoran');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceCool,
      body: SafeArea(
        child: Column(
          children: [
            TopBarBack(title: 'Preview Setoran'),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.green))
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
          if (!widget.dariQr) ...[
            const SizedBox(height: 16),
            _buildFotoSection(),
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
        border: Border.all(color: AppColors.green.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.green.withValues(alpha: 0.12),
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
                    color: AppColors.green, size: 24)
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.nasabahName,
                  style: AppText.w700(14, AppColors.dark),
                ),
                const SizedBox(height: 1),
                Text(
                  widget.nasabahId,
                  style: AppText.r(11, AppColors.dark.withValues(alpha: 0.45)),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.green.withValues(alpha: 0.12),
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
                  color: AppColors.green,
                ),
                const SizedBox(width: 5),
                Text(
                  widget.dariQr ? 'Via QR' : 'Manual',
                  style: AppText.w600(10, AppColors.green),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFotoSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.green.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.dark.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.camera_alt_rounded,
                    color: AppColors.dark, size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Bukti Foto Nasabah',
                  style: AppText.w700(14, AppColors.dark),
                ),
              ),
              if (_fotoBukti == null)
                Text(
                  'Wajib',
                  style: AppText.w600(11, Colors.red),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _buildFotoContainer(),
        ],
      ),
    );
  }

  Widget _buildFotoContainer() {
    return GestureDetector(
      onTap: _fotoBukti == null ? _ambilFoto : null,
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: Container(
          decoration: BoxDecoration(
            color: _fotoBukti == null ? AppColors.surface : Colors.black,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _fotoBukti == null
                  ? AppColors.dark.withValues(alpha: 0.15)
                  : Colors.transparent,
              width: 1.5,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: _fotoBukti == null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt_rounded,
                        size: 32, color: AppColors.dark.withValues(alpha: 0.35)),
                    const SizedBox(height: 8),
                    Text(
                      'Ambil Foto Bukti Nasabah',
                      style: AppText.w600(12.5, AppColors.dark.withValues(alpha: 0.45)),
                    ),
                  ],
                )
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(_fotoBukti!, fit: BoxFit.cover),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Row(
                        children: [
                          _overlayIconButton(
                              Icons.fullscreen_rounded, _lihatFotoFull),
                          const SizedBox(width: 8),
                          _overlayIconButton(
                              Icons.replay_rounded, _ambilFoto),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _overlayIconButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }

  Widget _buildPreviewCard(List<Map<String, dynamic>> items, int totalItem) {
    String fmtQty(double v) => AppNumber.desimal(v);

    Color rewardColor(String jenis) {
      switch (jenis.toLowerCase()) {
        case 'uang':
          return const Color(0xFF27AE60);
        case 'barang':
          return const Color(0xFF2F80ED);
        default:
          return AppColors.dark;
      }
    }

    return Container(
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
                  color: AppColors.dark.withValues(alpha: 0.04),
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
                  style: AppText.w700(14, AppColors.dark),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$totalItem jenis',
                    style: AppText.w700(11, AppColors.dark),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                Expanded(
                    child: Text('Jenis Sampah',
                        style: AppText.w600(10.5, Colors.grey[500]))),
                SizedBox(
                    width: 72,
                    child: Text('Qty',
                        style: AppText.w600(10.5, Colors.grey[500]),
                        textAlign: TextAlign.center)),
                SizedBox(
                    width: 66,
                    child: Text('Reward',
                        style: AppText.w600(10.5, Colors.grey[500]),
                        textAlign: TextAlign.right)),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Divider(height: 12, color: Color(0xFFEEEEEE)),
          ),

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
                          style: AppText.r(12, AppColors.dark),
                        ),
                      ),
                      SizedBox(
                        width: 72,
                        child: Text(
                          '${fmtQty(qty)} $satuan',
                          style: AppText.w600(12, AppColors.dark),
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
                              style: AppText.w600(10, rewardBadgeColor),
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

          _buildPerforated(),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total Item',
                    style: AppText.r(12, Colors.grey[500])),
                Text(
                  '$totalItem jenis',
                  style: AppText.w700(13, AppColors.dark),
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
        color: AppColors.surfaceCool,
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

  Widget _buildError() => StateMessage(
        illustration: StateArt.error,
        message: _errorMsg!,
        action: StateRetryButton.icon(
          onPressed: () => Navigator.of(context).pop(),
          label: 'Ubah Item Setoran',
          icon: Icons.arrow_back_rounded,
        ),
      );

  Widget _buildBottomBar() {
    final disabled = _isSaving || !_bisaSimpan;
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 14, 20, MediaQuery.of(context).padding.bottom + 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: AppColors.dark.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!widget.dariQr && _fotoBukti == null) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                'Ambil foto bukti nasabah dulu sebelum menyimpan setoran.',
                style: AppText.r(11, AppColors.dark.withValues(alpha: 0.5)),
              ),
            ),
          ],
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: disabled ? Colors.grey.shade300 : AppColors.green,
              borderRadius: BorderRadius.circular(30),
            ),
            child: ElevatedButton(
              onPressed: disabled ? null : _simpanSetoran,
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
                  : Text(
                      'Simpan Setoran Nasabah',
                      style: AppText.p(13, weight: FontWeight.w600, color: Colors.white, letterSpacing: 0.2),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
