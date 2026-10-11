import 'package:enviroo/core/format/app_date.dart';
import 'package:enviroo/models/jadwal_model.dart';

import 'package:enviroo/services/pengangkutan_service.dart';
import 'package:enviroo/widgets/filter_chip_row.dart';
import 'package:enviroo/widgets/kalender.dart';
import 'package:enviroo/widgets/navbar_jadwal.dart';
import 'package:enviroo/widgets/topbar_back.dart';
import 'package:enviroo/widgets/custom_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:enviroo/providers/jadwal_provider.dart';
import 'package:enviroo/providers/auth_provider.dart';
import 'package:enviroo/core/theme/app_colors.dart';
import 'package:enviroo/core/theme/app_text.dart';

class _C {
  static const dark      = AppColors.dark;
  static const green     = AppColors.green;
  static const lime      = AppColors.neon;
  static const softGreen = AppColors.mintSoft;
  static const surface   = Color(0xFFF5F9F3);
  static const orange    = Color(0xFFFD7D00);
}


class JadwalScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const JadwalScreen({super.key, this.onBack});

  @override
  State<JadwalScreen> createState() => _JadwalScreenState();
}

class _JadwalScreenState extends State<JadwalScreen>
    with SingleTickerProviderStateMixin {
  int _selectedTab = 0;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  DateTime _focusedMonth = DateTime.now();

  List<JadwalPenimbanganItem> _bsmJadwal = [];
  bool _bsmLoading = false;
  String? _bsmError;
  String _bsmFilter = 'semua';

  @override
  void initState() {
    super.initState();

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

  Future<void> _fetchData({DateTime? month}) async {
    final auth = context.read<AuthProvider>();
    final target = month ?? _focusedMonth;

    if (auth.role == 'petugas_bsm') {
      await _fetchBsmJadwal(target);
      return;
    }

    final prov = context.read<JadwalProvider>();
    await prov.fetchJadwal(auth, month: target.month, year: target.year);
  }

  Future<void> _fetchBsmJadwal(DateTime target) async {
    final auth = context.read<AuthProvider>();
    final bankId = auth.bankId;
    if (bankId == null) return;

    setState(() {
      _bsmLoading = true;
      _bsmError = null;
    });

    final res = await context.read<JadwalProvider>().fetchPenimbanganBsm(
      bankId,
      month: target.month,
      year: target.year,
    );

    if (!mounted) return;
    setState(() {
      _bsmLoading = false;
      if (res['success'] == true) {
        _bsmJadwal = (res['data'] as List<JadwalPenimbanganItem>?) ?? [];
      } else {
        _bsmError = res['message']?.toString();
      }
    });
  }

  List<JadwalPenimbanganItem> get _filteredBsmJadwal {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final viewingPastMonth =
        DateTime(_focusedMonth.year, _focusedMonth.month).isBefore(DateTime(now.year, now.month));
    final upcoming = _bsmJadwal.where((j) =>
        viewingPastMonth ||
        !DateTime(j.tanggal.year, j.tanggal.month, j.tanggal.day)
            .isBefore(today));
    final list = _bsmFilter == 'rutin'
        ? upcoming.where((j) => j.isRutin).toList()
        : _bsmFilter == 'khusus'
            ? upcoming.where((j) => !j.isRutin).toList()
            : upcoming.toList();
    list.sort((a, b) => a.tanggal.compareTo(b.tanggal));
    return list;
  }

  Map<DateTime, List<String>> _buildBsmEvents() {
    final map = <DateTime, List<String>>{};
    for (final j in _bsmJadwal) {
      final key = DateTime(j.tanggal.year, j.tanggal.month, j.tanggal.day);
      map.putIfAbsent(key, () => []);
      map[key]!.add('${j.namaJadwal.isNotEmpty ? j.namaJadwal : "Penimbangan"}  ${j.formattedJam}');
    }
    return map;
  }

  (String, Color) _bsmStatusBadge(String status) {
    switch (status) {
      case 'upcoming':    return ('Perkiraan', _C.dark.withAlpha(120));
      case 'pending':     return ('Mendatang', _C.green);
      case 'aktif':       return ('Sedang berlangsung', _C.orange);
      case 'selesai':     return ('Selesai', _C.dark.withAlpha(100));
      case 'dibatalkan':  return ('Batal', AppColors.dangerAlt);
      default:            return (status, _C.dark.withAlpha(100));
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

  List<JadwalRutin> get _currentRutin {
    final prov = context.read<JadwalProvider>();
    return _selectedTab == 0 ? prov.rutinPenimbangan : prov.rutinPengangkutan;
  }
  
  List<JadwalCustom> get _currentCustom {
    final prov = context.read<JadwalProvider>();
    return _selectedTab == 0 ? prov.customPenimbangan : prov.customPengangkutan;
  }

  Map<DateTime, List<String>> _buildEvents() {
    final map = <DateTime, List<String>>{};
    void addEvent(DateTime d, String label) {
      final key = DateTime(d.year, d.month, d.day);
      map.putIfAbsent(key, () => []);
      map[key]!.add(label);
    }

    for (final r in _currentRutin) {
      for (final d in r.datesInMonth(_focusedMonth.year, _focusedMonth.month)) {
        final String eventLabel;
        if (_selectedTab == 1 && r.targetBankName.isNotEmpty) {
          eventLabel = 'Angkut ${r.targetBankName}  ${r.waktu}';
        } else {
          eventLabel = '${_selectedTab == 0 ? "Penimbangan" : "Pengangkutan"} Rutin  ${r.waktu}';
        }
        addEvent(d, eventLabel);
      }
    }

    for (final c in _currentCustom) {
      final customLabel = (c.pesan != null && c.pesan!.isNotEmpty)
          ? c.pesan!
          : (_selectedTab == 0 ? 'Penimbangan Khusus' : 'Pengajuan Pengangkutan');
      addEvent(c.tanggal, '$customLabel  ${c.waktu}');
    }
    return map;
  }

  void _onDaySelected(DateTime date) {
    final role = context.read<AuthProvider>().role;
    final isBsi = role == 'petugas_bsi';
    final isBsm = role == 'petugas_bsm';
    final key = DateTime(date.year, date.month, date.day);

    if (isBsm) {
      final dayItems = _bsmJadwal.where((j) {
        final t = j.tanggal;
        return t.year == key.year && t.month == key.month && t.day == key.day;
      }).toList()
        ..sort((a, b) => a.jamMulai.compareTo(b.jamMulai));
      if (dayItems.isNotEmpty) _showBsmDayOptions(date, dayItems);
      return;
    }

    final events = _buildEvents();
    final dayEvents = events[key] ?? [];

    if (dayEvents.isEmpty) {
      if (_selectedTab == 1 && !isBsi) _showAjukanPengangkutan(date);
    } else {
      _showDayOptions(date, dayEvents);
    }
  }

  void _showDayOptions(DateTime date, List<String> events) {
    final dateStr = AppDate.tanggalPanjang(date);

    _showSheet(
      builder: (ctx, setBS) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _handleBar(),

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
                  Text(dateStr, style: AppText.w600(15, _C.dark)),
                  const SizedBox(height: 2),
                  Text('${events.length} jadwal', style: AppText.r(12, _C.dark.withAlpha(100))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

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
                    child: Text(e, style: AppText.p(12, weight: FontWeight.w500, color: _C.dark.withAlpha(180), height: 1.4)),
                  ),
                ],
              ),
            ),
          )),
          const SizedBox(height: 16),

          if (_selectedTab == 1 && context.read<AuthProvider>().role != 'petugas_bsi')
            SizedBox(
              width: double.infinity, height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _showAjukanPengangkutan(date);
                },
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(
                  'Ajukan Pengangkutan',
                  style: AppText.w600(13),
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

  void _showBsmDayOptions(DateTime date, List<JadwalPenimbanganItem> items) {
    final dateStr = AppDate.tanggalPanjang(date);

    _showSheet(
      builder: (ctx, setBS) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _handleBar(),

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
                  Text(dateStr, style: AppText.w600(15, _C.dark)),
                  const SizedBox(height: 2),
                  Text('${items.length} jadwal', style: AppText.r(12, _C.dark.withAlpha(100))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          ...items.map((j) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildBsmSheetItem(j),
          )),
        ],
      ),
    );
  }

  Widget _buildBsmSheetItem(JadwalPenimbanganItem j) {
    final (badgeLabel, badgeColor) = _bsmStatusBadge(j.statusJadwal);
    final isDead = j.statusJadwal == 'selesai' ||
        j.statusJadwal == 'dibatalkan' ||
        !j.isActive;

    final content = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  j.namaJadwal.isNotEmpty ? j.namaJadwal : 'Penimbangan',
                  style: AppText.w600(13, _C.dark.withAlpha(isDead ? 140 : 220)),
                ),
              ),
              const SizedBox(width: 8),
              _jadwalChip(badgeLabel, badgeColor),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.access_time_rounded, size: 11, color: _C.dark.withAlpha(70)),
              const SizedBox(width: 4),
              Text(j.formattedJam, style: AppText.r(11.5, _C.dark.withAlpha(90))),
            ],
          ),
        ],
      ),
    );

    return isDead ? Opacity(opacity: 0.55, child: content) : content;
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthProvider>().role;
    final isBsm = role == 'petugas_bsm';
    final isBsi = role == 'petugas_bsi';
    final isLoading = isBsm ? _bsmLoading : context.watch<JadwalProvider>().isLoading;

    return Scaffold(
      backgroundColor: _C.surface,
      body: SafeArea(
        child: Column(
          children: [
            TopBarBack(title: "Monitoring Jadwal", onBack: widget.onBack),

            if (!isBsm)
              NavbarJadwal(
                selectedIndex: _selectedTab,
                onTabChanged: _switchTab,
              ),

            if (!isBsm) const SizedBox(height: 12),

            Expanded(
              child: isLoading
                ? const Center(child: CircularProgressIndicator(color: _C.green))
                : FadeTransition(
                opacity: _fadeAnim,
                child: SingleChildScrollView(
                  key: ValueKey(_selectedTab),
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 36),
                  child: Column(
                    children: isBsm
                        ? [
                            CalendarWidget(
                              events: _buildBsmEvents(),
                              onDaySelected: _onDaySelected,
                              onPageChanged: (m) {
                                setState(() => _focusedMonth = m);
                                _fetchData(month: m);
                              },
                              eventDotColor: _C.green,
                              initialMonth: _focusedMonth,
                              showEventBadge: false,
                            ),
                            const SizedBox(height: 25),
                            _buildBsmJadwalSection(),
                            const SizedBox(height: 60),
                          ]
                        : [
                            _buildRutinSection(),

                            const SizedBox(height: 10),

                            if (_selectedTab == 1 && !isBsi) _buildInfoBanner(),

                            CalendarWidget(
                              events: _buildEvents(),
                              onDaySelected: _onDaySelected,
                              onPageChanged: (m) {
                                setState(() => _focusedMonth = m);
                                _fetchData(month: m);
                              },
                              eventDotColor: _selectedTab == 0 ? _C.green : _C.orange,
                              initialMonth: _focusedMonth,
                            ),

                            const SizedBox(height: 25),

                            _buildJadwalKhususSection(),

                            const SizedBox(height: 60),
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

  List<(JadwalRutin, DateTime?)> _sortedRutinWithDate() {
    final today = DateTime.now();
    final todayNorm = DateTime(today.year, today.month, today.day);

    final entries = _currentRutin.map((r) {
      DateTime? nextDate;
      for (int offset = 0; offset <= 2; offset++) {
        final m = DateTime(today.year, today.month + offset);
        final dates = r.datesInMonth(m.year, m.month)..sort();
        for (final d in dates) {
          if (!d.isBefore(todayNorm)) { nextDate = d; break; }
        }
        if (nextDate != null) break;
      }
      if (nextDate == null) {
        final dates = r.datesInMonth(today.year, today.month)
          ..sort((a, b) => b.compareTo(a));
        if (dates.isNotEmpty) nextDate = dates.first;
      }
      return (r, nextDate);
    }).toList();

    entries.sort((a, b) {
      final dA = a.$2; final dB = b.$2;
      if (dA == null && dB == null) return 0;
      if (dA == null) return 1;
      if (dB == null) return -1;
      final aF = !dA.isBefore(todayNorm);
      final bF = !dB.isBefore(todayNorm);
      if (aF != bF) return aF ? -1 : 1;
      return dA.compareTo(dB);
    });

    return entries;
  }

  Widget _occurrenceChip(DateTime? nextDate) {
    if (nextDate == null) return _jadwalChip('Tidak Ada', _C.dark.withAlpha(60));
    final today = DateTime.now();
    final todayNorm = DateTime(today.year, today.month, today.day);
    final diff = nextDate.difference(todayNorm).inDays;
    if (diff == 0) return _jadwalChip('Hari Ini', _C.orange);
    if (diff == 1) return _jadwalChip('Besok', _C.green);
    if (diff > 0) return _jadwalChip('$diff hari lagi', _C.dark.withAlpha(110));
    return _jadwalChip('Lewat', _C.dark.withAlpha(65));
  }

  Widget _jadwalChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(60), width: 0.8),
      ),
      child: Text(label, style: AppText.w600(9.5, color)),
    );
  }

  Widget _buildBsmJadwalSection() {
    final monthLabel = AppDate.bulanTahun(_focusedMonth);
    final filtered = _filteredBsmJadwal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(30, 0, 30, 12),
          child: Row(
            children: [
              Text(
                'Jadwal bulan ini',
                style: AppText.w600(13.5, _C.dark),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _C.green.withAlpha(18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  monthLabel,
                  style: AppText.w600(10, _C.green),
                ),
              ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: FilterChipRow<String>(
            items: const [
              FilterChipItem(value: 'semua', label: 'Semua'),
              FilterChipItem(value: 'rutin', label: 'Rutin'),
              FilterChipItem(value: 'khusus', label: 'Khusus'),
            ],
            selectedValue: _bsmFilter,
            onSelected: (v) => setState(() => _bsmFilter = v),
            padding: const EdgeInsets.symmetric(horizontal: 27),
          ),
        ),

        if (_bsmError != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 27, vertical: 8),
            child: Text(
              _bsmError!,
              style: AppText.r(12, Colors.red),
            ),
          )
        else if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: _frostedCard(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 28),
                child: Column(
                  children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(color: _C.green.withAlpha(15), shape: BoxShape.circle),
                      child: Icon(Icons.event_busy_rounded, size: 22, color: _C.dark.withAlpha(50)),
                    ),
                    const SizedBox(height: 12),
                    Text('Belum ada jadwal bulan ini',
                      style: AppText.r(12.5, _C.dark.withAlpha(90))),
                  ],
                ),
              ),
            ),
          )
        else
          ...filtered.asMap().entries.map((e) => _buildBsmJadwalRow(
                e.value,
                isLast: e.key == filtered.length - 1,
              )),
      ],
    );
  }

  Widget _buildBsmJadwalRow(JadwalPenimbanganItem j, {required bool isLast}) {
    final dateStr = AppDate.hariTanggal(j.tanggal);
    final (badgeLabel, badgeColor) = _bsmStatusBadge(j.statusJadwal);
    final isDead = j.statusJadwal == 'selesai' ||
        j.statusJadwal == 'dibatalkan' ||
        !j.isActive;
    final now = DateTime.now();
    final isToday = j.tanggal.year == now.year &&
        j.tanggal.month == now.month &&
        j.tanggal.day == now.day;
    final dateColor = isDead ? _C.dark.withAlpha(90) : badgeColor;

    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: dateColor.withAlpha(14),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${j.tanggal.day}',
                style: AppText.p(16, weight: FontWeight.w700, color: dateColor, height: 1.1),
              ),
              Text(
                AppDate.bulanSingkat(j.tanggal).toUpperCase(),
                style: AppText.w600(8.5, dateColor.withAlpha(160)),
              ),
            ],
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      j.namaJadwal.isNotEmpty ? j.namaJadwal : 'Penimbangan',
                      style: AppText.w600(12.5, _C.dark.withAlpha(isDead ? 130 : 210)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _jadwalChip(badgeLabel, badgeColor),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.calendar_today_rounded, size: 10, color: _C.dark.withAlpha(60)),
                  const SizedBox(width: 4),
                  Text(dateStr, style: AppText.r(11, _C.dark.withAlpha(80))),
                  if (j.isRutin) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.repeat_rounded, size: 10, color: _C.green.withAlpha(140)),
                  ],
                ],
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  Icon(Icons.access_time_rounded, size: 10, color: _C.dark.withAlpha(60)),
                  const SizedBox(width: 4),
                  Text(j.formattedJam, style: AppText.r(11, _C.dark.withAlpha(80))),
                ],
              ),
            ],
          ),
        ),
      ],
    );

    final rowBody = isDead ? Opacity(opacity: 0.55, child: content) : content;

    final rowContent = isToday
        ? Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _C.green.withAlpha(16),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _C.green.withAlpha(90), width: 1.2),
            ),
            child: rowBody,
          )
        : rowBody;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isToday ? 20 : 27,
            vertical: isToday ? 6 : 12,
          ),
          child: rowContent,
        ),
        if (!isLast)
          Divider(
            height: 1,
            thickness: 0.5,
            indent: 24,
            endIndent: 24,
            color: _C.dark.withAlpha(18),
          ),
      ],
    );
  }

  Widget _buildJadwalKhususSection() {
    final monthCustom = _currentCustom.where((c) {
      return c.tanggal.year == _focusedMonth.year && c.tanggal.month == _focusedMonth.month;
    }).toList()
      ..sort((a, b) => a.tanggal.compareTo(b.tanggal));

    if (monthCustom.isEmpty) return const SizedBox.shrink();

    final monthLabel = AppDate.bulanTahun(_focusedMonth);
    final typeLabel = _selectedTab == 0 ? 'Penimbangan' : 'Pengangkutan';
    final accentColor = _selectedTab == 0 ? _C.green : _C.orange;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(30, 0, 30, 12),
          child: Row(
            children: [
              Text(
                'Jadwal Khusus',
                style: AppText.w600(13.5, _C.dark),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: accentColor.withAlpha(18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  monthLabel,
                  style: AppText.w600(10, accentColor),
                ),
              ),
            ],
          ),
        ),

        ...monthCustom.asMap().entries.map((entry) {
          final idx = entry.key;
          final c = entry.value;
          final dateStr = AppDate.hariTanggal(c.tanggal);
          final isLast = idx == monthCustom.length - 1;
          final today = DateTime.now();
          final todayNorm = DateTime(today.year, today.month, today.day);
          final tglNorm = DateTime(c.tanggal.year, c.tanggal.month, c.tanggal.day);
          final diff = tglNorm.difference(todayNorm).inDays;
          final (String, Color)? customChip = diff == 0
              ? ('Hari Ini', _C.orange)
              : diff == 1
                  ? ('Besok', _C.green)
                  : diff < 0
                      ? ('Lewat', _C.dark.withAlpha(80))
                      : diff <= 7
                          ? ('$diff hari lagi', _C.dark.withAlpha(100))
                          : null;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 27, vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
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
                            style: AppText.p(16, weight: FontWeight.w700, color: accentColor, height: 1.1),
                          ),
                          Text(
                            AppDate.bulanSingkat(c.tanggal).toUpperCase(),
                            style: AppText.w600(8.5, accentColor.withAlpha(160)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  c.pesan != null && c.pesan!.isNotEmpty
                                      ? c.pesan!
                                      : '$typeLabel Khusus',
                                  style: AppText.w600(12.5, _C.dark.withAlpha(210)),
                                ),
                              ),
                              if (customChip != null) ...[
                                const SizedBox(width: 8),
                                _jadwalChip(customChip.$1, customChip.$2),
                              ],
                            ],
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Icon(Icons.calendar_today_rounded, size: 10, color: _C.dark.withAlpha(60)),
                              const SizedBox(width: 4),
                              Text(dateStr, style: AppText.r(11, _C.dark.withAlpha(80))),
                              const SizedBox(width: 10),
                              Icon(Icons.access_time_rounded, size: 10, color: _C.dark.withAlpha(60)),
                              const SizedBox(width: 4),
                              Text(c.waktu, style: AppText.r(11, _C.dark.withAlpha(80))),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  thickness: 0.5,
                  indent: 24,
                  endIndent: 24,
                  color: _C.dark.withAlpha(18),
                ),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildInfoBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color : AppColors.dark,
          borderRadius: BorderRadius.circular(25),
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
                style: AppText.p(11.5, color: Colors.white.withAlpha(210), height: 1.55),
              ),
            ),
          ],
        ),
      ),
    );
  }

  

  Widget _buildRutinSection() {
    final sorted = _sortedRutinWithDate();
    final hideTarget = context.read<AuthProvider>().role == 'petugas_bsu';

    if (sorted.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: _frostedCard(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28),
            child: Column(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(color: _C.green.withAlpha(15), shape: BoxShape.circle),
                  child: Icon(Icons.event_busy_rounded, size: 22, color: _C.dark.withAlpha(50)),
                ),
                const SizedBox(height: 12),
                Text('Belum ada jadwal rutin',
                  style: AppText.r(12.5, _C.dark.withAlpha(90))),
              ],
            ),
          ),
        ),
      );
    }

    final pages = <List<(JadwalRutin, DateTime?)>>[];
    for (int i = 0; i < sorted.length; i += 5) {
      pages.add(sorted.sublist(i, (i + 5).clamp(0, sorted.length)));
    }

    Widget buildCard(List<(JadwalRutin, DateTime?)> items, int pageIdx) {
      return _frostedCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                  Text('Jadwal Rutin', style: AppText.w600(13.5, _C.dark)),
                  const Spacer(),
                  if (pages.length > 1)
                    Text(
                      '${pageIdx + 1}/${pages.length}',
                      style: AppText.r(11, _C.dark.withAlpha(80)),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 4),
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [_C.green.withAlpha(20), _C.dark.withAlpha(6), Colors.transparent]),
                ),
              ),
            ),
            ...items.asMap().entries.map((e) => _buildRutinRow(
              e.value.$1,
              nextDate: e.value.$2,
              isLast: e.key == items.length - 1,
              hideTarget: hideTarget,
            )),
            const SizedBox(height: 8),
          ],
        ),
      );
    }

    if (pages.length == 1) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: buildCard(pages[0], 0),
      );
    }

    final rowH = hideTarget ? 64.0 : 82.0;
    final cardH = 70.0 + pages.first.length * rowH + 8.0;
    final cardW = MediaQuery.of(context).size.width - 48.0;

    return SizedBox(
      height: cardH,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        itemCount: pages.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (ctx, i) => SizedBox(
          width: cardW,
          child: buildCard(pages[i], i),
        ),
      ),
    );
  }

  Widget _frostedCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(25),
        border : Border.all(color: _C.dark.withValues(alpha: 0.1), width: 1),
      ),
      child: child,
    );
  }

  Widget _buildRutinRow(JadwalRutin r, {bool isLast = false, bool hideTarget = false, DateTime? nextDate}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.label,
                      style: AppText.p(12, weight: FontWeight.w500, color: _C.dark.withAlpha(200), height: 1.45),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(Icons.access_time_rounded, size: 12, color: _C.dark.withAlpha(60)),
                        const SizedBox(width: 4),
                        Text(r.waktu, style: AppText.r(11, _C.dark.withAlpha(90))),
                      ],
                    ),
                    if (r.targetBankName.isNotEmpty && !hideTarget) ...[
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Icon(Icons.place_rounded, size: 12, color: _C.green.withAlpha(160)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              r.targetBankName,
                              style: AppText.w700(11, _C.green.withAlpha(200)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _occurrenceChip(nextDate),
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
  }


  void _showAjukanPengangkutan(DateTime date) {
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
            style: AppText.p(12, color: _C.dark.withAlpha(100), height: 1.4),
          ),
          const SizedBox(height: 20),

          _dateBox(
            dateText: AppDate.tanggalPanjang(date),
            color: _C.green,
            bgColor: _C.softGreen,
          ),
          const SizedBox(height: 22),

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
                Text(jamMulaiCtrl.text, style: AppText.w500(14, _C.dark)),
                const Spacer(),
                Icon(Icons.edit_rounded, size: 15, color: _C.dark.withAlpha(60)),
              ]),
            ),
          ),
          const SizedBox(height: 22),

          _sectionLabel('Pesan untuk BSI'),
          const SizedBox(height: 10),
          TextField(
            controller: pesanCtrl,
            maxLines: 4,
            cursorColor: _C.green,
            style: AppText.p(13, color: _C.dark, height: 1.5),
            decoration: InputDecoration(
              hintText: 'Tuliskan pesan / catatan untuk BSI...',
              hintStyle: AppText.r(13, _C.dark.withAlpha(55)),
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
                    final sheetNav = Navigator.of(ctx);
                    setBS(() => _submitting = true);
                    final auth = context.read<AuthProvider>();
                    final bsuId   = auth.bankId ?? '';
                    final adminId = auth.identityId ?? '';

                    final res = await PengangkutanService.requestPengangkutan(
                      bsuId, adminId, date, jamMulaiCtrl.text.trim(),
                      pesanCtrl.text.trim(),
                    );

                    if (!mounted) return;
                    setBS(() => _submitting = false);

                    sheetNav.pop();
                    if (res['success'] == true) {
                      _fetchData();
                      _showSuccessSnackbar('Pengajuan pengangkutan berhasil dikirim');
                    } else {
                      showCustomSnackBar(context, res['message'] ?? 'Gagal mengajukan');
                    }
                  },
                ),
        ],
      ),
    );
  }

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
    return Text(text, style: AppText.w600(14, _C.dark));
  }

  Widget _sectionLabel(String text) {
    return Text(text, style: AppText.w600(13, _C.dark.withAlpha(200)));
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
          Text(dateText, style: AppText.w600(14, _C.dark)),
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
          child: Text(label, style: AppText.w600(14)),
        ),
      ),
    );
  }

  void _showSuccessSnackbar(String msg) {
    showCustomSnackBar(context, msg, type: SnackBarType.success);
  }
}
