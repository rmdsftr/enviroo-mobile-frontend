import 'package:enviroo/layouts/balance.dart';
import 'package:enviroo/layouts/informasi_layouts.dart';
import 'package:enviroo/layouts/jadwal_layouts.dart';
import 'package:enviroo/layouts/menu_layouts.dart';
import 'package:enviroo/providers/auth_provider.dart';
import 'package:enviroo/providers/konten_provider.dart';
import 'package:enviroo/screens/katalog_screen.dart';
import 'package:enviroo/services/reward_overview_service.dart';
import 'package:enviroo/services/riwayat_transaksi_service.dart';
import 'package:enviroo/widgets/filter_chip_row.dart';
import 'package:enviroo/widgets/navbar.dart';
import 'package:enviroo/widgets/topbar_custom.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);
  
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}


class _HomeScreenState extends State<HomeScreen> {
  int _selectedNavIndex = 0;
  
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

  // ── Riwayat Transaksi state ──────────────────────────────────────
  bool _transaksiLoading = true;
  String? _transaksiError;
  List<Map<String, dynamic>> _transaksiList = [];
  bool _transaksiFetched = false;
  String _filterJenis = 'semua'; // 'semua' | 'setoran' | 'penarikan'

  Future<void> _fetchRiwayatTransaksi() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final nasabahId = auth.identityId;
    final token = auth.currentUser?.accessToken;
    if (nasabahId == null || token == null) return;

    setState(() {
      _transaksiLoading = true;
      _transaksiError = null;
    });

    final result = await RiwayatTransaksiService.getRiwayatTransaksi(nasabahId, token);

