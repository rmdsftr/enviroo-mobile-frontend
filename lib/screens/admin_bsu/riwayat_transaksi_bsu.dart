import 'package:enviroo/models/transaksi_model.dart';
import 'package:enviroo/widgets/navbar_transaksi.dart';
import 'package:enviroo/widgets/topbar_back.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

// ─────────────────────────────────────────────────────────────────────────────
// App Color Palette  (harmonised with balance, navbar, home_screen)
// ─────────────────────────────────────────────────────────────────────────────
class _C {
  // core
  static const dark      = Color(0xFF013236);   // primary dark teal
  static const green     = Color(0xFF4EA771);   // primary green
  static const bgLight   = Color(0xFFFFFFFF);   // scaffold bg
  static const softGreen = Color(0xFFFFFFFF);   // card / chip bg
  static const cardBg    = Color(0xFFF7FBF5);   // very faint green tint for cards

  // status (derived from the green family)
  static const success   = Color(0xFF4EA771);   // berhasil / selesai
  static const fail      = Color(0xFFD94848);   // gagal / dibatalkan
  static const pending   = Color(0xFFE6A817);   // sedang diajukan
  static const approved  = Color(0xFF2AA8A1);   // disetujui  (teal-green)
  static const onRoute   = Color(0xFF3A8FD6);   // sedang perjalanan
}

// ─────────────────────────────────────────────────────────────────────────────
// Pengangkutan Model (BSU → BSI)
// ─────────────────────────────────────────────────────────────────────────────
enum StatusPengangkutan {
  sedangDiajukan,
  disetujui,
  dibatalkan,
  sedangPerjalanan,
  selesai,
}

class PengangkutanBsu {
  final String id;
  final DateTime tanggal;
  final StatusPengangkutan status;
  final String adminBsuName;
  final String adminBsiName;
  final List<TransaksiItem>? detailSampah;

  PengangkutanBsu({
    required this.id,
    required this.tanggal,
    required this.status,
    required this.adminBsuName,
    required this.adminBsiName,
    this.detailSampah,
  });

  int get totalUang => (detailSampah ?? [])
      .where((i) => i.nilaiType == NilaiType.uang)
      .fold(0, (sum, item) => sum + item.nilai);

  int get totalPoin => (detailSampah ?? [])
      .where((i) => i.nilaiType == NilaiType.poin)
      .fold(0, (sum, item) => sum + item.nilai);
}

// ─────────────────────────────────────────────────────────────────────────────
// Setoran BSU Model (admin perspective)
// ─────────────────────────────────────────────────────────────────────────────
class SetoranBsu {
  final String id;
  final DateTime tanggal;
  final bool isSuccess;
  final String nasabahName;
  final String adminName;
  final List<TransaksiItem> items;

  SetoranBsu({
    required this.id,
    required this.tanggal,
    required this.isSuccess,
    required this.nasabahName,
    required this.adminName,
    required this.items,
  });

  int get totalUang =>
      items.where((i) => i.nilaiType == NilaiType.uang).fold(0, (s, i) => s + i.nilai);
  int get totalPoin =>
      items.where((i) => i.nilaiType == NilaiType.poin).fold(0, (s, i) => s + i.nilai);
}

