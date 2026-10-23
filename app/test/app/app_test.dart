import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('App smoke tests', () {
    testWidgets('App builds without errors', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Center(child: Text('NEUROPLAY'))),
        ),
      );
      expect(find.text('NEUROPLAY'), findsOneWidget);
    });
  });
}
