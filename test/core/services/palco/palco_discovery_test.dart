library;

import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:louvorja_piano_mobile/core/services/palco/palco_discovery.dart';

/// F3.4: descoberta de receivers Palco na sub-rede (mesma técnica que o
/// receiver usa para achar o sender: GET :7080/status com JSON válido).
/// Serve o StageCastButton listar "Palcos encontrados" em vez de só IP manual.
void main() {
  test('descobre sender LouvorJA ativo na sub-rede', () async {
    // sender falso na porta efêmera — mas discovery espera :7080 fixo em
    // cada IP candidato. Subimos um server HTTP real na 7080 se livre.
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 7080);
    server.listen((req) {
      req.response.headers.contentType = ContentType.json;
      req.response.write('{"unlocked":true,"clients":0}');
      req.response.close();
    });
    addTearDown(() => server.close(force: true));

    final found = await PalcoDiscovery.scan(
        subnet: '127.0.0', timeout: const Duration(milliseconds: 800));
    expect(found, isNotEmpty);
    expect(found, contains('127.0.0.1'));
  });

  test('IP sem sender não aparece (JSON inválido/sem resposta)', () async {
    // porta fechada proposital: 7071 não responde nada
    final found = await PalcoDiscovery.scan(
        subnet: '127.0.0.99', timeout: const Duration(milliseconds: 400));
    expect(found, isEmpty);
  });
}