// ─────────────────────────────────────────────────────────────────────────────
// Dummy data — Setoran
// ─────────────────────────────────────────────────────────────────────────────
List<SetoranBsu> getDummySetoranBsuData() {
  return [
    SetoranBsu(
      id: 'sb1',
      tanggal: DateTime(2026, 2, 14, 9, 30),
      isSuccess: true,
      nasabahName: 'Ramadhani Safitri',
      adminName: 'Budi Santoso',
      items: [
        TransaksiItem(nama: 'Botol Plastik', jumlah: '3 kg', nilai: 9000, nilaiType: NilaiType.uang),
        TransaksiItem(nama: 'Kardus', jumlah: '2 kg', nilai: 4000, nilaiType: NilaiType.uang),
        TransaksiItem(nama: 'Kertas HVS', jumlah: '1 kg', nilai: 15, nilaiType: NilaiType.poin),
      ],
    ),
    SetoranBsu(
      id: 'sb2',
      tanggal: DateTime(2026, 2, 13, 14, 15),
      isSuccess: false,
      nasabahName: 'Siti Aminah',
      adminName: 'Budi Santoso',
      items: [],
    ),
    SetoranBsu(
      id: 'sb3',
      tanggal: DateTime(2026, 2, 10, 10, 0),
      isSuccess: true,
      nasabahName: 'Ahmad Fauzi',
      adminName: 'Ramadhani Safitri',
      items: [
        TransaksiItem(nama: 'Kaleng Aluminium', jumlah: '5 kg', nilai: 40000, nilaiType: NilaiType.uang),
        TransaksiItem(nama: 'Besi Bekas', jumlah: '3 kg', nilai: 15000, nilaiType: NilaiType.uang),
        TransaksiItem(nama: 'Plastik Kemasan', jumlah: '2 kg', nilai: 20, nilaiType: NilaiType.poin),
      ],
    ),
    SetoranBsu(
      id: 'sb4',
      tanggal: DateTime(2026, 2, 7, 11, 45),
      isSuccess: true,
      nasabahName: 'Dewi Lestari',
      adminName: 'Budi Santoso',
      items: [
        TransaksiItem(nama: 'Botol Kaca', jumlah: '10 pcs', nilai: 15000, nilaiType: NilaiType.uang),
        TransaksiItem(nama: 'Minyak Jelantah', jumlah: '1.5 L', nilai: 38, nilaiType: NilaiType.poin),
      ],
    ),
    SetoranBsu(
      id: 'sb5',
      tanggal: DateTime(2026, 2, 3, 8, 20),
      isSuccess: true,
      nasabahName: 'Rizky Pratama',
      adminName: 'Ramadhani Safitri',
      items: [
        TransaksiItem(nama: 'Koran Bekas', jumlah: '4 kg', nilai: 60, nilaiType: NilaiType.poin),
        TransaksiItem(nama: 'Kardus', jumlah: '5 kg', nilai: 10000, nilaiType: NilaiType.uang),
      ],
    ),
    SetoranBsu(
      id: 'sb6',
      tanggal: DateTime(2026, 1, 25, 13, 0),
      isSuccess: true,
      nasabahName: 'Siti Aminah',
      adminName: 'Budi Santoso',
      items: [
        TransaksiItem(nama: 'Botol Plastik', jumlah: '2 kg', nilai: 6000, nilaiType: NilaiType.uang),
        TransaksiItem(nama: 'Kertas HVS', jumlah: '3 kg', nilai: 45, nilaiType: NilaiType.poin),
      ],
    ),
    SetoranBsu(
      id: 'sb7',
      tanggal: DateTime(2026, 1, 18, 9, 0),
      isSuccess: false,
      nasabahName: 'Ahmad Fauzi',
      adminName: 'Budi Santoso',
      items: [],
    ),
  ];
}

// ─────────────────────────────────────────────────────────────────────────────
// Dummy data — Pengangkutan
// ─────────────────────────────────────────────────────────────────────────────
List<PengangkutanBsu> getDummyPengangkutanBsuData() {
  return [
    PengangkutanBsu(
      id: 'pg1',
      tanggal: DateTime(2026, 2, 15, 8, 0),
      status: StatusPengangkutan.sedangDiajukan,
      adminBsuName: 'Budi Santoso',
      adminBsiName: '-',
    ),
    PengangkutanBsu(
      id: 'pg2',
      tanggal: DateTime(2026, 2, 12, 10, 30),
      status: StatusPengangkutan.disetujui,
      adminBsuName: 'Budi Santoso',
      adminBsiName: 'Hendra Kurniawan',
    ),
    PengangkutanBsu(
      id: 'pg3',
      tanggal: DateTime(2026, 2, 10, 7, 45),
      status: StatusPengangkutan.sedangPerjalanan,
      adminBsuName: 'Ramadhani Safitri',
      adminBsiName: 'Hendra Kurniawan',
    ),
    PengangkutanBsu(
      id: 'pg4',
      tanggal: DateTime(2026, 2, 5, 9, 0),
      status: StatusPengangkutan.selesai,
      adminBsuName: 'Budi Santoso',
      adminBsiName: 'Hendra Kurniawan',
      detailSampah: [
        TransaksiItem(nama: 'Botol Plastik', jumlah: '25 kg', nilai: 75000, nilaiType: NilaiType.uang),
        TransaksiItem(nama: 'Kardus', jumlah: '18 kg', nilai: 36000, nilaiType: NilaiType.uang),
        TransaksiItem(nama: 'Kaleng Aluminium', jumlah: '10 kg', nilai: 80000, nilaiType: NilaiType.uang),
        TransaksiItem(nama: 'Kertas HVS', jumlah: '8 kg', nilai: 120, nilaiType: NilaiType.poin),
        TransaksiItem(nama: 'Plastik Kemasan', jumlah: '5 kg', nilai: 50, nilaiType: NilaiType.poin),
      ],
    ),
    PengangkutanBsu(
      id: 'pg5',
      tanggal: DateTime(2026, 2, 1, 14, 0),
      status: StatusPengangkutan.dibatalkan,
      adminBsuName: 'Budi Santoso',
      adminBsiName: 'Hendra Kurniawan',
    ),
    PengangkutanBsu(
      id: 'pg6',
      tanggal: DateTime(2026, 1, 20, 10, 0),
      status: StatusPengangkutan.selesai,
      adminBsuName: 'Ramadhani Safitri',
      adminBsiName: 'Hendra Kurniawan',
      detailSampah: [
        TransaksiItem(nama: 'Besi Bekas', jumlah: '15 kg', nilai: 75000, nilaiType: NilaiType.uang),
        TransaksiItem(nama: 'Botol Kaca', jumlah: '20 pcs', nilai: 30000, nilaiType: NilaiType.uang),
        TransaksiItem(nama: 'Minyak Jelantah', jumlah: '5 L', nilai: 125, nilaiType: NilaiType.poin),
      ],
    ),
    PengangkutanBsu(
      id: 'pg7',
      tanggal: DateTime(2026, 1, 10, 8, 30),
      status: StatusPengangkutan.selesai,
      adminBsuName: 'Budi Santoso',
      adminBsiName: 'Hendra Kurniawan',
      detailSampah: [
        TransaksiItem(nama: 'Botol Plastik', jumlah: '30 kg', nilai: 90000, nilaiType: NilaiType.uang),
        TransaksiItem(nama: 'Kardus', jumlah: '20 kg', nilai: 40000, nilaiType: NilaiType.uang),
      ],
    ),
  ];
}

