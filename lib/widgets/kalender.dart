import 'package:flutter/material.dart';

// ─── Color Palette ───────────────────────────────────────────────────────────
class AppColors {
  static const primary = Color(0xFF4EA771);
  static const dark = Color(0xFF013236);
  static const light = Color(0xFFFFFFFF);
  static const pale = Color(0xFFFFFFFF);
}

// ─── Data ─────────────────────────────────────────────────────────────────────
const List<String> _dayLabels = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];
const List<String> _monthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

// ─── Calendar Widget ──────────────────────────────────────────────────────────
class CalendarWidget extends StatefulWidget {
  /// Events keyed by date (year, month, day only — time is ignored).
  final Map<DateTime, List<String>> events;

  /// Called when a day in the current month is tapped.
  final ValueChanged<DateTime>? onDaySelected;

  /// Colour of the small event-dot under day numbers. Defaults to [AppColors.primary].
  final Color? eventDotColor;

  const CalendarWidget({
    super.key,
    this.events = const {},
    this.onDaySelected,
    this.eventDotColor,
  });

  @override
  State<CalendarWidget> createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends State<CalendarWidget>
    with SingleTickerProviderStateMixin {
  late DateTime _current;
  late DateTime _today;
  DateTime? _selected;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  /// Normalise a DateTime to date-only (year, month, day).
  DateTime _normalise(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Look up events for a specific day in the current month.
  List<String> _eventsForDay(int day) {
    final key = _normalise(DateTime(_current.year, _current.month, day));
    return widget.events[key] ?? [];
  }

  @override
  void initState() {
    super.initState();
    _today = DateTime.now();
    _current = DateTime(_today.year, _today.month);
    _selected = _today;
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _prevMonth() {
    setState(() {
      _current = DateTime(_current.year, _current.month - 1);
      _animCtrl.forward(from: 0);
    });
  }

  void _nextMonth() {
    setState(() {
      _current = DateTime(_current.year, _current.month + 1);
      _animCtrl.forward(from: 0);
    });
  }

  int get _daysInMonth =>
      DateTime(_current.year, _current.month + 1, 0).day;

  int get _daysInPrevMonth =>
      DateTime(_current.year, _current.month, 0).day;

  /// Monday = 0, Sunday = 6
  int get _firstWeekday {
    int wd = DateTime(_current.year, _current.month, 1).weekday;
    return wd - 1; // weekday 1=Mon → 0
  }

  bool _isToday(int day) =>
      day == _today.day &&
          _current.month == _today.month &&
          _current.year == _today.year;

  bool _isSelected(int day) =>
      _selected != null &&
          day == _selected!.day &&
          _current.month == _selected!.month &&
          _current.year == _selected!.year;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(28),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            children: [
              // Decorative top-right corner
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [
                        AppColors.pale,
                        Colors.white.withOpacity(0),
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(28),
                      bottomLeft: Radius.circular(100),
                    ),
                  ),
                ),
              ),
              // Dot decorations
              const Positioned(
                top: 18,
                right: 22,
                child: _DecorDot(size: 8, color: AppColors.primary, opacity: 0.5),
              ),
              const Positioned(
                top: 32,
                right: 36,
                child: _DecorDot(size: 5, color: AppColors.light),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 4),
                    _buildDivider(),
                    const SizedBox(height: 16),
                    _buildDayLabels(),
                    const SizedBox(height: 8),
                    FadeTransition(
                      opacity: _fadeAnim,
                      child: _buildGrid(),
                    ),
                    const SizedBox(height: 16),
                    _buildEventBadge(),
                    const SizedBox(height: 20),
                    _buildPaletteStrip(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: _monthNames[_current.month - 1].substring(0, 3),
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 30,
                      fontWeight: FontWeight.w600,
                      color: AppColors.dark,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const TextSpan(
                    text: '.',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 30,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _current.year.toString(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
                letterSpacing: 2.5,
              ),
            ),
          ],
        ),
        const Spacer(),
        Row(
          children: [
            _NavButton(icon: Icons.chevron_left_rounded, onTap: _prevMonth),
            const SizedBox(width: 4),
            _NavButton(icon: Icons.chevron_right_rounded, onTap: _nextMonth),
          ],
        ),
      ],
    );
  }

  // ── Gradient Divider ──────────────────────────────────────────────────────
  Widget _buildDivider() {
    return Container(
      height: 2,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(2)),
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.light, Colors.transparent],
        ),
      ),
    );
  }

  // ── Day Labels ────────────────────────────────────────────────────────────
  Widget _buildDayLabels() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (i) {
        final isWeekend = i >= 5;
        return SizedBox(
          width: 36,
          child: Center(
            child: Text(
              _dayLabels[i],
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                color: isWeekend
                    ? AppColors.primary
                    : AppColors.dark.withOpacity(0.4),
              ),
            ),
          ),
        );
      }),
    );
  }

  // ── Calendar Grid ─────────────────────────────────────────────────────────
  Widget _buildGrid() {
    final List<_DayCell> cells = [];

    // Previous month trailing days
    for (int i = 0; i < _firstWeekday; i++) {
      cells.add(_DayCell(
        day: _daysInPrevMonth - _firstWeekday + 1 + i,
        type: _CellType.prev,
      ));
    }

    // Current month
    for (int d = 1; d <= _daysInMonth; d++) {
      cells.add(_DayCell(day: d, type: _CellType.current));
    }

    // Next month leading days
    final remaining = 42 - cells.length;
    for (int i = 1; i <= remaining; i++) {
      cells.add(_DayCell(day: i, type: _CellType.next));
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1,
        mainAxisSpacing: 4,
        crossAxisSpacing: 0,
      ),
      itemCount: cells.length,
      itemBuilder: (_, index) {
        final cell = cells[index];
        final today = _isToday(cell.day) && cell.type == _CellType.current;
        final sel = _isSelected(cell.day) && cell.type == _CellType.current;
        final hasEvent =
            cell.type == _CellType.current && _eventsForDay(cell.day).isNotEmpty;
        final isWeekend = index % 7 >= 5;

        return GestureDetector(
          onTap: cell.type == _CellType.current
              ? () {
                  final date = DateTime(_current.year, _current.month, cell.day);
                  setState(() => _selected = date);
                  widget.onDaySelected?.call(date);
                }
              : null,
          child: _DayTile(
            day: cell.day,
            isOtherMonth: cell.type != _CellType.current,
            isToday: today,
            isSelected: sel,
            hasEvent: hasEvent && !today && !sel,
            eventDotColor: widget.eventDotColor,
            isWeekend: isWeekend,
          ),
        );
      },
    );
  }

  // ── Event Badge ───────────────────────────────────────────────────────────
  Widget _buildEventBadge() {
    final day = _selected?.day;
    final events = (day != null &&
        _selected!.month == _current.month &&
        _selected!.year == _current.year)
        ? _eventsForDay(day)
        : <String>[];
    final hasEvent = events.isNotEmpty;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (child, anim) =>
          FadeTransition(opacity: anim, child: child),
      child: hasEvent
          ? _EventCard(
        key: ValueKey(day),
        month: _monthNames[_current.month - 1].substring(0, 3),
        day: day!,
        label: events.first,
      )
          : SizedBox(
        key: ValueKey('empty_$day'),
        height: 44,
        child: Center(
          child: Text(
            day != null &&
                _selected!.month == _current.month
                ? '${_monthNames[_current.month - 1]} $day — No events'
                : 'Select a day',
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: AppColors.primary.withOpacity(0.5),
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }

  // ── Palette Strip ─────────────────────────────────────────────────────────
  Widget _buildPaletteStrip() {
    const colors = [
      AppColors.pale,
      AppColors.light,
      AppColors.primary,
      AppColors.dark,
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: colors.asMap().entries.map((e) {
        final isActive = e.key == 2;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 20 : 8,
          height: 4,
          decoration: BoxDecoration(
            color: e.value,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Day Tile ─────────────────────────────────────────────────────────────────
class _DayTile extends StatelessWidget {
  final int day;
  final bool isOtherMonth;
  final bool isToday;
  final bool isSelected;
  final bool hasEvent;
  final bool isWeekend;
  final Color? eventDotColor;

  const _DayTile({
    required this.day,
    required this.isOtherMonth,
    required this.isToday,
    required this.isSelected,
    required this.hasEvent,
    required this.isWeekend,
    this.eventDotColor,
  });

  @override
  Widget build(BuildContext context) {
    Color textColor;
    if (isOtherMonth) {
      textColor = AppColors.light;
    } else if (isToday) {
      textColor = Color(0xFF94DF0C);
    } else if (isSelected) {
      textColor = AppColors.dark;
    } else if (isSelected) {
      textColor = Color(0xFF4EA771);
    } else if (isWeekend) {
      textColor = AppColors.primary;
    } else {
      textColor = AppColors.dark;
    }

    Widget bg = const SizedBox.shrink();
    if (isToday) {
      bg = Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFF013236),
          boxShadow: [
            BoxShadow(
              color: Color(0x554EA771),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
      );
    } else if (isSelected) {
      bg = Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFF94DF0C),
          boxShadow: [
            BoxShadow(
              color: Color(0x334EA771),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        bg,
        Text(
          day.toString(),
          style: TextStyle(
            fontSize: 13,
            fontWeight:
            (isToday || isSelected) ? FontWeight.w700 : FontWeight.w400,
            color: textColor,
          ),
        ),
        if (hasEvent)
          Positioned(
            bottom: 4,
            child: Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: eventDotColor ?? AppColors.primary,
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Event Card ───────────────────────────────────────────────────────────────
class _EventCard extends StatelessWidget {
  final String month;
  final int day;
  final String label;

  const _EventCard({
    super.key,
    required this.month,
    required this.day,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.pale,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.access_time_rounded,
            color: AppColors.dark,
            size: 18,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: const BoxDecoration(
              color: AppColors.dark,
              border: Border(
                left: BorderSide(color: Color(0xFF94DF0C), width: 3),
              ),
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0x224EA771),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Text(
                  '$month $day'.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF94DF0C),
                    letterSpacing: 1.2,
                  ),
                ),
                const Text(
                  '  ·  ',
                  style: TextStyle(
                    color: Color(0x99013236),
                    fontSize: 12,
                  ),
                ),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.light,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Nav Button ───────────────────────────────────────────────────────────────
class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _NavButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.transparent,
        ),
        child: Icon(icon, color: AppColors.dark, size: 22),
      ),
    );
  }
}

// ─── Decorative Dot ───────────────────────────────────────────────────────────
class _DecorDot extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;

  const _DecorDot({
    required this.size,
    required this.color,
    this.opacity = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}

// ─── Internal Models ──────────────────────────────────────────────────────────
enum _CellType { prev, current, next }

class _DayCell {
  final int day;
  final _CellType type;
  const _DayCell({required this.day, required this.type});
}
