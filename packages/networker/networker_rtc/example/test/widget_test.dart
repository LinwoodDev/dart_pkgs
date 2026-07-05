import 'package:flutter_test/flutter_test.dart';
import 'package:networker_rtc_example/main.dart';

void main() {
  testWidgets('shows chat controls', (tester) async {
    await tester.pumpWidget(const RtcChatApp());

    expect(find.text('Networker RTC Chat'), findsOneWidget);
    expect(find.text('Start signaling server'), findsOneWidget);
    expect(find.text('Join as peer'), findsOneWidget);
    expect(find.text('Signaling URL'), findsOneWidget);
    expect(find.text('ICE servers'), findsOneWidget);
  });
}