    if (!mounted) return;
    if (result['success'] == true) {
      setState(() {
        _transaksiList = List<Map<String, dynamic>>.from(result['data'] ?? []);
        _transaksiLoading = false;
        _transaksiFetched = true;
      });
    } else {
      setState(() {
        _transaksiError = result['message'] ?? 'Gagal memuat riwayat transaksi';
        _transaksiLoading = false;
        _transaksiFetched = true;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredTransaksi {
    return _transaksiList.where((t) {
      final raw = t['tanggal'] as String? ?? '';
      DateTime? date;
      try { date = DateTime.parse(raw.replaceAll(' ', 'T')); } catch (_) {}

      final matchesMonth = date == null ||
          (date.month == _selectedMonth && date.year == _selectedYear);
      final jenis = (t['jenis_transaksi'] as String? ?? '').toLowerCase();
      final matchesJenis = _filterJenis == 'semua' ||
          (_filterJenis == 'setoran' && jenis == 'setoran') ||
          (_filterJenis == 'penarikan' && jenis != 'setoran');
      return matchesMonth && matchesJenis;
    }).toList();
  }

  Widget _buildTransaksiLayouts() {
    if (!_transaksiFetched) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fetchRiwayatTransaksi());
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: Colors.white
      ),
      child: Column(
        children: [
          // ── Filter bulan/tahun ──
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GestureDetector(
              onTap: () => _showMonthYearPicker(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                decoration: BoxDecoration(
                  color: const Color(0xFF013236).withOpacity(0.07),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF013236).withAlpha(22),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.calendar_today_rounded,
                          size: 14, color: Color(0xFF013236)),
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
                    Icon(Icons.keyboard_arrow_down_rounded,
                        size: 20, color: const Color(0xFF013236).withAlpha(140)),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── Filter chip: Semua / Setoran / Penarikan ──
          FilterChipRow<String>(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            selectedValue: _filterJenis,
            onSelected: (v) => setState(() => _filterJenis = v),
            items: const [
              FilterChipItem(value: 'semua', label: 'Semua'),
              FilterChipItem(value: 'setoran', label: 'Setoran'),
              FilterChipItem(value: 'penarikan', label: 'Penarikan'),
            ],
          ),

          const SizedBox(height: 8),

          // ── List ──
          Expanded(child: _buildTransaksiList()),
        ],
      ),
    );
  }

  Widget _buildTransaksiList() {
    if (_transaksiLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF4EA771)),
      );
    }

    if (_transaksiError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: Colors.redAccent, size: 44),
              const SizedBox(height: 12),
              Text(_transaksiError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 13)),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4EA771),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50)),
                ),
                onPressed: () {
                  _transaksiFetched = false;
                  _fetchRiwayatTransaksi();
                },
                child: const Text('Coba lagi',
                    style: TextStyle(fontFamily: 'Poppins')),
              ),
            ],
          ),
        ),
      );
    }

    final list = _filteredTransaksi;

    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 52, color: const Color(0xFF013236).withAlpha(40)),
            const SizedBox(height: 14),
            Text(
              'Tidak ada transaksi',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: const Color(0xFF013236).withAlpha(100),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 16),
      physics: const BouncingScrollPhysics(),
      itemCount: list.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        color: const Color(0xFF013236).withOpacity(0.06),
      ),
      itemBuilder: (context, i) {
        final t = list[i];
        final raw = t['tanggal'] as String? ?? '';
        DateTime? date;
        try { date = DateTime.parse(raw.replaceAll(' ', 'T')); } catch (_) {}

        final jenis = (t['jenis_transaksi'] as String? ?? '').toLowerCase();
        final isSetoran = jenis == 'setoran';
        final jumlah = (t['jumlah'] as num?)?.toDouble() ?? 0;

        // Format tanggal
        String tanggalStr = '-';
        if (date != null) {
          tanggalStr =
              '${date.day.toString().padLeft(2, '0')}/'
              '${date.month.toString().padLeft(2, '0')}/'
              '${date.year}';
        }
        String jamStr = '';
        if (date != null) {
          jamStr =
              '${date.hour.toString().padLeft(2, '0')}:'
              '${date.minute.toString().padLeft(2, '0')}';
        }

        // Format angka
        final jumlahAbs = jumlah.abs();
        String jumlahStr;
        if (jumlahAbs == jumlahAbs.truncateToDouble()) {
          jumlahStr = jumlahAbs.toInt().toString();
        } else {
          jumlahStr = jumlahAbs.toStringAsFixed(2);
        }
        final numParts = jumlahStr.split('.');
        final intPart = numParts[0].replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
        jumlahStr = numParts.length > 1 ? '$intPart,${numParts[1]}' : intPart;

        final color = isSetoran ? const Color(0xFF2E9F6A) : const Color(0xFFD94040);
        final bgColor = isSetoran ? const Color(0xFFF0FAF4) : const Color(0xFFFDF2F2);
        final prefix = isSetoran ? '+' : '-';
        final jenisLabel = isSetoran ? 'Setoran' : 'Penarikan';
        final jenisIcon = isSetoran
            ? Icons.arrow_upward_rounded
            : Icons.arrow_downward_rounded;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            children: [
              // ── Icon badge ──
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(jenisIcon, color: color, size: 22),
              ),
              const SizedBox(width: 14),

              // ── Info kiri ──
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      jenisLabel,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF013236),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$tanggalStr${jamStr.isNotEmpty ? '  •  $jamStr' : ''}',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: const Color(0xFF013236).withOpacity(0.4),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Jumlah kanan ──
              Text(
                '$prefix $jumlahStr',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
        );
      },
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

  // ─── Reward Overview ─────────────────────────────────────────────
  bool _rewardLoading = true;
  String? _rewardError;
  String _rewardDeskripsi = '';
  List<Map<String, dynamic>> _rewardList = [];
  bool _rewardFetched = false;

  Future<void> _fetchRewardOverview() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final nasabahId = auth.identityId;
    final token = auth.currentUser?.accessToken;
    if (nasabahId == null || token == null) return;

    setState(() {
      _rewardLoading = true;
      _rewardError = null;
    });

    final result = await RewardOverviewService.getRewardOverview(nasabahId, token);

    if (!mounted) return;
    if (result['success'] == true && result['data'] != null) {
      final data = result['data'] as Map<String, dynamic>;
      setState(() {
        _rewardDeskripsi = data['deskripsi_menu'] ?? '';
        _rewardList = List<Map<String, dynamic>>.from(data['list_reward'] ?? []);
        _rewardLoading = false;
        _rewardFetched = true;
      });
    } else {
      setState(() {
        _rewardError = result['message'] ?? 'Gagal memuat data reward';
        _rewardLoading = false;
        _rewardFetched = true;
      });
    }
  }

  String _formatKonversi(double v) {
    if (v == v.truncateToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(4).replaceAll(RegExp(r'0*$'), '').replaceAll(RegExp(r'\.$'), '');
  }

  Widget _buildRewardLayouts() {
    // Fetch once when tab is opened
    if (!_rewardFetched) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fetchRewardOverview());
    }

    if (_rewardLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF4EA771)),
      );
    }

    if (_rewardError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
              const SizedBox(height: 12),
              Text(
                _rewardError!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4EA771),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                ),
                onPressed: () {
                  _rewardFetched = false;
                  _fetchRewardOverview();
                },
                child: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Reward Penukaran Saldo',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF013236),
                  ),
                ),
                if (_rewardDeskripsi.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    _rewardDeskripsi,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: Color(0xFF013236).withOpacity(0.6),
                      height: 1.5,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 15),

          // ── Reward cards ──
          if (_rewardList.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Icon(Icons.card_giftcard_outlined, size: 48,
                      color: const Color(0xFF013236).withOpacity(0.25)),
                  const SizedBox(height: 10),
                  Text(
                    'Belum ada reward tersedia',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      color: const Color(0xFF013236).withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            )
          else
            ...List.generate(_rewardList.length, (i) {
              final r = _rewardList[i];
              return _RewardCard(rewardData: r);
            }),
        ],
      ),
    );
  }
}

