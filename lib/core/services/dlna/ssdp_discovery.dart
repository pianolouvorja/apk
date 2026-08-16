library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Descoberta de MediaRenderers DLNA na rede local (SSDP M-SEARCH).
///
/// Não é só LG: qualquer TV/aparelho que implemente UPnP AVTransport
/// (Samsung, Sony, Philips, TCL, Panasonic...) responde e aparece.
/// A porta/UUID do serviço MUDA entre reboots da TV — por isso o
/// discovery é por SSDP + SCPD a cada sessão, nunca cache de controlURL.
class SsdpDiscovery {
  static const _msearch = 'M-SEARCH * HTTP/1.1\r\n'
      'HOST: 239.255.255.250:1900\r\n'
      'MAN: "ssdp:discover"\r\n'
      'MX: 3\r\n'
      'ST: urn:schemas-upnp-org:service:AVTransport:1\r\n\r\n';

  /// Varre a rede por renderers. Retorna em até [timeoutMs].
  static Future<List<DlnaRenderer>> scan({int timeoutMs = 4000}) async {
    final found = <String, DlnaRenderer>{};
    RawDatagramSocket? socket;
    try {
      socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        0,
        reuseAddress: true,
      );
      socket.multicastLoopback = false;
      try {
        socket.joinMulticast(
          InternetAddress('239.255.255.250'),
        );
      } catch (_) {/* alguns Androids bloqueiam multicast join; M-SEARCH ainda sai */}
      socket.listen((event) {
        if (event != RawSocketEvent.read) return;
        final dg = socket?.receive();
        if (dg == null) return;
        _handleResponse(dg, found);
      });

      socket.send(
        utf8.encode(_msearch),
        InternetAddress('239.255.255.250'),
        1900,
      );

      await Future<void>.delayed(Duration(milliseconds: timeoutMs));
    } catch (_) {
      // sem rede/multicast: lista vazia
    } finally {
      socket?.close();
    }
    return found.values.toList();
  }

  static void _handleResponse(Datagram dg, Map<String, DlnaRenderer> found) {
    final text = utf8.decode(dg.data, allowMalformed: true);
    if (!text.contains('AVTransport')) return;
    final locationMatch = RegExp(
      r'LOCATION:\s*(http://[^\r\n]+)',
      caseSensitive: false,
    ).firstMatch(text);
    if (locationMatch == null) return;
    final location = locationMatch.group(1)!.trim();
    // Dedup por IP (uma TV anuncia em múltiplas portas).
    final ip = dg.address.address;
    if (found.containsKey(ip)) return;
    found[ip] = DlnaRenderer(ip: ip, descriptionUrl: location);
  }
}

/// Um renderer DLNA encontrado na rede.
class DlnaRenderer {
  final String ip;
  final String descriptionUrl;

  /// Preenchido após [resolve].
  String? friendlyName;
  String? avTransportControlUrl;

  /// Perfis sink declarados via ConnectionManager#GetProtocolInfo.
  /// Base para inferir a resolução máxima de render (PNG_LRG etc).
  String sinkProtocols = '';

  DlnaRenderer({required this.ip, required this.descriptionUrl});

