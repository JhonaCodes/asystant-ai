import 'package:asystant_ai/src/widgets/chat_activity_pulse.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('reduced motion stops activity and keeps the icon visible', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: ChatActivityPulse(active: true, child: Text('Activity')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final transition = tester.widget<FadeTransition>(
      find.descendant(
        of: find.byType(ChatActivityPulse),
        matching: find.byType(FadeTransition),
      ),
    );
    expect(transition.opacity.value, 1);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}
