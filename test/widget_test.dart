import 'package:bodycare_home_service/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('CareGo app starts on splash screen', (tester) async {
    await tester.pumpWidget(const BodyCareApp());

    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.byType(Image), findsWidgets);

    await tester.pump(const Duration(milliseconds: 1300));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
