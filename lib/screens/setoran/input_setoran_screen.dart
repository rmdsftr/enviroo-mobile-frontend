import 'package:enviroo/models/katalog_model.dart';
import 'package:enviroo/providers/auth_provider.dart';
import 'package:enviroo/screens/setoran/preview_setoran_screen.dart';
import 'package:enviroo/screens/setoran/detail_setoran_screen.dart';
import 'package:enviroo/providers/katalog_provider.dart';
import 'package:enviroo/widgets/custom_snackbar.dart';
import 'package:enviroo/widgets/filter_chip_row.dart';
import 'package:enviroo/widgets/search.dart';
import 'package:enviroo/widgets/topbar_back.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:enviroo/core/theme/app_colors.dart';
import 'package:enviroo/core/theme/app_text.dart';

String _labelSaldo(String namaReward) {
  switch (namaReward.toLowerCase()) {
    case 'uang':
      return 'Rupiah';
    case 'barang':
      return 'Poin';
    default:
      return namaReward;
  }
}

class InputSetoranScreen extends StatefulWidget {
  final String penimbanganId;
  final String nasabahId;
  final String nasabahName;
  final String photoUrl;
  final bool dariQr;

  const InputSetoranScreen({
    super.key,
    required this.penimbanganId,
    required this.nasabahId,
    required this.nasabahName,
    required this.photoUrl,
    required this.dariQr,
  });

  @override
  State<InputSetoranScreen> createState() => _InputSetoranState();
}