// ═══════════════════════════════════════════════════════════════════════════════
// MAIN SCREEN
// ═══════════════════════════════════════════════════════════════════════════════
class RiwayatTransaksiBsuScreen extends StatefulWidget {
  const RiwayatTransaksiBsuScreen({Key? key}) : super(key: key);

  @override
  State<RiwayatTransaksiBsuScreen> createState() => _RiwayatTransaksiBsuState();
}

class _RiwayatTransaksiBsuState extends State<RiwayatTransaksiBsuScreen> {
  int _selectedTab = 0;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  final List<String> _months = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  String _formatDate(DateTime d) {
    final m = ['','Januari','Februari','Maret','April','Mei','Juni',
      'Juli','Agustus','September','Oktober','November','Desember'];
    return '${d.day} ${m[d.month]} ${d.year}  ${d.hour.toString().padLeft(2,'0')}.${d.minute.toString().padLeft(2,'0')}';
  }

  String _formatCurrency(int amount) => NumberFormat('#,###', 'id_ID').format(amount);

  // ─── BUILD ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bgLight,
      body: SafeArea(
        child: Column(
          children: [
            TopBarBack(title: "Riwayat Transaksi"),
            NavbarTransaksi(
              selectedIndex: _selectedTab,
              onTabChanged: (i) => setState(() => _selectedTab = i),
            ),

            // ── Month filter ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
              child: GestureDetector(
                onTap: _showMonthYearPicker,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                  decoration: BoxDecoration(
                    color: _C.softGreen,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 18, color: _C.dark),
                      const SizedBox(width: 10),
                      Text(
                        '${_months[_selectedMonth - 1]} $_selectedYear',
                        style: const TextStyle(
                          fontFamily: 'Poppins', fontSize: 13,
                          fontWeight: FontWeight.w500, color: _C.dark,
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.keyboard_arrow_down_rounded, color: _C.dark.withAlpha(120)),
                    ],
                  ),
                ),
              ),
            ),

