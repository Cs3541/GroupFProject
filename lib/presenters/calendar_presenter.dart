class CalendarPresenter {

  //I want to replicate a 7 day week thats viewable with the selected day in the middle
  // and the 3 previous days to the left of it and the 3 following days to the right of it
  static const int daysEachSide = 3;
  static const int daysPerPage = daysEachSide * 2 + 1;

  static const _months = ['January','February','March','April','May',
    'June','July','August','September','October','November','December'
  ];
  static const _weekdays = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];

  CalendarPresenter({DateTime? now}){
    _today = dateOnly(now ?? DateTime.now());
    _selectedDay = _today;
  }
  // Varibale Declarations after constructor
  late DateTime _today;
  late DateTime _selectedDay;
  int _pageOffset = 0;


  DateTime get today => _today;
  DateTime get selectedDay => _selectedDay;
  int get pageOffset => _pageOffset;
  bool get isShowingToday => _pageOffset == 0;
  

  List<DateTime> daysForPage(int offset){
    final firstDay = _today.day - daysEachSide + offset * daysPerPage;
    return List.generate(
      daysPerPage,
       (i) => DateTime(_today.year, _today.month, firstDay + i)
    );
  }

  List<DateTime> get visibleDays => daysForPage(_pageOffset);


  String rangeLabelForPage(int offset){
    final days = daysForPage(offset);
    final first = days.first;
    final last = days.last;

    if(first.year != last.year){
      return '${_monthDay(first)}, ${first.year} – ${_monthDay(last)}, ${last.year}';
    }

    final end = first.month == last.month ? '${last.day}' : _monthDay(last);
    final yearSuffix = first.year == _today.year ? '' : ', ${first.year}';
    return '${_monthDay(first)} – $end$yearSuffix';
  }


  String get rangeLabel => rangeLabelForPage(_pageOffset);


  String get selectedDayLabel {
    final yesterday = DateTime(_today.year, _today.month, _today.day - 1);
    final tomorrow = DateTime(_today.year, _today.month, _today.day + 1);
    if (isSameDay(_selectedDay, _today)) return 'Today';
    if (isSameDay(_selectedDay, yesterday)) return 'Yesterday';
    if (isSameDay(_selectedDay, tomorrow)) return 'Tomorrow';
    return '${_weekdays[_selectedDay.weekday - 1]}, ${_monthDay(_selectedDay)}';
  }

  static String weekdayLetter(DateTime day) => _weekdays[day.weekday - 1][0];

  void selectDay(DateTime day) => _selectedDay = dateOnly(day);

  void changePage(int newOffset){
    if(newOffset == _pageOffset) return;
    _pageOffset = newOffset;
    _selectedDay = daysForPage(newOffset)[daysEachSide];
  }

  void goToToday({DateTime? now}) {
    _today = dateOnly(now ?? DateTime.now());
    _pageOffset = 0;
    _selectedDay = _today;
  }

  //Which page a given date falls on to later display
  int pageForDate(DateTime date){
    final days = daysBetween(_today, date);
    return((days + daysEachSide)/ daysPerPage).floor();
  }

  void jumpToDate(DateTime date) {
    _pageOffset = pageForDate(date);
    _selectedDay = dateOnly(date);
  }

  DateTime get firstPickableDate => DateTime(_today.year - 10);
  DateTime get lastPickableDate => DateTime(_today.year + 10, 12, 31);

  static int daysBetween(DateTime from, DateTime to) {
    final a = DateTime.utc(from.year, from.month, from.day);
    final b = DateTime.utc(to.year, to.month, to.day);
    return b.difference(a).inDays;
  }

  String _monthDay(DateTime d) => '${_months[d.month - 1]} ${d.day}';

  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

