import 'package:enviroo/providers/auth_provider.dart';
import 'package:enviroo/providers/katalog_provider.dart';
import 'package:enviroo/widgets/topbar_back.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Enum jenis penarikan
// ─────────────────────────────────────────────────────────────────────────────
enum PenarikanType { uang, sembako, emas }

// ─────────────────────────────────────────────────────────────────────────────
// Color palette
// ─────────────────────────────────────────────────────────────────────────────
class _C {
  static const bg    = Color(0xFFFFFFFF);
  static const dark  = Color(0xFF013236);
  static const green = Color(0xFF4EA771);
  static const lime  = Color(0xFF94DF0C);
  static const card  = Color(0xFFFFFFFF);
  static const mute  = Color(0xFF64748B);
}

class PenarikanScreen extends StatefulWidget {
  final PenarikanType type;
  const PenarikanScreen({Key? key, required this.type}) : super(key: key);

  @override
  State<PenarikanScreen> createState() => _PenarikanScreenState();
}

class _PenarikanScreenState extends State<PenarikanScreen> {
  // ── Uang state ────────────────────────────────────────────────────────
  final TextEditingController _nominalController = TextEditingController();
  final TextEditingController _accountController = TextEditingController();
  String? _selectedMedia;
  int? _selectedQuickAmount;

  // ── Sembako state ─────────────────────────────────────────────────────
  Map<String, int> _cartItems = {}; // sembakoId -> qty

  // ── Emas state ────────────────────────────────────────────────────────
  double _gramEmas = 0;

  final List<Map<String, dynamic>> _mediaOptions = [
    {'value': 'bni',      'label': 'Bank BNI',    'icon': Icons.account_balance_rounded,  'hint': 'Nomor rekening BNI'},
    {'value': 'bca',      'label': 'Bank BCA',    'icon': Icons.account_balance_rounded,  'hint': 'Nomor rekening BCA'},
    {'value': 'mandiri',  'label': 'Bank Mandiri','icon': Icons.account_balance_rounded,  'hint': 'Nomor rekening Mandiri'},
    {'value': 'gopay',    'label': 'GoPay',       'icon': Icons.wallet_rounded,           'hint': 'Nomor HP GoPay'},
    {'value': 'shopeepay','label': 'ShopeePay',   'icon': Icons.shopping_bag_rounded,     'hint': 'Nomor HP ShopeePay'},
    {'value': 'dana',     'label': 'DANA',        'icon': Icons.payments_rounded,         'hint': 'Nomor HP DANA'},
    {'value': 'ovo',      'label': 'OVO',         'icon': Icons.phone_android_rounded,    'hint': 'Nomor HP OVO'},
  ];

  // ── Computed ──────────────────────────────────────────────────────────
  int get _totalPoinSembako {
    final katalog = Provider.of<KatalogProvider>(context, listen: false);
    int total = 0;
    _cartItems.forEach((id, qty) {
      final found = katalog.katalogSembako.where((s) => s.sembakoId == id);
      if (found.isNotEmpty) total += found.first.poin * qty;
    });
    return total;
  }

  String _getAccountHint() {
    if (_selectedMedia == null) return 'Pilih media transfer dulu';
    return _mediaOptions.firstWhere((m) => m['value'] == _selectedMedia)['hint'];
  }

  String get _title {
    switch (widget.type) {
      case PenarikanType.uang:    return 'Pencairan Dana';
      case PenarikanType.sembako: return 'Tukar Sembako';
      case PenarikanType.emas:    return 'Konversi Emas';
    }
  }

  @override
  void dispose() {
    _nominalController.dispose();
    _accountController.dispose();
    super.dispose();
  }

