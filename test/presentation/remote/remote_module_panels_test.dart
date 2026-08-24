library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:louvorja_piano_mobile/core/services/remote/remote_protocol.dart';
import 'package:louvorja_piano_mobile/presentation/remote/remote_module_panels.dart';

void main() {
  final sent = <RemoteCommand>[];

  Future<void> fakeSend(
    RemoteAction action, {
    int? index,
    int? volume,
    int? versionId,
    int? bookId,
    int? chapter,
    int? verse,
    int? durationMs,
  }) async {
    sent.add(RemoteCommand(
      id: 't',
      action: action,
      index: index,
      volume: volume,
      versionId: versionId,
      bookId: bookId,
      chapter: chapter,
      verse: verse,
      durationMs: durationMs,
    ));
  }

  Widget wrap(Widget child) => MaterialApp(
        home: Scaffold(body: child),
      );

  setUp(() => sent.clear());

  testWidgets('RemoteBiblePanel envia bible.open com livro/cap/versículo',
      (tester) async {
    await tester.pumpWidget(
      wrap(RemoteBiblePanel(send: fakeSend)),
    );
    await tester.enterText(
      find.byKey(const Key('remote-bible-book')),
      '1',
    );
    await tester.enterText(
      find.byKey(const Key('remote-bible-chapter')),
      '3',
    );
    await tester.enterText(
      find.byKey(const Key('remote-bible-verse')),
      '5',
    );
    await tester.tap(find.byKey(const Key('remote-bible-open')));
    await tester.pump();

    expect(sent, hasLength(1));
    expect(sent.single.action, RemoteAction.bibleOpen);
    expect(sent.single.bookId, 1);
    expect(sent.single.chapter, 3);
    expect(sent.single.verse, 5);
  });

  testWidgets('RemoteBiblePanel com livro vazio NÃO envia', (tester) async {
    await tester.pumpWidget(wrap(RemoteBiblePanel(send: fakeSend)));
    await tester.tap(find.byKey(const Key('remote-bible-open')));
    await tester.pump();
    expect(sent, isEmpty);
  });

  testWidgets('RemoteTimePanel renderiza timer + countdown e envia ações',
      (tester) async {
    const state = RemotePlayerState(
      playing: false,
      position: Duration.zero,
      duration: Duration.zero,
      slideIndex: 0,
      slideCount: 0,
      volume: 0,
      canPrevious: false,
      canNext: false,
      timerModule: RemoteTimerState(
        status: 'idle',
        accumulatedMs: 0,
        isProjecting: false,
      ),
      countdownModule: RemoteCountdownState(
        status: 'running',
        durationMs: 300000,
        accumulatedMs: 60000,
        finished: false,
        isProjecting: false,
      ),
    );
    await tester.pumpWidget(
      wrap(RemoteTimePanel(send: fakeSend, state: state)),
    );

    expect(find.byKey(const Key('remote-timer-card')), findsOneWidget);
    expect(find.byKey(const Key('remote-countdown-card')), findsOneWidget);

    // countdown está abaixo da dobra — arrasta a lista pra cima
    await tester.drag(
      find.byKey(const Key('remote-timer-card')),
      const Offset(0, -400),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('remote-countdown-card')), findsOneWidget);

    // countdown rodando → botão principal = pause
    await tester.tap(find.byKey(const Key('remote-countdown-toggle')));
    await tester.pump();
    expect(sent.single.action, RemoteAction.countdownPause);

    // timer parado → botão principal = start
    sent.clear();
    await tester.tap(find.byKey(const Key('remote-timer-toggle')));
    await tester.pump();
    expect(sent.single.action, RemoteAction.timerStart);
  });
}
