import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format/app_date.dart';
import '../../core/format/app_number.dart';
import '../../models/penjualan_model.dart';
import '../../providers/penjualan_provider.dart';
import 'package:enviroo/core/theme/app_colors.dart';
import 'package:enviroo/core/theme/app_text.dart';
import 'package:enviroo/widgets/state_message.dart';

class _T {
  static const title = 16.0;
  static const emphasis = 15.0;
  static const section = 13.0;
  static const value = 12.0;
  static const label = 11.0;
  static const caption = 10.5;
}

class PdfBuktiPenjualanScreen extends StatefulWidget {
  final String penjualanId;

  const PdfBuktiPenjualanScreen({super.key, required this.penjualanId});

  @override
  State<PdfBuktiPenjualanScreen> createState() => _PdfBuktiPenjualanScreenState();
}

class _PdfBuktiPenjualanScreenState extends State<PdfBuktiPenjualanScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    await context.read<PenjualanProvider>().fetchDetail(widget.penjualanId);
  }

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
              Expanded(
                child: Consumer<PenjualanProvider>(
                  builder: (_, prov, __) {
                    if (prov.detailStatus == FetchStatus.loading) {
                      return const Center(
                        child: CircularProgressIndicator(color: AppColors.green),
                      );
                    }
                    if (prov.detailStatus == FetchStatus.error ||
                        prov.detail == null) {
                      return _buildError(prov.detailError ?? 'Gagal memuat bukti penjualan');
                    }
                    return _buildBody(prov.detail!);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError(String msg) => StateMessage(
        illustration: StateArt.error,
        message: msg,
        action: StateRetryButton(onPressed: _load),
      );

  Widget _buildBody(DetailPenjualanModel d) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: BuktiPenjualanTemplate(detail: d),
    );
  }
}

class BuktiPenjualanTemplate extends StatelessWidget {
  final DetailPenjualanModel detail;

