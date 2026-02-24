import 'package:flutter_test/flutter_test.dart';

import 'package:deepgram_transcription/main.dart';

void main() {
  testWidgets('App renders with initial text and buttons',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(
      find.text('To start transcribing your voice, press start.'),
      findsOneWidget,
    );
    expect(find.text('Start'), findsOneWidget);
    expect(find.text('Stop'), findsOneWidget);
  });
}
