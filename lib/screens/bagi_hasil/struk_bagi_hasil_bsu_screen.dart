import 'package:enviroo/models/bagi_hasil_bsu_model.dart';
import 'package:enviroo/services/bagi_hasil_service.dart';
import 'package:enviroo/widgets/topbar_back.dart';
import 'package:flutter/material.dart';
import 'package:enviroo/core/format/app_date.dart';
import 'package:enviroo/core/format/app_number.dart';
import 'package:enviroo/core/theme/app_colors.dart';
import 'package:enviroo/core/theme/app_text.dart';
import 'package:enviroo/widgets/state_message.dart';

class StrukBagiHasilBsuScreen extends StatefulWidget {
  final String penerimaSisaId;
  const StrukBagiHasilBsuScreen({super.key, required this.penerimaSisaId});

  @override
  State<StrukBagiHasilBsuScreen> createState() =>
      _StrukBagiHasilBsuScreenState();
}

class _StrukBagiHasilBsuScreenState extends State<StrukBagiHasilBsuScreen> {

  DistribusiSisaBsuDetail? _detail;
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

    final res = await BagiHasilService.getDetailDistribusiSisaBsu(widget.penerimaSisaId);
    if (!mounted) return;
    if (res['success'] == true) {
      setState(() {
        _detail = DistribusiSisaBsuDetail.fromJson(res['data'] as Map<String, dynamic>);
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = res['message'] ?? 'Gagal memuat detail distribusi sisa';
        _isLoading = false;
      });
    }
  }

  String _fmtNominal(double val, String satuan) =>
      AppNumber.nominalSatuan(val, satuan);

  String _fmtNum(double v) => AppNumber.desimal(v);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              const TopBarBack(title: 'Detail Distribusi Sisa BSU'),
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
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      child: Column(
        children: [
          _buildHero(d),
          const SizedBox(height: 16),

          _buildInfoCard(d),

          if (d.perhitunganSisa.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildPerhitunganCard(d),
          ],
        ],
      ),
    );
  }

  Widget _buildHero(DistribusiSisaBsuDetail d) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.green.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.account_balance_wallet_rounded,
                color: AppColors.green, size: 36),
          ),
          const SizedBox(height: 12),
          Text(
            d.namaBank,
            textAlign: TextAlign.center,
            style: AppText.w700(16, AppColors.dark),
          ),
          const SizedBox(height: 4),
          Text(
            _fmtNominal(d.nominalDiterima, d.satuanNominal),
            style: AppText.p(26, weight: FontWeight.w800, color: AppColors.green, letterSpacing: -0.5),
          ),
          Text(
            'ID: ${d.penerimaSisaId}',
            textAlign: TextAlign.center,
            style: AppText.r(10, AppColors.dark.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 10),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.dark.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              AppDate.tanggalPenuhJam(d.tanggalDistribusi),
              style: AppText.w500(10, AppColors.dark.withValues(alpha: 0.65)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(DistribusiSisaBsuDetail d) {
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
          _sectionTitle('Informasi'),
          const SizedBox(height: 10),
          _infoRow(Icons.pie_chart_rounded, 'Porsi Bagi Hasil',
              _fmtNominal(d.porsi, d.satuanNominal)),
          _divider(),
          _infoRow(Icons.local_shipping_rounded, 'Biaya Transportasi',
              _fmtNominal(d.transportasi, d.satuanNominal)),
          _divider(),
          _infoRow(Icons.account_balance_wallet_rounded, 'Nominal Diterima',
              _fmtNominal(d.nominalDiterima, d.satuanNominal)),
        ],
      ),
    );
  }

  Widget _buildPerhitunganCard(DistribusiSisaBsuDetail d) {
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
          _sectionTitle('Rincian Tabungan Sampah'),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Expanded(
                    flex: 4,
                    child: Text('Nama Sampah', style: _headerStyle)),
                Expanded(
                    flex: 3,
                    child: Text('Qty Dipakai',
                        textAlign: TextAlign.right, style: _headerStyle)),
                Expanded(
                    flex: 2,
                    child: Text('Satuan',
                        textAlign: TextAlign.right, style: _headerStyle)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _dashedDivider(),
          const SizedBox(height: 8),
          ...d.perhitunganSisa.map((item) => _buildPerhitunganRow(item)),
        ],
      ),
    );
  }

  Widget _buildPerhitunganRow(PerhitunganSisaItem item) {
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
            flex: 3,
            child: Text(
              _fmtNum(item.qtyDipakai),
              textAlign: TextAlign.right,
              style: AppText.w600(11, AppColors.dark.withValues(alpha: 0.8)),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              item.satuan,
              textAlign: TextAlign.right,
              style: AppText.r(11, AppColors.dark.withValues(alpha: 0.5)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() => StateMessage(
        illustration: StateArt.error,
        message: _error!,
        action: StateRetryButton.pill(onPressed: _fetchDetail),
      );

  Widget _sectionTitle(String label) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
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
        ),
      );

  Widget _infoRow(IconData icon, String label, String value,
          {bool small = false}) =>
      Padding(
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
                  Text(label,
                      style: AppText.r(10, AppColors.dark.withValues(alpha: 0.45))),
                  Text(value,
                      style: AppText.w600(small ? 10.5 : 12, AppColors.dark)),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _divider() =>
      Divider(color: AppColors.dark.withValues(alpha: 0.06), height: 1);

  Widget _dashedDivider() => LayoutBuilder(
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
                  color: AppColors.dark.withValues(alpha: 0.12)),
            ),
          );
        },
      );

  TextStyle get _headerStyle => AppText.w600(10, AppColors.dark.withValues(alpha: 0.45));
}
