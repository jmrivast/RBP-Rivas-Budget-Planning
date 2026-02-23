import 'package:flutter_test/flutter_test.dart';

import 'package:rbp_flutter/utils/date_helpers.dart' as dh;

void main() {
  test('getQuincenaRange normal paydays (1,16)', () {
    final q1 = dh.getQuincenaRange(2026, 2, 1, day1: 1, day2: 16);
    final q2 = dh.getQuincenaRange(2026, 2, 2, day1: 1, day2: 16);

    expect(q1.start, '2026-02-01');
    expect(q1.end, '2026-02-15');
    expect(q2.start, '2026-02-16');
    expect(q2.end, '2026-02-28');
  });

  test('getQuincenaRange custom paydays (15,30)', () {
    final q1 = dh.getQuincenaRange(2026, 2, 1, day1: 15, day2: 30);
    final q2 = dh.getQuincenaRange(2026, 2, 2, day1: 15, day2: 30);

    expect(q1.start, '2026-02-15');
    expect(q1.end, '2026-02-27');
    expect(q2.start, '2026-02-28');
    expect(q2.end, '2026-03-14');
  });

  test('getQuincenaRange crossed paydays (25,10)', () {
    final q1 = dh.getQuincenaRange(2026, 2, 1, day1: 25, day2: 10);
    final q2 = dh.getQuincenaRange(2026, 2, 2, day1: 25, day2: 10);

    expect(q1.start, '2026-01-25');
    expect(q1.end, '2026-02-09');
    expect(q2.start, '2026-02-10');
    expect(q2.end, '2026-02-24');
  });

  test('getCycleForDate in quincenal mode', () {
    final c1 = dh.getCycleForDate(
      DateTime(2026, 2, 5),
      periodMode: 'quincenal',
      day1: 1,
      day2: 16,
    );
    final c2 = dh.getCycleForDate(
      DateTime(2026, 2, 20),
      periodMode: 'quincenal',
      day1: 1,
      day2: 16,
    );
    expect(c1, 1);
    expect(c2, 2);
  });

  test('prev and next quincena navigation', () {
    final prev = dh.previousQuincena(2026, 1, 1);
    final next = dh.nextQuincena(2026, 12, 2);

    expect(prev, (year: 2025, month: 12, cycle: 2));
    expect(next, (year: 2027, month: 1, cycle: 1));
  });

  test('monthly range by payday', () {
    final range = dh.getMonthRangeByPayday(2026, 2, 15);
    expect(range.start, '2026-02-15');
    expect(range.end, '2026-03-14');
  });
}
