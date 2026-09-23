import 'package:enviroo/models/katalog_model.dart';
import 'package:enviroo/providers/auth_provider.dart';
import 'package:enviroo/providers/bank_provider.dart';
import 'package:enviroo/providers/barang_provider.dart';
import 'package:enviroo/screens/distribusi_barang/preview_distribusi_barang_screen.dart';
import 'package:enviroo/widgets/dropdown_custom.dart';
import 'package:enviroo/widgets/search.dart';
import 'package:enviroo/widgets/custom_snackbar.dart';
import 'package:enviroo/widgets/topbar_back.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class _C {
  static const bg     = Color(0xFFF2FAF0);
  static const dark   = Color(0xFF0D3B3E);
  static const accent = Color(0xFF4EA771);
  static const teal   = Color(0xFF013236);
}

class InputDistribusiBarangScreen extends StatefulWidget {
  const InputDistribusiBarangScreen({super.key});

  @override
  State<InputDistribusiBarangScreen> createState() =>
      _InputDistribusiBarangScreenState();
}

class _InputDistribusiBarangScreenState
    extends State<InputDistribusiBarangScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedBsuId;
  String? _expandedBarangId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final barang = context.read<BarangProvider>();
      final bankId = auth.bankId ?? '';

      barang.fetchKatalogBsi(bankId);
      context.read<BankProvider>().fetchBsuList(bankId);
      barang.clearDistribusiItems();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<KatalogBarangModel> _filtered(BarangProvider barang) {
    if (_searchQuery.isEmpty) return barang.katalogBsi;
    return barang.katalogBsi
        .where((e) =>
            e.namaBarang.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  Future<void> _goToPreview() async {
    final barang = context.read<BarangProvider>();
    final auth = context.read<AuthProvider>();

    if (_selectedBsuId == null) {
      _showSnack('Pilih BSU tujuan terlebih dahulu');
      return;
    }
    if (!barang.hasDistribusiItems) {
      _showSnack('Pilih minimal 1 item untuk didistribusikan');
      return;
    }

    final ok = await barang.previewDistribusi(
      bsiId: auth.bankId ?? '',
      bsuId: _selectedBsuId!,
      adminBsiId: auth.identityId ?? '',
    );

    if (!mounted) return;

    if (ok) {
      final result = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (_) => PreviewDistribusiBarangScreen(
            bsiId: auth.bankId ?? '',
            bsuId: _selectedBsuId!,
            namaBsu: _namaBsu(context.read<BankProvider>()),
          ),
        ),
      );
      if (result != null && mounted) {
        Navigator.pop(context, result);
      }
    } else {
      _showSnack(barang.errorMessage ?? 'Gagal membuat preview distribusi');
      barang.clearError();
    }
  }

  void _showSnack(String msg) {
    showCustomSnackBar(context, msg);
  }

  String _namaBsu(BankProvider bank) {
    if (_selectedBsuId == null) return '';
    try {
      return bank.bsuList
          .firstWhere((b) => b.bankId == _selectedBsuId)
          .namaBank;
    } catch (_) {
      return 'BSU';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<BarangProvider, AuthProvider>(
      builder: (context, barang, auth, _) {
        final filtered = _filtered(barang);

        return Scaffold(
          backgroundColor: _C.bg,
          body: SafeArea(
            child: Column(
              children: [
                const TopBarBack(title: 'Input Distribusi Barang'),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    physics: const BouncingScrollPhysics(),
                    children: [
                      const SizedBox(height: 16),
                      _buildBsuDropdown(barang),
                      const SizedBox(height: 12),
                      _buildSearchBar(),
                      const SizedBox(height: 16),
                      _buildListHeader(barang),
                      const SizedBox(height: 12),
                      if (barang.isLoading)
                        const Padding(
                          padding: EdgeInsets.only(top: 60),
                          child: Center(
                            child: CircularProgressIndicator(color: _C.accent),
                          ),
                        )
                      else if (filtered.isEmpty)
                        _buildEmptyState()
                      else
                        ...filtered.map(
                            (item) => _buildExpandableCard(item, barang)),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: _buildBottomBar(barang),
        );
      },
    );
  }

  Widget _buildBsuDropdown(BarangProvider barang) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomDropdown<String>(
            value: _selectedBsuId,
            hintText: 'Pilih BSU tujuan...',
            prefixIcon: Icons.house_rounded,
            items: context.watch<BankProvider>().bsuList
                .map((bsu) => CustomDropdownItem(value: bsu.bankId, label: bsu.namaBank, icon: Icons.house_rounded))
                .toList(),
            onChanged: (val) => setState(() => _selectedBsuId = val),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return CustomSearchBar(
      controller: _searchController,
      hintText: 'Cari barang...',
      searchQuery: _searchQuery,
      onChanged: (v) => setState(() => _searchQuery = v),
      onClear: () {
        _searchController.clear();
        setState(() => _searchQuery = '');
      },
      padding: const EdgeInsets.symmetric(horizontal: 24),
    );
  }

  Widget _buildListHeader(BarangProvider barang) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          const Text(
            'Pilih Item Barang',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: _C.dark,
            ),
          ),
          const Spacer(),
          if (barang.hasDistribusiItems)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _C.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${barang.distribusiQty.length} dipilih',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: _C.accent,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildExpandableCard(KatalogBarangModel item, BarangProvider barang) {
    final isExpanded = _expandedBarangId == item.produkId;
    final qty = barang.getDistribusiQty(item.produkId);
    final hasQty = qty > 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() {
            _expandedBarangId = isExpanded ? null : item.produkId;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasQty
                  ? _C.accent.withValues(alpha: 0.5)
                  : Colors.grey.withValues(alpha: 0.15),
              width: hasQty ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: _C.dark.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: const Color(0xFFF2F2F2),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: item.photoUrl.isNotEmpty
                          ? Image.network(
                              item.photoUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.storefront_rounded,
                                size: 22,
                                color: _C.accent.withValues(alpha: 0.5),
                              ),
                            )
                          : Icon(
                              Icons.storefront_rounded,
                              size: 22,
                              color: _C.accent.withValues(alpha: 0.5),
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.namaBarang,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _C.dark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Stok: ${item.stok.toInt()} item',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              color: _C.dark.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (hasQty)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _C.accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$qty item',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _C.accent,
                          ),
                        ),
                      ),
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: _C.dark.withValues(alpha: 0.35),
                      size: 20,
                    ),
                  ],
                ),
              ),
              if (isExpanded) ...[
                Divider(height: 1, color: Colors.grey.shade100),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                  child: _buildQtyInput(item, barang, qty),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQtyInput(
      KatalogBarangModel item, BarangProvider barang, int qty) {
    final maxQty = item.stok.toInt();
    final atMax = qty >= maxQty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Jumlah distribusi:',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: _C.dark.withValues(alpha: 0.6),
              ),
            ),
            const Spacer(),
            _qtyButton(
              icon: Icons.remove_rounded,
              onTap: qty > 0
                  ? () {
                      HapticFeedback.selectionClick();
                      barang.updateDistribusiQty(item.produkId, qty - 1);
                    }
                  : null,
            ),
            const SizedBox(width: 8),
            Container(
              width: 40,
              padding: const EdgeInsets.symmetric(vertical: 5),
              decoration: BoxDecoration(
                color: atMax
                    ? Colors.orange.withValues(alpha: 0.08)
                    : _C.accent.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: atMax
                      ? Colors.orange.withValues(alpha: 0.35)
                      : _C.accent.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                '$qty',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: atMax ? Colors.orange : _C.accent,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _qtyButton(
              icon: Icons.add_rounded,
              onTap: atMax
                  ? null
                  : () {
                      HapticFeedback.selectionClick();
                      barang.updateDistribusiQty(item.produkId, qty + 1);
                    },
            ),
          ],
        ),
        if (atMax && maxQty > 0) ...[
          const SizedBox(height: 6),
          Text(
            'Maksimal stok tersedia ($maxQty item)',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10,
              color: Colors.orange,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _qtyButton({required IconData icon, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 25,
        height: 25,
        decoration: BoxDecoration(
          color: onTap != null ? _C.accent : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Icon(
          icon,
          size: 18,
          color: onTap != null ? Colors.white : Colors.grey,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.search_off_rounded,
                size: 48, color: _C.dark.withValues(alpha: 0.15)),
            const SizedBox(height: 12),
            Text(
              'Tidak ada barang',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: _C.dark.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(BarangProvider barang) {
    final canPreview = _selectedBsuId != null && barang.hasDistribusiItems;

    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 14, 20, MediaQuery.of(context).padding.bottom + 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: _C.teal.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: canPreview ? const Color(0xFF013236) : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(30),
        ),
        child: ElevatedButton(
          onPressed:
              barang.isPreviewLoading || !canPreview ? null : _goToPreview,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.transparent,
            disabledForegroundColor: Colors.grey.shade500,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
          child: barang.isPreviewLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.preview_rounded, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      canPreview
                          ? 'Preview Distribusi Barang'
                          : _selectedBsuId == null
                              ? 'Pilih BSU tujuan dulu'
                              : 'Pilih item dulu',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
