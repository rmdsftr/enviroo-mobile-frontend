import 'package:flutter/material.dart';
import 'package:enviroo/core/format/app_date.dart';
import 'package:enviroo/core/theme/app_colors.dart';
import 'package:enviroo/core/theme/app_text.dart';

class CalendarWidget extends StatefulWidget {
  final Map<DateTime, List<String>> events;

  final ValueChanged<DateTime>? onDaySelected;

  final ValueChanged<DateTime>? onPageChanged;

  final Color? eventDotColor;

  final DateTime? initialMonth;

  final bool showEventBadge;

  const CalendarWidget({
    super.key,
    this.events = const {},
    this.onDaySelected,
    this.onPageChanged,
    this.eventDotColor,
    this.initialMonth,
    this.showEventBadge = true,
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

  DateTime _normalise(DateTime d) => DateTime(d.year, d.month, d.day);

  List<String> _eventsForDay(int day) {
    final key = _normalise(DateTime(_current.year, _current.month, day));
    return widget.events[key] ?? [];
  }

  @override
  void initState() {
    super.initState();
    _today = DateTime.now();
    final init = widget.initialMonth;
    _current = init != null ? DateTime(init.year, init.month) : DateTime(_today.year, _today.month);
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
    widget.onPageChanged?.call(_current);
  }

  void _nextMonth() {
    setState(() {
      _current = DateTime(_current.year, _current.month + 1);
      _animCtrl.forward(from: 0);
    });
    widget.onPageChanged?.call(_current);
  }

  int get _daysInMonth =>
      DateTime(_current.year, _current.month + 1, 0).day;

  int get _daysInPrevMonth =>
      DateTime(_current.year, _current.month, 0).day;

  int get _firstWeekday {
    int wd = DateTime(_current.year, _current.month, 1).weekday;
    return wd - 1;
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border : Border.all(
            color: AppColors.dark.withValues(alpha: 0.1),
            width: 1,
          )
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            children: [
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
                        Colors.white,
                        Colors.white.withValues(alpha: 0),
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(28),
                      bottomLeft: Radius.circular(100),
                    ),
                  ),
                ),
              ),
              const Positioned(
                top: 18,
                right: 22,
                child: _DecorDot(size: 8, color: AppColors.green, opacity: 0.5),
              ),
              const Positioned(
                top: 32,
                right: 36,
                child: _DecorDot(size: 5, color: Colors.white),
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
                    if (widget.showEventBadge) _buildEventBadge(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
                    text: AppDate.bulanSingkat(_current),
                    style: AppText.p(30, weight: FontWeight.w600, color: AppColors.dark, letterSpacing: -0.5),
                  ),
                  TextSpan(
                    text: '.',
                    style: AppText.r(30, AppColors.green),
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
                color: AppColors.green,
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

  Widget _buildDivider() {
    return Container(
      height: 2,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(2)),
        gradient: LinearGradient(
          colors: [AppColors.green, Colors.white, Colors.transparent],
        ),
      ),
    );
  }

  Widget _buildDayLabels() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (i) {
        final isWeekend = i >= 5;
        return SizedBox(
          width: 36,
          child: Center(
            child: Text(
              AppDate.labelHariSingkat[i],
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                color: isWeekend
                    ? AppColors.green
                    : AppColors.dark.withValues(alpha: 0.4),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildGrid() {
    final List<_DayCell> cells = [];

    for (int i = 0; i < _firstWeekday; i++) {
      cells.add(_DayCell(
        day: _daysInPrevMonth - _firstWeekday + 1 + i,
        type: _CellType.prev,
      ));
    }

    for (int d = 1; d <= _daysInMonth; d++) {
      cells.add(_DayCell(day: d, type: _CellType.current));
    }

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
          ? Column(
              key: ValueKey(day),
              mainAxisSize: MainAxisSize.min,
              children: events.asMap().entries.map((e) => Padding(
                padding: EdgeInsets.only(bottom: e.key < events.length - 1 ? 6 : 0),
                child: _EventBadge(label: e.value),
              )).toList(),
            )
          : SizedBox(
              key: ValueKey('empty_$day'),
              height: 36,
              child: Center(
                child: Text(
                  day != null && _selected!.month == _current.month
                      ? 'Tidak ada jadwal'
                      : 'Pilih tanggal',
                  style: AppText.p(12, color: AppColors.green.withValues(alpha: 0.5), fontStyle: FontStyle.italic),
                ),
              ),
            ),
    );
  }
}

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
      textColor = Colors.white;
    } else if (isToday) {
      textColor = AppColors.neon;
    } else if (isSelected) {
      textColor = AppColors.dark;
    } else if (isSelected) {
      textColor = AppColors.green;
    } else if (isWeekend) {
      textColor = AppColors.green;
    } else {
      textColor = AppColors.dark;
    }

    Widget bg = const SizedBox.shrink();
    if (isToday) {
      bg = Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.dark,
        ),
      );
    } else if (isSelected) {
      bg = Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.neon,
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
                color: eventDotColor ?? AppColors.green,
              ),
            ),
          ),
      ],
    );
  }
}

class _EventBadge extends StatelessWidget {
  final String label;
  const _EventBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    final parts = label.split('  ');
    final name = parts.first.trim();
    final time = parts.length >= 2 ? parts.last.trim() : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.mintSoft,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          if (time != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.green.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                time,
                style: AppText.w700(10, AppColors.dark),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(
              name,
              style: AppText.w500(12, AppColors.dark.withValues(alpha: 0.75)),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

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

enum _CellType { prev, current, next }

class _DayCell {
  final int day;
  final _CellType type;
  const _DayCell({required this.day, required this.type});
}
