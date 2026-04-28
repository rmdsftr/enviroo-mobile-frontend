import 'dart:ui';
import 'package:enviroo/services/pengangkutan_service.dart';
import 'package:enviroo/widgets/kalender.dart';
import 'package:enviroo/widgets/navbar_jadwal.dart';
import 'package:enviroo/widgets/topbar_back.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:enviroo/providers/jadwal_provider.dart';
import 'package:enviroo/providers/auth_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Palette (harmonised with app)
// ─────────────────────────────────────────────────────────────────────────────
class _C {
  static const dark      = Color(0xFF013236);
  static const green     = Color(0xFF4EA771);
  static const lime      = Color(0xFF94DF0C);
  static const bgLight   = Color(0xFFFFFFFF);
  static const softGreen = Color(0xFFEAF8E7);
  static const surface   = Color(0xFFF5F9F3);
  static const orange    = Color(0xFFFD7D00);
}

// ─────────────────────────────────────────────────────────────────────────────
// Day-of-week / week helpers
// ─────────────────────────────────────────────────────────────────────────────
const _dayNames   = ['Senin','Selasa','Rabu','Kamis','Jumat','Sabtu','Minggu'];
const _dayShort   = ['Sen','Sel','Rab','Kam','Jum','Sab','Min'];
const _weekLabels = ['Minggu 1','Minggu 2','Minggu 3','Minggu 4'];

// ─────────────────────────────────────────────────────────────────────────────
// Model: Jadwal Rutin
// ─────────────────────────────────────────────────────────────────────────────
class JadwalRutin {
  final List<int> days;      // 1=Senin … 7=Minggu
  final List<int> weeks;     // 1-4, empty = setiap minggu
  final String waktu;        // e.g. "08:00 – 12:00"

  JadwalRutin({required this.days, required this.weeks, required this.waktu});

  String get label {
    final dayStr = days.map((d) => _dayNames[d - 1]).join(', ');
    final weekStr = weeks.isEmpty
        ? 'tiap minggunya'
        : weeks.map((w) => 'minggu ke-$w').join(' & ');
    return 'Setiap hari $dayStr $weekStr';
  }

