library;

import 'package:flutter_test/flutter_test.dart';
import 'package:louvorja_piano_mobile/core/services/dlna/dlna_renderer_client.dart';

void main() {
  group('DIDL-Lite (formato validado na LG real)', () {
    test('imagem contém classe imageItem, res PNG e protocolInfo', () {
      final didl = DlnaRendererClient.didlImageFor(
        'http://192.168.1.10:54321/slide.jpg?v=2',
        'Nosso Sol é Jesus',
      );

      expect(didl, contains('object.item.imageItem'));
      expect(didl, contains('http-get:*:image/png:DLNA.ORG_PN=PNG_LRG'));
      expect(didl, contains('http://192.168.1.10:54321/slide.jpg?v=2'));
      expect(didl, contains('<dc:title>Nosso Sol é Jesus</dc:title>'));
    });

    test('título com XML especial é escapado', () {
      final didl = DlnaRendererClient.didlImageFor(
        'http://x/s.png',
        'Hino <Grande> & Pequeno',
      );
      // No DIDL final (que vai DENTRO do CurrentURIMetaData escapado),
      // o título precisa estar seguro.
      expect(didl, isNot(contains('<dc-title-não-escapado>')));
      expect(didl, contains('&amp;'));
    });

    test('estrutura DIDL tem namespaces corretos', () {
      final didl = DlnaRendererClient.didlImageFor('http://x/s.png', 'T');
      expect(didl.startsWith('<DIDL-Lite'), isTrue);
      expect(didl, contains('urn:schemas-upnp-org:metadata-1-0/DIDL-Lite/'));
      expect(didl, contains('xmlns:upnp'));
      expect(didl.endsWith('</DIDL-Lite>'), isTrue);
    });
  });
}
