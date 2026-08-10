library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:louvorja_piano_mobile/presentation/shared/widgets/hymn_list_tile.dart';

void main() {
  testWidgets('exibe número, título e subtítulo do hino', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: HymnListTile(
            number: '001',
            title: 'Santo, Santo, Santo',
            subtitle: 'Hinário Adventista',
          ),
        ),
      ),
    );
    expect(find.text('001'), findsOneWidget);
    expect(find.text('Santo, Santo, Santo'), findsOneWidget);
    expect(find.text('Hinário Adventista'), findsOneWidget);
  });

  testWidgets('executa callback ao tocar', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HymnListTile(
            number: '001',
            title: 'Hino',
            onTap: () => tapped = true,
          ),
        ),
      ),
    );
    await tester.tap(find.text('Hino'));
    expect(tapped, isTrue);
  });

  testWidgets('exibe estado baixado sem subtítulo', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: HymnListTile(
            number: '002',
            title: 'Hino Offline',
            isDownloaded: true,
          ),
        ),
      ),
    );
    expect(find.text('Hino Offline'), findsOneWidget);
  });
}