  const BuktiPenjualanTemplate({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    final d = detail;
    final isRupiah = AppNumber.tampakRupiah(d.satuanReward);

    String fmtNominal(double val) =>
        AppNumber.nominalSatuan(val, d.satuanReward, isUang: isRupiah);

    final terbilangStr =
        _capitalize('${terbilang(d.totalPenjualan.round())} ${isRupiah ? 'rupiah' : d.satuanReward}');

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _plainCard(
            child: Column(
              children: [
                Image.asset(
                  'assets/images/logo-fix.png',
                  height: 38,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 10),
                Text(
                  'Bukti Penjualan Sampah'.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: AppText.p(_T.title, weight: FontWeight.w700, color: AppColors.dark, letterSpacing: 0.4),
                ),
                const SizedBox(height: 5),
                Text(
                  d.namaBank,
                  textAlign: TextAlign.center,
                  style: AppText.r(_T.value, AppColors.dark.withValues(alpha: 0.5)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          _card(
            title: 'Informasi Penjualan',
            children: [
              _kv('ID Penjualan', d.penjualanId),
              _kv('Tanggal Penjualan',
                  '${AppDate.tanggalPenuh(d.createdAt)} ${AppDate.jamWib(d.createdAt)}'),
              _kv('Mitra Pengepul', d.namaMitra),
              _kv('Jenis Insentif', d.namaReward),
            ],
          ),
          const SizedBox(height: 12),

          _card(
            title: 'Item Sampah Terjual',
            children: [
              if (d.itemsSampah.isEmpty)
                Text(
                  'Tidak ada item sampah.',
                  style: AppText.r(_T.value, AppColors.dark.withValues(alpha: 0.4)),
                )
              else
                ...d.itemsSampah.asMap().entries.map((entry) {
                  final isLast = entry.key == d.itemsSampah.length - 1;
                  final item = entry.value;
                  return Container(
                    width: double.infinity,
                    margin: EdgeInsets.only(top: 6, bottom: isLast ? 2 : 0),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.green.withValues(alpha: 0.075),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                item.namaSampah,
                                style: AppText.w600(_T.value, AppColors.dark),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              fmtNominal(item.subtotalPenjualan),
                              style: AppText.w600(_T.value, AppColors.dark),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${AppNumber.desimal(item.qty)} ${item.satuan} x ${fmtNominal(item.hargaJual)}',
                          style: AppText.r(_T.caption, AppColors.dark.withValues(alpha: 0.45)),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
          const SizedBox(height: 12),

          _card(
            title: 'Total Penjualan',
            children: [
              _kv(
                'Nominal',
                fmtNominal(d.totalPenjualan),
                valueColor: AppColors.green,
                valueSize: _T.emphasis,
                valueWeight: FontWeight.w700,
              ),
              _kv('Terbilang', terbilangStr, italic: true),
            ],
          ),
          const SizedBox(height: 12),

          _plainCard(
            child: Align(
              alignment: Alignment.centerRight,
              child: Column(
                children: [
                  Text(
                    'Petugas yang Melayani,',
                    style: AppText.r(_T.label, AppColors.dark.withValues(alpha: 0.5)),
                  ),
                  const SizedBox(height: 46),
                  Text(
                    d.adminName,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: _T.value,
                      color: AppColors.dark,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.dark,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    d.namaBank,
                    style: AppText.r(_T.caption, AppColors.dark.withValues(alpha: 0.45)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _plainCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          width: 1,
          color: AppColors.dark.withValues(alpha: 0.1),
        ),
      ),
      child: child,
    );
  }

  Widget _card({required String title, required List<Widget> children}) {
    return _plainCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppText.w600(_T.section, AppColors.dark),
          ),
          const SizedBox(height: 7),
          Divider(color: AppColors.dark.withValues(alpha: 0.1), height: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _kv(
    String label,
    String value, {
    Color? valueColor,
    double valueSize = _T.value,
    FontWeight valueWeight = FontWeight.w600,
    bool italic = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(
              label,
              style: AppText.r(_T.label, AppColors.dark.withValues(alpha: 0.5)),
            ),
          ),
          Text(
            ': ',
            style: AppText.r(_T.label, AppColors.dark.withValues(alpha: 0.5)),
          ),
          Expanded(
            child: Text(
              value,
              style: AppText.p(valueSize, weight: valueWeight, color: valueColor ?? AppColors.dark, fontStyle: italic ? FontStyle.italic : FontStyle.normal),
            ),
          ),
        ],
      ),
    );
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}

String terbilang(int n) {
  if (n == 0) return 'nol';
  if (n < 0) return 'minus ${terbilang(-n)}';

  const satuan = [
    '', 'satu', 'dua', 'tiga', 'empat', 'lima',
    'enam', 'tujuh', 'delapan', 'sembilan', 'sepuluh', 'sebelas',
  ];

  if (n < 12) return satuan[n];
  if (n < 20) return '${terbilang(n - 10)} belas';
  if (n < 100) {
    final sisa = n % 10;
    return '${terbilang(n ~/ 10)} puluh${sisa != 0 ? ' ${terbilang(sisa)}' : ''}';
  }
  if (n < 200) {
    final sisa = n % 100;
    return 'seratus${sisa != 0 ? ' ${terbilang(sisa)}' : ''}';
  }
  if (n < 1000) {
    final sisa = n % 100;
    return '${terbilang(n ~/ 100)} ratus${sisa != 0 ? ' ${terbilang(sisa)}' : ''}';
  }
  if (n < 2000) {
    final sisa = n % 1000;
    return 'seribu${sisa != 0 ? ' ${terbilang(sisa)}' : ''}';
  }
  if (n < 1000000) {
    final sisa = n % 1000;
    return '${terbilang(n ~/ 1000)} ribu${sisa != 0 ? ' ${terbilang(sisa)}' : ''}';
  }
  if (n < 1000000000) {
    final sisa = n % 1000000;
    return '${terbilang(n ~/ 1000000)} juta${sisa != 0 ? ' ${terbilang(sisa)}' : ''}';
  }
  if (n < 1000000000000) {
    final sisa = n % 1000000000;
    return '${terbilang(n ~/ 1000000000)} miliar${sisa != 0 ? ' ${terbilang(sisa)}' : ''}';
  }
  final sisa = n % 1000000000000;
  return '${terbilang(n ~/ 1000000000000)} triliun${sisa != 0 ? ' ${terbilang(sisa)}' : ''}';
}
