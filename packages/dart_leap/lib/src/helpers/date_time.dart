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
    final currentStart = getStartOfWeek(startOfWeek);
    final firstStart = DateTime(year, 1, 1).getStartOfWeek(startOfWeek);
    final diff = currentStart.difference(firstStart).inDays;
    return (diff / 7).ceil() + 1;
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

void main() {
  print(DateTime(24, 1, 1).getStartOfWeek(DateTime.monday));
  print(DateTime.now().getStartOfWeek(DateTime.monday));
  print(DateTime.now().getStartOfWeek(DateTime.saturday));
  print(DateTime.now().getWeek(DateTime.saturday));
  print(DateTime(2024, 01, 01).getWeek(DateTime.saturday));
  print(DateTime(2024, 01, 02).getWeek(DateTime.saturday));
  print(DateTime(2024, 01, 03).getWeek(DateTime.saturday));
  print(DateTime(2024, 01, 04).getWeek(DateTime.saturday));
  print(DateTime(2024, 01, 05).getWeek(DateTime.saturday));
  print(DateTime(2024, 01, 06).getWeek(DateTime.saturday));
  print(DateTime(2024, 01, 07).getWeek(DateTime.saturday));
  print(DateTime(2024, 01, 08).getWeek(DateTime.saturday));
}
