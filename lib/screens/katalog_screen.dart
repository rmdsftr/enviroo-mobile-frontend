import 'package:enviroo/widgets/navbar_katalog.dart';
import 'package:enviroo/widgets/topbar_back.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class KatalogScreen extends StatefulWidget {
  @override
  State<KatalogScreen> createState() => _KatalogScreenState();
}

class _KatalogScreenState extends State<KatalogScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _searchSembakoController = TextEditingController();
  final GlobalKey _headerKey = GlobalKey();
  String _selectedFilter = 'semua';
  String _searchQuery = '';
  String _searchSembakoQuery = '';
  int _selectedTab = 0;
  double _headerHeight = 0;

  // Dummy data untuk katalog sampah
  final List<Map<String, dynamic>> _katalogItems = [
    {'nama': 'Botol Plastik', 'gambar': 'assets/images/sampah/botol_plastik.png', 'tipe': 'uang', 'harga': 3000},
    {'nama': 'Kardus', 'gambar': 'assets/images/sampah/kardus.png', 'tipe': 'uang', 'harga': 2000},
    {'nama': 'Kaleng Aluminium', 'gambar': 'assets/images/sampah/kaleng.png', 'tipe': 'uang', 'harga': 8000},
    {'nama': 'Kertas HVS', 'gambar': 'assets/images/sampah/kertas.png', 'tipe': 'poin', 'harga': 15},
    {'nama': 'Botol Kaca', 'gambar': 'assets/images/sampah/botol_kaca.png', 'tipe': 'uang', 'harga': 1500},
    {'nama': 'Plastik Kemasan', 'gambar': 'assets/images/sampah/plastik_kemasan.png', 'tipe': 'poin', 'harga': 10},
    {'nama': 'Besi Bekas', 'gambar': 'assets/images/sampah/besi.png', 'tipe': 'uang', 'harga': 5000},
    {'nama': 'Minyak Jelantah', 'gambar': 'assets/images/sampah/minyak.png', 'tipe': 'poin', 'harga': 25},
  ];

  // Dummy data untuk katalog sembako
  final List<Map<String, dynamic>> _sembakoItems = [
    {'nama': 'Beras 5kg', 'gambar': 'assets/images/sembako/beras.png', 'poin': 500},
    {'nama': 'Minyak Goreng 1L', 'gambar': 'assets/images/sembako/minyak_goreng.png', 'poin': 250},
    {'nama': 'Gula Pasir 1kg', 'gambar': 'assets/images/sembako/gula.png', 'poin': 150},
    {'nama': 'Telur 1 Tray', 'gambar': 'assets/images/sembako/telur.png', 'poin': 300},
    {'nama': 'Mie Instan (5 pcs)', 'gambar': 'assets/images/sembako/mie.png', 'poin': 100},
    {'nama': 'Kecap Manis 250ml', 'gambar': 'assets/images/sembako/kecap.png', 'poin': 75},
    {'nama': 'Susu UHT 1L', 'gambar': 'assets/images/sembako/susu.png', 'poin': 120},
    {'nama': 'Tepung Terigu 1kg', 'gambar': 'assets/images/sembako/tepung.png', 'poin': 100},
  ];

  List<Map<String, dynamic>> get _filteredItems {
    return _katalogItems.where((item) {
      final matchesFilter = _selectedFilter == 'semua' || item['tipe'] == _selectedFilter;
      final matchesSearch = item['nama'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesFilter && matchesSearch;
    }).toList();
  }

  List<Map<String, dynamic>> get _filteredSembakoItems {
    return _sembakoItems.where((item) {
      return item['nama'].toString().toLowerCase().contains(_searchSembakoQuery.toLowerCase());
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateHeaderHeight();
    });
  }

  void _calculateHeaderHeight() {
    final RenderBox? renderBox = _headerKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      setState(() {
        _headerHeight = renderBox.size.height;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchSembakoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String descriptionText = _selectedTab == 0
        ? "Katalog ini merupakan harga sampah yang bernilai ketika kamu menyetorkan sampah"
        : "Katalog ini merupakan sembako yang bisa kamu dapat dengan menukarkan saldo poin tabunganmu";

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Calculate sheet sizes based on header height and available space
            final double availableHeight = constraints.maxHeight;
            final double sheetMinHeight = availableHeight - _headerHeight;
            final double minChildSize = _headerHeight > 0 
                ? (sheetMinHeight / availableHeight).clamp(0.3, 0.9)
                : 0.7;
            final double maxChildSize = 0.95;

            return Stack(
              children: [
                // Header content (stays behind)
                Column(
                  key: _headerKey,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TopBarBack(title: "Katalog"),
                    NavbarKatalog(
                      selectedIndex: _selectedTab,
                      onTabChanged: (index) {
                        setState(() {
                          _selectedTab = index;
                        });
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                      child: Text(
                        descriptionText,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: Colors.black.withOpacity(0.6),
                        ),
                      ),
                    ),
                  ],
                ),
                // Draggable Sheet
                DraggableScrollableSheet(
                  initialChildSize: minChildSize,
                  minChildSize: minChildSize,
                  maxChildSize: maxChildSize,
                  builder: (context, scrollController) {
                    return _selectedTab == 0
                        ? _ListKatalogSampah(scrollController)
                        : _ListKatalogSembako(scrollController);
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _ListKatalogSampah(ScrollController scrollController) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF013236),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          // Handle bar (drag indicator)
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 20),
            width: 36,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.4),
              borderRadius: BorderRadius.circular(3),
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFEAF8E7),
                borderRadius: BorderRadius.circular(40),
                border: Border.all(
                  color: const Color(0xFF4EA771).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  color: Color(0xFF013236),
                  letterSpacing: -0.3,
                ),
                decoration: InputDecoration(
                  hintText: "Cari jenis sampah...",
                  hintStyle: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 15,
                    color: const Color(0xFF013236).withOpacity(0.4),
                    letterSpacing: -0.3,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: const Color(0xFF4EA771),
                    size: 22,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Filter Chips - Segmented Style
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF8E7),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Row(
                children: [
                  _buildFilterChip('semua', 'Semua'),
                  const SizedBox(width: 4),
                  _buildFilterChip('uang', 'Uang'),
                  const SizedBox(width: 4),
                  _buildFilterChip('poin', 'Poin'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // List Items
          Expanded(
            child: _filteredItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 48,
                          color: const Color(0xFF013236).withOpacity(0.25),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Tidak ada hasil",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            color: const Color(0xFF013236).withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    physics: const BouncingScrollPhysics(),
                    itemCount: _filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = _filteredItems[index];
                      final isFirst = index == 0;
                      final isLast = index == _filteredItems.length - 1;
                      return _buildItemCard(item, isFirst, isLast);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _ListKatalogSembako(ScrollController scrollController) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF013236), // Changed from 0xFFC1E6BA
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30), // Changed from 24
          topRight: Radius.circular(30), // Changed from 24
        ),
      ),
      child: Column(
        children: [
          // Handle bar (drag indicator)
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 20),
            width: 36,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.4), // Changed from Color(0xFF013236).withOpacity(0.25)
              borderRadius: BorderRadius.circular(3),
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFEAF8E7), // Changed from Colors.white
                borderRadius: BorderRadius.circular(40),
                border: Border.all( // Added border
                  color: const Color(0xFF4EA771).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _searchSembakoController,
                onChanged: (value) {
                  setState(() {
                    _searchSembakoQuery = value;
                  });
                },
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  color: Color(0xFF013236), // Changed from Colors.black
                  letterSpacing: -0.3,
                ),
                decoration: InputDecoration(
                  hintText: "Cari sembako...",
                  hintStyle: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 15,
                    color: const Color(0xFF013236).withOpacity(0.4), // Changed from Colors.black.withOpacity(0.35)
                    letterSpacing: -0.3,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: const Color(0xFF4EA771), // Changed from Colors.black.withOpacity(0.4)
                    size: 22,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // List Items
          Expanded(
            child: _filteredSembakoItems.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off_rounded,
                    size: 48,
                    color: const Color(0xFF013236).withOpacity(0.25),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Tidak ada hasil",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      color: const Color(0xFF013236).withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              physics: const BouncingScrollPhysics(),
              itemCount: _filteredSembakoItems.length,
              itemBuilder: (context, index) {
                final item = _filteredSembakoItems[index];
                final isFirst = index == 0;
                final isLast = index == _filteredSembakoItems.length - 1;
                return _buildSembakoItemCard(item, isFirst, isLast);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() {
            _selectedFilter = value;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF4EA771) : Colors.transparent,
            borderRadius: BorderRadius.circular(50),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF013236).withOpacity(0.7),
                letterSpacing: -0.2,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItemCard(Map<String, dynamic> item, bool isFirst, bool isLast) {
    final bool isUang = item['tipe'] == 'uang';
    final String priceText = isUang
        ? 'Rp ${_formatNumber(item['harga'])}/kg'
        : '${item['harga']} poin/kg';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF8E7),
        borderRadius: BorderRadius.vertical(
          top: isFirst ? const Radius.circular(25) : Radius.zero,
          bottom: isLast ? const Radius.circular(25) : Radius.zero,
        ),
        border: !isLast
            ? Border(
                bottom: BorderSide(
                  color: const Color(0xFF4EA771).withOpacity(0.2),
                  width: 1,
                ),
              )
            : null,
      ),
      child: Row(
        children: [
          // Image placeholder
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF013236),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Center(
              child: Icon(
                Icons.recycling_rounded,
                size: 24,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name
                Text(
                  item['nama'],
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF013236),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),

                // Price
                Text(
                  priceText,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF013236).withOpacity(0.6),
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),

          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isUang
                  ? const Color(0xFF06C0C9).withOpacity(0.12)
                  : const Color(0xFFFF9500).withOpacity(0.12),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Text(
              isUang ? 'Uang' : 'Poin',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isUang ? const Color(0xFF06C0C9) : const Color(0xFFFF9500),
                letterSpacing: -0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSembakoItemCard(Map<String, dynamic> item, bool isFirst, bool isLast) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF8E7), // Changed from Colors.white
        borderRadius: BorderRadius.vertical(
          top: isFirst ? const Radius.circular(25) : Radius.zero,
          bottom: isLast ? const Radius.circular(25) : Radius.zero,
        ),
        border: !isLast
            ? Border(
          bottom: BorderSide(
            color: const Color(0xFF4EA771).withOpacity(0.2), // Changed from Color(0xFF013236).withOpacity(0.1)
            width: 1, // Changed from 0.5
          ),
        )
            : null,
      ),
      child: Row(
        children: [
          // Image placeholder
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF013236),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Center(
              child: Icon(
                Icons.shopping_basket_rounded,
                size: 24,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name
                Text(
                  item['nama'],
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF013236),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),

                // Poin
                Text(
                  '${item['poin']} poin',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF013236).withOpacity(0.6),
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }
}
