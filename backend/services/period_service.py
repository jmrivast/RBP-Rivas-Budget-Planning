from __future__ import annotations

from dataclasses import dataclass
from datetime import date, timedelta


@dataclass(slots=True)
class PeriodBounds:
    start: date
    end: date


class PeriodService:
    MONTH_LABELS = {
        1: "Ene",
        2: "Feb",
        3: "Mar",
        4: "Abr",
        5: "May",
        6: "Jun",
        7: "Jul",
        8: "Ago",
        9: "Sep",
        10: "Oct",
        11: "Nov",
        12: "Dic",
    }

    @staticmethod
    def previous_quincena(year: int, month: int, cycle: int) -> tuple[int, int, int]:
        if cycle == 2:
            return year, month, 1
        if month == 1:
            return year - 1, 12, 2
        return year, month - 1, 2

    @staticmethod
    def next_quincena(year: int, month: int, cycle: int) -> tuple[int, int, int]:
        if cycle == 1:
            return year, month, 2
        if month == 12:
            return year + 1, 1, 1
        return year, month + 1, 1

    @staticmethod
    def last_day_of_month(year: int, month: int) -> int:
        if month == 2:
            if PeriodService._is_leap_year(year):
                return 29
            return 28
        if month in {4, 6, 9, 11}:
            return 30
        return 31

    @classmethod
    def safe_day(cls, year: int, month: int, day: int) -> int:
        return max(1, min(day, cls.last_day_of_month(year, month)))

    @staticmethod
    def next_month(year: int, month: int) -> tuple[int, int]:
        return (year + 1, 1) if month == 12 else (year, month + 1)

    @staticmethod
    def previous_month(year: int, month: int) -> tuple[int, int]:
        return (year - 1, 12) if month == 1 else (year, month - 1)

    @classmethod
    def get_month_range(cls, year: int, month: int, payday: int) -> PeriodBounds:
        current_payday = cls.safe_day(year, month, payday)
        next_year, next_month = cls.next_month(year, month)
        next_payday = cls.safe_day(next_year, next_month, payday)
        start = date(year, month, current_payday)
        end = date(next_year, next_month, next_payday) - timedelta(days=1)
        return PeriodBounds(start=start, end=end)

    @classmethod
    def get_quincena_range(
        cls,
        year: int,
        month: int,
        cycle: int,
        *,
        day1: int,
        day2: int,
    ) -> PeriodBounds:
        d1 = cls.safe_day(year, month, day1)
        d2 = cls.safe_day(year, month, day2)

        if d1 < d2:
            if cycle == 1:
                return PeriodBounds(
                    start=date(year, month, d1),
                    end=date(year, month, max(d1, d2 - 1)),
                )
            next_year, next_month = cls.next_month(year, month)
            next_d1 = cls.safe_day(next_year, next_month, day1)
            return PeriodBounds(
                start=date(year, month, d2),
                end=date(next_year, next_month, next_d1) - timedelta(days=1),
            )

        prev_year, prev_month = cls.previous_month(year, month)
        prev_d1 = cls.safe_day(prev_year, prev_month, day1)
        if cycle == 1:
            return PeriodBounds(
                start=date(prev_year, prev_month, prev_d1),
                end=date(year, month, max(1, d2 - 1)),
            )
        return PeriodBounds(
            start=date(year, month, d2),
            end=date(year, month, max(d2, d1 - 1)),
        )

    @classmethod
    def get_cycle_for_date(cls, value: date, *, period_mode: str, day1: int, day2: int) -> int:
        if period_mode == "mensual":
            return 1
        q1 = cls.get_quincena_range(value.year, value.month, 1, day1=day1, day2=day2)
        if q1.start <= value <= q1.end:
            return 1
        return 2

    @classmethod
    def iterate_months(cls, start: date, end: date):
        year = start.year
        month = start.month
        while year < end.year or (year == end.year and month <= end.month):
            yield year, month
            year, month = cls.next_month(year, month)

    @classmethod
    def format_period_label(
        cls,
        *,
        year: int,
        month: int,
        cycle: int,
        period_mode: str,
        start_date: date | str,
        end_date: date | str,
    ) -> str:
        start = date.fromisoformat(start_date) if isinstance(start_date, str) else start_date
        end = date.fromisoformat(end_date) if isinstance(end_date, str) else end_date
        label = cls.MONTH_LABELS[month]
        if period_mode == "mensual":
            return f"{start.day}-{end.day} {label} {year}  (Mensual)"
        return f"{start.day}-{end.day} {label} {year}  (Q{cycle})"

    @staticmethod
    def _is_leap_year(year: int) -> bool:
        if year % 400 == 0:
            return True
        if year % 100 == 0:
            return False
        return year % 4 == 0