  List<DateTime> datesInMonth(int year, int month) {
    final result = <DateTime>[];
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final firstOfMonth = DateTime(year, month, 1);
    final firstWeekday = firstOfMonth.weekday % 7; // Sunday=0, Monday=1, dll

    for (int d = 1; d <= daysInMonth; d++) {
      final date = DateTime(year, month, d);
      final weekday = date.weekday;
      
      // Hitung minggu ke berapa, menyesuaikan dengan offset hari pertama di bulan tersebut
      final adjustedDay = d + firstWeekday - 1;
      final weekNum = (adjustedDay ~/ 7) + 1;

      if (days.contains(weekday)) {
        if (weeks.isEmpty || weeks.contains(weekNum)) {
          result.add(date);
        }
      }
    }
    return result;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Model: Jadwal Custom
// ─────────────────────────────────────────────────────────────────────────────
class JadwalCustom {
  final DateTime tanggal;
  final String waktu;
  final String? pesan;

  JadwalCustom({required this.tanggal, required this.waktu, this.pesan});
}



// ═══════════════════════════════════════════════════════════════════════════════
// MAIN SCREEN
// ═══════════════════════════════════════════════════════════════════════════════
class JadwalScreen extends StatefulWidget {
  @override
  State<JadwalScreen> createState() => _JadwalScreenState();
}

class _JadwalScreenState extends State<JadwalScreen>
    with SingleTickerProviderStateMixin {
  int _selectedTab = 0;

  late List<JadwalRutin> _rutinPenimbangan;
  late List<JadwalRutin> _rutinPengangkutan;
  late List<JadwalCustom> _customPenimbangan;
  late List<JadwalCustom> _customPengangkutan;

  // For smooth content transitions
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _rutinPenimbangan   = [];
    _rutinPengangkutan  = [];
    _customPenimbangan  = [];
    _customPengangkutan = [];

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();
    final prov = context.read<JadwalProvider>();
    await prov.fetchJadwal(auth);
    if (mounted) {
      setState(() {
        _rutinPenimbangan = List.from(prov.rutinPenimbangan);
        _rutinPengangkutan = List.from(prov.rutinPengangkutan);
        _customPenimbangan = List.from(prov.customPenimbangan);
        _customPengangkutan = List.from(prov.customPengangkutan);
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _switchTab(int i) {
    if (i == _selectedTab) return;
    _fadeCtrl.reverse().then((_) {
      setState(() => _selectedTab = i);
      _fadeCtrl.forward();
    });
  }

  // ── Getters for current tab ──
  List<JadwalRutin> get _currentRutin =>
      _selectedTab == 0 ? _rutinPenimbangan : _rutinPengangkutan;
  List<JadwalCustom> get _currentCustom =>
      _selectedTab == 0 ? _customPenimbangan : _customPengangkutan;

  // ── Build calendar event map ──
  Map<DateTime, List<String>> _buildEvents() {
    final map = <DateTime, List<String>>{};
    void addEvent(DateTime d, String label) {
      final key = DateTime(d.year, d.month, d.day);
      map.putIfAbsent(key, () => []);
      map[key]!.add(label);
    }

    final now = DateTime.now();
    for (int offset = -1; offset <= 2; offset++) {
      final m = DateTime(now.year, now.month + offset);
      for (final r in _currentRutin) {
        for (final d in r.datesInMonth(m.year, m.month)) {
          addEvent(d, '${_selectedTab == 0 ? "Penimbangan" : "Pengangkutan"} Rutin  ${r.waktu}');
        }
      }
    }

    for (final c in _currentCustom) {
      addEvent(c.tanggal, _selectedTab == 0
          ? 'Penimbangan Custom  ${c.waktu}'
          : 'Pengajuan Pengangkutan  ${c.waktu}');
    }
    return map;
  }

  void _onDaySelected(DateTime date) {
    final events = _buildEvents();
    final key = DateTime(date.year, date.month, date.day);
    final dayEvents = events[key] ?? [];

    if (dayEvents.isEmpty) {
      // No events → go directly to add form
      if (_selectedTab == 0) {
        _showAddCustomPenimbangan(date);
      } else {
        _showAjukanPengangkutan(date);
      }
    } else {
      // Has events → show choice sheet first
      _showDayOptions(date, dayEvents);
    }
  }

  // ── Choice sheet when date already has events ──
  void _showDayOptions(DateTime date, List<String> events) {
    final months = ['','Januari','Februari','Maret','April','Mei','Juni','Juli','Agustus','September','Oktober','November','Desember'];
    final dateStr = '${date.day} ${months[date.month]} ${date.year}';

    _showSheet(
      builder: (ctx, setBS) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _handleBar(),

          // Date header
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: _C.green.withAlpha(18),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(Icons.calendar_today_rounded, size: 16, color: _C.green),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dateStr, style: const TextStyle(
                    fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.w600,
                    color: _C.dark,
                  )),
                  const SizedBox(height: 2),
                  Text('${events.length} jadwal', style: TextStyle(
                    fontFamily: 'Poppins', fontSize: 12, color: _C.dark.withAlpha(100),
                  )),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Event list
          ...events.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: _C.surface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Container(
                    width: 3, height: 28,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [_C.green.withAlpha(200), _C.lime.withAlpha(140)],
                      ),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(e, style: TextStyle(
                      fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w500,
                      color: _C.dark.withAlpha(180), height: 1.4,
                    )),
                  ),
                ],
              ),
            ),
          )),
          const SizedBox(height: 16),