            // ── Content area with rounded top corners ──
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  // borderRadius: BorderRadius.only(
                  //   topLeft: Radius.circular(28),
                  //   topRight: Radius.circular(28),
                  // ),
                ),
                child: Column(
                  children: [
                    // Handle bar
                    // Container(
                    //   margin: const EdgeInsets.only(top: 12, bottom: 16),
                    //   width: 40, height: 4,
                    //   decoration: BoxDecoration(
                    //     color: _C.dark.withAlpha(25),
                    //     borderRadius: BorderRadius.circular(2),
                    //   ),
                    // ),
                    // List
                    SizedBox(height: 20),
                    Expanded(
                      child: _selectedTab == 0
                          ? _buildSetoranList()
                          : _buildPengangkutanList(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── SETORAN LIST ──────────────────────────────────────────────────────
  Widget _buildSetoranList() {
    final filtered = getDummySetoranBsuData()
        .where((s) => s.tanggal.month == _selectedMonth && s.tanggal.year == _selectedYear)
        .toList()
      ..sort((a, b) => b.tanggal.compareTo(a.tanggal));

    if (filtered.isEmpty) return _buildEmptyState();

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      physics: const BouncingScrollPhysics(),
      itemCount: filtered.length,
      itemBuilder: (_, i) => _SetoranBsuCard(
        setoran: filtered[i],
        formatDate: _formatDate,
        formatCurrency: _formatCurrency,
      ),
    );
  }

  // ─── PENGANGKUTAN LIST ─────────────────────────────────────────────────
  Widget _buildPengangkutanList() {
    final filtered = getDummyPengangkutanBsuData()
        .where((p) => p.tanggal.month == _selectedMonth && p.tanggal.year == _selectedYear)
        .toList()
      ..sort((a, b) => b.tanggal.compareTo(a.tanggal));

    if (filtered.isEmpty) return _buildEmptyState();

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      physics: const BouncingScrollPhysics(),
      itemCount: filtered.length,
      itemBuilder: (_, i) => _PengangkutanBsuCard(
        pengangkutan: filtered[i],
        formatDate: _formatDate,
        formatCurrency: _formatCurrency,
      ),
    );
  }

  // ─── EMPTY STATE ───────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: _C.softGreen,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(Icons.receipt_long_outlined, size: 36, color: _C.green.withAlpha(120)),
          ),
          const SizedBox(height: 16),
          Text(
            'Tidak ada transaksi',
            style: TextStyle(
              fontFamily: 'Poppins', fontSize: 14,
              fontWeight: FontWeight.w600, color: _C.dark.withAlpha(100),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Belum ada data untuk periode ini',
            style: TextStyle(
              fontFamily: 'Poppins', fontSize: 12,
              color: _C.dark.withAlpha(70),
            ),
          ),
        ],
      ),
    );
  }

  // ─── MONTH-YEAR PICKER ─────────────────────────────────────────────────
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
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: _C.dark.withAlpha(30),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Pilih Periode', style: TextStyle(
                fontFamily: 'Poppins', fontSize: 16,
                fontWeight: FontWeight.w600, color: _C.dark,
              )),
            ),
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _pickerColumn(12, (i) => _months[i], (i) => _selectedMonth == i + 1, (i) => setState(() => _selectedMonth = i + 1))),
                  Container(width: 1, color: _C.dark.withAlpha(15)),
                  Expanded(child: _pickerColumn(3, (i) => (2024 + i).toString(), (i) => _selectedYear == 2024 + i, (i) => setState(() => _selectedYear = 2024 + i))),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _C.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                    elevation: 0,
                  ),
                  child: const Text('Selesai', style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pickerColumn(int count, String Function(int) label, bool Function(int) isSelected, ValueChanged<int> onTap) {
    return ListView.builder(
      itemCount: count,
      itemBuilder: (_, i) {
        final sel = isSelected(i);
        return GestureDetector(
          onTap: () => onTap(i),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            color: sel ? _C.softGreen : Colors.transparent,
            child: Center(child: Text(
              label(i),
              style: TextStyle(
                fontFamily: 'Poppins', fontSize: 14,
                fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                color: sel ? _C.green : _C.dark,
              ),
            )),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SHARED HELPERS (used by both cards)
// ═══════════════════════════════════════════════════════════════════════════════

Widget _infoRow(IconData icon, String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        Icon(icon, size: 15, color: _C.green.withAlpha(180)),
        const SizedBox(width: 8),
        Text('$label ', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: _C.dark.withAlpha(150))),
        Flexible(child: Text(value, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600, color: _C.dark), overflow: TextOverflow.ellipsis)),
      ],
    ),
  );
}

Widget _itemRow(TransaksiItem item, String Function(int) fmt) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
    child: Row(
      children: [
        Expanded(flex: 5, child: Text(item.nama, style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: _C.dark.withAlpha(200)))),
        SizedBox(width: 60, child: Text(item.jumlah, style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: _C.dark.withAlpha(120)), textAlign: TextAlign.center)),
        SizedBox(width: 65, child: Text(fmt(item.nilai), style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600, color: _C.dark), textAlign: TextAlign.end)),
      ],
    ),
  );
}

