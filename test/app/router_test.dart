library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:louvorja_piano_mobile/app/router.dart';

void main() {
  testWidgets('deep link de álbum resolve /hymns/:albumId', (tester) async {
    appRouter.go('/hymns/123');
    await tester.pumpWidget(MaterialApp.router(routerConfig: appRouter));
    await tester.pumpAndSettle();

    expect(find.text('Álbum'), findsOneWidget);
    expect(find.text('ID: 123'), findsOneWidget);
  });

  testWidgets('deep link de hino resolve /hymns/:albumId/:hymnId',
      (tester) async {
    appRouter.go('/hymns/123/456');
    await tester.pumpWidget(MaterialApp.router(routerConfig: appRouter));
    await tester.pumpAndSettle();

    expect(find.text('Hino'), findsOneWidget);
    expect(find.text('ID: 456'), findsOneWidget);
  });
}
