import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:currency_converter_ocr/main.dart';

void main() {
  testWidgets('Upload button appears and functions', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp());

    final uploadButton = find.text('Upload Image');
    expect(uploadButton, findsOneWidget);

    await tester.tap(uploadButton);
    await tester.pump();
  });
}
