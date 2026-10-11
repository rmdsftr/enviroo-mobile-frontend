import 'package:enviroo/models/penimbangan_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:enviroo/providers/penimbangan_provider.dart';
import 'package:enviroo/screens/penimbangan/scanner_penimbangan_screen.dart';
import 'package:enviroo/screens/setoran/detail_setoran_screen.dart';
import 'package:enviroo/widgets/custom_snackbar.dart';
import 'package:enviroo/widgets/topbar_back.dart';
import 'package:enviroo/core/theme/app_colors.dart';
import 'package:enviroo/core/theme/app_text.dart';
import 'package:enviroo/widgets/state_message.dart';

class PenimbanganAktifScreen extends StatefulWidget {
  final String penimbanganId;

  const PenimbanganAktifScreen({super.key, required this.penimbanganId});

  @override
  State<PenimbanganAktifScreen> createState() => _PenimbanganAktifScreenState();
}

class _PenimbanganAktifScreenState extends State<PenimbanganAktifScreen> {
  bool _isLoading = true;
  bool _actionLoading = false;
  bool _isExpanded = false;
  SesiPenimbanganAktif? _sesi;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
  }

  Future<void> _fetch() async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });
    final prov = context.read<PenimbanganProvider>();
    await prov.fetchDetail(widget.penimbanganId);
    if (!mounted) return;

    if (prov.detail != null) {
      setState(() {
        _sesi = prov.detail;
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMsg = prov.detailError ?? 'Gagal memuat data sesi';
        _isLoading = false;
      });
    }
  }

  Future<void> _updateSesi(String status) async {
    setState(() => _actionLoading = true);

    final res = await context
        .read<PenimbanganProvider>()
        .updateStatus(widget.penimbanganId, status);
    if (!mounted) return;
    setState(() => _actionLoading = false);

    if (res['success'] == true) {
      Navigator.pop(context, true);
    } else {
      _snackBar(res['message'] ?? 'Gagal memperbarui sesi', isError: true);
    }
  }

  void _snackBar(String msg, {bool isError = false}) {
    showCustomSnackBar(context, msg,
        type: isError ? SnackBarType.error : SnackBarType.success);
  }

  void _showKonfirmasi(String status) {
    final isSelesai = status == 'selesai';

    final IconData icon     = isSelesai ? Icons.check_circle_outline_rounded : Icons.cancel_outlined;
    final Color iconBg      = isSelesai ? AppColors.mintPale : const Color(0xFFFFEEEA);
    final Color iconColor   = isSelesai ? AppColors.green : const Color(0xFFFF5A36);
    final String title      = isSelesai ? 'Tutup Sesi Penimbangan' : 'Batalkan Penimbangan';
    final String subtitle   = isSelesai
        ? 'Apakah sesi penimbangan ini sudah benar-benar selesai?'
        : 'Apakah Anda yakin ingin membatalkan sesi ini?\nSemua data akan dihapus.';
    final String labelAksi  = isSelesai ? 'Ya, Tutup' : 'Ya, Batalkan';
    final Color colorAksi   = isSelesai ? AppColors.green : const Color(0xFFFF5A36);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36, height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: AppText.w700(15, AppColors.dark),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AppText.p(12, color: AppColors.dark.withValues(alpha: 0.5), height: 1.6),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.dark,
                      side: BorderSide(color: AppColors.dark.withValues(alpha: 0.25)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                    ),
                    child: Text('Tidak', style: AppText.w600(13)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _updateSesi(status);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorAksi,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                    ),
                    child: Text(labelAksi, style: AppText.w600(13)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceCool,
      body: SafeArea(
        child: Column(
          children: [
            TopBarBack(title: 'Sesi Penimbangan Aktif'),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.green))
                  : _errorMsg != null
                      ? _buildError()
                      : RefreshIndicator(
                          onRefresh: _fetch,
                          color: AppColors.green,
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding:
                                const EdgeInsets.fromLTRB(20, 16, 20, 32),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildHeaderCard(),
                                const SizedBox(height: 16),
                                _buildScannerButton(),
                                const SizedBox(height: 28),
                                _buildSetoranSection(),
                                const SizedBox(height: 24),
                                _buildActionButtons(),
                              ],
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    final s = _sesi!;
    return Container(
      width: double.infinity,
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
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sesi Penimbangan',
                      style: AppText.w700(15, AppColors.dark),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'ID: ${s.penimbanganId}',
                      style: AppText.w500(11, AppColors.dark.withValues(alpha: 0.55)),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'AKTIF',
                        style: AppText.w700(10, AppColors.green),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.divider),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
            child: Column(
              children: [
                _infoRow(
                    Icons.account_balance_rounded, 'Bank Sampah', s.namaBank),
                const SizedBox(height: 12),
                _infoRow(
                    Icons.calendar_today_rounded, 'Dibuka', s.startedAt),
                const SizedBox(height: 12),
                _infoRow(Icons.person_rounded, 'Sesi dibuka oleh', s.startedBy),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: AppColors.green.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: AppColors.green),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppText.r(10.5, Colors.grey[500]),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: AppText.w600(13, AppColors.dark),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScannerButton() {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              ScannerPenimbanganScreen(penimbanganId: widget.penimbanganId),
        ),
      ).then((_) => _fetch()),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: AppColors.dark,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Text(
              'Scanner Penyetoran Nasabah',
              style: AppText.w600(13, Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSetoranSection() {
    final list = _sesi!.listSetoran;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
              child: Text(
                'Setoran Masuk',
                style: AppText.w700(13, AppColors.dark),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                color: list.isEmpty
                    ? Colors.grey.shade100
                    : AppColors.dark.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${list.length}',
                style: AppText.w700(11, list.isEmpty
                      ? Colors.grey.shade400
                      : AppColors.dark),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (list.isEmpty)
          _buildEmptySetoran()
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _buildSetoranTile(list[i]),
          ),
      ],
    );
  }

  Widget _buildEmptySetoran() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          width: 1,
          color: AppColors.dark.withValues(alpha: 0.1),
        ),
      ),
      child: const StateMessage(
        illustration: StateArt.empty,
        illustrationWidth: 80,
        padding: EdgeInsets.symmetric(horizontal: 24),
        message: 'Belum ada setoran',
        subtitle: 'Tap "Scanner" untuk mulai mencatat setoran',
      ),
    );
  }

  Widget _buildSetoranTile(PenimbanganSetoranItem item) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DetailSetoranScreen(setoranId: item.setoranId),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            width: 1,
            color: AppColors.dark.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.green.withValues(alpha: 0.07),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_rounded,
                  size: 20, color: AppColors.green),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.namaNasabah,
                    style: AppText.w600(13, AppColors.dark),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Pukul ${item.waktuFmt}',
                    style: AppText.r(11, Colors.grey[500]),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: Colors.grey[350], size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return GestureDetector(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
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
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: AppColors.dark,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Penimbangan selesai?',
                      style: AppText.w500(12, AppColors.dark),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 22,
                      color: AppColors.dark,
                    ),
                  ),
                ],
              ),
            ),

            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              child: _isExpanded
                  ? Column(
                      children: [
                        const Divider(height: 1, color: AppColors.divider),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                          child: _actionLoading
                              ? const Center(
                                  child: Padding(
                                    padding:
                                        EdgeInsets.symmetric(vertical: 8),
                                    child: CircularProgressIndicator(
                                        color: AppColors.green,
                                        strokeWidth: 2.5),
                                  ),
                                )
                              : SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: () =>
                                        _showKonfirmasi('selesai'),
                                    icon: const Icon(
                                        Icons.check_circle_outline_rounded,
                                        size: 15,
                                        color: AppColors.dark),
                                    label: Text(
                                      'Tutup Sesi Penimbangan',
                                      style: AppText.w600(12, AppColors.dark),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(
                                          color: AppColors.dark),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(50)),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                    ),
                                  ),
                                ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() => StateMessage(
        illustration: StateArt.error,
        message: _errorMsg!,
        action: StateRetryButton.icon(onPressed: _fetch),
      );
}