  /// Baixa o SCPD (XML de descrição) e extrai nome + controlURL do
  /// AVTransport. Portas são dinâmicas — sempre resolver na sessão.
  Future<bool> resolve() async {
    try {
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 4);
      final req = await client.getUrl(Uri.parse(descriptionUrl));
      final res = await req.close();
      final xml = await res.transform(utf8.decoder).join();
      client.close();

      final nameMatch = RegExp(
        r'<friendlyName>([^<]+)</friendlyName>',
      ).firstMatch(xml);
      friendlyName = nameMatch?.group(1)?.trim() ?? ip;

      final svc = RegExp(
        r'<serviceType>urn:schemas-upnp-org:service:AVTransport:1</serviceType>.*?<controlURL>([^<]+)</controlURL>',
        dotAll: true,
      ).firstMatch(xml);
      if (svc == null) return false;
      final path = svc.group(1)!.trim();
      final base = Uri.parse(descriptionUrl).replace(path: '', query: '');
      avTransportControlUrl = base.toString().replaceAll(RegExp(r'/$'), '') + path;

      // ConnectionManager#GetProtocolInfo → Sink: perfis que a TV aceita
      // (PNG_LRG etc). Usado para inferir resolução máxima de render.
      final cm = RegExp(
        r'<serviceType>urn:schemas-upnp-org:service:ConnectionManager:1</serviceType>.*?<controlURL>([^<]+)</controlURL>',
        dotAll: true,
      ).firstMatch(xml);
      if (cm != null) {
        final cmUrl =
            base.toString().replaceAll(RegExp(r'/$'), '') + cm.group(1)!.trim();
        sinkProtocols = await _fetchSinkProtocols(cmUrl);
      }

      // SCPD do AVTransport → ações suportadas (fila etc).
      final scpdUrlM = RegExp(
        r'<serviceType>urn:schemas-upnp-org:service:AVTransport:1</serviceType>.*?<SCPDURL>([^<]+)</SCPDURL>',
        dotAll: true,
      ).firstMatch(xml);
      if (scpdUrlM != null) {
        final scpdUrl = base.toString().replaceAll(RegExp(r'/$'), '') +
            scpdUrlM.group(1)!.trim();
        avTransportActions = await _fetchActions(scpdUrl);
      }

      // RenderingControl → volume/mute da TV via app.
      final rc = RegExp(
        r'<serviceType>urn:schemas-upnp-org:service:RenderingControl:1</serviceType>.*?<controlURL>([^<]+)</controlURL>',
        dotAll: true,
      ).firstMatch(xml);
      if (rc != null) {
        renderingControlUrl =
            base.toString().replaceAll(RegExp(r'/$'), '') + rc.group(1)!.trim();
      }

      return avTransportControlUrl != null;
    } catch (_) {
      return false;
    }
  }

  static Future<Set<String>> _fetchActions(String scpdUrl) async {
    try {
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 4);
      final req = await client.getUrl(Uri.parse(scpdUrl));
      final res = await req.close();
      final xml = await res.transform(utf8.decoder).join();
      client.close();
      return RegExp(r'<action>\s*<name>([^<]+)</name>')
          .allMatches(xml)
          .map((m) => m.group(1)!)
          .toSet();
    } catch (_) {
      return const {};
    }
  }

  static Future<String> _fetchSinkProtocols(String cmControlUrl) async {
    try {
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 4);
      final req = await client.postUrl(Uri.parse(cmControlUrl));
      req.headers.set('Content-Type', 'text/xml; charset="utf-8"');
      req.headers.set(
        'SOAPACTION',
        '"urn:schemas-upnp-org:service:ConnectionManager:1#GetProtocolInfo"',
      );
      req.write('<?xml version="1.0" encoding="utf-8"?>'
          '<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" '
          's:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">'
          '<s:Body><u:GetProtocolInfo xmlns:u="urn:schemas-upnp-org:service:ConnectionManager:1">'
          '</u:GetProtocolInfo></s:Body></s:Envelope>');
      final res = await req.close();
      final xml = await res.transform(utf8.decoder).join();
      client.close();
      final m = RegExp(r'<Sink>(.*?)</Sink>', dotAll: true).firstMatch(xml);
      return m?.group(1) ?? '';
    } catch (_) {
      return '';
    }
  }

  /// Resolução alvo de render inferida dos perfis sink declarados.
  ///
  /// DLNA não expõe o painel físico (FHD/4K) — expõe CAPACIDADE:
  /// PNG_LRG = até 1920x1080; PNG_SM = 640x480; PNG_TN = thumbnail.
  /// Sem informação: Full HD (padrão seguro universal).
  DlnaScreenCapability get screenCapability {
    final sink = sinkProtocols.toUpperCase();
    // JPEG_LRG também implica 1920x1080 (perfil mais universal).
    if (sink.contains('PNG_LRG') || sink.contains('JPEG_LRG') ||
        sink.contains('PNG:*') || sink.contains('IMAGE/PNG:*') ||
        sink.contains('IMAGE/JPEG:*')) {
      return DlnaScreenCapability.fhd;
    }
    if (sink.contains('PNG_SM') || sink.contains('JPEG_SM')) {
      return DlnaScreenCapability.sm;
    }
    if (sink.contains('PNG_TN') || sink.contains('JPEG_TN')) {
      return DlnaScreenCapability.tn;
    }
    return DlnaScreenCapability.fhd; // default seguro
  }

  /// Formato de imagem preferido pelo sink (compatibilidade máxima):
  /// PNG quando declarado; JPEG caso contrário (universal em DMR-1.0).
  /// TVs DMR-1.50+ aceitam ambos — PNG preserva nitidez de texto.
  StageImageFormat get preferredImageFormat {
    final sink = sinkProtocols.toUpperCase();
    // PNG wildcard ou PNG_LRG → PNG nativo.
    if (sink.contains('PNG_LRG') || sink.contains('IMAGE/PNG:*') ||
        sink.contains('PNG:*')) {
      return StageImageFormat.png;
    }
    // JPEG presente (qualquer perfil) → JPEG.
    if (sink.contains('JPEG')) return StageImageFormat.jpeg;
    // Sem declaração: JPEG é o perfil com maior cobertura histórica.
    return StageImageFormat.jpeg;
  }

  /// Ações AVTransport suportadas (do SCPD) — habilita recursos
  /// opcionais como fila (SetNextAVTransportURI) quando presentes.
  Set<String> avTransportActions = const {};

  bool get supportsQueue =>
      avTransportActions.contains('SetNextAVTransportURI');

  /// RenderingControl exposto? (volume/mute da TV pelo app)
  String? renderingControlUrl;
  bool get supportsVolume => renderingControlUrl != null;
}

/// Formato de projeção escolhido pela capacidade do sink.
enum StageImageFormat { png, jpeg }

/// Capacidade de render do sink (perfis DLNA PNG).
class DlnaScreenCapability {
  final int width;
  final int height;
  const DlnaScreenCapability(this.width, this.height);

  /// PNG_LRG: 1920x1080.
  static const fhd = DlnaScreenCapability(1920, 1080);

  /// PNG_SM: 640x480 (4:3 — TVs/renders legados).
  static const sm = DlnaScreenCapability(640, 480);

  /// PNG_TN: 160x160 thumbnail — impróprio para palco, mas informa.
  static const tn = DlnaScreenCapability(160, 160);
}
