import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tetsudo_teikoku/main.dart';

void main() {
  testWidgets('App boots and shows the home screen app bar', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: TetsudoTeikokuApp()),
    );
    await tester.pump();

    expect(find.text('鉄道帝国'), findsOneWidget);
  });
}
