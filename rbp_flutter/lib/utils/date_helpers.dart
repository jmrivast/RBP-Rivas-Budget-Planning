import 'dart:math';

({int year, int month, int cycle}) previousQuincena(
    int year, int month, int cycle) {
  if (cycle == 2) {
    return (year: year, month: month, cycle: 1);
  }
  if (month == 1) {
    return (year: year - 1, month: 12, cycle: 2);
  }
  return (year: year, month: month - 1, cycle: 2);
}

({int year, int month, int cycle}) nextQuincena(
    int year, int month, int cycle) {
  if (cycle == 1) {
    return (year: year, month: month, cycle: 2);
  }
  if (month == 12) {
    return (year: year + 1, month: 1, cycle: 1);
  }
  return (year: year, month: month + 1, cycle: 1);
}

int lastDayOfMonth(int year, int month) {
  final monthLengths = <int>[
    31,
    _isLeapYear(year) ? 29 : 28,
    31,
    30,
    31,
    30,
    31,
    31,
    30,
    31,
    30,
    31,
  ];
  return monthLengths[month - 1];
}

int safeDay(int year, int month, int day) {
  return min(max(1, day), lastDayOfMonth(year, month));
}

(int, int) nextMonth(int year, int month) {
  if (month == 12) {
    return (year + 1, 1);
  }
  return (year, month + 1);
}

(int, int) previousMonth(int year, int month) {
  if (month == 1) {
    return (year - 1, 12);
  }
  return (year, month - 1);
}

({String start, String end}) getMonthRangeByPayday(
  int year,
  int month,
  int payday,
) {
  final currentPayday = safeDay(year, month, payday);
  final (nextYear, nextMonthValue) = nextMonth(year, month);
  final nextPayday = safeDay(nextYear, nextMonthValue, payday);
  final start = DateTime(year, month, currentPayday);
  final end = DateTime(nextYear, nextMonthValue, nextPayday).subtract(
    const Duration(days: 1),
  );
  return (
    start: _isoDate(start),
    end: _isoDate(end),
  );
}

({String start, String end}) getQuincenaRange(
  int year,
  int month,
  int cycle, {
  required int day1,
  required int day2,
}) {
  final d1 = safeDay(year, month, day1);
  final d2 = safeDay(year, month, day2);

  if (d1 < d2) {
    if (cycle == 1) {
      final start = DateTime(year, month, d1);
      final end = DateTime(year, month, max(d1, d2 - 1));
      return (start: _isoDate(start), end: _isoDate(end));
    }
    final start = DateTime(year, month, d2);
    final (nextYear, nextMonthValue) = nextMonth(year, month);
    final nextD1 = safeDay(nextYear, nextMonthValue, day1);
    final end = DateTime(nextYear, nextMonthValue, nextD1).subtract(
      const Duration(days: 1),
    );
    return (start: _isoDate(start), end: _isoDate(end));
  }

  final (prevYear, prevMonthValue) = previousMonth(year, month);
  final prevD1 = safeDay(prevYear, prevMonthValue, day1);

  if (cycle == 1) {
    final start = DateTime(prevYear, prevMonthValue, prevD1);
    final end = DateTime(year, month, max(1, d2 - 1));
    return (start: _isoDate(start), end: _isoDate(end));
  }

  final start = DateTime(year, month, d2);
  final end = DateTime(year, month, max(d2, d1 - 1));
  return (start: _isoDate(start), end: _isoDate(end));
}

int getCycleForDate(
  DateTime date, {
  required String periodMode,
  required int day1,
  required int day2,
}) {
  if (periodMode == 'mensual') {
    return 1;
  }
  final q1 = getQuincenaRange(
    date.year,
    date.month,
    1,
    day1: day1,
    day2: day2,
  );
  final startQ1 = DateTime.parse(q1.start);
  final endQ1 = DateTime.parse(q1.end);
  if (!date.isBefore(startQ1) && !date.isAfter(endQ1)) {
    return 1;
  }
  return 2;
}

String formatPeriodLabel({
  required int year,
  required int month,
  required int cycle,
  required String periodMode,
  required String startDate,
  required String endDate,
}) {
  const months = <int, String>{
    1: 'Ene',
    2: 'Feb',
    3: 'Mar',
    4: 'Abr',
    5: 'May',
    6: 'Jun',
    7: 'Jul',
    8: 'Ago',
    9: 'Sep',
    10: 'Oct',
    11: 'Nov',
    12: 'Dic',
  };
  final startDay = int.tryParse(startDate.split('-').last) ?? 1;
  final endDay = int.tryParse(endDate.split('-').last) ?? 1;
  if (periodMode == 'mensual') {
    return '$startDay-$endDay ${months[month]} $year  (Mensual)';
  }
  return '$startDay-$endDay ${months[month]} $year  (Q$cycle)';
}

String _isoDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

bool _isLeapYear(int year) {
  if (year % 400 == 0) {
    return true;
  }
  if (year % 100 == 0) {
    return false;
  }
  return year % 4 == 0;
}