Widget _totalRow(String label, String value, {bool isLast = true}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
    decoration: BoxDecoration(
      color: _C.green.withAlpha(20),
      borderRadius: isLast
          ? const BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12))
          : BorderRadius.zero,
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600, color: _C.green)),
        Text(value, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w700, color: _C.green)),
      ],
    ),
  );
}

Widget _itemsContainer(List<TransaksiItem> items, String Function(int) fmt) {
  final uang = items.where((i) => i.nilaiType == NilaiType.uang).toList();
  final poin = items.where((i) => i.nilaiType == NilaiType.poin).toList();
  final totalUang = uang.fold(0, (s, i) => s + i.nilai);
  final totalPoin = poin.fold(0, (s, i) => s + i.nilai);

  return Container(
    decoration: BoxDecoration(
      color: _C.softGreen.withAlpha(120),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _C.green.withAlpha(30)),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (uang.isNotEmpty) ...[
          ...uang.map((i) => _itemRow(i, fmt)),
          _totalRow('Total uang', 'Rp${fmt(totalUang)}', isLast: poin.isEmpty),
        ],
        if (poin.isNotEmpty) ...[
          if (uang.isNotEmpty)
            Container(height: 1, margin: const EdgeInsets.symmetric(horizontal: 12), color: _C.green.withAlpha(25)),
          ...poin.map((i) => _itemRow(i, fmt)),
          _totalRow('Total poin', '${fmt(totalPoin)} poin'),
        ],
      ],
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// SETORAN CARD
// ═══════════════════════════════════════════════════════════════════════════════
class _SetoranBsuCard extends StatefulWidget {
  final SetoranBsu setoran;
  final String Function(DateTime) formatDate;
  final String Function(int) formatCurrency;

  const _SetoranBsuCard({required this.setoran, required this.formatDate, required this.formatCurrency});

  @override
  State<_SetoranBsuCard> createState() => _SetoranBsuCardState();
}

class _SetoranBsuCardState extends State<_SetoranBsuCard> with SingleTickerProviderStateMixin {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.setoran;
    final statusColor = s.isSuccess ? _C.success : _C.fail;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          width: 1,
          color: _isExpanded ? _C.green.withAlpha(60) : _C.dark.withAlpha(20),
        ),
        boxShadow: [
          BoxShadow(
            color: _C.dark.withAlpha(_isExpanded ? 18 : 10),
            blurRadius: _isExpanded ? 16 : 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: () { HapticFeedback.selectionClick(); setState(() => _isExpanded = !_isExpanded); },
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Header ──
                Row(
                  children: [
                    // Status icon
                    Container(
                      width: 42, height: 42,
                      decoration: BoxDecoration(
                        color: statusColor.withAlpha(22),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(
                        s.isSuccess ? Icons.check_rounded : Icons.close_rounded,
                        color: statusColor, size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.formatDate(s.tanggal), style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600, color: _C.dark)),
                          const SizedBox(height: 3),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: statusColor.withAlpha(18),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              s.isSuccess ? 'Berhasil' : 'Gagal',
                              style: TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w600, color: statusColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Chevron
                    AnimatedRotation(
                      duration: const Duration(milliseconds: 200),
                      turns: _isExpanded ? 0.5 : 0,
                      child: Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          color: _C.softGreen,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.keyboard_arrow_down_rounded, color: _C.dark.withAlpha(140), size: 20),
                      ),
                    ),
                  ],
                ),

                // ── Expanded ──
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: _buildExpandedContent(),
                  crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 250),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedContent() {
    final s = widget.setoran;

    if (!s.isSuccess) {
      return Padding(
        padding: const EdgeInsets.only(top: 14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: _C.fail.withAlpha(12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _C.fail.withAlpha(25)),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 16, color: _C.fail.withAlpha(180)),
              const SizedBox(width: 8),
              Text('Setoran gagal diproses',
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w500, color: _C.fail.withAlpha(200))),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: double.infinity, height: 1, color: _C.green.withAlpha(20)),
          const SizedBox(height: 12),
          _infoRow(Icons.person_outline_rounded, 'Nasabah', s.nasabahName),
          _infoRow(Icons.admin_panel_settings_outlined, 'Dilayani oleh', s.adminName),
          const SizedBox(height: 12),
          _itemsContainer(s.items, widget.formatCurrency),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// PENGANGKUTAN HELPERS
// ═══════════════════════════════════════════════════════════════════════════════
String _statusLabel(StatusPengangkutan status) {
  switch (status) {
    case StatusPengangkutan.sedangDiajukan:  return 'Sedang Diajukan';
    case StatusPengangkutan.disetujui:       return 'Disetujui';
    case StatusPengangkutan.dibatalkan:      return 'Dibatalkan';
    case StatusPengangkutan.sedangPerjalanan: return 'Sedang Perjalanan';
    case StatusPengangkutan.selesai:         return 'Selesai';
  }
}

Color _statusColor(StatusPengangkutan status) {
  switch (status) {
    case StatusPengangkutan.sedangDiajukan:  return _C.pending;
    case StatusPengangkutan.disetujui:       return _C.approved;
    case StatusPengangkutan.dibatalkan:      return _C.fail;
    case StatusPengangkutan.sedangPerjalanan: return _C.onRoute;
    case StatusPengangkutan.selesai:         return _C.success;
  }
}

IconData _statusIcon(StatusPengangkutan status) {
  switch (status) {
    case StatusPengangkutan.sedangDiajukan:  return Icons.hourglass_top_rounded;
    case StatusPengangkutan.disetujui:       return Icons.thumb_up_alt_rounded;
    case StatusPengangkutan.dibatalkan:      return Icons.cancel_rounded;
    case StatusPengangkutan.sedangPerjalanan: return Icons.local_shipping_rounded;
    case StatusPengangkutan.selesai:         return Icons.check_circle_rounded;
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// PENGANGKUTAN CARD
// ═══════════════════════════════════════════════════════════════════════════════
class _PengangkutanBsuCard extends StatefulWidget {
  final PengangkutanBsu pengangkutan;
  final String Function(DateTime) formatDate;
  final String Function(int) formatCurrency;

  const _PengangkutanBsuCard({required this.pengangkutan, required this.formatDate, required this.formatCurrency});

  @override
  State<_PengangkutanBsuCard> createState() => _PengangkutanBsuCardState();
}

class _PengangkutanBsuCardState extends State<_PengangkutanBsuCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.pengangkutan;
    final color = _statusColor(p.status);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          width: 1,
          color: _isExpanded ? _C.green.withAlpha(60) : _C.dark.withAlpha(20),
        ),
        boxShadow: [
          BoxShadow(
            color: _C.dark.withAlpha(_isExpanded ? 18 : 10),
            blurRadius: _isExpanded ? 16 : 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: () { HapticFeedback.selectionClick(); setState(() => _isExpanded = !_isExpanded); },
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Header ──
                Row(
                  children: [
                    Container(
                      width: 42, height: 42,
                      decoration: BoxDecoration(
                        color: color.withAlpha(22),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(_statusIcon(p.status), color: color, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.formatDate(p.tanggal), style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600, color: _C.dark)),
                          const SizedBox(height: 3),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: color.withAlpha(18),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _statusLabel(p.status),
                              style: TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w600, color: color),
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      duration: const Duration(milliseconds: 200),
                      turns: _isExpanded ? 0.5 : 0,
                      child: Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(color: _C.softGreen, borderRadius: BorderRadius.circular(8)),
                        child: Icon(Icons.keyboard_arrow_down_rounded, color: _C.dark.withAlpha(140), size: 20),
                      ),
                    ),
                  ],
                ),

                // ── Expanded ──
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: _buildExpandedContent(),
                  crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 250),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedContent() {
    final p = widget.pengangkutan;

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: double.infinity, height: 1, color: _C.green.withAlpha(20)),
          const SizedBox(height: 12),

          _infoRow(Icons.person_outline_rounded, 'Admin BSU', p.adminBsuName),
          _infoRow(Icons.business_rounded, 'Admin BSI', p.adminBsiName),

          // Cancelled
          if (p.status == StatusPengangkutan.dibatalkan) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: _C.fail.withAlpha(12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _C.fail.withAlpha(25)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 16, color: _C.fail.withAlpha(180)),
                  const SizedBox(width: 8),
                  Text('Pengangkutan dibatalkan',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w500, color: _C.fail.withAlpha(200))),
                ],
              ),
            ),
          ],

          // Detail sampah for "Selesai"
          if (p.status == StatusPengangkutan.selesai && p.detailSampah != null && p.detailSampah!.isNotEmpty) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(Icons.inventory_2_outlined, size: 15, color: _C.green.withAlpha(180)),
                const SizedBox(width: 6),
                Text('Detail Sampah Diangkut', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600, color: _C.dark.withAlpha(180))),
              ],
            ),
            const SizedBox(height: 8),
            _itemsContainer(p.detailSampah!, widget.formatCurrency),
          ],
        ],
      ),
    );
  }
}
