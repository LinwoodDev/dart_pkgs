extension DateTimeHelper on DateTime {
  bool isSameDay(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }

  DateTime addYears(int years) {
    if (isUtc) {
      return DateTime.utc(
        year + years,
        month,
        day,
        hour,
        minute,
        second,
        millisecond,
        microsecond,
      );
    }
    return DateTime(
      year + years,
      month,
      day,
      hour,
      minute,
      second,
      millisecond,
      microsecond,
    );
  }

  DateTime addDays(int days) {
    if (isUtc) {
      return DateTime.utc(
        year,
        month,
        day + days,
        hour,
        minute,
        second,
        millisecond,
        microsecond,
      );
    }
    return DateTime(
      year,
      month,
      day + days,
      hour,
      minute,
      second,
      millisecond,
      microsecond,
    );
  }

  int get week => getWeek(DateTime.monday);

  // Get the week number of the year
  // If startOfWeek is Monday, 2024-01-01 will be in week 1
  // Start with 1
  int getWeek(int startOfWeek) {
    final nextYear = (isUtc ? DateTime.utc(year + 1) : DateTime(year + 1))
        .getStartOfWeek(startOfWeek);
    if (!nextYear.isAfter(this)) {
      return 1;
    }
    final start = (isUtc ? DateTime.utc(year) : DateTime(year)).getStartOfWeek(
      startOfWeek,
    );
    final diff = difference(start);
    final week = (diff.inDays / 7).floor();
    return week + 1;
  }

  DateTime get startOfWeek => getStartOfWeek(DateTime.monday);

  DateTime getStartOfWeek(int startOfWeek) {
    return subtract(Duration(days: (7 + weekday - startOfWeek) % 7));
  }

  int getDaysInMonth() {
    if (isUtc) {
      return DateTime.utc(year, month + 1, 0).day;
    }
    return DateTime(year, month + 1, 0).day;
  }

  int get secondsSinceEpoch {
    var ms = millisecondsSinceEpoch;
    return (ms / 1000).round();
  }

  DateTime onlyDate() {
    if (isUtc) {
      return DateTime.utc(year, month, day);
    }
    return DateTime(year, month, day);
  }

  static DateTime fromSecondsSinceEpoch(int seconds, {bool isUtc = false}) {
    return DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: isUtc);
  }
}
