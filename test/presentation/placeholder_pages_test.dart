library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:louvorja_piano_mobile/presentation/bible/bible_page.dart';
import 'package:louvorja_piano_mobile/presentation/liturgy/liturgy_page.dart';

void main() {
  testWidgets('Bíblia placeholder renderiza', (tester) async {
    await tester.pumpWidget(MaterialApp(home: BiblePage()));
    expect(find.byType(BiblePage), findsOneWidget);
  });

  testWidgets('Liturgia placeholder renderiza', (tester) async {
    await tester.pumpWidget(MaterialApp(home: LiturgyPage()));
    expect(find.byType(LiturgyPage), findsOneWidget);
  });
}