          // Action buttons
          SizedBox(
            width: double.infinity, height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                if (_selectedTab == 0) {
                  _showAddCustomPenimbangan(date);
                } else {
                  _showAjukanPengangkutan(date);
                }
              },
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(
                _selectedTab == 0 ? 'Tambah Jadwal' : 'Ajukan Pengangkutan',
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _C.green,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── BUILD ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.softGreen,
      body: SafeArea(
        child: Column(
          children: [
            TopBarBack(title: "Kelola Jadwal"),

            // ── Tab Navbar ──
            NavbarJadwal(
              selectedIndex: _selectedTab,
              onTabChanged: _switchTab,
            ),

            const SizedBox(height: 12),

            // ── Scrollable content with fade transition ──
            Expanded(
              child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: _C.green))
                : FadeTransition(
                opacity: _fadeAnim,
                child: SingleChildScrollView(
                  key: ValueKey(_selectedTab),
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 36),
                  child: Column(
                    children: [
                      // ── Jadwal Rutin section ──
                      _buildRutinSection(),

                      const SizedBox(height: 14),

                      // ── Info banner (Pengangkutan only) ──
                      if (_selectedTab == 1) _buildInfoBanner(),

                      // ── "Tambah" button ──
                      if (_selectedTab == 0) _buildTambahButton(),

                      const SizedBox(height: 16),

                      // ── Calendar ──
                      CalendarWidget(
                        events: _buildEvents(),
                        onDaySelected: _onDaySelected,
                        eventDotColor: _selectedTab == 0 ? _C.green : _C.orange,
                      ),

                      const SizedBox(height: 16),

                      // ── Jadwal Khusus bulan ini ──
                      _buildJadwalKhususSection(),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // JADWAL KHUSUS BULAN INI
  // ═════════════════════════════════════════════════════════════════════════
  Widget _buildJadwalKhususSection() {
    final now = DateTime.now();
    final monthCustom = _currentCustom.where((c) {
      return c.tanggal.year == now.year && c.tanggal.month == now.month;
    }).toList()
      ..sort((a, b) => a.tanggal.compareTo(b.tanggal));

    if (monthCustom.isEmpty) return const SizedBox.shrink();

    final months = ['','Januari','Februari','Maret','April','Mei','Juni','Juli','Agustus','September','Oktober','November','Desember'];
    final monthLabel = '${months[now.month]} ${now.year}';
    final typeLabel = _selectedTab == 0 ? 'Penimbangan' : 'Pengangkutan';
    final accentColor = _selectedTab == 0 ? _C.green : _C.orange;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: _frostedCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            // ── List ──
            ...monthCustom.asMap().entries.map((entry) {
              final idx = entry.key;
              final c = entry.value;
              final dayNames = ['', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
              final dayName = dayNames[c.tanggal.weekday];
              final dateStr = '$dayName, ${c.tanggal.day} ${months[c.tanggal.month]} ${c.tanggal.year}';
              final isLast = idx == monthCustom.length - 1;

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Date badge ──
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            color: accentColor.withAlpha(14),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${c.tanggal.day}',
                                style: TextStyle(
                                  fontFamily: 'Poppins', fontSize: 16,
                                  fontWeight: FontWeight.w700, color: accentColor,
                                  height: 1.1,
                                ),
                              ),
                              Text(
                                months[c.tanggal.month].substring(0, 3).toUpperCase(),
                                style: TextStyle(
                                  fontFamily: 'Poppins', fontSize: 8.5,
                                  fontWeight: FontWeight.w600, color: accentColor.withAlpha(160),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 13),
                        // ── Info ──
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c.pesan != null && c.pesan!.isNotEmpty
                                    ? c.pesan!
                                    : '$typeLabel Khusus',
                                style: TextStyle(
                                  fontFamily: 'Poppins', fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: _C.dark.withAlpha(210),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(dateStr, style: TextStyle(
                                fontFamily: 'Poppins', fontSize: 11,
                                color: _C.dark.withAlpha(80),
                              )),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Icon(Icons.access_time_rounded, size: 11, color: _C.dark.withAlpha(60)),
                                  const SizedBox(width: 4),
                                  Text(c.waktu, style: TextStyle(
                                    fontFamily: 'Poppins', fontSize: 11,
                                    color: _C.dark.withAlpha(90),
                                  )),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // ── Tag ──
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: accentColor.withAlpha(14),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Khusus',
                            style: TextStyle(
                              fontFamily: 'Poppins', fontSize: 9.5,
                              fontWeight: FontWeight.w600, color: accentColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 36),
                      child: Container(height: 0.5, color: _C.dark.withAlpha(8)),
                    ),
                ],
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // INFO BANNER (Pengangkutan)
  // ═════════════════════════════════════════════════════════════════════════
  Widget _buildInfoBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF013236), Color(0xFF024950)],
          ),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: _C.dark.withAlpha(30),
              blurRadius: 20,
              spreadRadius: -2,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 30, height: 30,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                color: _C.lime.withAlpha(30),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(Icons.info_outline_rounded, size: 16, color: _C.lime.withAlpha(220)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "Anda dapat mengajukan permintaan pengangkutan kepada BSI dengan memilih salah satu tanggal pada kalender",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11.5,
                  height: 1.55,
                  color: Colors.white.withAlpha(210),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // TAMBAH BUTTON (elegant outlined)
  // ═════════════════════════════════════════════════════════════════════════
  Widget _buildTambahButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showTambahRutin(),
          borderRadius: BorderRadius.circular(50),
          splashColor: _C.green.withAlpha(20),
          highlightColor: _C.green.withAlpha(10),
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: _C.dark.withAlpha(50), width: 1.2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_rounded, size: 20, color: _C.dark.withAlpha(160)),
                const SizedBox(width: 8),
                Text(
                  'Tambah Jadwal Rutin',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _C.dark.withAlpha(180),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // JADWAL RUTIN SECTION
  // ═════════════════════════════════════════════════════════════════════════
  Widget _buildRutinSection() {
    final rutin = _currentRutin;

    if (rutin.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: _frostedCard(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 28),
            child: Column(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: _C.green.withAlpha(15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.event_busy_rounded, size: 22, color: _C.dark.withAlpha(50)),
                ),
                const SizedBox(height: 12),
                Text('Belum ada jadwal rutin',
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 12.5, color: _C.dark.withAlpha(90)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: _frostedCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
              child: Row(
                children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: _C.green.withAlpha(18),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: const Icon(Icons.repeat_rounded, color: _C.green, size: 16),
                  ),
                  const SizedBox(width: 10),
                  const Text('Jadwal Rutin', style: TextStyle(
                    fontFamily: 'Poppins', fontSize: 13.5, fontWeight: FontWeight.w600,
                    color: _C.dark,
                  )),
                ],
              ),
            ),

            // Subtle separator
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 4),
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _C.green.withAlpha(20),
                      _C.dark.withAlpha(6),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            ...rutin.asMap().entries.map(
              (e) => _buildRutinRow(e.value, isLast: e.key == rutin.length - 1),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// Frosted-glass style card wrapper used across the screen.
  Widget _frostedCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9), // Reduced opacity slightly since there's no blur
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: _C.dark.withOpacity(0.08),
            blurRadius: 24,
            spreadRadius: -4,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildRutinRow(JadwalRutin r, {bool isLast = false}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
          child: Row(
            children: [
              // Gradient accent bar
              Container(
                width: 3, height: 36,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [_C.green.withAlpha(200), _C.lime.withAlpha(140)],
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 13),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.label,
                      style: TextStyle(
                        fontFamily: 'Poppins', fontSize: 12,
                        fontWeight: FontWeight.w500, color: _C.dark.withAlpha(200),
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(Icons.access_time_rounded, size: 12, color: _C.dark.withAlpha(60)),
                        const SizedBox(width: 4),
                        Text(r.waktu, style: TextStyle(
                          fontFamily: 'Poppins', fontSize: 11,
                          color: _C.dark.withAlpha(90),
                        )),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              // Day chips
              Wrap(
                spacing: 3,
                children: r.days.map((d) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: _C.green.withAlpha(16),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(_dayShort[d - 1],
                    style: TextStyle(
                      fontFamily: 'Poppins', fontSize: 10,
                      fontWeight: FontWeight.w600, color: _C.green.withAlpha(200),
                    ),
                  ),
                )).toList(),
              ),
            ],
          ),
        ),
        if (!isLast)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36),
            child: Container(
              height: 0.5,
              color: _C.dark.withAlpha(8),
            ),
          ),
      ],
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // POPUP: TAMBAH JADWAL RUTIN
  // ═════════════════════════════════════════════════════════════════════════
  void _showTambahRutin() {
    final selectedDays  = <int>{};
    final selectedWeeks = <int>{};
    final jamMulaiCtrl   = TextEditingController(text: '08:00');
    final jamSelesaiCtrl = TextEditingController(text: '12:00');

    _showSheet(
      builder: (ctx, setBS) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _handleBar(),
          _sheetTitle('Tambah Jadwal Rutin'),
          const SizedBox(height: 24),

          // ── Pilih Hari ──
          _sectionLabel('Pilih Hari'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8, runSpacing: 10,
            children: List.generate(7, (i) {
              final day = i + 1;
              final sel = selectedDays.contains(day);
              return _chip(
                label: _dayNames[i],
                selected: sel,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setBS(() => sel ? selectedDays.remove(day) : selectedDays.add(day));
                },
              );
            }),
          ),
          const SizedBox(height: 24),

          // ── Pilih Minggu ──
          _sectionLabel('Pilih Minggu'),
          const SizedBox(height: 4),
          Text('Kosongkan untuk setiap minggu',
            style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: _C.dark.withAlpha(80)),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8, runSpacing: 10,
            children: List.generate(4, (i) {
              final week = i + 1;
              final sel = selectedWeeks.contains(week);
              return _chip(
                label: _weekLabels[i],
                selected: sel,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setBS(() => sel ? selectedWeeks.remove(week) : selectedWeeks.add(week));
                },
              );
            }),
          ),
          const SizedBox(height: 24),

          // ── Waktu ──
          _sectionLabel('Waktu'),
          const SizedBox(height: 10),
          _timeRow(jamMulaiCtrl, jamSelesaiCtrl),
          const SizedBox(height: 16),

          // ── Preview label ──
          if (selectedDays.isNotEmpty) ...[
            _previewBox(
              JadwalRutin(
                days: selectedDays.toList()..sort(),
                weeks: selectedWeeks.toList()..sort(),
                waktu: '${jamMulaiCtrl.text} – ${jamSelesaiCtrl.text}',
              ).label,
            ),
            const SizedBox(height: 16),
          ],

          // ── Submit ──
          _submitButton(
            label: 'Simpan',
            enabled: selectedDays.isNotEmpty,
            color: _C.green,
            onPressed: () {
              final newRutin = JadwalRutin(
                days: selectedDays.toList()..sort(),
                weeks: selectedWeeks.toList()..sort(),
                waktu: '${jamMulaiCtrl.text} – ${jamSelesaiCtrl.text}',
              );
              setState(() {
                if (_selectedTab == 0) {
                  _rutinPenimbangan.add(newRutin);
                } else {
                  _rutinPengangkutan.add(newRutin);
                }
              });
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // POPUP: TAMBAH JADWAL PENIMBANGAN CUSTOM
  // ═════════════════════════════════════════════════════════════════════════
  void _showAddCustomPenimbangan(DateTime date) {
    final months = ['','Januari','Februari','Maret','April','Mei','Juni','Juli','Agustus','September','Oktober','November','Desember'];
    final jamMulaiCtrl   = TextEditingController(text: '08:00');
    final jamSelesaiCtrl = TextEditingController(text: '10:00');

    _showSheet(
      builder: (ctx, setBS) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _handleBar(),
          _sheetTitle('Tambah Jadwal Penimbangan'),
          const SizedBox(height: 20),

          _dateBox(
            dateText: '${date.day} ${months[date.month]} ${date.year}',
            color: _C.green,
            bgColor: _C.softGreen,
          ),
          const SizedBox(height: 22),

          _sectionLabel('Waktu'),
          const SizedBox(height: 10),
          _timeRow(jamMulaiCtrl, jamSelesaiCtrl),
          const SizedBox(height: 28),

          _submitButton(
            label: 'Simpan',
            color: _C.green,
            onPressed: () {
              setState(() {
                _customPenimbangan.add(JadwalCustom(
                  tanggal: date,
                  waktu: '${jamMulaiCtrl.text} – ${jamSelesaiCtrl.text}',
                ));
              });
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // POPUP: AJUKAN PENGANGKUTAN
  // ═════════════════════════════════════════════════════════════════════════
  void _showAjukanPengangkutan(DateTime date) {
    final months = ['','Januari','Februari','Maret','April','Mei','Juni','Juli','Agustus','September','Oktober','November','Desember'];
    final pesanCtrl    = TextEditingController();
    final jamMulaiCtrl = TextEditingController(text: '08:00');
    bool  _submitting  = false;

    _showSheet(
      builder: (ctx, setBS) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _handleBar(),
          _sheetTitle('Ajukan Pengangkutan'),
          const SizedBox(height: 5),
          Text('Ajukan permintaan pengangkutan ke BSI',
            style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: _C.dark.withAlpha(100), height: 1.4),
          ),
          const SizedBox(height: 20),

          _dateBox(
            dateText: '${date.day} ${months[date.month]} ${date.year}',
            color: _C.green,
            bgColor: _C.softGreen,
          ),
          const SizedBox(height: 22),

          // ── Jam mulai ──
          _sectionLabel('Jam Mulai'),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () async {
              final picked = await showTimePicker(
                context: ctx,
                initialTime: const TimeOfDay(hour: 8, minute: 0),
                builder: (c, child) => Theme(
                  data: ThemeData.light().copyWith(
                    colorScheme: const ColorScheme.light(primary: _C.green),
                  ),
                  child: child!,
                ),
              );
              if (picked != null) {
                setBS(() {
                  jamMulaiCtrl.text =
                    '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                });
              }
            },
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: _C.surface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(children: [
                const Icon(Icons.access_time_rounded, size: 18, color: _C.green),
                const SizedBox(width: 10),
                Text(jamMulaiCtrl.text, style: const TextStyle(
                  fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w500, color: _C.dark,
                )),
                const Spacer(),
                Icon(Icons.edit_rounded, size: 15, color: _C.dark.withAlpha(60)),
              ]),
            ),
          ),
          const SizedBox(height: 22),

          // ── Catatan / alasan ──
          _sectionLabel('Pesan untuk BSI'),
          const SizedBox(height: 10),
          TextField(
            controller: pesanCtrl,
            maxLines: 4,
            cursorColor: _C.green,
            style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: _C.dark, height: 1.5),
            decoration: InputDecoration(
              hintText: 'Tuliskan pesan / catatan untuk BSI...',
              hintStyle: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: _C.dark.withAlpha(55)),
              filled: true,
              fillColor: _C.surface,
              contentPadding: const EdgeInsets.all(16),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: _C.green.withAlpha(80), width: 1.5),
              ),
            ),
            onChanged: (_) => setBS(() {}),
          ),
          const SizedBox(height: 28),

          // ── Submit ──
          _submitting
              ? const Center(child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: CircularProgressIndicator(color: _C.green, strokeWidth: 2.5),
                ))
              : _submitButton(
                  label: 'Kirim Pengajuan',
                  enabled: pesanCtrl.text.trim().isNotEmpty,
                  color: _C.green,
                  onPressed: () async {
                    setBS(() => _submitting = true);
                    final auth = context.read<AuthProvider>();
                    final bsuId   = auth.bankId ?? '';
                    final adminId = auth.identityId ?? '';
                    final token   = auth.currentUser?.accessToken ?? '';

                    final res = await PengangkutanService.requestPengangkutan(
                      bsuId, adminId, date, jamMulaiCtrl.text.trim(),
                      pesanCtrl.text.trim(), token,
                    );

                    if (!mounted) return;
                    setBS(() => _submitting = false);

                    Navigator.pop(ctx);
                    if (res['success'] == true) {
                      // Tambahkan ke local state agar kalender langsung update
                      setState(() {
                        _customPengangkutan.add(JadwalCustom(
                          tanggal: date,
                          waktu: jamMulaiCtrl.text.trim(),
                          pesan: pesanCtrl.text.trim(),
                        ));
                      });
                      _showSuccessSnackbar('Pengajuan pengangkutan berhasil dikirim');
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(res['message'] ?? 'Gagal mengajukan', style: const TextStyle(fontFamily: 'Poppins', color: Colors.white)),
                        backgroundColor: Colors.red.shade700,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        margin: const EdgeInsets.all(16),
                      ));
                    }
                  },
                ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // SHARED UI COMPONENTS
  // ═════════════════════════════════════════════════════════════════════════

  /// Unified bottom sheet launcher with spring-curve opening.
  void _showSheet({
    required Widget Function(BuildContext ctx, StateSetter setBS) builder,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      transitionAnimationController: AnimationController(
        vsync: Navigator.of(context),
        duration: const Duration(milliseconds: 400),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setBS) => Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 32),
            child: builder(ctx, setBS),
          ),
        ),
      ),
    );
  }

  Widget _handleBar() {
    return Center(child: Container(
      width: 36, height: 4,
      margin: const EdgeInsets.only(bottom: 22),
      decoration: BoxDecoration(
        color: _C.dark.withAlpha(18),
        borderRadius: BorderRadius.circular(4),
      ),
    ));
  }

  Widget _sheetTitle(String text) {
    return Text(text, style: const TextStyle(
      fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w600,
      color: _C.dark,
    ));
  }

  Widget _sectionLabel(String text) {
    return Text(text, style: TextStyle(
      fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600,
      color: _C.dark.withAlpha(200),
    ));
  }

  /// Selectable chip with smooth animation.
  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? _C.green : _C.surface,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: selected ? _C.green : _C.dark.withAlpha(12),
            width: 1,
          ),
          boxShadow: selected ? [
            BoxShadow(color: _C.green.withAlpha(30), blurRadius: 10, offset: const Offset(0, 3)),
          ] : [],
        ),
        child: Text(label, style: TextStyle(
          fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600,
          color: selected ? Colors.white : _C.dark.withAlpha(150),
        )),
      ),
    );
  }

  Widget _timeRow(TextEditingController mulai, TextEditingController selesai) {
    return Row(
      children: [
        Expanded(child: _timeField(mulai, 'Mulai')),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('–', style: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w400,
            color: _C.dark.withAlpha(60),
          )),
        ),
        Expanded(child: _timeField(selesai, 'Selesai')),
      ],
    );
  }

  Widget _timeField(TextEditingController ctrl, String hint) {
    return TextField(
      controller: ctrl,
      textAlign: TextAlign.center,
      cursorColor: _C.green,
      style: const TextStyle(
        fontFamily: 'Poppins', fontSize: 14,
        fontWeight: FontWeight.w600, color: _C.dark,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontFamily: 'Poppins', fontSize: 13,
          fontWeight: FontWeight.w400, color: _C.dark.withAlpha(55),
        ),
        filled: true,
        fillColor: _C.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _C.green.withAlpha(80), width: 1.5),
        ),
      ),
    );
  }

  Widget _dateBox({
    required String dateText,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: color.withAlpha(18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.calendar_today_rounded, size: 15, color: color),
          ),
          const SizedBox(width: 12),
          Text(dateText, style: const TextStyle(
            fontFamily: 'Poppins', fontSize: 14,
            fontWeight: FontWeight.w600, color: _C.dark,
          )),
        ],
      ),
    );
  }

  Widget _previewBox(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _C.softGreen,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(Icons.info_outline_rounded, size: 15, color: _C.green.withAlpha(140)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(
            text,
            style: TextStyle(
              fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w500,
              color: _C.dark.withAlpha(180), height: 1.45,
            ),
          )),
        ],
      ),
    );
  }

  Widget _submitButton({
    required String label,
    required Color color,
    required VoidCallback onPressed,
    bool enabled = true,
  }) {
    return SizedBox(
      width: double.infinity, height: 50,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(50),
          boxShadow: enabled ? [
            BoxShadow(color: color.withAlpha(35), blurRadius: 12, offset: const Offset(0, 4)),
          ] : [],
        ),
        child: ElevatedButton(
          onPressed: enabled ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            disabledBackgroundColor: _C.dark.withAlpha(20),
            disabledForegroundColor: _C.dark.withAlpha(60),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
          ),
          child: Text(label, style: const TextStyle(
            fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w600,
          )),
        ),
      ),
    );
  }

  void _showSuccessSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(msg, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13))),
        ],
      ),
      backgroundColor: _C.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      duration: const Duration(seconds: 2),
    ));
  }
}
