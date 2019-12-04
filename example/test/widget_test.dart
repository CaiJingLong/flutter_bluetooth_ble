// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility that Flutter provides. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bluetooth_ble_example/main.dart';

void main() {
  testWidgets('Verify Platform version', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp());

    // Verify that platform version is retrieved.
    expect(
      find.byWidgetPredicate(
        (Widget widget) =>
            widget is Text && widget.data.startsWith('Running on:'),
      ),
      findsOneWidget,
    );
  });

  test("print string", () {
    final rec =
        "12345678901234567890qwertyuiopasdfghjklzxcvbnm12345678901234567890qwertyuiopasdfghjklzxcvbnm12345678901234567890qwertyuiopasdfghjklzxcvbnm12345678901234567890qwertyuiopasdfghjklzxcvbnm12345678901234567890qwertyuiopasdfghjklzxcvbnm12345678901234567890qwertyuiopasdfghjklzxcvbnm12345678901234567890qwertyuiopasdfghjklzxcvbnm12345678901234567890qwertyuiopasdfghjklzxcvbnm12345678901234567890qwertyuiopasdfghjklzxcvbnm12345678901234567890qwertyuiopasdfghjklzxcvbnm12345678901234567890qwertyuiopasdfghjklzxcvbnm12345678901234567890qwertyuiopasdfghjklzxcvbnm12345678901234567890qwertyuiopasdfghjklzxcvbnm12345678901234567890qwertyuiopasdfghjklzxcvbnm12345678901234567890qwertyuiopasdfghjklzxcvbnm12345678901234567890qwertyuiopasdfghjklzxcvbnm12345678901234567890qwertyuiopasdfghjklzxcvbnm12345678901234567890qwertyuiopasdfghjklzxcvbnm12345678901234567890qwertyuiopasdfghjklzxcvbnm12345678901234567890qwertyuiopasdfghjklzxcvbnm";

    final send = "12345678901234567890qwertyuiopasdfghjklzxcvbnm" * 20;

    expectSync(rec, send);
  });

  test("always error", () {
    expectSync(1, 0);
  });
}
