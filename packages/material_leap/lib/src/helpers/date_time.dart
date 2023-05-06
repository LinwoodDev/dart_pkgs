extension DateTimeHelper on DateTime {
  bool isSameDay(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }

  DateTime addYears(int years) {
    return DateTime(
        year + years, month, day, hour, minute, second, millisecond);
  }

  DateTime addDays(int days) {
    return DateTime(year, month, day + days, hour, minute, second, millisecond);
  }

  int get week {
    final date = DateTime(year, month, day);
    final firstDay = DateTime(date.year - 1, 12, 31);
    final days = date.difference(firstDay).inDays;
    return (days / 7).ceil();
  }

  DateTime get nextStartOfWeek {
    var date = DateTime(year, month, day);
    return date.addDays(7 - date.weekday + 1);
  }

  int getDaysInMonth() {
    return DateTime(year, month + 1, 0).day;
  }
}
