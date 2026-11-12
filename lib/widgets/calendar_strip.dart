import 'package:flutter/material.dart';
import '../presenters/calendar_presenter.dart';

class CalendarStrip extends StatefulWidget {

  final CalendarPresenter presenter;
  final ValueChanged<DateTime>? onDaySelected;
  final bool Function(DateTime day)? isMarked;

  const CalendarStrip({
    super.key,
    required this.presenter,
    this.onDaySelected,
    this.isMarked,
  });

  @override
  State<CalendarStrip> createState() => _CalendarStripState();
}

class _CalendarStripState extends State<CalendarStrip> {
  static const int _originPage = 10000;

  late final PageController _pageController;

  CalendarPresenter get _presenter => widget.presenter;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: _originPage + _presenter.pageOffset,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() => _presenter.changePage(page - _originPage));
    widget.onDaySelected?.call(_presenter.selectedDay);
  }

  void _onDayTapped(DateTime day) {
    setState(() => _presenter.selectDay(day));
    widget.onDaySelected?.call(_presenter.selectedDay);
  }

  void _goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Future<void> _goToToday() async {
    final distance = _presenter.pageOffset.abs();
    // animate if it's close, otherwise jump so it doesn't spin through pages
    if (distance <= 3) {
      await _pageController.animateToPage(
        _originPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _pageController.jumpToPage(_originPage);
    }
    setState(() => _presenter.goToToday());
    widget.onDaySelected?.call(_presenter.selectedDay);
  }

  Future<void> _openMonthPicker() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _presenter.selectedDay,
      firstDate: _presenter.firstPickableDate,
      lastDate: _presenter.lastPickableDate,
      currentDate: _presenter.today,
      helpText: 'Jump to date',
    );
    if (picked == null || !mounted) return;

 
    setState(() => _presenter.jumpToDate(picked));
    final targetPage = _originPage + _presenter.pageOffset;
    if (_pageController.page?.round() != targetPage) {
      _pageController.jumpToPage(targetPage);
    }
    widget.onDaySelected?.call(_presenter.selectedDay);
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    final currentPage = _originPage + _presenter.pageOffset;

    // rounded light purple rounded rectangle behind widget
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 40,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // tap the range to open the month calendar
                InkWell(
                  onTap: _openMonthPicker,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _presenter.rangeLabel,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.calendar_month, size: 18),
                      ],
                    ),
                  ),
                ),
                if (!_presenter.isShowingToday)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _goToToday,
                      child: const Text('Today'),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),

          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Previous 7 days',
                onPressed: () => _goToPage(currentPage - 1),
              ),
              Expanded(
                child: SizedBox(
                  height: 72,
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    itemBuilder: (context, page) {
                      final days = _presenter.daysForPage(page - _originPage);
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: days
                            .map(
                              (day) => _DateCircle(
                                day: day,
                                isSelected: CalendarPresenter.isSameDay(
                                  day,
                                  _presenter.selectedDay,
                                ),
                                isToday: CalendarPresenter.isSameDay(
                                  day,
                                  _presenter.today,
                                ),
                                isMarked: widget.isMarked?.call(day) ?? false,
                                color: color,
                                onTap: () => _onDayTapped(day),
                              ),
                            )
                            .toList(),
                      );
                    },
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                tooltip: 'Next 7 days',
                onPressed: () => _goToPage(currentPage + 1),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DateCircle extends StatelessWidget {
  final DateTime day;
  final bool isSelected;
  final bool isToday;
  final bool isMarked;
  final Color color;
  final VoidCallback onTap;

  const _DateCircle({
    required this.day,
    required this.isSelected,
    required this.isToday,
    required this.isMarked,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            CalendarPresenter.weekdayLetter(day),
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
          ),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? color : Colors.white.withValues(alpha: 0.85),
              border: Border.all(
                color: isToday || isSelected
                    ? color
                    : color.withValues(alpha: 0.2),
                width: isToday ? 2 : 1,
              ),
            ),
            child: Text(
              '${day.day}',
              style: TextStyle(
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 4),
          // placeholder dot; only shows when isMarked is hooked up after calendar model is made
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isMarked ? color : Colors.transparent,
            ),
          ),
        ],
      ),
    );
  }
}
