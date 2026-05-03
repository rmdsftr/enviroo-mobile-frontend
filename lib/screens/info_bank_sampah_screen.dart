import 'package:enviroo/models/bank_sampah_model.dart';
import 'package:enviroo/providers/auth_provider.dart';
import 'package:enviroo/services/bank_service.dart';
import 'package:enviroo/widgets/topbar_back.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

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
    _fetchBankData();
  }

  Future<void> _fetchBankData() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final token = auth.currentUser?.accessToken ?? '';
    final result = await BankService.getAllBankSampah(token);
    
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result['success']) {
          _bankList = result['data'] ?? [];
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Gagal mengambil data')),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: const Color(0xFFFFFFFF),
        child: SafeArea(
          child: Column(
            children: [
              const TopBarBack(title: "Info Lokasi Bank Sampah"),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 4),
                child: Text(
                  "Kamu bisa lihat ada bank sampah apa aja yang ada di sekitarmu beserta alamat lengkap dan jadwal penimbangannya",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: const Color(0xFF013236).withOpacity(0.7),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Map
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
                            // Dismiss selection when tapping on map
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
                                color: Color(0xFF4EA771),
                              ),
                            )
                          else
                            MarkerLayer(
                              markers: _buildMarkers(),
                            ),
                        ],
                      ),
                      // Bank count badge
                      Positioned(
                        top: 16,
                        left: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF013236),
                            borderRadius: BorderRadius.circular(50),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF013236).withOpacity(0.3),
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
                                color: Color(0xFF94DF0C),
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _isLoading ? 'Memuat...' : '${_bankList.length} Bank Sampah Ditemukan',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Recenter button
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
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.my_location_rounded,
                              color: Color(0xFF013236),
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
                  ? const Color(0xFF013236)
                  : const Color(0xFF94DF0C),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isSelected
                          ? const Color(0xFF013236)
                          : const Color(0xFF4EA771))
                      .withOpacity(0.4),
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
          color: Color(0xFFFFFFFF),
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
              // Drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF013236).withAlpha(30),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Foto BSU
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    width: double.infinity,
                    height: 180,
                    color: const Color(0xFFFFFFFF),
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
                            color: const Color(0xFF4EA771),
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
                                color: const Color(0xFF4EA771).withOpacity(0.5),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Foto tidak tersedia',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  color: const Color(0xFF013236).withOpacity(0.4),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

              // Nama BSU
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bank.namaBank,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF013236),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 14,
                                color: const Color(0xFF013236).withOpacity(0.5),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  bank.alamatLengkap,
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12,
                                    color: const Color(0xFF013236).withOpacity(0.6),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Divider
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Divider(
                  height: 1,
                  color: const Color(0xFF013236).withAlpha(20),
                ),
              ),

              // Jadwal Penimbangan header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const Text(
                      'Jadwal Penimbangan',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF013236),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Jadwal list
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: bank.jadwalPenimbangan.map((jadwal) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 15,
                            color: Color(0xFF4EA771),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            jadwal.hari,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF013236),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4EA771).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${jadwal.jamMulai} - ${jadwal.jamSelesai}',
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF4EA771),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
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
