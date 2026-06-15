import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_layout_inspector/flutter_layout_inspector.dart';

void main() {
  testWidgets('LayoutInspector renders child widget', (tester) async {
    await tester.pumpWidget(
      LayoutInspector(
        child: const MaterialApp(
          home: Scaffold(body: Text('Hello')),
        ),
      ),
    );

    expect(find.text('Hello'), findsOneWidget);
  });

  testWidgets('LayoutInspector shows FAB in debug mode', (tester) async {
    await tester.pumpWidget(
      LayoutInspector(
        child: const MaterialApp(
          home: Scaffold(body: Text('Hello')),
        ),
      ),
    );

    // The FAB uses a search icon when inactive
    expect(find.byIcon(Icons.search_rounded), findsOneWidget);
  });
}
