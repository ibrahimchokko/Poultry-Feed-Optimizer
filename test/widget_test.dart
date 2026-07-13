// This is a basic Flutter widget test for the Feed Formulator app.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:feed_formulation_calculator_linear_method/main.dart';

void main() {
  testWidgets('App launches and renders app bar title', (WidgetTester tester) async {
    // Build the app and trigger a frame.
    await tester.pumpWidget(const FeedFormulatorApp());

    // Verify the app bar title is present.
    expect(find.textContaining('Feed Formulator'), findsOneWidget);
  });

  testWidgets('Input card contains all three input fields', (WidgetTester tester) async {
    await tester.pumpWidget(const FeedFormulatorApp());

    // Poultry type dropdown should be visible.
    expect(find.text('Poultry Type'), findsOneWidget);

    // Age and flock fields should be present.
    expect(find.text('Age in Weeks'), findsOneWidget);
    expect(find.text('Flock Size (number of birds)'), findsOneWidget);
  });

  testWidgets('Tapping calculate with empty fields shows validation error',
      (WidgetTester tester) async {
    await tester.pumpWidget(const FeedFormulatorApp());

    // Tap the Calculate button without filling any fields.
    await tester.tap(find.text('Calculate Formulation'));
    await tester.pump();

    // At least one validation message should appear.
    expect(
      find.textContaining('Please enter'),
      findsAtLeastNWidgets(1),
    );
  });
}
