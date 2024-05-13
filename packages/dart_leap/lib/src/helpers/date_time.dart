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

  int get week => getWeek(DateTime.monday);

  // Get the week number of the year
  // If startOfWeek is Monday, 2024-01-01 will be in week 1
  // Start with 1
  int getWeek(int startOfWeek) {
    final nextStart = getNextStartOfWeek(startOfWeek);
    final firstStart = DateTime(year, 1, 1).getNextStartOfWeek(startOfWeek);
    final diff = nextStart.difference(firstStart).inDays;
    return (diff / 7).ceil() + 1;
  }

  DateTime get nextStartOfWeek => getNextStartOfWeek(DateTime.monday);

  DateTime getNextStartOfWeek(int startOfWeek) {
    var date = DateTime(year, month, day);
    return date.addDays(7 - date.weekday + startOfWeek);
  }

  int getDaysInMonth() {
    return DateTime(year, month + 1, 0).day;
  }

  int get secondsSinceEpoch {
    var ms = millisecondsSinceEpoch;
    return (ms / 1000).round();
  }

  DateTime onlyDate() {
    return DateTime(year, month, day);
  }

  static DateTime fromSecondsSinceEpoch(int seconds) {
    return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
  }
}
