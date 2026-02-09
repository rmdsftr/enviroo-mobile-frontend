import 'package:enviroo/widgets/navbar_penarikan.dart';
import 'package:enviroo/widgets/topbar_back.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PenarikanScreen extends StatefulWidget {
  @override
  State<PenarikanScreen> createState() => _PenarikanScreenState();
}

class _PenarikanScreenState extends State<PenarikanScreen> {
  final TextEditingController _nominalController = TextEditingController();
  final TextEditingController _accountController = TextEditingController();
  String? _selectedMedia;
  int? _selectedQuickAmount;
  int _selectedTab = 0;

  // Cart untuk penukaran poin: Map<item_id, quantity>
  Map<int, int> _cartItems = {};

  final List<Map<String, dynamic>> _mediaOptions = [
    {'value': 'bni', 'label': 'Bank BNI', 'icon': Icons.account_balance_rounded, 'hint': 'Nomor rekening BNI'},
    {'value': 'bca', 'label': 'Bank BCA', 'icon': Icons.account_balance_rounded, 'hint': 'Nomor rekening BCA'},
    {'value': 'mandiri', 'label': 'Bank Mandiri', 'icon': Icons.account_balance_rounded, 'hint': 'Nomor rekening Mandiri'},
    {'value': 'gopay', 'label': 'GoPay', 'icon': Icons.wallet_rounded, 'hint': 'Nomor HP GoPay'},
    {'value': 'shopeepay', 'label': 'ShopeePay', 'icon': Icons.shopping_bag_rounded, 'hint': 'Nomor HP ShopeePay'},
    {'value': 'dana', 'label': 'DANA', 'icon': Icons.payments_rounded, 'hint': 'Nomor HP DANA'},
    {'value': 'ovo', 'label': 'OVO', 'icon': Icons.phone_android_rounded, 'hint': 'Nomor HP OVO'},
  ];

  // Dummy data sembako (sama dengan katalog)
  final List<Map<String, dynamic>> _sembakoItems = [
    {'id': 0, 'nama': 'Beras 5kg', 'gambar': 'assets/images/sembako/beras.png', 'poin': 500},
    {'id': 1, 'nama': 'Minyak Goreng 1L', 'gambar': 'assets/images/sembako/minyak_goreng.png', 'poin': 250},
    {'id': 2, 'nama': 'Gula Pasir 1kg', 'gambar': 'assets/images/sembako/gula.png', 'poin': 150},
    {'id': 3, 'nama': 'Telur 1 Tray', 'gambar': 'assets/images/sembako/telur.png', 'poin': 300},
    {'id': 4, 'nama': 'Mie Instan (5 pcs)', 'gambar': 'assets/images/sembako/mie.png', 'poin': 100},
    {'id': 5, 'nama': 'Kecap Manis 250ml', 'gambar': 'assets/images/sembako/kecap.png', 'poin': 75},
    {'id': 6, 'nama': 'Susu UHT 1L', 'gambar': 'assets/images/sembako/susu.png', 'poin': 120},
    {'id': 7, 'nama': 'Tepung Terigu 1kg', 'gambar': 'assets/images/sembako/tepung.png', 'poin': 100},
  ];

  // Dummy saldo
  final int _saldoUang = 250000;
  final int _saldoPoin = 1500;

  int get _totalPoinDipilih {
    int total = 0;
    _cartItems.forEach((itemId, qty) {
      final item = _sembakoItems.firstWhere((i) => i['id'] == itemId);
      total += (item['poin'] as int) * qty;
    });
    return total;
  }

  String _getAccountHint() {
    if (_selectedMedia == null) return 'Pilih media transfer dulu';
    final media = _mediaOptions.firstWhere((m) => m['value'] == _selectedMedia);
    return media['hint'];
  }

