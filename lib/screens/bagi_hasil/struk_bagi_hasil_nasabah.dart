import 'package:enviroo/models/bagi_hasil_nasabah_model.dart';
import 'package:enviroo/providers/bagi_hasil_provider.dart';
import 'package:enviroo/providers/penjualan_provider.dart' show FetchStatus;
import 'package:provider/provider.dart';
import 'package:enviroo/widgets/topbar_back.dart';
import 'package:flutter/material.dart';
import 'package:enviroo/core/format/app_date.dart';
import 'package:enviroo/core/format/app_number.dart';
import 'package:enviroo/core/theme/app_colors.dart';
import 'package:enviroo/core/theme/app_text.dart';
import 'package:enviroo/widgets/state_message.dart';

class StrukBagiHasilNasabah extends StatefulWidget {
  final String penerimaId;
  const StrukBagiHasilNasabah({super.key, required this.penerimaId});

  @override
  State<StrukBagiHasilNasabah> createState() => _StrukBagiHasilNasabahState();
}

class _StrukBagiHasilNasabahState extends State<StrukBagiHasilNasabah> {

  BagiHasilNasabahDetail? _detail;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchDetail());
  }

  Future<void> _fetchDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final prov = context.read<BagiHasilProvider>();
    await prov.fetchDetailNasabah(widget.penerimaId);
    if (!mounted) return;
    if (prov.nasabahDetailStatus == FetchStatus.success) {
      setState(() {
        _detail = prov.nasabahDetail;
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = prov.nasabahDetailError ?? 'Gagal memuat detail bagi hasil';
        _isLoading = false;
      });
    }
  }

  String _fmtValue(double v, String satuan) =>
      AppNumber.nominalSatuan(v, satuan);

  String _fmtNum(double v) =>
      v == v.truncateToDouble() ? v.toInt().toString() : AppNumber.desimal(v);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
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
              const TopBarBack(title: 'Detail Bagi Hasil Nasabah'),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: AppColors.green))
                    : _error != null
                        ? _buildError()
                        : _buildStruk(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStruk() {
    final d = _detail!;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                width: 1,
                color: AppColors.dark.withValues(alpha: 0.1),
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.green.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.volunteer_activism_rounded,
                    color: AppColors.green,
                    size: 26,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _fmtValue(d.totalDiterima, d.satuanDiterima),
                  style: AppText.p(26, weight: FontWeight.w800, color: AppColors.green, letterSpacing: -0.5),
                ),
                Text(
                  'Total Bagi Hasil Diterima',
                  style: AppText.r(10, AppColors.dark.withValues(alpha: 0.5)),
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.dark.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    AppDate.tanggalPenuhJam(d.tanggal),
                    style: AppText.w500(10, AppColors.dark.withValues(alpha: 0.65)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          _buildInfoCard(d),

          const SizedBox(height: 14),

          if (d.items.isNotEmpty) _buildItemsCard(d, d.satuanDiterima),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BagiHasilNasabahDetail d) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Informasi Penerima'),
          const SizedBox(height: 10),
          _infoRow(Icons.person_rounded, 'Nasabah', d.namaNasabah),
          _divider(),
          _infoRow(Icons.card_giftcard_rounded, 'Reward', d.reward),
          _divider(),
          _infoRow(
            Icons.receipt_long_rounded,
            'ID Transaksi',
            d.penerimaId,
            small: true,
          ),
        ],
      ),
    );
  }

  Widget _buildItemsCard(BagiHasilNasabahDetail d, String satuan) {
    final totalSubtotal =
        d.items.fold(0.0, (sum, item) => sum + item.subtotalHarga);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Rincian Sampah'),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Expanded(
                    flex: 4,
                    child: Text('Item', style: _headerStyle)),
                Expanded(
                    flex: 2,
                    child: Text('Qty',
                        textAlign: TextAlign.center,
                        style: _headerStyle)),
                Expanded(
                    flex: 3,
                    child: Text('Harga',
                        textAlign: TextAlign.right,
                        style: _headerStyle)),
                Expanded(
                    flex: 3,
                    child: Text('Subtotal',
                        textAlign: TextAlign.right,
                        style: _headerStyle)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _dashedDivider(),
          const SizedBox(height: 8),
          ...d.items.map((item) => _buildItemRow(item, satuan)),
          const SizedBox(height: 8),
          _dashedDivider(),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                flex: 6,
                child: Text(
                  'Total Nilai Sampah',
                  style: AppText.w600(12, AppColors.dark),
                ),
              ),
              Expanded(
                flex: 6,
                child: Text(
                  _fmtValue(totalSubtotal, satuan),
                  textAlign: TextAlign.right,
                  style: AppText.w700(13, AppColors.green),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(BagiHasilNasabahDetailItem item, String satuan) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              item.namaSampah,
              style: AppText.r(11, AppColors.dark),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _fmtNum(item.qty),
              textAlign: TextAlign.center,
              style: AppText.r(11, AppColors.dark.withValues(alpha: 0.7)),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              _fmtValue(item.hargaItem, satuan),
              textAlign: TextAlign.right,
              style: AppText.r(11, AppColors.dark.withValues(alpha: 0.7)),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              _fmtValue(item.subtotalHarga, satuan),
              textAlign: TextAlign.right,
              style: AppText.w600(11, AppColors.dark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String label) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: AppColors.green,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: AppText.w700(13, AppColors.dark),
        ),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value,
      {bool small = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppColors.green.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 15, color: AppColors.green),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppText.r(10, AppColors.dark.withValues(alpha: 0.45)),
                ),
                Text(
                  value,
                  style: AppText.w600(small ? 10.5 : 12, AppColors.dark),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Divider(color: AppColors.dark.withValues(alpha: 0.06), height: 1);

  Widget _dashedDivider() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const dashWidth = 6.0;
        const dashSpace = 4.0;
        final count =
            (constraints.maxWidth / (dashWidth + dashSpace)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            count,
            (_) => Container(
              width: dashWidth,
              height: 1,
              color: AppColors.dark.withValues(alpha: 0.12),
            ),
          ),
        );
      },
    );
  }

  TextStyle get _headerStyle => AppText.w600(10, AppColors.dark.withValues(alpha: 0.45));

  Widget _buildError() => StateMessage(
        illustration: StateArt.error,
        message: _error!,
        action: StateRetryButton.pill(onPressed: _fetchDetail),
      );
}
