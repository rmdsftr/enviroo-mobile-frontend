import 'package:enviroo/models/bagi_hasil_bsu_model.dart';
import 'package:enviroo/providers/auth_provider.dart';
import 'package:enviroo/services/bagi_hasil_service.dart';
import 'package:enviroo/screens/bagi_hasil/struk_bagi_hasil_bsu_screen.dart';
import 'package:enviroo/widgets/filter_month_year.dart';
import 'package:enviroo/widgets/topbar_back.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:enviroo/core/format/app_date.dart';
import 'package:enviroo/core/format/app_number.dart';
import 'package:enviroo/core/theme/app_colors.dart';
import 'package:enviroo/core/theme/app_text.dart';
import 'package:enviroo/widgets/state_message.dart';

class ListBagiHasilBsuScreen extends StatefulWidget {
  const ListBagiHasilBsuScreen({super.key});

  @override
  State<ListBagiHasilBsuScreen> createState() =>
      _ListBagiHasilBsuScreenState();
}

class _ListBagiHasilBsuScreenState extends State<ListBagiHasilBsuScreen> {

  late DateTime _filterStart;
  late DateTime _filterEnd;

  List<DistribusiSisaBsuItem> _allItems = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _filterEnd = DateTime(now.year, now.month);
    final startRaw = DateTime(now.year, now.month - 2);
    _filterStart = DateTime(startRaw.year, startRaw.month);
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchData());
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final bsuId = auth.bankId ?? '';

    final startDate = '${_filterStart.year}-${_filterStart.month.toString().padLeft(2, '0')}-01';
    final endDate = '${_filterEnd.year}-${_filterEnd.month.toString().padLeft(2, '0')}-${DateTime(_filterEnd.year, _filterEnd.month + 1, 0).day.toString().padLeft(2, '0')}';
    final res = await BagiHasilService.getListDistribusiSisaBsu(bsuId, startDate: startDate, endDate: endDate);
    if (!mounted) return;
    if (res['success'] == true) {
      final body = res['data'] as Map<String, dynamic>? ?? {};
      final list = (body['riwayat'] as List? ?? [])
          .map((e) => DistribusiSisaBsuItem.fromJson(e as Map<String, dynamic>))
          .toList();
      setState(() {
        _allItems = list;
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = res['message'] ?? 'Gagal memuat data distribusi sisa';
        _isLoading = false;
      });
    }
  }

  List<DistribusiSisaBsuItem> get _filtered {
    return _allItems.where((item) {
      final itemMonth = DateTime(
          item.tanggalDistribusi.year, item.tanggalDistribusi.month);
      final start = DateTime(_filterStart.year, _filterStart.month);
      final end = DateTime(_filterEnd.year, _filterEnd.month);
      return !itemMonth.isBefore(start) && !itemMonth.isAfter(end);
    }).toList();
  }

  String _fmtNominal(double val, String satuan) =>
      AppNumber.nominalSatuan(val, satuan);

  Color _cardColor(String satuan) {
    final s = satuan.toLowerCase();
    if (s == 'rp') return AppColors.green;
    if (s == 'poin') return const Color(0xFF2D9CDB);
    return const Color(0xFFF2C94C);
  }

  IconData _cardIcon(String satuan) {
    final s = satuan.toLowerCase();
    if (s == 'rp') return Icons.account_balance_wallet_rounded;
    if (s == 'poin') return Icons.shopping_basket_rounded;
    return Icons.diamond_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg_struk2.webp',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const TopBarBack(title: 'Bagi Hasil'),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Riwayat distribusi sisa bagi hasil yang telah diterima oleh BSU ini.',
                    style: AppText.p(12, color: AppColors.dark.withValues(alpha: 0.7), height: 1.5),
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                            child: Text(
                              'Riwayat distribusi bagi hasil',
                              style: AppText.w600(14, AppColors.dark),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: MonthYearFilterRow(
                              filterStart: _filterStart,
                              filterEnd: _filterEnd,
                              onChanged: (s, e) {
                                setState(() {
                                  _filterStart = s;
                                  _filterEnd = e;
                                });
                                _fetchData();
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: _isLoading
                                ? const Center(child: CircularProgressIndicator(color: AppColors.green))
                                : _error != null
                                    ? _buildError()
                                    : _buildList(),
                          ),
                        ],
                      ),
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

  Widget _buildList() {
    final items = _filtered;
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_rounded,
                size: 56, color: AppColors.dark.withValues(alpha: 0.18)),
            const SizedBox(height: 12),
            Text(
              'Belum ada distribusi sisa\nuntuk periode ini',
              textAlign: TextAlign.center,
              style: AppText.r(13, AppColors.dark.withValues(alpha: 0.45)),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.green,
      onRefresh: _fetchData,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        physics: const BouncingScrollPhysics(),
        itemCount: items.length,
        itemBuilder: (_, i) => _buildCard(items[i]),
      ),
    );
  }

  Widget _buildCard(DistribusiSisaBsuItem item) {
    final color = _cardColor(item.satuanNominal);
    final icon = _cardIcon(item.satuanNominal);
    final dateStr = AppDate.tanggalSingkatJam(item.tanggalDistribusi);
    final nominalStr = _fmtNominal(item.nominalDiterima, item.satuanNominal);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StrukBagiHasilBsuScreen(
              penerimaSisaId: item.penerimaSisaId),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              width: 1,
              color: AppColors.dark.withValues(alpha: 0.1)
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.dark.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.dark, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dateStr,
                    style: AppText.w600(12, AppColors.dark),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'ID: ${item.penerimaSisaId}',
                    style: AppText.r(10, AppColors.dark.withValues(alpha: 0.45)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Row(
              children: [
                Text(
                  nominalStr,
                  style: AppText.w700(13, color),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() => StateMessage(
        illustration: StateArt.error,
        message: _error!,
        action: StateRetryButton.pill(onPressed: _fetchData),
      );
}
