import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumsheet/main.dart';

void main() {
  testWidgets('the form comes up and offers a class and a chapter',
      (tester) async {
    await tester.pumpWidget(const SumSheetApp());
    // The syllabus is an asset read, so the first frame is the spinner.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.text('SumSheet'), findsOneWidget);
    expect(find.text('Class'), findsOneWidget);
    expect(find.text('Chapter'), findsOneWidget);
    expect(find.text('Download the worksheet'), findsOneWidget);
  });
}
