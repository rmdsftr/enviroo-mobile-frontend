import 'package:enviroo/layouts/balance.dart';
import 'package:enviroo/layouts/informasi_layouts.dart';
import 'package:enviroo/layouts/jadwal_layouts.dart';
import 'package:enviroo/layouts/menu_admin_bsu_layouts.dart';
import 'package:enviroo/layouts/menu_admin_bsi.dart';
import 'package:enviroo/layouts/menu_layouts.dart';
import 'package:enviroo/providers/auth_provider.dart';
import 'package:enviroo/providers/konten_provider.dart';

import 'package:enviroo/models/penarikan_model.dart';
import 'package:enviroo/models/transaksi_model.dart';
import 'package:enviroo/screens/admin_bsu/home_bsu_screen.dart';
import 'package:enviroo/widgets/navbar.dart';
import 'package:enviroo/widgets/penarikan_poin_card.dart';
import 'package:enviroo/widgets/penarikan_uang_card.dart';
import 'package:enviroo/widgets/topbar_custom.dart';
import 'package:enviroo/widgets/transaksi_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);
  
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _PodiumUser {
  final String name;
  final String weight;
  final int rank;
  const _PodiumUser({
    required this.name,
    required this.weight,
    required this.rank,
  });
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
  void initState() {
    super.initState();
    // Fetch profile data when home screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.role == 'nasabah') {
        auth.fetchNasabahProfile();
        
        // Fetch konten informasi too
        if (auth.bankId != null && auth.currentUser?.accessToken != null) {
          Provider.of<KontenProvider>(context, listen: false).fetchKonten(
            auth.bankId!,
            auth.currentUser!.accessToken,
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        return Scaffold(
          backgroundColor: Color(0xFFEAF8E7),
          body: SafeArea(
            child: Column(
              children: [
                const TopBarCustom(),
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
                      : _selectedNavIndex == 1
                      ? _buildTransaksiLayouts()
                      : _buildRewardLayouts(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHomeLayouts() {
    return Column(
      children: [
        SizedBox(height: 10),
        BalanceLayouts(),
        MainMenu(),
        JadwalSetoranSection(),
        InformasiSection(),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildTransaksiLayouts() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        // borderRadius: const BorderRadius.only(
        //   topLeft: Radius.circular(32),
        //   topRight: Radius.circular(32),
        // ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF013236).withAlpha(18),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Handle
          // Container(
          //   margin: const EdgeInsets.only(top: 14, bottom: 18),
          //   width: 36,
          //   height: 4,
          //   decoration: BoxDecoration(
          //     color: const Color(0xFF4EA771).withAlpha(50),
          //     borderRadius: BorderRadius.circular(2),
          //   ),
          // ),

          SizedBox(height: 20),
          
          // Segmented control (Setoran / Penarikan)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Color(0xFF013236).withOpacity(0.2),
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
          
          const SizedBox(height: 14),
          
          // Month/Year filter (only for Setoran)
          if (_selectedFilter == 'setoran')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: GestureDetector(
                onTap: () => _showMonthYearPicker(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                  decoration: BoxDecoration(
                    color: Color(0xFF013236).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF013236).withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.calendar_today_rounded,
                          size: 15,
                          color: Color(0xFF013236),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${_months[_selectedMonth - 1]} $_selectedYear',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF013236),
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 20,
                        color: const Color(0xFF013236).withAlpha(140),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Penarikan type filter (Saldo Uang / Saldo Poin)
          if (_selectedFilter == 'penarikan')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: DropdownButton2<String>(
                value: _selectedPenarikanType,
                onChanged: (value) {
                  if (value != null) {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedPenarikanType = value);
                  }
                },
                items: const [
                  DropdownMenuItem(value: 'uang', child: Text('Saldo Uang')),
                  DropdownMenuItem(value: 'poin', child: Text('Saldo Poin')),
                ],
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF013236),
                ),
                underline: const SizedBox.shrink(),
                buttonStyleData: ButtonStyleData(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                  decoration: BoxDecoration(
                    color: Color(0xFF013236).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  height: 48,
                ),
                iconStyleData: IconStyleData(
                  icon: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: const Color(0xFF013236).withAlpha(140),
                  ),
                  iconSize: 20,
                ),
                dropdownStyleData: DropdownStyleData(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    // boxShadow: [
                    //   BoxShadow(
                    //     color: const Color(0xFF013236).withAlpha(20),
                    //     blurRadius: 16,
                    //     offset: const Offset(0, 4),
                    //   ),
                    // ],
                  ),
                  offset: const Offset(0, -4),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                ),
                menuItemStyleData: const MenuItemStyleData(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                ),
                selectedItemBuilder: (context) => [
                  // Uang — dengan ikon wallet, mirip layout calendar filter
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF013236).withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_rounded,
                          size: 15,
                          color: Color(0xFF013236),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Saldo Uang',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF013236),
                        ),
                      ),
                    ],
                  ),
                  // Poin — dengan ikon stars
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF013236).withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.stars_rounded,
                          size: 15,
                          color: Color(0xFF013236),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Saldo Poin',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF013236),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          
          const SizedBox(height: 16),
          
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
            color: isSelected ? Color(0xFF013236) : Colors.transparent,
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
                                      ? const Color(0xFF94DF0C) 
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
                                      ? const Color(0xFF94DF0C) 
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
                    backgroundColor: const Color(0xFF94DF0C),
                    foregroundColor: const Color(0xFF013236),
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

  // ─── Ubah _buildRewardLayouts ─────────────────────────────────────
  Widget _buildRewardLayouts() {
    return Column( // <-- ini harus jadi children dari widget yang fill screen
      children: [
        Padding(
          padding: const EdgeInsets.all(25),
          child: Column(
            children: [
              Text(
                "Reward untuk nasabah terbaik dengan tabungan sampah terbanyak tiap bulannya",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: Color(0xFF013236).withOpacity(0.75),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 25),
              GestureDetector(
                onTap: () => _showMonthYearPicker(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                  decoration: BoxDecoration(
                    color: Color(0xFF013236).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(
                      width: 1,
                      color: Color(0xFF013236).withOpacity(0.2)
                    )
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 18, color: Color(0xFF013236)),
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
                      Icon(Icons.keyboard_arrow_down_rounded,
                          color: const Color(0xFF013236).withAlpha(120)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Expanded(child: _buildRankingLayout()), // ← Expanded di sini, bukan di dalam
      ],
    );
  }

  Widget _buildRankingLayout() {
    return Container(
      padding: const EdgeInsets.only(top: 28),
      decoration: const BoxDecoration(
        color: Color(0xFF013236),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          // ── Header ──
          Column(
            children: [
              const Text(
                "Top 3 Nasabah",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.5,
                  color: Color(0xFF94D18C),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                "BSU Fakultas Teknologi Informasi",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: Color(0xFFFFFFFF),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Podium ──
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final maxH = constraints.maxHeight;
                const avatarH = 50.0; // foto + nama + padding

                // Data dummy per rank (bisa diganti data asli)
                final users = [
                  _PodiumUser(name: "Siti Rahma", weight: "18.5 kg", rank: 2),
                  _PodiumUser(name: "Ramadhani S.", weight: "24.2 kg", rank: 1),
                  _PodiumUser(name: "Budi Santoso", weight: "12.0 kg", rank: 3),
                ];

                final barRatios = [0.62, 0.85, 0.48]; // rank 2, 1, 3

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(3, (i) {
                    return Expanded(
                      child: _buildPodiumColumn(
                        user: users[i],
                        barHeight: (maxH - avatarH) * barRatios[i],
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

// ── Data helper class ─────────────────────────────

// ── Kolom lengkap: avatar + bar ───────────────────
  Widget _buildPodiumColumn({
  required _PodiumUser user,
  required double barHeight,
  }) {
  return Column(
  mainAxisSize: MainAxisSize.min,
  children: [
  _buildIdentitasUser(user),
  _buildPodiumBar(height: barHeight, user: user),
  ],
  );
  }

// ── Podium Bar ────────────────────────────────────
  Widget _buildPodiumBar({
  required double height,
  required _PodiumUser user,
  }) {
  // Palette per rank
  final gradients = {
  1: [const Color(0xFFD4F55A), const Color(0xFF94C91A)],   // lime-gold
  2: [const Color(0xFF8ECAE6), const Color(0xFF4A9FBF)],   // silver-blue
  3: [const Color(0xFF6BD4A0), const Color(0xFF2E9F6A)],   // green
  };

  final glowColors = {
  1: const Color(0xFFD4F55A).withOpacity(0.15),
  2: const Color(0xFF8ECAE6).withOpacity(0.15),
  3: const Color(0xFF6BD4A0).withOpacity(0.15),
  };

  final medalIcons = {
  1: '👑',
  2: '🥈',
  3: '🥉',
  };

  return Padding(
  padding: const EdgeInsets.symmetric(horizontal: 10),
  child: Container(
  width: double.infinity,
  height: height,
  decoration: BoxDecoration(
  gradient: LinearGradient(
  colors: gradients[user.rank]!,
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  ),
  borderRadius: const BorderRadius.only(
  topLeft: Radius.circular(25),
  topRight: Radius.circular(25),
  ),
  boxShadow: [
  BoxShadow(
  color: glowColors[user.rank]!,
  blurRadius: 18,
  spreadRadius: 2,
  offset: const Offset(0, -4),
  ),
  ],
  ),
  child: Stack(
  children: [
  // ── Glossy highlight strip ──
  Positioned(
  top: 0,
  left: 0,
  right: 0,
  child: Container(
  height: height * 0.35,
  decoration: BoxDecoration(
  borderRadius: const BorderRadius.only(
  topLeft: Radius.circular(20),
  topRight: Radius.circular(20),
  ),
  gradient: LinearGradient(
  colors: [
  Colors.white.withOpacity(0.22),
  Colors.white.withOpacity(0.0),
  ],
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  ),
  ),
  ),
  ),

  // ── Content ──
  Column(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
  // Medal emoji
  Text(
  medalIcons[user.rank]!,
  style: const TextStyle(fontSize: 22),
  ),
  const SizedBox(height: 4),
  // Rank number
  Text(
  "#${user.rank}",
  style: const TextStyle(
  fontFamily: 'Poppins',
  fontSize: 22,
  fontWeight: FontWeight.w800,
  color: Colors.white,
  height: 1,
  ),
  ),
  const SizedBox(height: 6),
  // Divider line
  Container(
  width: 28,
  height: 1.5,
  decoration: BoxDecoration(
  color: Colors.white.withOpacity(0.45),
  borderRadius: BorderRadius.circular(1),
  ),
  ),
  const SizedBox(height: 8),
  // Weight chip
  Container(
  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  decoration: BoxDecoration(
  color: Colors.black.withOpacity(0.15),
  borderRadius: BorderRadius.circular(20),
  ),
  child: Text(
  user.weight,
  style: const TextStyle(
  fontFamily: 'Poppins',
  fontSize: 11,
  fontWeight: FontWeight.w600,
  color: Colors.white,
  ),
  ),
  ),
  ],
  ),
  ],
  ),
  ),
  );
  }

// ── Avatar + Nama ──────────────────────────────────
  Widget _buildIdentitasUser(_PodiumUser user) {
  // Border color per rank
  final borderColors = {
  1: const Color(0xFFD4F55A),
  2: const Color(0xFF8ECAE6),
  3: const Color(0xFF6BD4A0),
  };

  return Padding(
  padding: const EdgeInsets.only(bottom: 10, left: 6, right: 6),
  child: Column(
  children: [
  // Avatar dengan glow ring
  Container(
  width: 52,
  height: 52,
  decoration: BoxDecoration(
  shape: BoxShape.circle,
  border: Border.all(
  color: borderColors[user.rank]!,
  width: 2,
  ),
  ),
  child: ClipOval(
  child: Image.asset(
  "assets/images/profile.png",
  width: 48,
  height: 48,
  fit: BoxFit.cover,
  ),
  ),
  ),
  const SizedBox(height: 7),
  // Nama
  Text(
  user.name,
  style: const TextStyle(
  fontFamily: 'Poppins',
  fontSize: 10,
  color: Colors.white,
  fontWeight: FontWeight.w600,
  ),
  textAlign: TextAlign.center,
  maxLines: 2,
  overflow: TextOverflow.ellipsis,
  ),
  ],
  ),
  );
  }
}