  @override
  void dispose() {
    _nominalController.dispose();
    _accountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                TopBarBack(title: "Penarikan"),
                const SizedBox(height: 8),
                NavbarPenarikan(
                  selectedIndex: _selectedTab,
                  onTabChanged: (index) {
                    setState(() {
                      _selectedTab = index;
                    });
                  },
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 110),
                    child: _selectedTab == 0
                        ? _buildPencairanUang()
                        : _buildPenukaranPoin(),
                  ),
                ),
              ],
            ),
            // Bottom Button
            Positioned(
              left: 20,
              right: 20,
              bottom: 34,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50),
                  color: Colors.black,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF013236).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      // Handle submit
                    },
                    borderRadius: BorderRadius.circular(50),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Text(
                          _selectedTab == 0
                              ? "Ajukan Pencairan Dana"
                              : "Tukarkan Poin",
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
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

  Widget _buildPencairanUang() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 27),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Saldo Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF013236).withOpacity(0.9),
                  Color(0xFF2D5A1D).withOpacity(0.9),
                ],
              ),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Saldo Tersedia",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withOpacity(0.8),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Rp ${_formatNumber(_saldoUang)}",
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // Section Label
          Padding(
            padding: const EdgeInsets.only(left: 17, bottom: 8),
            child: Text(
              "Nominal Pencairan",
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black.withOpacity(0.8),
                letterSpacing: 0.5,
              ),
            ),
          ),

          // Form Card
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(40),
              border: Border.all(
                color: Colors.black.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextFormField(
                    controller: _nominalController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                      letterSpacing: -0.4,
                    ),
                    decoration: InputDecoration(
                      hintText: "Masukkan jumlah",
                      hintStyle: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: Colors.black.withOpacity(0.3),
                        letterSpacing: -0.4,
                      ),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(
                          "Rp",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            color: Colors.black.withOpacity(0.5),
                          ),
                        ),
                      ),
                      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _selectedQuickAmount = null;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 15),

          // Quick Amount Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [50000, 100000, 200000].map((amount) {
                final isSelected = _selectedQuickAmount == amount;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _selectedQuickAmount = amount;
                        _nominalController.text = _formatNumber(amount);
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF013236).withOpacity(0.12) : Colors.white,
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF013236).withOpacity(0.3) : Colors.black.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        "Rp ${_formatNumber(amount)}",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected ? const Color(0xFF013236) : Colors.black.withOpacity(0.6),
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 30),

          // Section Label
          Padding(
            padding: const EdgeInsets.only(left: 17, bottom: 8),
            child: Text(
              "Metode Transfer",
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black.withOpacity(0.8),
                letterSpacing: 0.5,
              ),
            ),
          ),

          // Transfer Method Card
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: Colors.black.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _showMediaPicker(),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Icon(
                            _selectedMedia != null
                                ? _mediaOptions.firstWhere((m) => m['value'] == _selectedMedia)['icon']
                                : Icons.payment_rounded,
                            color: const Color(0xFF013236),
                            size: 20,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              _selectedMedia != null
                                  ? _mediaOptions.firstWhere((m) => m['value'] == _selectedMedia)['label']
                                  : "Pilih metode",
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                                color: _selectedMedia != null ? Colors.black : Colors.black.withOpacity(0.3),
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.black.withOpacity(0.25),
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                Container(
                  margin: const EdgeInsets.only(left: 52),
                  height: 0.5,
                  color: Colors.black.withOpacity(0.2),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Icon(
                        _selectedMedia != null && !['bni', 'bca', 'mandiri'].contains(_selectedMedia)
                            ? Icons.phone_android_rounded
                            : Icons.credit_card_rounded,
                        color: const Color(0xFF013236),
                        size: 20,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: TextFormField(
                          controller: _accountController,
                          enabled: _selectedMedia != null,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            color: Colors.black,
                            letterSpacing: -0.3,
                          ),
                          decoration: InputDecoration(
                            hintText: _getAccountHint(),
                            hintStyle: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                              color: Colors.black.withOpacity(0.3),
                              letterSpacing: -0.3,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPenukaranPoin() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 27),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Saldo Poin Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF013236).withOpacity(0.9),
                  Color(0xFF2D5A1D).withOpacity(0.9),
                ],
              ),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.stars_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Saldo Poin Tersedia",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withOpacity(0.9),
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "${_formatNumber(_saldoPoin)} poin",
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                // Total poin dipilih
                if (_cartItems.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "-${_formatNumber(_totalPoinDipilih)}",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _totalPoinDipilih > _saldoPoin ? Colors.red[100] : Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Section Label
          Padding(
            padding: const EdgeInsets.only(left: 17, bottom: 12),
            child: Text(
              "Pilih Sembako",
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black.withOpacity(0.8),
                letterSpacing: 0.5,
              ),
            ),
          ),

          // Sembako Items Grid
          ..._sembakoItems.map((item) {
            final int itemId = item['id'];
            final int qty = _cartItems[itemId] ?? 0;
            final bool isSelected = qty > 0;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF4EA771).withOpacity(0.08) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? const Color(0xFF4EA771).withOpacity(0.3) : Colors.black.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  // Image placeholder
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Color(0xFF4EA771).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.shopping_basket_rounded,
                        size: 24,
                        color: Color(0xFF4EA771),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['nama'],
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF013236),
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${item['poin']} poin',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF4EA771),
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Quantity Controls
                  if (isSelected) ...[
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          if (qty > 1) {
                            _cartItems[itemId] = qty - 1;
                          } else {
                            _cartItems.remove(itemId);
                          }
                        });
                      },
                      child: Container(
                        width: 25,
                        height: 25,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(
                            color: Colors.black.withOpacity(0.1),
                          ),
                        ),
                        child: Icon(
                          Icons.remove_rounded,
                          size: 18,
                          color: Colors.black.withOpacity(0.6),
                        ),
                      ),
                    ),
                    Container(
                      width: 36,
                      alignment: Alignment.center,
                      child: Text(
                        '$qty',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF013236),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _cartItems[itemId] = qty + 1;
                        });
                      },
                      child: Container(
                        width: 25,
                        height: 25,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4EA771),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: const Icon(
                          Icons.add_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ] else
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _cartItems[itemId] = 1;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4EA771).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Pilih',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF4EA771),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          }).toList(),

          // Warning jika melebihi saldo
          if (_totalPoinDipilih > _saldoPoin)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.red.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_rounded,
                    color: Colors.red[400],
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Total poin melebihi saldo tersedia",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.red[400],
                        letterSpacing: -0.2,
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

  void _showMediaPicker() {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Pilih Metode Transfer",
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black.withOpacity(0.8),
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                itemCount: _mediaOptions.length,
                itemBuilder: (context, index) {
                  final media = _mediaOptions[index];
                  final isSelected = _selectedMedia == media['value'];
                  return Column(
                    children: [
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _selectedMedia = media['value'];
                              _accountController.clear();
                            });
                            Navigator.pop(context);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            child: Row(
                              children: [
                                Icon(
                                  media['icon'],
                                  color: const Color(0xFF013236),
                                  size: 24,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    media['label'],
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.black,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(
                                    Icons.check_rounded,
                                    color: Color(0xFF013236),
                                    size: 18,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (index < _mediaOptions.length - 1)
                        Container(
                          margin: const EdgeInsets.only(left: 60),
                          height: 0.5,
                          color: Colors.black.withOpacity(0.08),
                        ),
                    ],
                  );
                },
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
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