// ─── Reward Card Widget ─────────────────────────────────────────────────────

class _RewardCard extends StatefulWidget {
  final Map<String, dynamic> rewardData;
  const _RewardCard({required this.rewardData});

  @override
  State<_RewardCard> createState() => _RewardCardState();
}

class _RewardCardState extends State<_RewardCard> with SingleTickerProviderStateMixin {
  bool _expanded = false;
  final TextEditingController _poinCtrl = TextEditingController();
  late AnimationController _animCtrl;
  late Animation<double> _expandAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _expandAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _poinCtrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    if (_expanded) {
      _animCtrl.forward();
    } else {
      _animCtrl.reverse();
      _poinCtrl.clear();
    }
  }

  String _formatNumber(double v, bool isEmas) {
    if (isEmas) {
      // Tampilkan sampai 4 desimal, hapus trailing zero
      final s = v.toStringAsFixed(4).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
      return '$s gram';
    } else {
      // Format Rupiah
      final parts = v.toStringAsFixed(0).split('').reversed.toList();
      final buffer = StringBuffer();
      for (int i = 0; i < parts.length; i++) {
        if (i > 0 && i % 3 == 0) buffer.write('.');
        buffer.write(parts[i]);
      }
      return 'Rp ${buffer.toString().split('').reversed.join('')}';
    }
  }

  String get _kalkulasiHasil {
    final rasioPoin = (widget.rewardData['rasio_poin'] as num?)?.toDouble() ?? 0;
    final rasioKonversi = (widget.rewardData['rasio_konversi'] as num?)?.toDouble() ?? 0;
    final nama = (widget.rewardData['nama_reward'] ?? '') as String;
    final isEmas = nama.toLowerCase() == 'emas';

    final inputPoin = double.tryParse(_poinCtrl.text.replaceAll(',', '').replaceAll('.', ''));
    if (inputPoin == null || inputPoin <= 0 || rasioPoin <= 0) return '-';

    final hasil = (inputPoin / rasioPoin) * rasioKonversi;
    return _formatNumber(hasil, isEmas);
  }

  @override
  Widget build(BuildContext context) {
    final nama = (widget.rewardData['nama_reward'] ?? '-') as String;
    final deskripsi = (widget.rewardData['deskripsi_reward'] ?? '') as String;
    final rasioPoin = (widget.rewardData['rasio_poin'] as num?)?.toDouble() ?? 0;
    final rasioKonversi = (widget.rewardData['rasio_konversi'] as num?)?.toDouble() ?? 0;
    final isSembako = nama.toLowerCase() == 'sembako';
    final isEmas = nama.toLowerCase() == 'emas';
    final hasCalculator = !isSembako; // Uang & Emas punya kalkulator

    // Icon & accent per tipe
    IconData icon;
    Color accent;
    if (isEmas) {
      icon = Icons.auto_awesome_rounded;
      accent = const Color(0xFFD4A017);
    } else if (isSembako) {
      icon = Icons.shopping_basket_rounded;
      accent = const Color(0xFF4EA771);
    } else {
      icon = Icons.account_balance_wallet_rounded;
      accent = const Color(0xFF1E88E5);
    }

    String konversiLabel;
    if (isSembako) {
      konversiLabel = 'Lihat katalog sembako';
    } else if (isEmas) {
      konversiLabel = '${rasioPoin.toInt()} poin = ${rasioKonversi} gram';
    } else {
      konversiLabel = '${rasioPoin.toInt()} poin = Rp ${rasioKonversi.toInt()}';
    }

    return GestureDetector(
      onTap: hasCalculator ? _toggle : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _expanded ? accent.withOpacity(0.4) : accent.withOpacity(0.2),
            width: _expanded ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _expanded
                  ? accent.withOpacity(0.12)
                  : Colors.black.withOpacity(0.04),
              blurRadius: _expanded ? 14 : 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ──
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: accent, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    nama,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF013236),
                    ),
                  ),
                ),
                if (hasCalculator)
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 280),
                    child: Icon(Icons.keyboard_arrow_down_rounded,
                        color: accent, size: 22),
                  ),
              ],
            ),

            // ── Deskripsi ──
            if (deskripsi.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                deskripsi,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: const Color(0xFF013236).withOpacity(0.6),
                  height: 1.45,
                ),
              ),
            ],

            const SizedBox(height: 12),

            // ── Konversi chip ──
            GestureDetector(
              onTap: isSembako
                  ? () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const KatalogScreen(
                            role: 'nasabah',
                            initialTab: 1,
                          ),
                        ),
                      )
                  : null,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isSembako ? Icons.arrow_forward_rounded : Icons.swap_horiz_rounded,
                      size: 16,
                      color: accent,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        konversiLabel,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: accent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Kalkulator (dropdown, hanya Uang & Emas) ──
            if (hasCalculator)
              SizeTransition(
                sizeFactor: _expandAnim,
                axisAlignment: -1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Divider(color: accent.withOpacity(0.15), thickness: 1, height: 1),
                    const SizedBox(height: 14),
                    Text(
                      'Kalkulator Konversi',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF013236).withOpacity(0.7),
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Input poin
                    TextField(
                      controller: _poinCtrl,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        color: Color(0xFF013236),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Masukkan jumlah poin',
                        hintStyle: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          color: const Color(0xFF013236).withOpacity(0.35),
                        ),
                        suffixText: 'poin',
                        suffixStyle: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: accent,
                        ),
                        filled: true,
                        fillColor: accent.withOpacity(0.05),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: accent.withOpacity(0.2)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: accent, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Hasil konversi
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: accent.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isEmas
                                ? Icons.auto_awesome_rounded
                                : Icons.account_balance_wallet_rounded,
                            color: accent,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Kamu akan mendapatkan',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 11,
                                  color: const Color(0xFF013236).withOpacity(0.55),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _poinCtrl.text.isEmpty ? '-' : _kalkulasiHasil,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: accent,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