  // ── Theme colours per type ────────────────────────────────────────────
  Color get _accentColor {
    switch (widget.type) {
      case PenarikanType.uang:    return _C.dark;
      case PenarikanType.sembako: return _C.green;
      case PenarikanType.emas:    return const Color(0xFFD4A017);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final saldoPoin = auth.saldoPoin;

    return Scaffold(
      backgroundColor: _C.bg,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                TopBarBack(title: _title),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 120),
                    child: Column(
                      children: [
                        // ── Saldo card ─────────────────────────────────
                        _buildSaldoCard(saldoPoin),
                        const SizedBox(height: 32),
                        // ── Content ───────────────────────────────────
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: _buildContent(saldoPoin),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // ── Bottom CTA button ────────────────────────────────────
            Positioned(
              left: 20,
              right: 20,
              bottom: 24,
              child: _buildCTAButton(saldoPoin),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Premium White Saldo Card
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildSaldoCard(int saldoPoin) {
    int poinTerpakai = 0;
    if (widget.type == PenarikanType.sembako) poinTerpakai = _totalPoinSembako;
    if (widget.type == PenarikanType.emas)    poinTerpakai = (_gramEmas * 50000).toInt();
    if (widget.type == PenarikanType.uang) {
      final nominal = int.tryParse(_nominalController.text.replaceAll('.', '')) ?? 0;
      poinTerpakai = (nominal / 10).toInt(); // Rp 10.000 = 1000 poin
    }
    final bool isOver = poinTerpakai > saldoPoin;

    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _C.dark.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: _C.dark.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              widget.type == PenarikanType.uang ? Icons.account_balance_wallet_rounded
                  : widget.type == PenarikanType.sembako ? Icons.shopping_basket_rounded
                  : Icons.auto_awesome_rounded,
              color: _accentColor,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Saldo Poin Tersedia",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _C.mute,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "${_formatNumber(saldoPoin)} poin",
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: _C.dark,
                  ),
                ),
              ],
            ),
          ),
          if (poinTerpakai > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: (isOver ? Colors.red : _C.lime).withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "-${_formatNumber(poinTerpakai)}",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isOver ? Colors.red[600] : _C.dark,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Content switch
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildContent(int saldoPoin) {
    switch (widget.type) {
      case PenarikanType.uang:    return _buildUangForm();
      case PenarikanType.sembako: return _buildSembakoForm(saldoPoin);
      case PenarikanType.emas:    return _buildEmasForm();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Uang form
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildUangForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel("Nominal Pencairan"),
        _inputCard(
          child: TextFormField(
            controller: _nominalController,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w700, color: _C.dark),
            decoration: InputDecoration(
              hintText: "Masukkan jumlah",
              hintStyle: TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.w500, color: _C.dark.withOpacity(0.3)),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text("Rp", style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w700, color: _accentColor)),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 18),
            ),
            onChanged: (_) => setState(() => _selectedQuickAmount = null),
          ),
        ),
        const SizedBox(height: 14),
        // Quick amounts
        Row(
          children: [50000, 100000, 200000].map((a) {
            final sel = _selectedQuickAmount == a;
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _selectedQuickAmount = a;
                    _nominalController.text = _formatNumber(a);
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: sel ? _accentColor : Colors.white,
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(color: sel ? _accentColor : _C.dark.withOpacity(0.1)),
                  ),
                  child: Text(
                    "Rp ${_formatNumber(a)}",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: sel ? Colors.white : _C.dark,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 32),
        _sectionLabel("Metode Transfer"),
        _inputCard(
          child: Column(
            children: [
              // Dropdown
              InkWell(
                onTap: _showMediaPicker,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 18),
                  child: Row(
                    children: [
                      Icon(
                        _selectedMedia != null
                            ? _mediaOptions.firstWhere((m) => m['value'] == _selectedMedia)['icon']
                            : Icons.payment_rounded,
                        color: _accentColor, size: 22),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          _selectedMedia != null
                              ? _mediaOptions.firstWhere((m) => m['value'] == _selectedMedia)['label']
                              : "Pilih metode transfer",
                          style: TextStyle(
                            fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.w600,
                            color: _selectedMedia != null ? _C.dark : _C.dark.withOpacity(0.35),
                          ),
                        ),
                      ),
                      Icon(Icons.keyboard_arrow_down_rounded, color: _C.dark.withOpacity(0.3), size: 24),
                    ],
                  ),
                ),
              ),
              Divider(height: 1, color: _C.dark.withOpacity(0.08)),
              // Account field
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      _selectedMedia != null && !['bni','bca','mandiri'].contains(_selectedMedia)
                          ? Icons.phone_android_rounded : Icons.credit_card_rounded,
                      color: _accentColor, size: 22),
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextFormField(
                        controller: _accountController,
                        enabled: _selectedMedia != null,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.w600, color: _C.dark),
                        decoration: InputDecoration(
                          hintText: _getAccountHint(),
                          hintStyle: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w500, color: _C.dark.withOpacity(0.3)),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 18),
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
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Sembako form
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildSembakoForm(int saldoPoin) {
    return Consumer<KatalogProvider>(
      builder: (context, katalog, _) {
        final items = katalog.katalogSembako;
        if (katalog.isLoading && items.isEmpty) {
          return const Center(child: Padding(
            padding: EdgeInsets.only(top: 40),
            child: CircularProgressIndicator(),
          ));
        }
        if (items.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Text("Belum ada item sembako tersedia",
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: _C.mute)),
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel("Pilih Kebutuhan Sembako"),
            ...items.map((item) {
              final id   = item.sembakoId;
              final qty  = _cartItems[id] ?? 0;
              final isSel= qty > 0;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isSel ? _accentColor.withOpacity(0.4) : _C.dark.withOpacity(0.08),
                    width: isSel ? 1.5 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _C.dark.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        width: 54, height: 54,
                        color: _accentColor.withOpacity(0.05),
                        child: item.photoUrl.isNotEmpty
                            ? Image.network(item.photoUrl, fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Icon(Icons.shopping_basket_rounded, color: _accentColor, size: 24))
                            : Icon(Icons.shopping_basket_rounded, color: _accentColor, size: 24),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.namaSembako,
                              style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w700, color: _C.dark)),
                          const SizedBox(height: 4),
                          Text("${item.poin} poin",
                              style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600, color: _accentColor)),
                        ],
                      ),
                    ),
                    // Controls
                    if (isSel) ...[
                      _qtyButton(Icons.remove_rounded, () {
                        setState(() {
                          if (qty > 1) _cartItems[id] = qty - 1;
                          else _cartItems.remove(id);
                        });
                      }, border: true),
                      SizedBox(
                        width: 40,
                        child: Text('$qty', textAlign: TextAlign.center,
                            style: const TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w800, color: _C.dark)),
                      ),
                      _qtyButton(Icons.add_rounded, () {
                        setState(() => _cartItems[id] = qty + 1);
                      }, filled: true),
                    ] else
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _cartItems[id] = 1);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: _accentColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text("Pilih",
                              style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w700, color: _accentColor)),
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),

            // Warning exceeded
            if (_totalPoinSembako > saldoPoin)
              _warningBox("Total penggunaan poin melebihi saldo tersedia"),
          ],
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Emas form
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildEmasForm() {
    return Column(
      children: [
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: const Color(0xFFD4A017).withOpacity(0.15)),
            boxShadow: [BoxShadow(color: _C.dark.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 8))],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4A017).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.diamond_rounded, size: 48, color: Color(0xFFD4A017)),
              ),
              const SizedBox(height: 24),
              const Text("Kabar Gembira!",
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w800, color: _C.dark)),
              const SizedBox(height: 12),
              Text(
                "Fitur konversi poin ke emas digital sedang disiapkan khusus untuk nasabah setia. Nantikan kejutan menarik lainnya!",
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Poppins', fontSize: 13, height: 1.6, color: _C.mute),
              ),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4A017),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: const Color(0xFFD4A017).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: const Text("1 gram = 50.000 poin (estimasi)",
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Premium CTA Button
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildCTAButton(int saldoPoin) {
    String label;
    bool enabled = true;
    switch (widget.type) {
      case PenarikanType.uang:
        label = "Ajukan Pencairan Dana";
        final nominal = int.tryParse(_nominalController.text.replaceAll('.', '')) ?? 0;
        enabled = nominal > 0 && _selectedMedia != null && _accountController.text.isNotEmpty && (nominal/10) <= saldoPoin;
        break;
      case PenarikanType.sembako:
        label = "Konfirmasi Penukaran";
        enabled = _cartItems.isNotEmpty && _totalPoinSembako <= saldoPoin;
        break;
      case PenarikanType.emas:
        label = "Beritahu Saya";
        enabled = false;
        break;
    }

    return GestureDetector(
      onTap: enabled ? () {
        HapticFeedback.mediumImpact();
        // TODO: submit logic
      } : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: enabled ? _C.dark : _C.mute.withOpacity(0.15),
          borderRadius: BorderRadius.circular(50),
          boxShadow: enabled
              ? [BoxShadow(color: _C.dark.withOpacity(0.25), blurRadius: 15, offset: const Offset(0, 8))]
              : [],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: enabled ? Colors.white : _C.mute.withOpacity(0.5),
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Bottom sheet: media picker
  // ─────────────────────────────────────────────────────────────────────────
  void _showMediaPicker() {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: _C.dark.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            ),
            const SizedBox(height: 24),
            const Text("Pilih Metode Transfer",
                style: TextStyle(fontFamily: 'Poppins', fontSize: 17, fontWeight: FontWeight.w800, color: _C.dark)),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 32),
                itemCount: _mediaOptions.length,
                separatorBuilder: (_, __) => Divider(height: 1, indent: 70, color: _C.dark.withOpacity(0.05)),
                itemBuilder: (context, index) {
                  final media   = _mediaOptions[index];
                  final isSel   = _selectedMedia == media['value'];
                  return InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _selectedMedia = media['value'];
                        _accountController.clear();
                      });
                      Navigator.pop(context);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isSel ? _accentColor.withOpacity(0.1) : _C.dark.withOpacity(0.03),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(media['icon'], color: isSel ? _accentColor : _C.dark, size: 22),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Text(media['label'],
                                style: TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: isSel ? FontWeight.w700 : FontWeight.w600, color: _C.dark)),
                          ),
                          if (isSel) Icon(Icons.check_circle_rounded, color: _accentColor, size: 24),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────
  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.fromLTRB(8, 0, 0, 12),
    child: Text(text,
        style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w700,
            color: _C.dark.withOpacity(0.8), letterSpacing: 0.3)),
  );

  Widget _inputCard({required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: _C.dark.withOpacity(0.08)),
      boxShadow: [BoxShadow(color: _C.dark.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
    ),
    child: child,
  );

  Widget _qtyButton(IconData icon, VoidCallback onTap, {bool filled = false, bool border = false}) {
    return GestureDetector(
      onTap: () { HapticFeedback.selectionClick(); onTap(); },
      child: Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: filled ? _accentColor : Colors.white,
          shape: BoxShape.circle,
          border: border ? Border.all(color: _accentColor, width: 1.5) : null,
        ),
        child: Icon(icon, size: 20, color: filled ? Colors.white : _accentColor),
      ),
    );
  }

  Widget _warningBox(String msg) => Container(
    margin: const EdgeInsets.only(top: 16),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.red.withOpacity(0.05),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.red.withOpacity(0.1)),
    ),
    child: Row(
      children: [
        Icon(Icons.error_outline_rounded, color: Colors.red[600], size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Text(msg,
              style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600, color: Colors.red[700])),
        ),
      ],
    ),
  );

  String _formatNumber(int n) => n.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
}
