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
    final nextYear = DateTime(year + 1).getStartOfWeek(startOfWeek);
    if (!nextYear.isAfter(this)) {
      return 1;
    }
    final start = DateTime(year).getStartOfWeek(startOfWeek);
    final diff = difference(start);
    final week = (diff.inDays / 7).floor();
    return week + 1;
  }

  DateTime get startOfWeek => getStartOfWeek(DateTime.monday);

  DateTime getStartOfWeek(int startOfWeek) {
    return subtract(Duration(days: (7 + weekday - startOfWeek) % 7));
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
