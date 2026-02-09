import 'package:enviroo/layouts/balance.dart';
import 'package:enviroo/layouts/informasi_layouts.dart';
import 'package:enviroo/layouts/jadwal_layouts.dart';
import 'package:enviroo/layouts/menu_layouts.dart';
import 'package:enviroo/layouts/statistik_layouts.dart';
import 'package:enviroo/models/penarikan_model.dart';
import 'package:enviroo/models/transaksi_model.dart';
import 'package:enviroo/widgets/navbar.dart';
import 'package:enviroo/widgets/penarikan_poin_card.dart';
import 'package:enviroo/widgets/penarikan_uang_card.dart';
import 'package:enviroo/widgets/topbar_custom.dart';
import 'package:enviroo/widgets/transaksi_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);
  
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedNavIndex = 0;
  String _selectedFilter = 'setoran';
  String _selectedPenarikanType = 'uang'; // 'uang' atau 'poin'
  
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  
  final List<String> _months = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFC1E6BA),
      body: SafeArea(
        child: Column(
          children: [
            TopBarCustom(),
            MainNavbar(
              selectedIndex: _selectedNavIndex,
              onTabChanged: (index) {
                setState(() {
                  _selectedNavIndex = index;
                });
              },
            ),
            Expanded(
              child: _selectedNavIndex == 0 
                  ? SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: _buildHomeLayouts(),
                    )
                  : _buildTransaksiLayouts(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeLayouts() {
    return Column(
      children: [
        BalanceLayouts(),
        MainMenu(),
        const SizedBox(height: 10),
        StatistikSection(),
        const SizedBox(height: 10),
        JadwalSetoranSection(),
        InformasiSection(),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildTransaksiLayouts() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 20),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFF013236).withAlpha(30),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Segmented control (Setoran / Penarikan) - always on top
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF013236).withOpacity(0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Row(
                children: [
                  _buildSegment('setoran', 'Setoran'),
                  _buildSegment('penarikan', 'Penarikan'),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Month/Year filter (only for Setoran)
          if (_selectedFilter == 'setoran')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _showMonthYearPicker(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF013236).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_rounded,
                              size: 18,
                              color: Color(0xFF013236),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '${_months[_selectedMonth - 1]} $_selectedYear',
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF013236),
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: const Color(0xFF013236).withAlpha(120),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          // Penarikan type filter (Saldo Uang / Saldo Poin)
          if (_selectedFilter == 'penarikan')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: const Color(0xFF4EA771).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Row(
                  children: [
                    _buildPenarikanTypeSegment('uang', 'Saldo Uang'),
                    _buildPenarikanTypeSegment('poin', 'Saldo Poin'),
                  ],
                ),
              ),
            ),
          
          const SizedBox(height: 20),
          
          // List
          Expanded(
            child: _selectedFilter == 'setoran'
                ? _buildSetoranList()
                : _buildPenarikanList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSetoranList() {
    List<Transaksi> allData = getDummySetoranData();
    
    List<Transaksi> filteredData = allData.where((t) {
      return t.tanggal.month == _selectedMonth && t.tanggal.year == _selectedYear;
    }).toList();
    
    filteredData.sort((a, b) => b.tanggal.compareTo(a.tanggal));

    if (filteredData.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      physics: const BouncingScrollPhysics(),
      itemCount: filteredData.length,
      itemBuilder: (context, index) {
        return TransaksiCard(transaksi: filteredData[index]);
      },
    );
  }

  Widget _buildPenarikanList() {
    if (_selectedPenarikanType == 'uang') {
      List<PenarikanUang> data = getDummyPenarikanUangData();
      data.sort((a, b) => b.tanggalDiajukan.compareTo(a.tanggalDiajukan));

      if (data.isEmpty) {
        return _buildEmptyState();
      }

      return ListView.builder(
        padding: const EdgeInsets.only(bottom: 24),
        physics: const BouncingScrollPhysics(),
        itemCount: data.length,
        itemBuilder: (context, index) {
          return PenarikanUangCard(penarikan: data[index]);
        },
      );
    } else {
      List<PenarikanPoin> data = getDummyPenarikanPoinData();
      data.sort((a, b) => b.tanggalDiajukan.compareTo(a.tanggalDiajukan));

      if (data.isEmpty) {
        return _buildEmptyState();
      }

      return ListView.builder(
        padding: const EdgeInsets.only(bottom: 24),
        physics: const BouncingScrollPhysics(),
        itemCount: data.length,
        itemBuilder: (context, index) {
          return PenarikanPoinCard(penarikan: data[index]);
        },
      );
    }
  }

  Widget _buildPenarikanTypeSegment(String value, String label) {
    final isSelected = _selectedPenarikanType == value;
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedPenarikanType = value);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF4EA771) : Colors.transparent,
            borderRadius: BorderRadius.circular(40),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF4EA771),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSegment(String value, String label) {
    final isSelected = _selectedFilter == value;
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedFilter = value);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF013236) : Colors.transparent,
            borderRadius: BorderRadius.circular(40),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF013236).withAlpha(250),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 56,
            color: const Color(0xFF013236).withAlpha(40),
          ),
          const SizedBox(height: 16),
          Text(
            'Tidak ada transaksi',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF013236).withAlpha(100),
            ),
          ),
        ],
      ),
    );
  }

  void _showMonthYearPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 320,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF013236).withAlpha(30),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Pilih Periode',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF013236),
                ),
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  // Month picker
                  Expanded(
                    child: ListView.builder(
                      itemCount: 12,
                      itemBuilder: (context, index) {
                        final isSelected = _selectedMonth == index + 1;
                        return GestureDetector(
                          onTap: () {
                            setState(() => _selectedMonth = index + 1);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            color: isSelected ? const Color(0xFFF5F8F4) : Colors.transparent,
                            child: Center(
                              child: Text(
                                _months[index],
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 14,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                  color: isSelected 
                                      ? const Color(0xFF4EA771) 
                                      : const Color(0xFF013236),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Container(width: 1, color: const Color(0xFF013236).withAlpha(15)),
                  // Year picker
                  Expanded(
                    child: ListView.builder(
                      itemCount: 3,
                      itemBuilder: (context, index) {
                        final year = 2024 + index;
                        final isSelected = _selectedYear == year;
                        return GestureDetector(
                          onTap: () {
                            setState(() => _selectedYear = year);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            color: isSelected ? const Color(0xFFF5F8F4) : Colors.transparent,
                            child: Center(
                              child: Text(
                                year.toString(),
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 14,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                  color: isSelected 
                                      ? const Color(0xFF4EA771) 
                                      : const Color(0xFF013236),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            // Done button
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4EA771),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Selesai',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
