import 'package:dart_leap/dart_leap.dart';
import 'package:test/test.dart';

void main() {
  group('Test datetime weeks', () {
    test('Test start of weeks', () {
      expect(DateTime(2024, 1, 1).getStartOfWeek(DateTime.monday),
          DateTime(2024, 1, 1));
      expect(DateTime(2024, 05, 19).getStartOfWeek(DateTime.monday),
          DateTime(2024, 05, 13));
      expect(DateTime(2024, 05, 19).getStartOfWeek(DateTime.saturday),
          DateTime(2024, 05, 18));
    });
    test('Test week number', () {
      expect(DateTime(2024, 05, 19).getWeek(DateTime.saturday), 21);
      expect(DateTime(2024, 05, 19).getWeek(DateTime.monday), 20);
      expect(DateTime(2023, 12, 30).getWeek(DateTime.saturday), 1);
      expect(DateTime(2024, 01, 01).getWeek(DateTime.saturday), 1);
      expect(DateTime(2024, 01, 02).getWeek(DateTime.saturday), 1);
      expect(DateTime(2024, 01, 03).getWeek(DateTime.saturday), 1);
      expect(DateTime(2024, 01, 04).getWeek(DateTime.saturday), 1);
      expect(DateTime(2024, 01, 05).getWeek(DateTime.saturday), 1);
      expect(DateTime(2024, 01, 06).getWeek(DateTime.saturday), 2);
      expect(DateTime(2024, 01, 07).getWeek(DateTime.saturday), 2);
      expect(DateTime(2024, 01, 08).getWeek(DateTime.saturday), 2);
      expect(DateTime(2024, 01, 08).getWeek(DateTime.saturday), 2);
    });
  });
}