class _InputSetoranState extends State<InputSetoranScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedReward = 'Semua';
  final Map<String, TextEditingController> _inputControllers = {};

  List<KatalogSampahModel> _katalog = [];
  bool _isLoading = true;

  List<KatalogSampahModel> get _filtered => _katalog.where((item) {
        final matchSearch = item.namaSampah
            .toLowerCase()
            .contains(_searchQuery.toLowerCase());
        final matchReward = _selectedReward == 'Semua' ||
            (item.reward?.namaReward ?? '') == _selectedReward;
        return matchSearch && matchReward;
      }).toList();

  List<String> get _rewardOptions {
    final seen = <String>{};
    final result = <String>['Semua'];
    for (final item in _katalog) {
      final name = item.reward?.namaReward ?? '';
      if (name.isNotEmpty && seen.add(name)) result.add(name);
    }
    return result;
  }

  TextEditingController _controllerFor(String sampahId) =>
      _inputControllers.putIfAbsent(sampahId, () => TextEditingController());

  bool get _adaInput => _inputControllers.values
      .any((c) => c.text.isNotEmpty && (double.tryParse(c.text) ?? 0) > 0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchKatalog());
  }

  Future<void> _fetchKatalog() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final katalog = Provider.of<KatalogProvider>(context, listen: false);

    await katalog.fetchKatalogSampah(auth.bankId ?? '');

    if (!mounted) return;

    if (katalog.errorMessage == null) {
      setState(() {
        _katalog = katalog.katalogSampah;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      showCustomSnackBar(
          context, katalog.errorMessage ?? 'Gagal mengambil katalog sampah');
    }
  }

  Future<void> _goToPreview() async {
    if (!_adaInput) return;

    List<Map<String, dynamic>> items = [];
    for (final sampah in _katalog) {
      final ctrl = _inputControllers[sampah.sampahId];
      if (ctrl == null || ctrl.text.isEmpty) continue;
      final qty = double.tryParse(ctrl.text) ?? 0;
      if (qty > 0) {
        items.add({'sampah_id': sampah.sampahId, 'qty': qty});
      }
    }

    if (!mounted) return;

    final setoranId = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => PreviewSetoranScreen(
          penimbanganId: widget.penimbanganId,
          nasabahId: widget.nasabahId,
          nasabahName: widget.nasabahName,
          photoUrl: widget.photoUrl,
          dariQr: widget.dariQr,
          items: items,
        ),
      ),
    );

    if (setoranId != null && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DetailSetoranScreen(setoranId: setoranId),
        ),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    for (final ctrl in _inputControllers.values) ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            TopBarBack(title: "Input Setoran"),
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator(color: AppColors.green))
                : ListView(
                padding: EdgeInsets.zero,
                children: [
                  const SizedBox(height: 8),
                  _buildNasabahCard(),
                  const SizedBox(height: 20),
                  _buildSearchBar(),
                  const SizedBox(height: 15),
                  _buildRewardFilter(),
                  const SizedBox(height: 20),
                  _buildKatalogHeader(),
                  const SizedBox(height: 8),
                  if (_filtered.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 40),
                        child: Text(
                          'Katalog tidak ditemukan',
                          style: TextStyle(fontFamily: 'Poppins', color: Colors.grey[400]),
                        ),
                      ),
                    ),
                  ...List.generate(_filtered.length, (i) => _CardInput(
                    key: ValueKey(_filtered[i].sampahId),
                    item: _filtered[i],
                    controller: _controllerFor(_filtered[i].sampahId),
                    onChanged: (_) => setState(() {}),
                  )),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildNasabahCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: AppColors.green.withValues(alpha:0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.green.withValues(alpha:0.12),
                borderRadius: BorderRadius.circular(13),
                image: widget.photoUrl.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(widget.photoUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: widget.photoUrl.isEmpty
                  ? const Icon(
                      Icons.person_rounded,
                      color: AppColors.green,
                      size: 24,
                    )
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
                    style: AppText.r(11, AppColors.dark.withValues(alpha:0.45)),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.green.withValues(alpha:0.12),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.dariQr ? Icons.qr_code_rounded : Icons.person_search_rounded,
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
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha:0.5),
          borderRadius: BorderRadius.circular(50),
        ),
        child: CustomSearchBar(
          controller: _searchController,
          hintText: 'Cari sampah dari katalog...',
          onChanged: (v) => setState(() => _searchQuery = v),
          searchQuery: _searchQuery,
          onClear: () {
            setState(() {
              _searchController.clear();
              _searchQuery = '';
            });
          },
        ),
      ),
    );
  }

  Widget _buildRewardFilter() {
    final options = _rewardOptions;
    return FilterChipRow<String>(
      items: options
          .map((n) => FilterChipItem<String>(value: n, label: _labelSaldo(n)))
          .toList(),
      selectedValue: _selectedReward,
      onSelected: (v) => setState(() => _selectedReward = v),
    );
  }

  Widget _buildKatalogHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Text(
            'Katalog Sampah',
            style: AppText.w600(12, AppColors.dark),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha:0.65),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_filtered.length} item',
              style: AppText.w500(10, AppColors.green),
            ),
          ),
        ],
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
            color: AppColors.dark.withValues(alpha:0.08),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: AnimatedOpacity(
        opacity: _adaInput ? 1.0 : 0.4,
        duration: const Duration(milliseconds: 200),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.dark,
            borderRadius: BorderRadius.circular(30),
          ),
          child: ElevatedButton(
            onPressed: _adaInput ? _goToPreview : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              disabledBackgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              foregroundColor: Colors.white,
              disabledForegroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Preview Setoran Nasabah',
                  style: AppText.p(13, weight: FontWeight.w600, color: Colors.white, letterSpacing: 0.2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}

class _CardInput extends StatelessWidget {
  final KatalogSampahModel item;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _CardInput({
    super.key,
    required this.item,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha:0.5),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            width: 1,
            color: AppColors.dark.withValues(alpha:0.1),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.green.withValues(alpha:0.12),
                borderRadius: BorderRadius.circular(11),
              ),
              clipBehavior: Clip.antiAlias,
              child: item.photoUrl.isNotEmpty
                  ? Image.network(
                      item.photoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.recycling_rounded,
                        size: 20,
                        color: AppColors.green,
                      ),
                    )
                  : const Icon(
                      Icons.recycling_rounded,
                      size: 20,
                      color: AppColors.green,
                    ),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.namaSampah,
                    style: AppText.w600(13, AppColors.dark),
                  ),
                  const SizedBox(height: 4),
                  _RewardBadge(namaReward: item.reward?.namaReward ?? ''),
                ],
              ),
            ),
            const SizedBox(width: 12),

            SizedBox(
              width: 70,
              height: 42,
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                textAlign: TextAlign.center,
                style: AppText.w700(14, AppColors.dark),
                decoration: InputDecoration(
                  hintText: '0',
                  hintStyle: AppText.w700(14, AppColors.dark.withValues(alpha:0.18)),
                  filled: true,
                  fillColor: const Color(0xFFF4FCF4),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(
                      color: AppColors.green.withValues(alpha:0.2),
                      width: 1,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(
                      color: AppColors.green.withValues(alpha:0.2),
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(
                      color: AppColors.green,
                      width: 1,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 8),

            Text(
              item.satuan,
              style: AppText.w500(12, AppColors.dark.withValues(alpha:0.55)),
            ),
          ],
        ),
      ),
    );
  }
}

class _RewardBadge extends StatelessWidget {
  final String namaReward;

  const _RewardBadge({required this.namaReward});

  Color get _color {
    switch (namaReward.toLowerCase()) {
      case 'uang':
      case 'rupiah':
        return AppColors.green;
      case 'barang':
      case 'poin':
        return const Color(0xFFE57C2C);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (namaReward.isEmpty) return const SizedBox.shrink();
    final color = _color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _labelSaldo(namaReward),
        style: AppText.p(9, weight: FontWeight.w700, color: color, letterSpacing: 0.2),
      ),
    );
  }
}
