import 'package:enviroo/models/bank_sampah_model.dart';
import 'package:enviroo/providers/bank_provider.dart';
import 'package:enviroo/providers/penjualan_provider.dart' show FetchStatus;
import 'package:enviroo/widgets/custom_snackbar.dart';
import 'package:enviroo/widgets/topbar_back.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:enviroo/core/theme/app_colors.dart';
import 'package:enviroo/core/theme/app_text.dart';

class InfoBankSampahScreen extends StatefulWidget {
  @override
  State<InfoBankSampahScreen> createState() => _InfoBankSampahScreenState();
}

class _InfoBankSampahScreenState extends State<InfoBankSampahScreen> {
  List<BankSampahModel> _bankList = [];
  bool _isLoading = true;
  final MapController _mapController = MapController();
  int? _selectedBankIndex;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchBankData());
  }

  Future<void> _fetchBankData() async {
    final prov = context.read<BankProvider>();
    await prov.fetchSemuaBank();
    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (prov.semuaStatus == FetchStatus.success) {
        _bankList = prov.semuaBank;
      }
    });
    if (prov.semuaStatus != FetchStatus.success) {
      showCustomSnackBar(context, prov.semuaError ?? 'Gagal mengambil data');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: SafeArea(
          child: Column(
            children: [
              const TopBarBack(title: "Info Lokasi Bank Sampah"),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 4),
                child: Text(
                  "Kamu bisa lihat ada bank sampah apa aja yang ada di sekitarmu beserta alamat lengkapnya",
                  style: AppText.r(13, AppColors.dark.withValues(alpha: 0.7)),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  child: Stack(
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: const LatLng(-0.9135, 100.3550),
                          initialZoom: 14.0,
                          onTap: (_, __) {
                            if (_selectedBankIndex != null) {
                              setState(() => _selectedBankIndex = null);
                            }
                          },
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.enviroo.app',
                          ),
                          if (_isLoading)
                            const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.green,
                              ),
                            )
                          else
                            MarkerLayer(
                              markers: _buildMarkers(),
                            ),
                        ],
                      ),
                      Positioned(
                        top: 16,
                        left: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.dark,
                            borderRadius: BorderRadius.circular(50),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.dark.withValues(alpha: 0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.location_on_rounded,
                                color: AppColors.neon,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _isLoading ? 'Memuat...' : '${_bankList.length} Bank Sampah Ditemukan',
                                style: AppText.w600(12, Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 20,
                        right: 16,
                        child: GestureDetector(
                          onTap: () {
                            _mapController.move(
                              const LatLng(-0.9135, 100.3550),
                              14.0,
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.my_location_rounded,
                              color: AppColors.dark,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Marker> _buildMarkers() {
    return _bankList.asMap().entries.map((entry) {
      final index = entry.key;
      BankSampahModel bank = entry.value;
      final isSelected = _selectedBankIndex == index;

      return Marker(
        point: LatLng(bank.latitude, bank.longitude),
        width: isSelected ? 55 : 45,
        height: isSelected ? 55 : 45,
        child: GestureDetector(
          onTap: () {
            setState(() => _selectedBankIndex = index);
            _showBankDetailBottomSheet(bank);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.dark
                  : AppColors.neon,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isSelected
                          ? AppColors.dark
                          : AppColors.green)
                      .withValues(alpha: 0.4),
                  blurRadius: isSelected ? 14 : 8,
                  spreadRadius: isSelected ? 2 : 0,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              Icons.recycling_rounded,
              color: Colors.white,
              size: isSelected ? 24 : 20,
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildLocationRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 15,
            color: AppColors.green,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppText.w500(12, AppColors.dark.withValues(alpha: 0.75)),
            ),
          ),
        ],
      ),
    );
  }

  void _showBankDetailBottomSheet(BankSampahModel bank) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.65,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.dark.withAlpha(30),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    width: double.infinity,
                    height: 180,
                    color: Colors.white,
                    child: Image.network(
                      bank.photoUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                            color: AppColors.green,
                            strokeWidth: 2,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.store_rounded,
                                size: 48,
                                color: AppColors.green.withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Foto tidak tersedia',
                                style: AppText.r(12, AppColors.dark.withValues(alpha: 0.4)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                child: Text(
                  bank.namaBank,
                  style: AppText.w700(16, AppColors.dark),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Divider(
                  height: 1,
                  color: AppColors.dark.withAlpha(20),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      'Lokasi',
                      style: AppText.w600(13, AppColors.dark),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (bank.alamatBank.isNotEmpty)
                      _buildLocationRow(
                          Icons.signpost_outlined, bank.alamatBank),
                    if (bank.kelurahan.isNotEmpty)
                      _buildLocationRow(
                          Icons.holiday_village_outlined, bank.kelurahan),
                    if (bank.kecamatan.isNotEmpty)
                      _buildLocationRow(Icons.map_outlined, bank.kecamatan),
                    if (bank.kabupatenKota.isNotEmpty || bank.provinsi.isNotEmpty)
                      _buildLocationRow(
                        Icons.public_outlined,
                        [bank.kabupatenKota, bank.provinsi]
                            .where((s) => s.isNotEmpty)
                            .join(', '),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    ).whenComplete(() {
      setState(() => _selectedBankIndex = null);
    });
  }
}
